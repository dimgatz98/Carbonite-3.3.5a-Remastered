# Routing Contracts

## Query-node attachment
`BuildTransportLeg()` may add bounded local walk edges from synthetic start/goal query nodes into the travel graph.

### Contract
- Attachment count may be capped for graph size/performance.
- Candidate ranking may use routing tuning bonuses.
- Candidate eligibility must not use hard portal/taxi walk thresholds that can hide valid routes from Dijkstra.
- Final path optimality should be decided by graph costs, not by pre-pruning transport anchors.

## Portal discovery contract
Learned transport discovery must:
- stay inside the transport-discovery subsystem
- avoid prompting on clearly local indoor/building map overlays
- still detect true cross-map transport transitions
- persist instance entrance/destination metadata when the learned destination is an instance

## Out of scope
This contract does not change:
- queue semantics
- sync projection into Carbonite
- minimal vs deep route display policy
- learned transport graph injection
