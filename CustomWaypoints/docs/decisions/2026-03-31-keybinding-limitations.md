# Decision: Known Locations keybinding behavior

## Date
2026-03-31

## Problem
Standard WoW keybinding system is not reliable in this environment:
- Carbonite and other addons override bindings
- SetBinding is not guaranteed to persist or execute last
- user-defined bindings may conflict silently

## Current behavior
- Known Locations bound to SHIFT-G by default
- binding is force-set on load
- may still not trigger due to external overrides

## Decision
Treat keybinding as best-effort:
- UI access must always be available via command or menu
- keybinding is convenience, not primary access path

## Implications
- cannot guarantee deterministic keybinding behavior
- future improvement requires:
  - late-binding enforcement
  - conflict detection
  - or custom input handling layer

## Non-goals
- no invasive override of Blizzard or Carbonite key handling
