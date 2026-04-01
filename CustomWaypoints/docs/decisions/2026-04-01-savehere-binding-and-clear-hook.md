# Decision: Save Here binding + Carbonite clear-hook safety

## Context
Two regressions were reported:
1. `savehere` had no addon-native keybinding command, so it could only be reached through slash/UI flows.
2. Carbonite `ClT1` clears were mirrored into a full CW queue wipe even when the clear happened because the player was merely near the first waypoint.

## Decision
- Add a dedicated binding command `CW_SAVE_HERE` in `Bindings.xml` and expose `CustomWaypoints_SaveHere()` in Lua.
- Use best-effort auto-bind for `CW_SAVE_HERE`, preferring `SHIFT-PERIOD` and falling back to `SHIFT-.` only if the key is free.
- Reuse a small shared `TryAutoBindCommand()` helper so Known Locations and Save Here follow the same auto-bind policy.
- Treat Carbonite proximity clears as queue-progress signals, not full-queue-destructive events:
  - if first stop is reached and `autoAdvance=true`, advance only one waypoint
  - if first stop is reached and `autoAdvance=false`, ignore the Carbonite clear
  - otherwise preserve the old behavior and clear the whole queue

## Invariants preserved
- Carbonite remains the renderer / target layer; CW remains owner of queue semantics.
- Minimal/deep routing behavior is unchanged.
- Saved variable schema is unchanged.
- Explicit far-away Carbonite clears still clear the whole CW queue.
