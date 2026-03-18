# Known issues & caveats

Some of these are bugs; most are just “this is a prototype router on top of a big commercial addon” reality.

## Routing

- Costs are **heuristic** — good enough to steer you, not to prove shortest path.  
- Weird connector combinations can look silly but still be “valid” for the graph.  
- Quality == Carbonite’s connector data for your client/build.  
- Flight masters in deep mode are **approximate** (see developer reference §15.x).

## Client / SavedVariables

- Huge exports belong in the **CW log**, not one chat line.  
- `debug` is coerced to a real boolean on load so `"false"` in SavedVariables doesn’t accidentally leave verbose mode on.  
- Fresh profiles inherit **`debug = true`** from `DEFAULTS` until you turn it off — expect chat + log noise at first.

## Import / export

- Export lines == **queue stops** only. The map may show **more** pins after sync — that’s normal.  
- Import expects sane **pipe-separated** rows; we normalize BOM / chat prefixes when we can, not always.  
- **`/cw export` with `debug` on** can dump the entire block through `dbg()` to chat as well as the log — turn debug off if chat scrolls too fast.

## UI / log

- **`pr()`** always mirrors to the log; **`dbg()`** only when `debug` is true.  
- The log `EditBox` is shared: heavy manual typing there can get overwritten the next time something calls `pr()` / `AppendUiLogLine`.

## Undo

- History caps around **100** snapshots.  
- **Redo** clears when you perform a **new** edit after undo (normal editor behaviour).

## Misc

- **`/cw legend`** flips `showLegend` in the DB, but the main UI **hides** the legend frame right now — effectively a no-op until that UI gets wired back up.

## Reporting a bug

Grab **`/cw list`**, **`/cw route`**, and **`/cw graph`** (with routing issues). For import failures, copy the **`import: rejected (reason): …`** line after `/reload` on the build you’re running.
