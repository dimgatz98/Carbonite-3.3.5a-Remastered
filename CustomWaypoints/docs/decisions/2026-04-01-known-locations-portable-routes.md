# Decision: portable Known Locations blocks + full-route dedup

## Context
Known Locations could save a route, but editing only changed route metadata. There was also no portable import/export path for sharing saved routes between users, and route dedup did not compare the full ordered waypoint chain.

## Decision
- Keep the saved-variable schema unchanged.
- Add route editing through exported waypoint-line text so the entire saved waypoint chain can be edited without redesigning the storage model.
- Add portable Known Locations export/import blocks that reuse the existing waypoint-line format inside entry headers.
- Dedup known routes by the full ordered waypoint chain, not only by final destination or metadata.

## Consequences
- Sharing saved routes becomes practical through copy/paste text blocks.
- Import can do union + dedup without overwriting an existing library.
- Two routes with the same destination but different intermediate waypoints remain distinct.
- Exact metadata formatting is still intentionally simple and pipe characters are normalized for safe transport.
