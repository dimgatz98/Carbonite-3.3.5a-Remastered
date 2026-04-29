# Routing Contracts — Current

## Contract 1: query-node attachment

`BuildTransportLeg()` may attach synthetic start/goal query nodes to graph candidates.

Rules:

- Candidate eligibility should stay cost/score driven.
- Hard walk-distance gates can hide valid transport paths and must be avoided.
- Candidate count can be capped for performance.
- Dijkstra/uniform-cost search should decide final route quality.

## Contract 2: transport-required legs

A leg is transport-required when it looks like a parent/child map-layer transition or other map transition that cannot be represented by ordinary walk/fly.

Rules:

- Direct flying is not allowed for transport-required legs.
- Same-map/same-coordinate child layers must still be able to use explicit transport.
- If no transport exists, failure is better than a bogus straight cross-layer route, unless a marked parent fallback is used.

## Contract 3: child/subzone fallback

When graph routing to a child destination fails:

1. Try to derive a conservative parent point.
2. Try to find an explicit transport from parent to child.
3. If found, route to parent/entry and append transport hop to child.
4. If not found, route to parent only and mark fallback metadata.

This contract must not fire when the player already matches the child zone context.

## Contract 4: known transports

Known transport entries must be usable both from:

- graph injection, and
- slash/destination resolution when the user names a subzone/transport alias.

Single-node transports require alias resolution to synthesize a from-side anchor.

## Contract 5: known routes

Known routes are user-authored graph hints. They are not arbitrary hidden teleports.

- Each adjacent route point pair becomes an edge.
- Stored transport kind controls edge type when present.
- Bidirectional controls reverse traversal except flight masters, which are always bidirectional.

## Contract 6: flying

Direct flying is allowed only when:

- the player can fly in the region,
- start and destination are in the same flyable expansion region,
- the leg is not transport-required.

Flying-tail optimization must obey the same rule.

## Contract 7: cross-continent fallback

Cross-continent direct walk is blocked by default.

Allowed exceptions must be narrow, named, and test-covered, such as the current Outland entry bridge and South Kalimdor fallback.

## Contract 8: sync projection

Expanded route can be richer than Carbonite sync points.

- Queue stop points must survive as sync anchors.
- Transit edges should generally be sync anchors.
- Simplified mode can collapse non-essential noise.
- User labels should be preferred over generic edge labels.
