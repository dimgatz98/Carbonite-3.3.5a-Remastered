# CustomWaypoints Checkpoint

_Last updated from current `CustomWaypoints.lua` and refreshed audit docs._

This file is the short operational checkpoint for future edits. Treat it as the project state summary, not as full architecture documentation. Full details live in the updated architecture/manual/routing/invariants docs.

---

## Current Project Shape

CustomWaypoints is a monolithic WotLK 3.3.5a Lua addon layered on top of Carbonite.

Carbonite owns map rendering, low-level target storage, map IDs, coordinate projection, and existing travel data. CustomWaypoints owns the waypoint queue, route planning, known-location database, import/export, transport discovery, UI flows, and the projection of computed route points back into Carbonite targets.

Primary source of truth:

- Active queue: `CustomWaypointsDB.destinations`
- Known saved data: `CustomWaypointsDB.knownLocations`
- Learned runtime/imported transports: `CustomWaypointsDB.learnedTransports`
- Runtime route cache: `STATE.expandedRoute`
- Carbonite targets: output/projection only, never durable CW truth

---

## Core Capabilities

- Waypoint capture from Carbonite world map.
- Current-location save flow via `/cw savehere` and Save Here binding.
- Persistent waypoint queue in `STATE.db.destinations` / `CustomWaypointsDB.destinations`.
- Queue import/export.
- Queue-based routing from current player position through one or more queue stops.
- Minimal/deep routing separation through `simplifyTransitWaypoints`.
- Transport-aware routing across portals, boats, zeppelins, tram/passages, taxi/flight masters, saved routes, and learned/manual transports.
- Graph-based route expansion using Carbonite connectors, known locations, learned transports, saved routes, taxi nodes, and local walk links.
- Carbonite sync reduction: expanded route can contain more points than the reduced sync points pushed into Carbonite.
- Destination search UI for ambiguous destination names.
- Slash destination fallback:
  - `/cw <current-map-x> <current-map-y>`
  - `/cw <zone name> <x> <y>`
  - `/cw <keyword>` search across known locations and Carbonite-derived candidates.
- Known Locations system as the single source of truth for:
  - saved routes
  - manual transports
  - learned transports
  - instance entrances
- Import/export for known locations with merge/dedupe behavior.
- Undo/redo via `STATE.history` and `STATE.future`.
- Login recovery: non-empty saved queue auto-syncs once the map is available.
- Optional transport discovery with confirmation/suppression behavior.
- Death auto-route to remembered saved instance entrance.
- Taxi-aware routing behavior:
  - injects active taxi destination as temporary queue head
  - suppresses repeated heavy route refreshes while on taxi
  - refreshes once after taxi ends when needed.

---

## UI / UX

Main user-facing UI surfaces:

- Main CustomWaypoints window.
- Known Locations window.
- Destination Search window.
- Routing Tuning window.
- Waypoint import/export popups.
- Known-location import/export popups.
- Save Here / Save Route metadata flows.
- Transport confirmation popup.
- Interface Options panel.

Interface/options settings currently include or imply:

- auto-sync to Carbonite
- auto-advance
- deep/minimal transit simplification
- flight master usage
- transport discovery
- transport confirmation
- transport logging/debugging
- death auto-route to saved instance
- UI scale/show UI
- routing tuning overrides

Input/keyboard rules:

- ESC belongs to the CW modal stack; it should close only the most recent CW modal.
- Passive CW frames must not consume WASD during normal play.
- Known Locations is the management surface for transports; do not reintroduce a separate transport manager.
- Delete/Shift+Delete behavior must not fire while typing in a search box.
- Search focus behavior must be deliberate; avoid stealing input too early.

---

## Routing Pipeline

Normal queue-to-Carbonite flow:

1. User action changes the queue or target.
2. CW records history when appropriate.
3. CW invalidates graph/route/signature state.
4. `BuildExpandedRoute()` chains legs from current player position to every queue stop.
5. `BuildRouteLeg()` builds each leg.
6. `BuildTransportLeg()` uses the graph when transport/deep routing is required or useful.
7. `BuildSyncPoints()` reduces the expanded route into Carbonite-facing sync points.
8. `SyncQueueToCarbonite()` clears Carbonite targets under suppression and pushes the reduced points.

