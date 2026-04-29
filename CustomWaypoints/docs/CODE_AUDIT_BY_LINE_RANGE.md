# Code Audit by Line Range — CustomWaypoints.lua

Scope: current appended `CustomWaypoints.lua`, no code changes. The file is 11,740 lines. This audit is line-range based and function-level, because a literal per-line paraphrase would duplicate the source without adding useful engineering signal.

## Executive model

CustomWaypoints is a queue-owning route planner and data layer on top of Carbonite. Carbonite remains the visual map/HUD/target backend. CW owns the saved queue, known locations, learned/manual transports, route expansion, reduced sync projection, UI, import/export, and event-driven refresh policy.

The central runtime flow is:

`slash/UI/click input -> queue mutation -> InvalidateRoute -> BuildExpandedRoute -> BuildRouteLeg -> BuildTransportLeg/graph/fallback -> BuildSyncPoints -> ClearCarboniteTargets -> map:SeT3(...)`

The central persistence flow is:

`CustomWaypointsDB -> EnsureDb normalization -> STATE.db -> queue/knownLocations/learnedTransports -> import/export/dedupe -> route graph injection`

## Line-range audit

| Lines | Area | What it does | Risk / rule |
|---:|---|---|---|
| 1-126 | Header, cached Lua globals, defaults, state forward declarations | See detailed notes below. | Header is stale; update docs/title but avoid changing runtime here unless needed. |
| 127-312 | Early UI/logging/autodiscovery/tuning compatibility helpers | See detailed notes below. | Main-chunk local pressure; avoid adding new top-level local functions. |
| 313-407 | WotLK 3.3.5a/flying capability policy | See detailed notes below. | Preserve behavior; changes here can cascade. |
| 408-605 | Transport kind canonicalization and manual transport record construction | See detailed notes below. | Routing/transport core; prefer existing helpers and add debug before policy changes. |
| 631-953 | Transport aliases, endpoint matching, zone-context checks, transport-required leg detection | See detailed notes below. | Routing/transport core; prefer existing helpers and add debug before policy changes. |
| 964-1125 | Tuning costs, attach scoring, STATE runtime cache/state table | See detailed notes below. | Main-chunk local pressure; avoid adding new top-level local functions. |
| 1133-1420 | Carbonite map accessor, player start point, taxi queue injection/override | See detailed notes below. | Main-chunk local pressure; avoid adding new top-level local functions. |
| 1433-1599 | Walk/fly cost model and faction-restricted graph filtering | See detailed notes below. | Preserve behavior; changes here can cascade. |
| 1600-2093 | Transport costs, learned/known transport injection, known route injection, taxi node lookup | See detailed notes below. | Routing/transport core; prefer existing helpers and add debug before policy changes. |
| 2095-2467 | Uniform-cost path search, parent/child route fallback helpers, explicit child transport append | See detailed notes below. | Routing/transport core; prefer existing helpers and add debug before policy changes. |
| 2468-2708 | Base graph construction from Carbonite connectors, known routes/transports, taxis, walk links | See detailed notes below. | Routing/transport core; prefer existing helpers and add debug before policy changes. |
| 2712-3218 | Path selection, optional learned prefix, taxi chain collapse, BuildTransportLeg, flying-tail optimization | See detailed notes below. | Routing/transport core; prefer existing helpers and add debug before policy changes. |
| 3220-3476 | Route leg policy: direct/fly fast path, graph path, child fallback, Outland/Kalimdor fallbacks | See detailed notes below. | Routing/transport core; prefer existing helpers and add debug before policy changes. |
| 3478-3817 | Expanded route assembly, sync point reduction, world-context refresh, taxi periodic refresh | See detailed notes below. | Preserve behavior; changes here can cascade. |
| 3832-4078 | String display escaping, transport confirmation keys, modal stack, ESC/Delete overrides | See detailed notes below. | UI/hook code can block movement or cause sticky frames; test ESC/WASD and Carbonite clear. |
| 4092-4387 | Routing tuning UI and tuning mutation | See detailed notes below. | Preserve behavior; changes here can cascade. |
| 4387-5278 | Serialization, import/export parsing, signatures, history, queue lifecycle | See detailed notes below. | Data compatibility; export/import signatures and dedupe must remain stable. |
| 5281-6050 | Known location route/save/edit flows, route vs transport vs instance behavior | See detailed notes below. | Data compatibility; export/import signatures and dedupe must remain stable. |
| 6051-6872 | Known location editor/import/export popups, filtering, dedupe, selection | See detailed notes below. | Data compatibility; export/import signatures and dedupe must remain stable. |
| 6910-7297 | Known locations frame and key binding setup | See detailed notes below. | UI/hook code can block movement or cause sticky frames; test ESC/WASD and Carbonite clear. |
| 7298-7770 | Main CW UI, interface options panel, hotkeys, undo/redo bindings | See detailed notes below. | UI/hook code can block movement or cause sticky frames; test ESC/WASD and Carbonite clear. |
| 7770-8055 | SavedVariables normalization, player position, death-instance autoroute base | See detailed notes below. | Main-chunk local pressure; avoid adding new top-level local functions. |
| 8078-8567 | Transport discovery heuristics and confirmation frame | See detailed notes below. | Event-driven code can spam, reroute, or detect false transports; keep cooldowns/dedupe. |
| 8600-8866 | Learned transport list/clear, discovery pulse, Carbonite hooks, undo/redo, invalidation | See detailed notes below. | Event-driven code can spam, reroute, or detect false transports; keep cooldowns/dedupe. |
| 8874-9585 | Taxi variants, slash zone coordinate resolution, manual transport aliases, South Kalimdor fallback | See detailed notes below. | Preserve behavior; changes here can cascade. |
| 9586-9658 | SyncQueueToCarbonite: build route, reduce sync points, push SeT3 targets | See detailed notes below. | Preserve behavior; changes here can cascade. |
| 9660-10385 | Capture, metadata popup, queue clear/pop/autoadvance, probe/route/graph summaries, map buttons | See detailed notes below. | UI/hook code can block movement or cause sticky frames; test ESC/WASD and Carbonite clear. |
| 10386-10477 | Map click hook and Carbonite clear hook | See detailed notes below. | UI/hook code can block movement or cause sticky frames; test ESC/WASD and Carbonite clear. |
| 10478-10583 | Queue export and flight master debug inspection | See detailed notes below. | Preserve behavior; changes here can cascade. |
| 10584-11340 | Destination keyword search across known locations, Carbonite favorites, guide POIs, UI | See detailed notes below. | Preserve behavior; changes here can cascade. |
| 11348-11504 | Slash command dispatcher | See detailed notes below. | Preserve behavior; changes here can cascade. |
| 11506-11740 | Login/event/update loop, frame registration, public CW exports | See detailed notes below. | Event-driven code can spam, reroute, or detect false transports; keep cooldowns/dedupe. |


