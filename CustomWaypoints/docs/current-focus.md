# Current Focus

## Active scope
Stabilization of Known Locations system, keybinding reliability, and Carbonite clear-hook queue safety.

## Current state
- Save Here:
  - addon-native binding command now exists
  - best-effort auto-bind prefers Shift+Period when free
  - manual binding remains available through WoW keybindings

- Portal discovery:
  - robust detection of real transports vs indoor map changes
  - instance transitions correctly captured
  - entrance + destination stored

- Known Locations:
  - unified list of:
    - manual locations
    - learned transports
    - instances
  - search supports case-insensitive substring match
  - optional instance-only filtering

- UI:
  - left click selects
  - double click triggers routing

## Known limitations
- Keybindings remain best-effort if Carbonite or another addon forcibly overrides them after login.
- Carbonite may still clear its own visible target list; CW now guards queue semantics near the active waypoint instead of mirroring every `ClT1` into a full queue wipe.

## In scope
- portable Known Locations import/export
- route-level saved waypoint editing
- stronger dedup for multi-waypoint known routes

- UI usability improvements
- keybinding reliability hardening
- Carbonite clear-hook safety around reached waypoints
- better transport classification

## Out of scope
- routing algorithm changes
- deep/minimal scoring behavior
- saved variable schema changes

## Next safe step
- add optional late-bind / rebind diagnostics for addon-native keybindings
