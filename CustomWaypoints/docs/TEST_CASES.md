# Manual Regression Tests — Updated

Run after touching capture, queue, sync, routing, known locations, transport discovery, taxi, death autoroute, or UI.

## Baseline queue/capture

1. `/cw clear` leaves queue empty and clears Carbonite targets.
2. Ctrl+Shift+Click on visible Carbonite map adds a waypoint on the displayed map.
3. `/cw add` behaves like cursor capture.
4. `/cw list` shows correct `maI`, `zx/zy`, `wx/wy`, label/name.
5. `/cw 50 50` adds current-map waypoint.
6. `/cw Dalaran 57.4 47.2` resolves Dalaran or reports ambiguity clearly.

## Route/sync

1. Add one same-zone waypoint; `/cw route` has start + walk/fly point.
2. Add cross-zone waypoint in same continent; route uses connector/transport when available.
3. Stormwind -> Dalaran routes through valid transport/flying path and does not direct-walk across continents.
4. Dalaran -> Underbelly requires explicit passage or marked parent fallback.
5. Underbelly -> Dalaran works if passage is bidirectional.
6. Failed route rebuild must not poison the next waypoint/sync attempt.

## Known locations

1. Save ordinary current location; zone field hidden.
2. Save route with two or more queue points; appears as kind `route`.
3. Save one-point transport anchor with zone/subzone hint; appears as kind `transport`.
4. Save two-point transport; learned/manual transport edge is created or deduped.
5. Flight Master checkbox forces bidirectional.
6. Edit known location type route/transport/instance and verify type-specific fields.
7. Delete selected known location with button and Shift+Delete outside search box.

## Destination search

1. `/cw search` opens search UI without unwanted movement capture.
2. Query with one best result routes immediately.
3. Ambiguous query opens result UI.
4. Double-click result routes.
5. Search known route loads route points; search known single destination loads one queue stop.
6. Search known transport/subzone alias injects transport entry/exit when appropriate.

## Import/export

1. `/cw export` then import replaces active queue with same points.
2. Known locations export/import merges and dedupes.
3. `T|...` transport rows import into learned transports.
4. Bad rows are rejected with reason and do not wipe existing data.

## UI/input

1. ESC closes only latest CW modal.
2. WASD still moves after opening/closing each CW frame.
3. Search boxes do not trigger global delete while focused.
4. Known locations search focus does not insert the hotkey character.

## Taxi

1. Open taxi map; known taxi nodes refresh.
2. Start taxi with active route; transient taxi destination may be inserted at queue head.
3. While on taxi, route refresh is throttled and does not repeatedly recenter Carbonite.
4. On taxi end, transient destination is removed and route refreshes once.

## Transport discovery

1. Walk through a real portal/passage; confirmation appears once.
2. Press No/ESC; repeated prompt is suppressed.
3. LFG teleport into instance does not create a learned walked transport.
4. Re-enter same discovered transition touches/dedupes, does not duplicate.

## Death autoroute

1. Die inside saved instance context; route to saved entrance after delay.
2. Die outside instance; no false autoroute.
3. PLAYER_ALIVE/UNGHOST clears pending autoroute.