## Detailed notes by block

### 1-126 — file identity, defaults, constants

- Caches common globals (`table.insert`, `wipe`, `math.sqrt`, etc.) for old Lua performance.
- Defines `CustomWaypoints` and the local alias `CW`.
- Defines straight/transit edge type sets. `route` is intentionally a transit/straight edge for post-processing and sync behavior.
- Defines SavedVariables defaults: queue, bindings, autosync/autoadvance, routing mode, flight masters, discovery, death autoroute, known locations, and routing tuning.
- Current header still says “Phase 5B”; docs should stop using phase names as architecture truth.

### 127-312 — early helpers

- `RefreshUiHeader` mirrors runtime settings into the main CW UI and Interface Options checkboxes.
- Import text is normalized for BOM/NUL/CRLF cases before parsing.
- `AppendUiLogLine` mirrors chat output into the CW log box.
- `SetAutoDiscoveryEnabled` and `ToggleAutoDiscovery` mutate the discovery setting and clear pending discovery state when disabled.
- `GetRoutingTuning` merges saved tuning overrides with defaults.

### 313-407 — WotLK/flying capability

- The code explicitly gates spell-based flying detection to WotLK 3.3.5a compatibility.
- Northrend and Outland are flyable regions; old world is not treated as flyable.
- `CW.CanUseCapabilityDirectFlyingLeg` is the important policy gate: direct flying is allowed only when both points are in the same flyable expansion region and the leg is not a transport-only map-layer transition.
- Important invariant: Dalaran parent to Underbelly child must not be “solved” by direct flying. It requires a passage/transport or a conservative parent fallback.

### 408-605 — manual transport records

