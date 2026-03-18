# Architecture

## The one-sentence version

CustomWaypoints is a thin **planner + queue** on top of Carbonite; Carbonite stays the map, HUD, and low-level target plumbing.

---

## Who owns what

### Carbonite

- Full map / minimap / HUD  
- Coordinate conversion, tooltips, native goto storage  
- Connector & travel data CW uses to build its graph  

### CustomWaypoints

- Click → waypoint capture from the **visible** map  
- The ordered **queue** (`CustomWaypointsDB.destinations`)  
- Route **expansion** between queue stops  
- Choosing which expanded nodes become Carbonite **targets** (`BuildSyncPoints` → `SeT3`)  
- UI, import/export parsers, undo stacks  
- Deferred **login sync** when the queue wasn’t empty at logout  

---

## Where state lives

### Saved — `CustomWaypointsDB`

- `destinations` — array of `{ maI, mapName, zx, zy, wx, wy, ts, … }`  
- Feature flags: autosync, autoadvance, flying, flight masters, deep/minimal, debug, bindings, UI scale, etc.  

`EnsureDb()` fills missing keys from `DEFAULTS` and **normalizes `debug`** so SavedVariables strings don’t accidentally enable `dbg()`.

### Runtime — `STATE`

| Field | Role |
|--------|------|
| `expandedRoute`, `graph` | Cached routing artifacts; invalidated when queue/options change |
| `syncing`, `suppressClearUntil` | Tell “user cleared goto” apart from “CW cleared during sync” |
| `history`, `future` | Undo / redo snapshots |
| `needLoginQueueSync` | “We need one `SyncQueueToCarbonite` once the map exists” |
| `ui` | Frames, import box, log scroll |

Hooks: map click, Carbonite clear (`ClT1`), travel expansion guard, optional SCL guard.

---

## Happy path (add → sync)

1. User adds a stop (mouse or `/cw add`).  
2. Capture samples **displayed** map id + cursor → world + zone coords.  
3. Stop appended; snapshot pushed for undo when applicable.  
4. `BuildExpandedRoute()` chains legs from **current player position** through each queue entry.  
5. `BuildSyncPoints()` filters noise for Carbonite.  
6. `ClearCarboniteTargets` then `SeT3` per sync point inside a short suppression window.  

---

## Capture semantics

We **intentionally** use the map view you’re staring at. That’s how cross-continent planning while parked in a city works. Player zone APIs are only for **where am I now** when routing the first leg.

---

## Queue vs Carbonite targets

The queue is **source of truth**. Carbonite targets are a **projection** that can have more/fewer visual hops than raw queue length.

- **Autosync** (`autoSyncToCarbonite`): if on, queue edits call `SyncQueueToCarbonite()` (or clear targets when undo/import says to).  
- **Login sync** (`TryPendingLoginQueueSync`): if the saved queue has stops, we call `SyncQueueToCarbonite()` **once** after load — **without** requiring autosync to be on. `SyncQueueToCarbonite` itself does not check the autosync flag.

---

## Sync / clear interaction

CW clears Carbonite before pushing a rebuilt route. Carbonite may clear again mid-operation — we use **`suppressClearUntil`** + `STATE.syncing` so that doesn’t read as “user nuked the plan”. A **real** user clear still empties the queue via the `ClT1` hook.

---

## Import / export

- **Export:** `----- COPY FROM HERE -----` … pipe rows … `----- COPY TO HERE -----` → **`AppendUiLogLine`** + short `pr()` summary.  
- **Import:** split lines → `ParseExportLine` → replace queue + snapshot.  
- **`CustomWaypoints.ImportWaypointsFromText`** is public for other addons.  

---

## Graph model (short)

Built from Carbonite’s connector graph + policy flags (`useFlightMasters`, `hasFlyingMount`, `simplifyTransitWaypoints`). Details: [`routing-notes.md`](routing-notes.md).

---

## More reading

- [`../CHECKPOINT.md`](../CHECKPOINT.md) — regression list  
- [`known-issues.md`](known-issues.md) — UX caveats  
- [`test-cases.md`](test-cases.md) — manual tests  
