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
