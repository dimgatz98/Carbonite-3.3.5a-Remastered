# Decision: known locations selection UX + safe binding action

## Date
2026-03-31

## Problem
Known Locations was route-first, with no persistent row selection, and opening the UI required either a button or slash command.

## Decision
- Add row selection on left click.
- Add immediate route on double click.
- Keep an explicit Route Selected button.
- Expose a keybinding action for Known Locations.
- Auto-bind Ctrl+Shift+L only if the action is currently unbound and the key is free.

## Rationale
This gives a more standard list interaction model while avoiding accidental keybinding overrides.

## Non-goals
- no routing graph changes
- no queue semantic changes
- no portal discovery changes