Important distinction:

- `STATE.expandedRoute` is the semantic route CW computed.
- Carbonite targets are a reduced visual/control projection.
- A smaller Carbonite target count is not necessarily a routing bug.

---

## Routing Model

Graph sources:

- Carbonite map/zone connector data.
- Carbonite travel/passages where usable.
- Known manual transports.
- Learned transports.
- Saved known routes.
- Known/session taxi and flight master nodes.
- Same-map walk links between graph nodes.

Edge-like concepts:

- `start`
- `walk`
- `fly`
- `connector`
- `portal`
- `boat`
- `zeppelin`
- `tram`
- `passage`
- `flight_master`
- `taxi` normalized toward flight-master semantics
- `route` for saved known-route hops
- transport/walk-to-transport/node-to-goal helper edges

Pathfinding is effectively uniform-cost graph search; route quality is heuristic rather than exact real-world travel-time optimal.

---

## Child / Subzone Routing

Known sensitive case:

- Parent map: `Dalaran`
- Child/subzone layer: `Dalaran Underbelly`
- Example target: `Dalaran Solo Queue`

Rules:

- Parent/child map-layer transitions must not be silently treated as ordinary walk/fly.
- Being in the parent zone does not automatically mean being in the child subzone.
- If the queued destination has already been resolved to the parent map, child transport logic may never get a chance to run. Debug `/cw list` first.
- Saved passage/transport entries such as `Dalaran <-> Underbelly` should be preferred over parent fallback.
- Parent fallback is acceptable only as conservative fallback metadata, not as a silent replacement of the real child destination.
- Single-node transport anchors need zone/subzone alias metadata to synthesize a routeable parent-side entry.

Current focus area:

- Validate that destination resolution preserves child identity before routing.
- Validate that manual transport/passages are injected into the graph for child/subzone targets.
- Simplify any heavy child-subzone continuation code once the exact minimum decision point is proven.

---

## Transport / Known Location Contracts

Known-location kinds:

- `route`
- `transport`
- `instance`

Transport kinds:

- `portal`
- `tram`
- `boat`
- `zeppelin`
- `taxi`
- `flight_master`
- `passage`
- `route`

Contracts:

- Known Locations remains the single management UI for saved routes, transports, learned transports, and instances.
- Import of known locations is merge/dedupe; queue import is replace-queue.
- Transport kind must be normalized before comparison/routing.
- Flight masters are always bidirectional for WotLK behavior.
- Bidirectional flag controls reverse traversal for non-flight-master manual transports.
- Saved routes are graph hints, not hidden teleports.
- Adjacent route points become graph edges.
- Single-node manual transports are allowed only when enough destination alias/hint metadata exists to make them routeable.
- Two-point manual transports must preserve both endpoint metadata blocks.

---

## Death Auto Route

Capability:

- Automatically routes to a saved instance entrance after death when a valid remembered instance context exists.

Controlled by:

- `autoRouteSavedInstanceOnDeath`

Main flow:

- `CaptureDeathInstanceContext`
- `RememberCorpseInstanceContext`
- `StartPendingDeathAutoRoute`
- `PulsePendingDeathAutoRoute`
- `TryAutoRouteSavedInstanceOnDeath`
- `ResetDeathAutoRouteCycle`

Rules:

- Optional and user-controlled.
- Retry-based, not instant-only.
- Must be safe when map data is not ready.
- Must not spam or loop indefinitely.
- Must not route to an instance entrance unless the player actually had a remembered relevant instance/death context.

---

## Taxi Routing

Capability:

- While on taxi, CW injects an active taxi destination as a temporary queue head.
- Route refresh while airborne is throttled/suppressed to avoid repeated Carbonite churn.
- On taxi end, CW removes the transient taxi point and reroutes once if needed.

Important helpers/concepts:

