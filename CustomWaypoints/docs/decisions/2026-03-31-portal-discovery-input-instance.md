# Decision: remove frame keyboard capture and harden portal discovery

## Date
2026-03-31

## Problem
1. Top-level addon frames were enabling keyboard input and consuming Enter, which interfered with opening chat.
2. Portal discovery treated too many map changes as transports, including local indoor/building overlays.
3. Entering instances through learned portal discovery needed persistent known-location metadata.

## Decision
- Remove keyboard capture from top-level non-edit frames and rely on `UISpecialFrames` for ESC-close behavior.
- Add a transport-transition heuristic that ignores local overlay hops but still accepts instance entry, cross-continent transitions, and clearly non-local map hops.
- When a learned transport enters an instance, also save a known-location record with `previousTarget` and `lastTarget`.

## Rationale
These changes are narrowly scoped to UI input and transport discovery, and do not modify queue, sync, or routing graph semantics.

## Non-goals
- no routing graph redesign
- no sync/UI redesign beyond keyboard capture removal
- no queue/history changes
