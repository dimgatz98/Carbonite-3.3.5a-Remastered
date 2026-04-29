# Architecture — CustomWaypoints

## One sentence

CustomWaypoints is a queue-owning route planner, known-location database, and Carbonite sync layer for WotLK/Carbonite. Carbonite remains the map renderer and low-level target backend.

## Ownership

### Carbonite owns

- Map/minimap/HUD rendering.
- Native goto target storage.
- Map IDs and coordinate conversion (`GWP`, `GZP`, `GCMI`, `ITN`).
- Native connector/travel data (`Nx.ZoC`, `MWI`, taxi data).

### CustomWaypoints owns

- Active waypoint queue: `CustomWaypointsDB.destinations`.
- Queue import/export.
- Known locations: routes, instances, and manual transports.
- Learned transports discovered at runtime.
- Deep route graph construction and route expansion.
- Sync-point reduction before pushing targets to Carbonite.
- UI, hotkeys, modal stack, metadata popups, search UI.
- Death instance autoroute and taxi-aware refresh policy.

## State layers

### Persistent state: `CustomWaypointsDB`

- `destinations`: active queue.
- `knownLocations`: user-authored saved routes/transports/instances.
- `learnedTransports`: discovered/imported transport edges.
- Settings: autosync, autoadvance, deep/minimal, flight masters, discovery, death autoroute, debug, UI scale, routing tuning.

`EnsureDb()` creates missing defaults and coerces booleans that may have been persisted as strings.

### Runtime state: `STATE`

- `graph`: cached graph.
- `expandedRoute`: full expanded route from current player position through queue stops.
- `lastCarboniteSyncSignature`: reduced sync signature used to skip unchanged sync.
- `syncing` and `suppressClearUntil`: guard internal Carbonite clears.
- `history` and `future`: undo/redo.
- `cwModalStack`: modal ESC ownership.
- taxi, discovery, death-route, and UI scratch state.

Runtime state is never the durable source of truth.

## Main flow: queue to route to Carbonite

1. User action adds/replaces/removes queue points.
2. CW pushes history snapshot where needed.
3. CW invalidates route/graph/signature.
4. `BuildExpandedRoute()` chains route legs from current player position to each queue stop.
5. Each leg is built by `BuildRouteLeg()`.
6. Deep legs use `BuildTransportLeg()` and the graph when useful/required.
7. `BuildSyncPoints()` reduces expanded route points for Carbonite.
8. `SyncQueueToCarbonite()` clears Carbonite targets under suppression and calls `map:SeT3` for each sync point.

## Graph model

The graph is built from:

- Carbonite passages.
- Carbonite zone connectors.
- Learned transports.
- Known manual transports.
- Known routes.
- Known/session taxi nodes.
- Local walk links between same-map graph nodes.

Graph pathfinding is uniform-cost search. `FindPathAStar` currently uses a zero heuristic.

## Routing modes

### Deep mode

- Full graph-based routing when useful or required.
- Explicit transport/fly/route nodes are preserved unless sync reduction collapses visual noise.
- Cross-map direct fallback is blocked when unsafe.

### Minimal/simplified transit mode

- Route computation can still happen, but transit noise is collapsed more aggressively before sync.
- Carbonite receives fewer intermediate points.

## Transport model

Transport-like kinds include:

- `portal`
- `tram`
- `boat`
- `zeppelin`
- `passage`
- `flight_master`
- `taxi` normalized to `flight_master`
- `route` for saved known-route hops

Manual transports can be:

- two-point edge: entry -> destination;
- one-point anchor: destination only, with zone/subzone aliases used to synthesize a routeable from-side when possible.

## Child/subzone model

Some Carbonite/WotLK layers behave like separate map IDs even when they share world coordinates with a parent zone. Example: Dalaran and Dalaran Underbelly.

Rules:

- Parent/child layer transitions are transport-required unless the player already matches the child context.
- Direct flying must not replace child-layer transports.
- If graph routing to a child layer fails, CW may route to a conservative parent point and continue through an explicit saved transport if one exists.
- If the queued destination was resolved to the parent map already, the child transport layer cannot be used unless transport injection happened before routing.

## UI model

- Main UI and Known Locations UI are lazy-created.
- ESC is controlled by CW modal stack.
- WASD must not be consumed by passive UI.
- Search boxes must not steal global delete/ESC behavior.

## Event model

Startup installs hooks/bindings/options and schedules one pending sync for a non-empty saved queue.

OnUpdate drives:

- pending login sync,
- transport discovery,
- death autoroute retries,
- autoadvance,
- taxi lifecycle,
- hook/binding safety reinstallation.

Zone events refresh route only when cached route context is no longer valid. Taxi suppresses repeated route rebuilds.