- `CW.GetActiveTaxiDestination`
- `CW.EnsureTaxiDestinationQueueHead`
- `CW.RemoveTaxiDestinationQueueHead`
- `CW.EnterTaxiTransitRoutingOverride`
- `CW.LeaveTaxiTransitRoutingOverride`
- `CW.TryTaxiPeriodicRefresh`
- `STATE.sessionKnownTaxis`
- `STATE.lastGroundPlayerPos`

Rules:

- Taxi-injected destinations must not become persistent user queue entries.
- Taxi routing must not repeatedly rebuild unchanged routes.
- Taxi end is a meaningful reroute point; every zone-change while on taxi is not.

---

## Import / Export

Queue import/export:

- Queue export serializes active destinations.
- Queue import replaces the active queue.

Known-location import/export:

- Export uses `CWKNOWN|...` style known-location records plus transport edge lines where applicable.
- Import should be strict about invalid rows.
- Import should merge and dedupe rather than blindly duplicate existing known locations.
- Backward compatibility matters: old valid records should keep importing unless explicitly retired.

---

## Debugging Commands

Primary commands:

- `/cw help`
- `/cw ui`
- `/cw options`
- `/cw tuning`
- `/cw savehere`
- `/cw saveroute`
- `/cw list`
- `/cw route`
- `/cw graph`
- `/cw sync`
- `/cw clear`
- `/cw pop`
- `/cw undo`
- `/cw redo`
- `/cw export`
- `/cw import`
- `/cw knownlocations`
- `/cw search`
- `/cw autosync`
- `/cw autoadvance`
- `/cw flightmasters` / `/cw taxi`
- `/cw deep`
- `/cw minimal`
- `/cw simplify`
- `/cw autodiscovery`
- `/cw transportconfirmation`
- `/cw transportlog`
- `/cw transports`
- `/cw cleartransports`
- `/cw debug`
- `/cw debugfm <name>`

Important route debug fields:

- queue count
- Carbonite target count
- expanded route point count
- sync point count
- total cost
- explored node count
- spell flying detection
- simplify transit flag
- use flight masters flag
- each route point `maI`, map name, zone coords, world coords, edge type, cost, label

For child/subzone bugs, always capture:

1. `/cw list`
2. `/cw route`
3. Known-location record/export for the relevant transport/passsage
4. Current map/subzone text if available
5. Whether the target resolved to parent map or child map

---

## Do NOT Break These

- Queue persistence across reload.
- Carbonite sync isolation: internal Carbonite clears must not accidentally wipe CW queue.
- User-triggered Carbonite clear may clear CW queue only through the intended hook path.
- Minimal vs deep routing semantic separation.
- Known Locations as single source of truth.
- Import/export backward compatibility.
- Death auto-route safety and retry behavior.
- Taxi transient queue entry cleanup.
- UI modal stack / ESC behavior.
- WASD pass-through for passive frames.
- Flight master bidirectionality.
- Child/subzone identity preservation.
- Transport-required legs must not be replaced by unsafe walk/fly fallback.
- Lua 5.1 local/upvalue limits.

---

## Lua / Patch Discipline

The file is monolithic and already close to Lua 5.1 limits.

Rules for future patches:

- Search for existing helpers before adding new helpers.
- Prefer modifying the existing decision point over adding a parallel subsystem.
- Avoid new top-level `local function` unless absolutely necessary.
- Prefer `CW.HelperName = function(...)` for top-level helpers that must be globally reachable inside the file.
- Prefer nested local helpers only when they are truly one-off and do not increase dangerous upvalue pressure.
- Keep diff small enough to review manually.
- Do not add broad fallback routing without a named reason and test case.
- Do not silently change persisted schema without import/export compatibility handling.
- Run at least a Lua syntax/load sanity check before release.

Recent concrete lesson:

- Hitting `main function has more than 200 local variables` means the patch added too many top-level locals. The fix should reduce top-level local declarations, not keep expanding the main chunk.

---

## Known Limitations

