# Checkpoint — CustomWaypoints (Phase 5B)

**Doc pass:** March 2026, checked against `CustomWaypoints.lua` (UI, import/export, undo, login sync, safer deep fallback).

This file is the “if you’re shipping a build, did we forget something?” note.

---

## What actually works today

- Capture from the **Carbonite map you have open** (including “I’m planning on another continent while standing in Stormwind”).
- Persistent queue: **`CustomWaypointsDB.destinations`**.
- Expanded routing through the queue (graph / transports / configurable flight masters & flying flag).
- **Sync** pushes a **reduced** set of nodes into Carbonite (`SeT3`, clear + travel hook where needed).
- **Export** = one marked block in the CW **log**; **import** = paste + button or **`/cw import <line>`**.
- **Undo/redo** via `STATE.history` / `STATE.future`; special case after **`/reload`** (undo clears saved queue; redo brings it back).
- **Login:** non-empty queue → deferred **`SyncQueueToCarbonite`** until `GetMap()` works — **runs even if autosync is off** (autosync only affects edits after login).
- **UI:** main frame, scroll log, import box, Escape closes, Interface Options category, optional hotkeys.
- **`pr` vs `dbg`:** `EnsureDb` forces **`debug`** to a real boolean; only **`debug == true`** unlocks the noisy stuff.

---

## Please don’t regress these

- Displayed-map capture (not “player zone only”).
- Queue survives multi-stop planning and the first extra waypoint edge cases.
- While CW is syncing, Carbonite’s internal clears must **not** wipe the queue (`suppressClearUntil` / `STATE.syncing`).
- When the **user** clears Carbonite goto, the queue **must** wipe (`HookCarboniteClear` outside suppression).
- Synthetic **start** nodes shouldn’t become permanent Carbonite stops.
- Transport legs that are supposed to stay **straight** shouldn’t get “helpfully” re-expanded into nonsense.
- **Import** UI must keep **`ImportWaypointsFromText`** forward-declared (`local` at file top, assigned later).
- **Undo/redo** bindings must keep the same forward-declare pattern for **`UndoHistory` / `RedoHistory`**.

---

## Known limitations (still true)

- Routing costs are **heuristic**, not a perfect travel-time oracle.
- Graph quality == Carbonite connector data quality.
- **Export** ≠ every dot you see after sync — only **queue stops**.
- Import is defensive, not magic (weird unicode / broken rows still fail with a reason line).
- Undo history trims around **100** snapshots — long sessions lose the oldest step.

---

## Nice next steps (not blockers)

1. Optional **`CONTRIBUTING.md`** + git tag when you cut a release.
2. Tune flight / continent penalties (`docs/routing-notes.md`).
3. Separate “scratch notes” box if people type in the log and get overwritten by `pr()`.
4. WeakAura or macro checklist linking to `docs/test-cases.md`.

---

## Maintenance habit

When you tag a release, bump **`CHECKPOINT.md`** + **`README.md`** together so the zip matches reality.

After big routing changes, at least run the **clear / sync / import / login** rows in **`docs/test-cases.md`**.
