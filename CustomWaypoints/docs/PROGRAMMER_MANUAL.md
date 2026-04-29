# CustomWaypoints Programmer Manual — Personal Reference

## 0. Mental model

CustomWaypoints is not a replacement map. It is a planner and data layer that feeds Carbonite.

- CW owns the queue.
- Carbonite renders targets and supplies map/connector data.
- CW route expansion can produce more points than the queue.
- Carbonite sync points are a reduced projection of the expanded route.

Think in four layers:

1. **Persistent model**: `CustomWaypointsDB`.
2. **Runtime model**: `STATE`.
3. **Routing graph**: temporary/cached graph built from Carbonite + learned/known data.
4. **Carbonite projection**: `map:SeT3(...)` calls after route reduction.

## 1. Persistent data model

### `CustomWaypointsDB.destinations`

The active queue. Each item is a point-like table:

```lua
{
  maI = 4003,
  mapName = "Dalaran",
  zx = 57.4,
  zy = 47.2,
  wx = 2302.279,
  wy = -3098.887,
  userName = "Dalaran Solo Queue",
  userLabel = "...",
  description = "...",
  zoneText = "Dalaran",
  subZoneText = "Dalaran Underbelly",
  ts = "2026-..."
}
```

This queue is the source of truth. Never infer the queue from Carbonite targets.

### `CustomWaypointsDB.knownLocations`

User-authored durable places. Kinds:

- `route`: has `routePoints` and can load multiple queue stops.
- `transport`: represents a routeable transport-like known location, either one-point anchor or two-point edge.
- `instance`: saved instance/entrance target, used by death autoroute and known locations.

### `CustomWaypointsDB.learnedTransports`

Transport records discovered automatically or imported from `T|...` rows. These are graph edges, not ordinary queue stops.

## 2. Runtime state

`STATE` holds everything that should not be treated as saved truth:

- `STATE.graph`: cached graph from Carbonite + known/learned data.
- `STATE.expandedRoute`: latest expanded route object.
- `STATE.lastCarboniteSyncSignature`: last reduced Carbonite sync signature.
- `STATE.syncing` and `STATE.suppressClearUntil`: distinguish internal Carbonite clear from user clear.
- `STATE.history` / `STATE.future`: undo/redo.
- `STATE.pendingTransport`: transport discovery state.
- `STATE.cwModalStack`: modal ordering for ESC.
- taxi/death-route/session-taxi fields.

Rule: if a route-affecting persistent structure changes, call `InvalidateRoute(reason)`.

## 3. Add waypoint flow

### Click/cursor capture

1. User clicks or runs `/cw add`.
2. `GetDisplayedCapture(map)` reads the visible Carbonite map, not necessarily the player’s current zone.
3. A point is appended to `STATE.db.destinations`.
4. History snapshot is pushed.
5. `InvalidateRoute` clears graph/expanded route/signature.
6. If autosync is on, `SyncQueueToCarbonite()` runs.

This is why CW supports planning routes on a map you are viewing while standing somewhere else.

### `/cw <x> <y>`

Adds a waypoint to the current displayed/current Carbonite map coordinates.

### `/cw <zone> <x> <y>`

1. Parses final two tokens as coordinates.
2. Resolves the zone name through `CW.ResolveMapIdBySmartName`.
3. Also checks `CW.ResolveManualTransportDestinationByName`.
4. If a transport alias is a better match, the transport can be preferred.
5. For transport aliases, the queue can inject transport entry/exit before the final destination.

Important: for subzones like Underbelly, the stored/resolved `maI` matters. If the final queued stop is parent Dalaran, routing will end in Dalaran unless transport injection adds child points.

## 4. Known locations flow

### Route to known location

`RouteToKnownLocation(index)` clears the current queue and loads:

- every `routePoint` for `kind="route"`; or
- one cloned destination for `transport`/`instance`/single point entries.

Then it invalidates and optionally syncs.

### Save queue as known route or transport

`SaveQueueAsKnownRoute()` opens metadata popup.

- Normal save: stores `kind="route"` with `routePoints`.
- Transport checkbox checked:
  - one queue point -> single-node transport anchor in known locations.
  - two queue points -> learned/manual transport edge in `learnedTransports`.
- Flight Master checked:
  - transport kind is `flight_master`.
  - bidirectional is forced.

Zone/Subzone field is part of transport save flows because the map API may only report a parent zone while the user wants a child-layer route target.

## 5. Routing graph

### Base graph sources

`EnsureGraph()` builds graph nodes and edges from:

1. Carbonite map-window passages (`map.MWI[].Con1`).
2. Carbonite zone connectors (`Nx.ZoC`).
3. `learnedTransports`.
4. `knownLocations` of kind `transport`.
5. `knownLocations` of kind `route`.
6. Known/session taxi nodes.
7. Same-map walk edges between nearby graph nodes.

### Node/edge concepts

Node fields:

```lua
{
  id,
  maI,
  wx,
  wy,
  label,
  type = "connector" | "transport" | "route" | "start" | "goal",
  continent,
  edges = {}
}
```

Edge fields:

```lua
{
  to,
  cost,
  type = "walk" | "connector" | "portal" | "boat" | "zeppelin" | "tram" | "flight_master" | "route" | "passage",
  label,
  learnedHop,
  routeTransportKind
}
```

## 6. Path search

`BuildTransportLeg(startPoint, destPoint)`:

