# Carbonite 3.3.5a (Remastered) + CustomWaypoints

This repo bundles a **Wrath-era (3.3.5a)** Carbonite tree with **CustomWaypoints** — a separate addon that layers a waypoint queue and transport-aware routing on top, without editing Carbonite’s own files.

| Folder | What’s inside |
|--------|----------------|
| `Carbonite/` | The map / navigation addon |
| `CustomWaypoints/` | Queue, routing planner, sync, UI, import/export, transport system — **[start with its README](CustomWaypoints/README.md)** |
| `CarboniteTransfer/` | Related helpers (warehouse / transfer tooling) |

---

## Trying CustomWaypoints

1. Copy **`Carbonite`** and **`CustomWaypoints`** into `Interface\AddOns\`.
2. In-game: **`/cw help`** — default capture is **Shift+left-click** on the Carbonite world map (Ctrl+right-click alternate).
3. Maintenance / “what must not break” lives in **`CustomWaypoints/CHECKPOINT.md`**.

---

## Key Features

- **Waypoint queue & sync**
  - Capture custom waypoints from the Carbonite map
  - Sync queue into Carbonite for rendering / guidance
  - Auto-advance when reaching current waypoint

- **Transport-aware routing**
  - Intercontinental routing with portals, boats, zeppelins, trams, and taxis
  - Learned transports (auto-discovered and reused in future routes)
  - Duplicate detection and usage tracking for learned routes

- **Transport management system**
  - In-game UI to view and manage learned transports
  - Multi-select delete with **keyboard shortcuts (DELETE / ESC)**
  - Bulk clear and usage visibility
  - `/cw managetransports` for quick access

- **Transport discovery & confirmation**
  - Automatic detection of cross-map transports
  - Optional confirmation dialog before saving
  - Logging and tracking of discovered routes

- **Routing modes**
  - **Deep mode**: explicit graph traversal with transport usage
  - **Minimal mode**: Carbonite-driven routing with simplified anchors

- **Routing tuning (advanced)**
  - UI for fine-tuning routing preferences (portal, taxi, etc.)
  - Adjustable walking thresholds and transport prioritization
  - Changes apply dynamically with optional auto-sync

- **Undo / Redo system**
  - Full queue history tracking
  - `/cw undo`, `/cw redo`
  - Optional keybinds (e.g. Ctrl+Shift+Z / Y)

- **UI & workflow**
  - Main UI (`/cw ui`) with controls and debug output
  - Import / export waypoint lists
  - Interface options panel integration
  - Lazy UI creation to reduce Carbonite conflicts

---

## Commands

## Routing Modes

### Minimal Mode (Stable)
- Uses Carbonite routing
- Reliable and predictable
- Recommended for normal use

### Deep Mode (Experimental)
- Custom graph-based routing (Dijkstra-style)
- Uses learned transports and extended graph
- Not guaranteed to find optimal or correct routes yet
- May produce unexpected fallbacks

> Deep mode is under active development and should be treated as experimental.
