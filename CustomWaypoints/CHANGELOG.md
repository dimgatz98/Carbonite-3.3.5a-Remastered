# Changelog

## 2026-03-31
- Fixed cross-continent transport routing bug caused by hard query-node walk gating in `BuildTransportLeg()`.
- Removed `maxWalkToPortalEntry` and `maxWalkToTaxiEntry` from routing tuning and UI.
- Query-node attachment is now cost-driven so Dijkstra can evaluate valid portal/taxi routes instead of losing them before pathfinding.
- Removed keyboard capture from top-level addon frames so Enter can open chat reliably again.
- Made portal discovery more robust against local indoor/building map swaps.
- Added known instance-location persistence inside learned transport registration (`previousTarget` = entrance, `lastTarget` = instance destination).
- Added instance-specific transport confirmation note for queue teleports.
- Added a Known Locations UI list with row selection, double-click routing, and a Route Selected action.
- Added addon-native keybinding support for opening Known Locations, with safe auto-bind to Ctrl+Shift+L only when that key is currently free.

## 2026-03-31 (continued)
- Fixed corrupted portal discovery subsystem after partial regex removal (restored all transport detection functions).
- Known Locations now includes:
  - learned transports
  - instance entries with entrance + destination
- Added case-insensitive search (contains) and instance-only filter in Known Locations UI.
- Changed keybinding to SHIFT-G for Known Locations.
- Noted limitation: keybinding may not work reliably due to Carbonite or other addon overrides.

## 2026-04-01
- Added addon-native `Save Here` keybinding command (`CW_SAVE_HERE`) with best-effort auto-bind preference for Shift+Period when the key is free.
- `savehere` now marks `lastCaptureTime`, so a freshly saved current-location waypoint is protected by the same post-capture grace window as map-click captures.
- Hardened Carbonite `ClT1` clear hook: when Carbonite clears near the active waypoint, CW now advances only the first stop if `autoAdvance=true`, and ignores the proximity clear if `autoAdvance=false`, instead of wiping the whole queue.
- Known Routes can now be edited as full waypoint-line blocks instead of metadata-only edits.
- Added Known Locations export/import buttons; export writes a portable copy/paste block to the CW log, and import performs union + dedup instead of replacing the existing library.
- Known-route dedup now compares the full ordered waypoint chain, so multi-waypoint paths no longer collide only by destination.
- Save captured waypoint / save here now default to a short `wp` label, and Carbonite hover text replaces generic walk wording with the custom label when one exists.