- Transport kinds are canonicalized (`taxi` -> `flight_master`, empty -> `transport`, etc.).
- `NormalizeTransportRecord` makes old and new transport fields consistent.
- `CW.BuildManualTransportFromRoutePoints` is the preferred constructor for 2-point manual transports.
- Single-node transports are allowed: destination-only anchors with zone/subzone hints. They need alias support to act as graph edges later.

### 631-953 — aliases and strict zone context

- Transport aliases are built from map names, zone text, subzone text, labels, and explicit hints.
- `CW.TransportDestinationAliasMatches` is the canonical destination-name matcher for transport target names.
- `CW.IsSingleNodeManualTransportEdge` is the guard for destination-only transports.
- `CW.ResolveBestMapIdFromTransportAliases` attempts to recover a routeable map id from aliases.
- `CW.DoesPointMatchCurrentZoneContextStrict` is intentionally conservative: it accepts same map, loose player-zone match, or proximity to a target endpoint. This is used to avoid injecting parent/child anchors when the player is already in the relevant subzone.
- `CW.DoesLegRequireTransportPath` is the policy gate for parent/child or same-coordinate map-layer transitions.

### 964-1125 — tuning and runtime state

- Tuning bonuses are converted to bounded seconds reductions. The code avoids unbounded “free portal” behavior.
- Attach-candidate scoring biases toward learned portals, taxi hubs, known routes, and terminals while keeping eligibility mostly cost-driven.
- `STATE` is the runtime cache. Saved data lives in `STATE.db`; graph/expanded route/signature are runtime artifacts.
- There is an explicit note that forward locals were removed to stay below Lua 5.1 main-chunk local limits. Future edits must respect this.

### 1133-1420 — current position and taxi handling

- `GetMap` returns Carbonite’s active map object.
- `GetRouteBuildStartPoint` freezes start position while on taxi by using `lastGroundPlayerPos` when available.
- Taxi destination injection is transient and must be cleaned on login and taxi end.
- Taxi mode temporarily simplifies routing and throttles refresh. It should not recenter Carbonite repeatedly.

### 1433-1599 — costs and faction filtering

- Walking/flying costs are seconds-like estimates from world distance.
- Faction code helpers normalize player faction and edge ownership.
- Polygon checks support Dalaran-like restricted areas.
- `CW.IsGraphEdgeAllowedForPlayer` blocks faction-owned nodes/labels/areas during graph edge insertion. This is the correct place for future faction-specific spatial restrictions.

### 1600-2093 — graph edge injection

- Carbonite connectors, learned transports, known manual transports, known routes, and known taxi nodes become graph edges.
- Known transports are built via `CW.BuildManualTransportLikeEdgeFromKnownLocation`.
- Single-node known transports synthesize a from-side node when aliases resolve to a routeable map id and the world coordinate projects into that map.
- Known routes with >=2 points are injected as `route`/transport-kind edges and can be bidirectional.
- Taxi nodes are only injected if flight masters are enabled, not suppressed by flying mode, and known via Carbonite/session taxi knowledge.

### 2095-2467 — search and child-subzone helpers

- `FindPathAStar` is actually uniform-cost search because `HeuristicCost()` returns 0. This is correct for non-negative edge weights and avoids heuristic bugs.
- `CW.BuildRouteableParentPointForChildDestination` tries to derive a routeable parent map point from a child map destination by prefix matching map names and verifying projection with `GZP`.
- `CW.FindExplicitTransportEdgeBetweenMaps` searches learned transports and known transport entries, including reversed bidirectional edges and synthesized single-node entries.
- `TryAppendExplicitChildTransportAfterParentFallback` appends parent entry -> child transport exit -> final child target after a parent fallback.
- Audit finding: this child-subzone logic is functional but heavier than ideal for the project’s “surgical” invariant. If kept, it needs focused tests around Dalaran/Underbelly and exact destination map ids.

### 2468-2708 — base graph construction

- `EnsureGraph` builds and caches the graph.
- Carbonite `MWI.Con1` passages and `Nx.ZoC` connectors are converted into graph nodes/edges.
- Learned transports, known transports, known routes, and taxis are injected after Carbonite-native connectors.
- Same-map graph nodes are linked by bounded walk edges; route/transport nodes get one penalized forced walk link if no local neighbor exists.
- Performance risk: the same-map link phase is O(N²). Acceptable at current graph size, but it needs spatial bucketing if known data grows a lot.

