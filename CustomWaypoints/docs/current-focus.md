# Current Focus

## Active scope
Stabilization of Known Locations system and portal discovery reliability.

## Current state
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
- Keybinding (SHIFT-G):
  - may not trigger reliably
  - likely overridden by Carbonite or other addons
  - binding system is currently best-effort, not guaranteed

## In scope
- UI usability improvements
- keybinding reliability (future)
- better transport classification

## Out of scope
- routing algorithm changes
- Carbonite sync behavior
- queue semantics

## Next safe step
- implement robust keybinding system (priority / fallback / late-bind enforcement)
