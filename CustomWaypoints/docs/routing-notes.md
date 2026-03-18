# Routing Notes

## Current route policy

The current route builder favors a graph-based route when the start and destination are on different maps.

The graph may use:

- ordinary map connectors
- transport connectors such as tram, boat, zeppelin, or portal
- same-map walking transitions between graph nodes

## Why some transport hops stay straight

Certain transport hops are already explicit enough once chosen by CustomWaypoints. If Carbonite re-expands them, the result can become noisy or misleading.

For that reason, selected transport hops are synced as straight hops.

## Why the queue matters

The route shown on the map is a preview of the queue, not an independent Carbonite route plan.

If the queue changes, the route should be rebuilt from scratch.

## What still needs tuning

The remaining routing work is mostly policy work:

- how expensive long detours should be
- whether some continent transitions should carry extra penalties
- how aggressive same-world connector usage should be
- how much route detail should be visible on the map

## Relation to export

- The **graph** may produce **many** internal nodes for one queue leg.
- **Export** only lists **queue stops** (`destinations`), not every internal path node fed to Carbonite during sync. Use `/cw route` + `debug` to inspect expanded routes.

With **`debug` on**, the summary line looks like:

`queue=<stops> carboniteTargets=<n> expandedRoute=<points> syncPoints=<m> totalCost=…`

…i.e. expanded route size vs how many anchors we actually **`SeT3`** into Carbonite.
