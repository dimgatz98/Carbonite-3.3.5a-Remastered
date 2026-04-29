# Invariants — CustomWaypoints

These are the rules future changes must preserve.

## Queue ownership

- `CustomWaypointsDB.destinations` is the active queue source of truth.
- Carbonite targets are output/projection only.
- User Carbonite clear may clear the CW queue.
- CW internal Carbonite clear during sync must not clear the CW queue.

## Persistence

- Durable data lives in `CustomWaypointsDB`.
- `EnsureDb()` is the only normal startup/defaulting path.
- Runtime caches must not override saved queue/known-location truth.

## Route invalidation

Any change to these must invalidate route state:

- queue,
- known locations,
- learned transports,
- routing mode,
- flight master setting,
- routing tuning,
- faction/transport policy affecting graph eligibility.

Invalidation must clear graph, expanded route, and sync signature unless deliberately scoped.

## Carbonite sync

- Sync receives route points from CW, not from Carbonite.
- Sync must use suppression around internal Carbonite clears.
- Reduced sync points may differ from expanded route points.
- Failed route rebuild must not leave misleading stale route state.

## Routing modes

- Deep mode may use graph and explicit route nodes.
- Minimal mode may collapse transit noise but must not change the semantic destination.
- Cross-continent direct walk fallback is unsafe by default.
- Parent/child map-layer transitions require explicit transport or conservative parent fallback.

## Known locations

- Known Locations is the single management UI for routes, transports, and instances.
- No separate transport-management UI should be reintroduced.
- Known-location import is merge + dedupe.
- Waypoint queue import is replace-queue.
- Flight master transports are bidirectional.

## Transport records

- Normalize transport kinds before comparison/routing.
- Reuse existing alias builders and endpoint builders.
- Single-node transports must preserve destination aliases/hints.
- Two-point manual transports must preserve from/to endpoint metadata.

## Destination identity

- Do not silently replace a child/subzone destination with its parent unless the fallback is explicitly marked.
- If a route falls back to parent, preserve child target metadata for debugging.
- User label/name should survive route expansion and Carbonite sync label generation.

## UI and input

- ESC closes only the most recent CW modal.
- CW UI must not block WASD during normal play.
- Delete override is allowed only for known-location selection and only when not typing.
- Frames should be lazy-created and cleaned from modal stack on hide.

## Transport discovery

- AutoDiscovery must be optional.
- No/ESC must suppress repeated prompts.
- LFG/teleport-like transitions must not be learned as walked transports.
- Duplicate learned transports must be compacted/touched, not duplicated.

## Death autoroute

- Must be optional.
- Must only use a remembered instance context.
- Must use delayed/retried pending state.
- Must not loop indefinitely.

## Monolithic Lua limits

- Avoid new top-level `local function` unless necessary.
- Prefer `CW.SomeHelper = function` or reuse existing helpers when helper must be top-level.
- Prefer nested locals inside existing functions for one-off code.
- Watch both Lua 5.1 main-chunk local limit and function upvalue limits.

## Change discipline

- Search for existing helpers before adding new helpers.
- Prefer a small change at the decision point over a parallel subsystem.
- Add debug evidence for route-policy changes.
- Update tests/docs for every new routing case.