### 2712-3218 — path selection and route-point assembly

- `FindBestPathWithOptionalLearnedPrefix` can force consideration of learned portal prefixes when portal bonuses make them competitive.
- `CollapseDeepTaxiChains` compresses consecutive flight-master legs and small connector noise.
- `BuildTransportLeg` copies the base graph, adds synthetic start/goal nodes, attaches them to same-map/same-continent candidates, runs search, and converts the path into route points.
- Attach eligibility remains mostly cost-driven; hard thresholding here previously caused missed transport paths.
- Flying-tail optimization replaces a graph tail with direct flying only when `CW.CanUseCapabilityDirectFlyingLeg` allows it.

### 3220-3476 — route-leg policy

- `BuildRouteLeg` decides direct, flying, graph, child fallback, Outland entry bridge, South Kalimdor fallback, or failure.
- Same-map graph route is accepted only if it uses transport and is cost-competitive or transport is required.
- Cross-continent direct fallback is blocked unless a special bridge is known.
- Current child fallback only runs after `BuildTransportLeg` fails. If destination search resolves “Solo Queue” to parent Dalaran instead of Underbelly, this fallback will never prove/repair that: the queued destination itself already says parent map.

### 3478-3817 — expanded route and sync reduction

- `BuildExpandedRoute` chains legs from current player position through all queue stops.
- Queue stop metadata is copied onto the last point of each leg so Carbonite labels prefer user labels.
- `BuildSyncPoints` reduces route points for Carbonite, especially in simplified mode.
- `CW.ShouldRefreshRouteForWorldContextChange` avoids expensive reroutes on shallow zone/subzone changes unless the current cached route context is no longer valid.

### 3832-4078 — modals and key overrides

- The modal stack exists so ESC closes the most recent CW modal instead of random UI frames.
- Delete override is scoped to known-location selection and should not fire when typing in search boxes.
- Any new UI frame must be pushed/removed from the modal stack and must not consume WASD.

### 4092-4387 — routing tuning UI

- Tuning values are mutable at runtime and sync can be skipped while editing.
- Changes invalidate route/graph as needed.
- This is the supported place to expose policy knobs instead of hardcoding new hidden biases.

### 4387-5278 — serialization, import/export, signatures, history

- Waypoint export uses pipe-delimited rows.
- Known location export uses headers plus route point rows; learned/manual transport export uses `T|...` rows.
- Ordinary waypoint import replaces the queue.
- Known-location import merges with existing known locations and deduplicates.
- Signatures are central to duplicate detection. Any schema change must preserve old import compatibility.

### 5281-6050 — route/save/edit known locations

- `RouteToKnownLocation` replaces the active queue with either the known route’s route points or a single cloned destination.
- `SaveQueueAsKnownRoute` has a transport-like mode: 1 point = single-node transport anchor, 2 points = entry -> destination manual transport edge.
- Flight Master forces bidirectional behavior.
- Zone/Subzone field is intentionally shown for transport save flows and hidden for ordinary savehere flows.
- The editor handles kind changes but has high coupling; future changes should be small and test route/transport/instance conversion separately.

### 6051-6872 — known location import/export UI

- Known import/export popups escape/unescape display text and support union + dedupe.
- Filtering and selection are derived from `BuildKnownLocationEntries`.
- UX invariant: double-click routing, selection highlight, and search focus must remain stable.

### 6910-7297 — known location frame and bindings

- Shows Known Locations UI and binds Shift+G, Shift+R, and delete selection behavior.
- Binding setup is runtime defensive because old clients and user setups may vary.

### 7298-7770 — main UI and options

- Main UI is lazy-created.
- Interface Options panel mirrors key toggles and discovery/death settings.
- Undo/redo bindings are installed from code.
- Main UI commands text is partially stale; update docs and command text together when adding slash commands.

### 7770-8055 — DB, player position, death autoroute

- `EnsureDb` is the normalization point for SavedVariables.
- Debug/discovery booleans are coerced because SavedVariables can persist strings.
- `GetPlayerWorldPos` uses WoW map APIs and Carbonite map methods, and falls back to synthetic instance positions when coordinates are unavailable.
- Death autoroute is delayed/retried and uses remembered instance context.

### 8078-8567 — transport discovery