1. Gets/copies the base graph.
2. Adds synthetic start and goal nodes.
3. Attaches start/goal to graph candidates on matching maps/continents.
4. Runs uniform-cost search through `FindPathAStar`.
5. Converts node path into route points.
6. Optionally optimizes the tail with direct flying if capability rules allow.
7. Collapses taxi chains/noise depending on mode.

The function name says A*, but heuristic is zero. This is Dijkstra/uniform-cost search. That is safer for current weighted graph behavior.

## 7. Route leg policy

`BuildRouteLeg(start, dest)` decides the strategy:

1. If direct flying is legal, return a simple fly leg.
2. Else try graph route.
3. If graph route succeeds:
   - same-map route must be useful/transport-aware to beat direct leg;
   - transport-required legs must actually use transport.
4. If graph route fails:
   - try parent fallback for child/subzone destination;
   - try explicit child transport continuation;
   - try Outland bridge if applicable;
   - try South Kalimdor fallback if applicable;
   - block unsafe cross-continent direct walk.
5. If transport is required and not found, fail.
6. Else use direct fallback.

## 8. Child/subzone routing

Current child/subzone behavior has four moving parts:

1. `CW.DoesLegRequireTransportPath`: identifies map-layer transitions that should not be treated as walk/fly.
2. `CW.BuildRouteableParentPointForChildDestination`: derives a routeable parent point from a child destination.
3. `CW.FindExplicitTransportEdgeBetweenMaps`: finds known/learned transport edges between parent and child maps.
4. `TryAppendExplicitChildTransportAfterParentFallback`: after parent fallback, append entry -> child transport -> final child target.

Diagnostic rule for Underbelly:

- If `/cw list` shows the queued destination as parent `Dalaran` (`maI=4003`), investigate destination search/saved data first.
- If `/cw list` shows child `Dalaran Underbelly` but route ends at parent Dalaran, investigate `FindExplicitTransportEdgeBetweenMaps` and parent fallback continuation.
- If route hard-fails with `transport-required-no-path`, inspect whether the saved passage is single-node and whether aliases resolve a parent map id.

## 9. Sync to Carbonite

`SyncQueueToCarbonite(skipIfUnchanged, routeOverride)`:

1. Gets Carbonite map.
2. Builds expanded route if no override is supplied.
3. Builds reduced sync points via `BuildSyncPoints`.
4. Builds signature and optionally skips unchanged sync.
5. Installs Carbonite travel hook.
6. Clears Carbonite targets through CW wrapper.
7. Calls `map:SeT3` for each sync point.
8. Sets suppression window so Carbonite clear hook does not wipe CW queue.

Risk: failed route rebuild currently returns before clearing stale route/signature/targets. A localized fix here is high-value.

## 10. Auto-advance

Auto-advance checks distance from player to current synced route point, not simply raw first queue item. This matters because expanded route may contain intermediate transport/fly nodes.

Queue pop goes through `AdvanceCurrentRouteTarget(reason)`, then invalidates/syncs.

## 11. Taxi behavior

Taxi behavior is special because player position changes rapidly and map zone events can fire repeatedly.

- While on taxi, CW uses a ground anchor as route start if available.
- CW can inject active taxi destination as queue head.
- Route refresh is throttled (`taxiRefreshInterval`).
- On taxi end, CW removes transient taxi queue head and reroutes once if needed.

## 12. Transport discovery

Discovery watches real world/map transitions. It tries not to prompt on:

- local indoor overlays,
- same/nearby coordinates,
- LFG teleports,
- repeated dismissed transitions,
- recent duplicate instance entries.

Confirmed discovery can save:

- learned transport edge; or
- known instance entry.

No/ESC must dismiss and suppress repeats.

## 13. UI and modal rules

All custom frames that behave like dialogs should use the CW modal stack.

- ESC closes only the latest CW modal.
- Search/edit boxes clear focus on ESC first when appropriate.
- WASD must not be consumed during normal gameplay.
- Delete override only applies to known-location selection when not typing.

## 14. Import/export formats

Queue export rows are ordinary waypoint rows.

Known location export uses:

- headers for known locations;
- waypoint rows for route points;
- `T|...` rows for learned/manual transports.

Ordinary waypoint import replaces the active queue.

Known locations import merges and deduplicates.

## 15. Debugging checklist

### Route bug

1. Run `/cw list`.
2. Run `/cw route` with debug on.
3. Check final queued destination `maI`, `mapName`, `zoneText`, `subZoneText`.
4. Check whether route points use expected `edgeType`.
5. If graph fails, note exact reason: `no-path`, `transport-required-no-path`, `cross-continent-no-transport-path`, etc.
6. If known transport should be used, export known locations and inspect `kind`, `transportKind`, `bidirectional`, from/to map ids, and zone hints.

### Sync bug

1. Check queue count vs `carboniteTargets` vs `expandedRoute` vs `syncPoints`.
2. If a failure happened before, clear stale Carbonite targets manually and retry.
3. Inspect `STATE.lastCarboniteSyncSignature` behavior when `skipIfUnchanged=true`.

### UI bug

1. Test ESC.
2. Test WASD after opening/closing frame.
3. Test search box focus.
4. Test Shift+Delete only outside input boxes.

## 16. Safe extension pattern

Before writing code:

1. Search for an existing helper in this order: transport normalization, alias matching, route-point clone/build, known-location clone, graph injection, slash parsing.
2. Prefer extending an existing helper over creating a parallel mechanism.
3. Avoid new top-level `local function` unless you confirm main-chunk local count is safe.
4. Keep changes close to the decision point.
5. Add a debug line before changing route policy.
6. Update manual test cases.