- Routing is heuristic, not exact optimal travel-time routing.
- Carbonite map/connector/taxi data quality directly affects routing quality.
- Child/subzone routing is fragile when Carbonite/API map identity collapses to parent zone text.
- Single-node transport anchors depend on good aliases/hints.
- Auto-discovery can be noisy around teleports/LFG/instance transitions.
- Instance detection can be noisy in edge cases or maps without stable world coordinates.
- Import is intentionally strict for malformed rows.
- Undo history is capped.
- Questie + Carbonite + CW can stutter in some setups; avoid unnecessary deep reroutes.

---

## Current High-Priority Improvement Backlog

1. Child/subzone routing audit:
   - prove whether `/cw solo queue` resolves to Dalaran parent or Underbelly child before graph routing;
   - ensure explicit `Dalaran <-> Underbelly` passage is visible to graph routing;
   - keep parent fallback explicit and debuggable.

2. Simplify heavy child/subzone fallback code:
   - remove duplicated helper logic where existing endpoint/alias helpers can be reused;
   - avoid parallel routing systems.

3. Failure cleanup:
   - route rebuild failure should clear stale expanded route/signature/Carbonite projection;
   - it must not destructively wipe the user queue.

4. Transport data quality:
   - improve validation/debug display for single-node transports;
   - show aliases/hints clearly in edit/export/debug output.

5. Routing invalidation discipline:
   - avoid route rebuild on every minor zone change;
   - reroute only when effective route context changes.

---

## Sanity Test Before Release

Basic queue/sync:

1. Add waypoint from Carbonite map click.
2. Add waypoint via `/cw <zone> <x> <y>`.
3. Add waypoint via `/cw <current-map-x> <current-map-y>`.
4. `/cw list` shows expected map/zone/world coordinates.
5. `/cw sync` pushes Carbonite targets.
6. `/cw clear` clears queue and Carbonite projection.

Routing:

1. Single waypoint route works.
2. Multi-waypoint route works.
3. `/cw route` prints expanded route and sync summary.
4. Deep mode preserves transit semantics.
5. Minimal mode reduces visual noise without changing final destination.
6. Cross-continent route uses valid transport, not direct walk.
7. Same-region flying only happens when allowed and not transport-required.

Known Locations:

1. Save route.
2. Save current location.
3. Add/edit/delete known location.
4. Route to known location.
5. Import/export known locations.
6. Duplicate import does not duplicate records.
7. Flight master transport remains bidirectional.

Child/subzone:

1. Save/verify `Dalaran <-> Underbelly` passage/transport.
2. Route from Dalaran parent to Underbelly target.
3. Route from Stormwind to `Dalaran Solo Queue`.
4. Confirm route includes Dalaran-side entry + Underbelly passage when target is child/subzone.
5. Confirm fallback to parent is explicit if no child transport exists.
6. Confirm `/cw list` preserves child target identity when expected.

Taxi:

1. Open taxi map and refresh known taxis.
2. Start taxi while queue exists.
3. Confirm temporary taxi destination appears only while on taxi.
4. Confirm no repeated route spam during taxi.
5. Confirm route refreshes after taxi ends.

Death auto-route:

1. Setting ON: death inside remembered saved instance context routes to entrance.
2. Setting OFF: no route.
3. Death outside valid instance context: no false route.
4. Missing map/coords: retries safely, then stops.

UI/input:

1. ESC closes only topmost CW modal.
2. WASD still moves character when passive CW frames are open.
3. Known Locations search focus does not swallow global controls incorrectly.
4. Delete selected known location does not trigger while typing.
5. Destination search ambiguity UI can select/double-click route.

Failure behavior:

1. Force/observe route failure.
2. Confirm stale expanded route is not reused.
3. Confirm subsequent unrelated waypoint does not keep failing because of stale state.
4. Confirm user queue is not wiped unless user explicitly clears it.

---

## Release Rule

A release candidate is acceptable only if:

- no Lua load errors,
- no main-chunk local limit errors,
- no obvious stale Carbonite target state after failure,
- queue survives reload,
- import/export round trip works,
- child/subzone case has been manually tested if routing code changed,
- taxi and death auto-route are not regressed if event logic changed.