- Similar learned transports are detected and touched instead of duplicated.
- Heuristics avoid LFG teleport false positives, local map overlays, and border noise.
- Confirmation popup can save instance known locations or learned transports; No/ESC dismisses with cooldown semantics.

### 8600-8866 — learned transport pulse, hooks, undo, invalidation

- `PulseTransportDiscovery` detects transitions after events.
- Carbonite travel and SCL hooks protect CW from Carbonite expansions/label crashes.
- `ClearCarboniteTargets` wraps Carbonite clear calls with sync suppression.
- `InvalidateRoute` clears graph/expanded route and sync signature.

### 8874-9585 — slash coordinate resolution and fallbacks

- Taxi key variants normalize Carbonite taxi node names.
- `/cw <zone> <x> <y>` resolves map ids by exact, normalized, or contains match, with ambiguity reporting.
- Manual transport destination matching can prefer known transport aliases and inject transport entry/exit points into the queue.
- South Kalimdor fallback is hardcoded and should remain narrowly scoped.

### 9586-9658 — sync to Carbonite

- `SyncQueueToCarbonite` builds/uses a route, reduces it to sync points, skips unchanged signatures, clears Carbonite targets, and calls `map:SeT3`.
- Current risk: on route rebuild failure it logs and returns without necessarily clearing stale `STATE.expandedRoute`, `STATE.lastCarboniteSyncSignature`, or old Carbonite targets. This explains “after one failure, later waypoints keep failing/looking stale” symptoms. Fix should be small and localized here or in `BuildExpandedRoute` failure handling.

### 9660-10385 — capture, metadata, queue ops, summaries, map buttons

- Cursor capture uses displayed Carbonite map, not player zone.
- SaveHere opens metadata popup with normal waypoint fields; zone field is hidden except transport flows.
- Queue clear/pop/autoadvance operate on CW queue and projected route points.
- `/cw route` prints expanded route points and costs; this is the primary routing debugger.

### 10386-10477 — Carbonite hooks

- Map-click hook implements Ctrl+Shift+Click capture behavior.
- Carbonite clear hook distinguishes CW internal clear during sync from user clear.
- This is a non-negotiable queue ownership area.

### 10478-10583 — export and flight-master debug

- `/cw export` emits queue rows only, not expanded route internals.
- `debugfm` inspects Carbonite taxi nodes by name.

### 10584-11340 — destination search

- Search candidates come from known locations, Carbonite favorites, and Carbonite guide points.
- Matching uses exact/substring/token scoring and opens ambiguity UI when top scores tie.
- `RouteToDestinationSearchCandidate` eventually routes via known location, guide/favorite, or candidate coordinates.
- Important current diagnostic: if `/cw solo queue` prints final route point `maI=4003 (Dalaran)`, first check the queued destination’s `maI` from `/cw list`. If the queue stop is already parent Dalaran, the graph is not ignoring Underbelly; destination resolution or saved data selected the parent layer.

### 11348-11504 — slash handler

- Slash command priority: debugfm, exact commands, import, toggles, routeknown, current-map coords, zone coords, destination keyword search.
- New slash features must be inserted carefully so they do not shadow coordinate parsing or destination search.

### 11506-11740 — event/update loop and public exports

- Login/entering world installs hooks, bindings, options, and pending sync.
- Zone events refresh route only when needed; taxi suppresses reroutes until safe.
- OnUpdate drives UI button hooks, pending login sync, transport discovery, death autoroute, autoadvance, taxi lifecycle, and safety re-hooks.
- Public exports at the end expose selected functions through `CW`.

## Main findings

1. The current file is feature-rich but still monolithic. The biggest technical constraint is Lua 5.1 main-chunk local/upvalue limits.
2. The current child-subzone continuation code exists and is probably over-large for the project’s surgical-change style. Keep it only if tests prove it fixes real child-layer routing without breaking parent-zone routing.
3. The current Underbelly symptom should be diagnosed from queue data first: if the queue destination is `maI=4003`, the transport graph cannot know you meant child Underbelly unless metadata/hints trigger injection.
4. Failure cleanup is still a strong small improvement candidate inside `SyncQueueToCarbonite`.
5. Existing docs are directionally correct but stale and incomplete for destination search, known-location transport editing, taxi, faction filtering, death autoroute, and child/subzone routing.
