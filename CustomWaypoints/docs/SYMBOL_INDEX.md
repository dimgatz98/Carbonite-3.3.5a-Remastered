# Symbol Index — CustomWaypoints.lua
Generated from current file: 11740 lines. This is a navigation aid, not a replacement for reading the code.
## Top-level function-like symbols
| Line | Kind | Symbol | Declaration |
|---:|---|---|---|
| 130 | local | `IsAutoDiscoveryEnabled` | `local function IsAutoDiscoveryEnabled()` |
| 134 | local | `ClearPendingTransport` | `local function ClearPendingTransport()` |
| 139 | local | `RefreshUiHeader` | `local function RefreshUiHeader()` |
| 175 | local | `StripLeadingBomAndBidi` | `local function StripLeadingBomAndBidi(s)` |
| 188 | assigned | `SplitLines` | `SplitLines = function(raw)` |
| 206 | local | `ResizeLogOutputEditor` | `local function ResizeLogOutputEditor(scrollToEnd)` |
| 233 | local | `AppendUiLogLine` | `local function AppendUiLogLine(line)` |
| 250 | local | `pr` | `local function pr(msg)` |
| 256 | local | `SetAutoDiscoveryEnabled` | `local function SetAutoDiscoveryEnabled(enabled, quiet)` |
| 277 | local | `ToggleAutoDiscovery` | `local function ToggleAutoDiscovery()` |
| 281 | local | `GetRoutingTuning` | `local function GetRoutingTuning()` |
| 294 | local | `IsTransitSimplifiedEffective` | `local function IsTransitSimplifiedEffective()` |
| 301 | local | `SpellKnownCompat` | `local function SpellKnownCompat(spellId)` |
| 307 | local | `AchievementCompleteCompat` | `local function AchievementCompleteCompat(achievementId)` |
| 313 | method | `CW.IsWotlk335a` | `function CW.IsWotlk335a()` |
| 329 | method | `CW.ShouldUseSpellFlyingDetection` | `function CW.ShouldUseSpellFlyingDetection()` |
| 333 | method | `CW.GetFlyableExpansionRegion` | `function CW.GetFlyableExpansionRegion(mapId)` |
| 346 | method | `CW.PlayerCanFlyInRegion` | `function CW.PlayerCanFlyInRegion(mapId)` |
| 367 | method | `CW.LegacyDirectFlyingEnabled` | `function CW.LegacyDirectFlyingEnabled()` |
| 373 | method | `CW.CanUseCapabilityDirectFlyingLeg` | `function CW.CanUseCapabilityDirectFlyingLeg(startPoint, destPoint)` |
| 408 | local | `ShouldSuppressFlightMasterRouting` | `local function ShouldSuppressFlightMasterRouting()` |
| 412 | local | `GetEdgeTransportKind` | `local function GetEdgeTransportKind(edge)` |
| 424 | local | `IsFlightMasterKind` | `local function IsFlightMasterKind(kind)` |
| 428 | local | `IsBidirectionalTransportRecord` | `local function IsBidirectionalTransportRecord(edge)` |
| 436 | local | `CanonicalTransportKind` | `local function CanonicalTransportKind(kind)` |
| 446 | local | `NormalizeTransportRecord` | `local function NormalizeTransportRecord(edge)` |
| 460 | local | `CloneTransportEdgeWithEndpoints` | `local function CloneTransportEdgeWithEndpoints(edge)` |
| 481 | method | `CW.BuildTransportEndpointLookupAliases` | `function CW.BuildTransportEndpointLookupAliases(edge, prefix)` |
| 484 | local | `add` | `local function add(value)` |
| 500 | method | `CW.ReverseTransportEdgeDirection` | `function CW.ReverseTransportEdgeDirection(edge)` |
| 511 | method | `CW.OrientTransportEdgeTowardDestination` | `function CW.OrientTransportEdgeTowardDestination(edge, name)` |
| 523 | local | `endpointMatches` | `local function endpointMatches(prefix)` |
| 542 | method | `CW.BuildManualTransportFromRoutePoints` | `function CW.BuildManualTransportFromRoutePoints(routePoints, opts)` |
| 605 | local | `BuildTransportRecordKey` | `local function BuildTransportRecordKey(edge)` |
| 631 | method | `CW.BuildTransportLookupAliases` | `function CW.BuildTransportLookupAliases(edge)` |
| 634 | local | `add` | `local function add(value)` |
| 653 | method | `CW.TransportDestinationAliasMatches` | `function CW.TransportDestinationAliasMatches(edge, name)` |
| 665 | method | `CW.IsSingleNodeManualTransportEdge` | `function CW.IsSingleNodeManualTransportEdge(edge)` |
| 669 | method | `CW.ResolveBestMapIdFromTransportAliases` | `function CW.ResolveBestMapIdFromTransportAliases(edge)` |
| 712 | method | `CW.BuildPointFromTransportEndpoint` | `function CW.BuildPointFromTransportEndpoint(edge, prefix, label)` |
| 736 | method | `CW.ArePointsNearSameLocation` | `function CW.ArePointsNearSameLocation(a, b)` |
| 747 | method | `CW.DoesPlayerAlreadyMatchZoneName` | `function CW.DoesPlayerAlreadyMatchZoneName(name)` |
| 754 | local | `matches` | `local function matches(value)` |
| 761 | method | `CW.DoesPlayerAlreadyMatchZoneNameLoosely` | `function CW.DoesPlayerAlreadyMatchZoneNameLoosely(name)` |
| 768 | local | `matches` | `local function matches(value)` |
| 775 | local | `Dist` | `local function Dist(wx1, wy1, wx2, wy2)` |
| 784 | local | `WorldToYards` | `local function WorldToYards(d)` |
| 791 | local | `IsNearWorldPoint` | `local function IsNearWorldPoint(wx1, wy1, wx2, wy2, maxYards)` |
| 796 | method | `CW.IsPlayerNearTransportEndpoint` | `function CW.IsPlayerNearTransportEndpoint(edge, prefix, maxYards)` |
| 814 | method | `CW.DoesPointMatchCurrentZoneContext` | `function CW.DoesPointMatchCurrentZoneContext(pt)` |
| 822 | method | `CW.GetPointMapNameForRouting` | `function CW.GetPointMapNameForRouting(pt)` |
| 846 | method | `CW.DoesPointMatchCurrentZoneContextStrict` | `function CW.DoesPointMatchCurrentZoneContextStrict(pt)` |
| 876 | local | `matches` | `local function matches(destValue)` |
| 900 | method | `CW.IsLikelyTransportOnlyMapTransition` | `function CW.IsLikelyTransportOnlyMapTransition(startPoint, destPoint)` |
| 930 | method | `CW.DoesLegRequireTransportPath` | `function CW.DoesLegRequireTransportPath(startPoint, destPoint)` |
| 953 | local | `InferStoredTransportKind` | `local function InferStoredTransportKind(loc)` |
| 964 | local | `TuningBonusToSeconds` | `local function TuningBonusToSeconds(bonus, scale, maxReduction)` |
| 974 | local | `GetTransportPreferenceReductionSeconds` | `local function GetTransportPreferenceReductionSeconds(transportType, learnedHop)` |
| 1009 | local | `CollapseMinimalTransitNoise` | `local function CollapseMinimalTransitNoise(points)` |
| 1017 | local | `ClonePoint` | `local function ClonePoint(pt)` |
| 1050 | local | `GetAttachCandidateScoreSeconds` | `local function GetAttachCandidateScoreSeconds(rawWalkSeconds, candidate, isStart, isGoal)` |
| 1133 | local | `GetMap` | `local function GetMap()` |
| 1138 | local | `IsPlayerOnTaxi` | `local function IsPlayerOnTaxi()` |
| 1142 | local | `CloneWorldPoint` | `local function CloneWorldPoint(pt)` |
| 1159 | local | `GetRouteBuildStartPoint` | `local function GetRouteBuildStartPoint()` |
| 1184 | local | `dbg` | `local function dbg(msg)` |
| 1190 | assigned | `CW.CleanupTransientTaxiDestinations` | `CW.CleanupTransientTaxiDestinations = function(silent)` |
| 1223 | assigned | `CW.ResolveTaxiNodeByName` | `CW.ResolveTaxiNodeByName = function(name, targetWx, targetWy)` |
| 1232 | local | `ConsiderCandidate` | `local function ConsiderCandidate(nod, displayName)` |
| 1288 | assigned | `CW.GetActiveTaxiDestination` | `CW.GetActiveTaxiDestination = function()` |
| 1321 | assigned | `CW.EnsureTaxiDestinationQueueHead` | `CW.EnsureTaxiDestinationQueueHead = function()` |
| 1376 | assigned | `CW.RemoveTaxiDestinationQueueHead` | `CW.RemoveTaxiDestinationQueueHead = function(syncAfter)` |
| 1401 | assigned | `CW.EnterTaxiTransitRoutingOverride` | `CW.EnterTaxiTransitRoutingOverride = function()` |
| 1415 | assigned | `CW.LeaveTaxiTransitRoutingOverride` | `CW.LeaveTaxiTransitRoutingOverride = function()` |
| 1433 | local | `WalkCostSeconds` | `local function WalkCostSeconds(wx1, wy1, wx2, wy2)` |
| 1443 | method | `CW.DirectFlyingCostSeconds` | `function CW.DirectFlyingCostSeconds(wx1, wy1, wx2, wy2)` |
| 1488 | method | `CW.GetPlayerFactionCode` | `function CW.GetPlayerFactionCode()` |
| 1495 | method | `CW.NormalizeFactionCode` | `function CW.NormalizeFactionCode(faction)` |
| 1503 | method | `CW.IsFactionOwnerAllowed` | `function CW.IsFactionOwnerAllowed(ownerFaction)` |
| 1511 | method | `CW.PointInPolygon` | `function CW.PointInPolygon(zx, zy, polygon)` |
| 1532 | method | `CW.GetFactionRestrictedAreaAtPoint` | `function CW.GetFactionRestrictedAreaAtPoint(maI, zx, zy)` |
| 1543 | method | `CW.IsFactionPointAllowed` | `function CW.IsFactionPointAllowed(maI, zx, zy)` |
| 1549 | method | `CW.InferFactionOwnerFromText` | `function CW.InferFactionOwnerFromText(text)` |
| 1564 | method | `CW.IsFactionEdgeLabelAllowed` | `function CW.IsFactionEdgeLabelAllowed(edgeType, label)` |
| 1569 | method | `CW.GetNodeZoneCoords` | `function CW.GetNodeZoneCoords(node, map)` |
| 1579 | method | `CW.IsGraphEdgeAllowedForPlayer` | `function CW.IsGraphEdgeAllowedForPlayer(aNode, bNode, edgeType, label, map)` |
| 1600 | local | `IsRealTransportType` | `local function IsRealTransportType(edgeType)` |
| 1604 | local | `IsTransitEdgeType` | `local function IsTransitEdgeType(edgeType)` |
| 1608 | local | `InferTransportType` | `local function InferTransportType(name1, name2)` |
| 1618 | local | `InferConnectorEdgeType` | `local function InferConnectorEdgeType(coT, name1, name2)` |
| 1625 | local | `TransportCostSeconds` | `local function TransportCostSeconds(transportType, wx1, wy1, wx2, wy2)` |
| 1673 | local | `LearnedTransportKey` | `local function LearnedTransportKey(edge)` |
| 1677 | local | `HasLearnedTransportCoords` | `local function HasLearnedTransportCoords(edge)` |
| 1685 | local | `CompactLearnedTransports` | `local function CompactLearnedTransports()` |
| 1756 | local | `EnsureTransportDb` | `local function EnsureTransportDb()` |
| 1763 | local | `TransportLabel` | `local function TransportLabel(edge)` |
| 1783 | local | `InjectLearnedTransportEdges` | `local function InjectLearnedTransportEdges(addNode, addEdge, graph)` |
| 1813 | local | `GetKnownRouteHopCostSeconds` | `local function GetKnownRouteHopCostSeconds(loc, a, b)` |
| 1821 | local | `InjectKnownTransportEdges` | `local function InjectKnownTransportEdges(addNode, addEdge, graph, map)` |
| 1826 | local | `validMapPoint` | `local function validMapPoint(maI, wx, wy)` |
| 1876 | local | `InjectKnownRouteEdges` | `local function InjectKnownRouteEdges(addNode, addEdge, graph)` |
| 1925 | local | `ConnectorCostSeconds` | `local function ConnectorCostSeconds(edgeType, wx1, wy1, wx2, wy2)` |
| 1932 | local | `BuildKnownTaxiLookup` | `local function BuildKnownTaxiLookup()` |
| 1956 | local | `NormalizeTaxiKey` | `local function NormalizeTaxiKey(name)` |
| 1969 | local | `BuildKnownTaxiNodes` | `local function BuildKnownTaxiNodes(map)` |
| 1986 | local | `FindKnownTaxiName` | `local function FindKnownTaxiName(nameA, nameB)` |
| 2000 | local | `pushTaxiAny` | `local function pushTaxiAny(taxiName, npcName, maI, wx, wy, knownTaxiName)` |
| 2095 | local | `HeuristicCost` | `local function HeuristicCost()` |
| 2099 | local | `FindPathAStar` | `local function FindPathAStar(nodes, startId, goalId)` |
| 2152 | local | `GetMapContinentForMaI` | `local function GetMapContinentForMaI(maI)` |
| 2166 | method | `CW.BuildRouteableParentPointForChildDestination` | `function CW.BuildRouteableParentPointForChildDestination(destPoint)` |
| 2183 | local | `isValidWorldPointOnMap` | `local function isValidWorldPointOnMap(maI, wx, wy)` |
| 2189 | local | `getMapNameForMaI` | `local function getMapNameForMaI(maI)` |
| 2204 | local | `addCandidate` | `local function addCandidate(maI, sourceName)` |
| 2232 | local | `addNamePrefixes` | `local function addNamePrefixes(rawName)` |
| 2287 | local | `CopyExplicitTransportEdge` | `local function CopyExplicitTransportEdge(edge)` |
| 2296 | local | `ExplicitTransportTargetMatches` | `local function ExplicitTransportTargetMatches(edge, targetName)` |
| 2307 | local | `SynthesizeSingleNodeTransportEntry` | `local function SynthesizeSingleNodeTransportEntry(edge, fromMaI)` |
| 2350 | method | `CW.FindExplicitTransportEdgeBetweenMaps` | `function CW.FindExplicitTransportEdgeBetweenMaps(fromMaI, toMaI, targetName)` |
| 2355 | local | `orient` | `local function orient(edge)` |
| 2402 | local | `BuildExplicitChildTransportEntryPoint` | `local function BuildExplicitChildTransportEntryPoint(edge, label)` |
| 2412 | local | `TryAppendExplicitChildTransportAfterParentFallback` | `local function TryAppendExplicitChildTransportAfterParentFallback(parentLeg, parentDest, childDest, explicitEdge)` |
| 2468 | local | `EnsureGraph` | `local function EnsureGraph()` |
| 2485 | local | `makeNodeKey` | `local function makeNodeKey(maI, wx, wy, nodeType, label)` |
| 2489 | local | `addNode` | `local function addNode(maI, wx, wy, label, nodeType)` |
| 2511 | local | `addEdge` | `local function addEdge(a, b, cost, edgeType, label, bidirectional, opts)` |
| 2538 | local | `addPassageEdgesFromMWI` | `local function addPassageEdgesFromMWI()` |
| 2624 | local | `IsTravelNodeType` | `local function IsTravelNodeType(t)` |
| 2661 | local | `linkLearnedPortalSourcesToNearbyCarbonitePortals` | `local function linkLearnedPortalSourcesToNearbyCarbonitePortals()` |
| 2662 | local | `hasWalkEdge` | `local function hasWalkEdge(fromId, toId)` |
| 2712 | local | `FindBestPathWithOptionalLearnedPrefix` | `local function FindBestPathWithOptionalLearnedPrefix(nodes, startId, goalId, startPoint, baseCount)` |
| 2766 | local | `CollapseDeepTaxiChains` | `local function CollapseDeepTaxiChains(points)` |
| 2782 | local | `ClonePoint` | `local function ClonePoint(pt)` |
| 2790 | local | `IsFlightMasterRoutePoint` | `local function IsFlightMasterRoutePoint(pt)` |
| 2796 | local | `GetFlightMasterChainStartName` | `local function GetFlightMasterChainStartName(pt)` |
| 2806 | local | `GetFlightMasterChainEndName` | `local function GetFlightMasterChainEndName(pt)` |
| 2816 | local | `IsMinorFlightMasterConnector` | `local function IsMinorFlightMasterConnector(pt)` |
| 2823 | local | `IsCompressibleFlightMasterConnector` | `local function IsCompressibleFlightMasterConnector(prevFlightPt, connectorPt, nextFlightPt)` |
| 2901 | local | `BuildTransportLeg` | `local function BuildTransportLeg(startPoint, destPoint)` |
| 2948 | local | `addQueryNode` | `local function addQueryNode(pt, nodeType, label)` |
| 2963 | local | `connectBidirectional` | `local function connectBidirectional(a, b, cost, edgeType, label)` |
| 2970 | local | `attachQueryNode` | `local function attachQueryNode(queryId, preferMapId, preferContinent, outwardLabel)` |
| 2977 | local | `countPortalTaxi` | `local function countPortalTaxi(node)` |
| 3150 | local | `optimizeFlyingTail` | `local function optimizeFlyingTail()` |
| 3220 | local | `BuildOutlandEntryBridgeLeg` | `local function BuildOutlandEntryBridgeLeg(startPoint, destPoint, why)` |
| 3267 | local | `appendPoints` | `local function appendPoints(points, skipFirst)` |
| 3285 | local | `BuildRouteLeg` | `local function BuildRouteLeg(startPoint, destPoint, suppressParentFallback)` |
| 3478 | local | `BuildExpandedRoute` | `local function BuildExpandedRoute()` |
| 3544 | local | `IsSyncAnchorPoint` | `local function IsSyncAnchorPoint(routePoints, idx)` |
| 3560 | local | `ShouldKeepRoutePointForSync` | `local function ShouldKeepRoutePointForSync(routePoints, idx)` |
| 3574 | local | `CollapseConsecutiveSyncPoints` | `local function CollapseConsecutiveSyncPoints(points)` |
| 3594 | local | `BuildSyncPoints` | `local function BuildSyncPoints(routePoints)` |
| 3615 | method | `CW.ShouldRefreshRouteForWorldContextChange` | `function CW.ShouldRefreshRouteForWorldContextChange(event)` |
| 3653 | method | `CW.RefreshRouteForWorldContextChange` | `function CW.RefreshRouteForWorldContextChange(event, reason)` |
| 3668 | local | `SanitizeCarboniteLabel` | `local function SanitizeCarboniteLabel(s)` |
| 3678 | local | `UseStraightLineForEdge` | `local function UseStraightLineForEdge(edgeType)` |
| 3682 | local | `GetTargetTypeForRoutePoint` | `local function GetTargetTypeForRoutePoint(pt)` |
| 3702 | local | `BuildSyncLabel` | `local function BuildSyncLabel(idx, pt)` |
| 3747 | local | `BuildRouteSignature` | `local function BuildRouteSignature(points)` |
| 3773 | assigned | `CW.TryTaxiPeriodicRefresh` | `CW.TryTaxiPeriodicRefresh = function(now)` |
| 3832 | local | `EscapeForDisplay` | `local function EscapeForDisplay(text)` |
| 3836 | local | `UnescapeFromDisplay` | `local function UnescapeFromDisplay(text)` |
| 3840 | local | `NormalizeKnownInstanceName` | `local function NormalizeKnownInstanceName(pt)` |
| 3848 | method | `BuildTransportConfirmationKey` | `function BuildTransportConfirmationKey(fromPos, toPos)` |
| 3874 | method | `IsConfirmationDismissed` | `function IsConfirmationDismissed(fromPos, toPos)` |
| 3885 | method | `DismissConfirmationCandidate` | `function DismissConfirmationCandidate(fromPos, toPos, seconds)` |
| 3892 | local | `MarkConfirmationRecentlyHandled` | `local function MarkConfirmationRecentlyHandled(fromPos, toPos, seconds)` |
| 3899 | local | `WasConfirmationRecentlyHandled` | `local function WasConfirmationRecentlyHandled(fromPos, toPos)` |
| 3910 | method | `CW.BuildInstanceEntryDedupeKey` | `function CW.BuildInstanceEntryDedupeKey(fromPos, toPos)` |
| 3921 | method | `CW.IsRecentInstanceEntryDuplicate` | `function CW.IsRecentInstanceEntryDuplicate(fromPos, toPos)` |
| 3935 | method | `CW.RememberRecentInstanceEntry` | `function CW.RememberRecentInstanceEntry(fromPos, toPos, seconds)` |
| 3950 | assigned | `ShouldEnableKnownLocationsDeleteOverride` | `ShouldEnableKnownLocationsDeleteOverride = function()` |
| 3968 | assigned | `RefreshCwEscOverride` | `RefreshCwEscOverride = function()` |
| 4005 | assigned | `HideTopCwModalFrame` | `HideTopCwModalFrame = function()` |
| 4023 | assigned | `EnsureCwEscOverrideButton` | `EnsureCwEscOverrideButton = function()` |
| 4039 | assigned | `EnsureCwDeleteOverrideButton` | `EnsureCwDeleteOverrideButton = function()` |
| 4055 | local | `PushCwModalFrame` | `local function PushCwModalFrame(frame)` |
| 4067 | local | `RemoveCwModalFrame` | `local function RemoveCwModalFrame(frame)` |
| 4078 | local | `ArmKeyboardModalFrame` | `local function ArmKeyboardModalFrame(frame)` |
| 4092 | local | `ColorizeEdgeName` | `local function ColorizeEdgeName(edgeType, textLabel)` |
| 4097 | local | `ApplyRoutingTuningChange` | `local function ApplyRoutingTuningChange(key, value, skipUiRefresh, skipSync)` |
| 4124 | assigned | `RefreshRoutingTuningUi` | `RefreshRoutingTuningUi = function()` |
| 4149 | assigned | `EnsureRoutingTuningUi` | `EnsureRoutingTuningUi = function()` |
| 4156 | local | `FlushPendingRoutingTuningChanges` | `local function FlushPendingRoutingTuningChanges()` |
| 4376 | local | `ToggleRoutingTuningUi` | `local function ToggleRoutingTuningUi()` |
| 4387 | local | `EscapePortableField` | `local function EscapePortableField(value)` |
| 4391 | assigned | `NormalizeSignatureNumber` | `NormalizeSignatureNumber = function(value, decimals)` |
| 4399 | local | `BuildWaypointSignature` | `local function BuildWaypointSignature(dest)` |
| 4411 | assigned | `BuildKnownLocationSignature` | `BuildKnownLocationSignature = function(loc)` |
| 4447 | assigned | `FindDuplicateKnownLocationIndex` | `FindDuplicateKnownLocationIndex = function(candidate, skipIndex)` |
| 4461 | local | `CloneDestinations` | `local function CloneDestinations(src, seen)` |
| 4479 | assigned | `CloneDestination` | `CloneDestination = function(dest, seen)` |
| 4500 | local | `NormalizeKnownLocationAfterEdit` | `local function NormalizeKnownLocationAfterEdit(loc)` |
| 4515 | local | `SerializeWaypointLine` | `local function SerializeWaypointLine(index, dest)` |
| 4531 | local | `SerializeRoutePointsBlock` | `local function SerializeRoutePointsBlock(routePoints)` |
| 4539 | local | `TrimField` | `local function TrimField(s)` |
| 4544 | local | `ToNumberField` | `local function ToNumberField(s)` |
| 4572 | assigned | `NormalizeImportLine` | `NormalizeImportLine = function(line)` |
| 4595 | assigned | `ParseExportLine` | `ParseExportLine = function(line)` |
| 4690 | local | `BuildKnownLocationExportHeader` | `local function BuildKnownLocationExportHeader(loc)` |
| 4705 | local | `BuildLearnedTransportExportHeader` | `local function BuildLearnedTransportExportHeader(edge)` |
| 4719 | local | `SerializeLearnedTransportLine` | `local function SerializeLearnedTransportLine(edge)` |
| 4747 | assigned | `SplitExportFields` | `SplitExportFields = function(line)` |
| 4772 | local | `ParseLearnedTransportLine` | `local function ParseLearnedTransportLine(line)` |
| 4821 | local | `ParseKnownLocationHeader` | `local function ParseKnownLocationHeader(line)` |
| 4845 | local | `FinalizeImportedKnownLocation` | `local function FinalizeImportedKnownLocation(header, routePoints)` |
| 4886 | local | `NormalizeOptionalMetadataField` | `local function NormalizeOptionalMetadataField(value)` |
| 4895 | local | `SanitizeRoutePointForEditing` | `local function SanitizeRoutePointForEditing(pt)` |
| 4921 | local | `BuildSingleKnownLocationImportBlock` | `local function BuildSingleKnownLocationImportBlock(loc)` |
| 4974 | local | `DeduplicateKnownLocationsPreserveOrder` | `local function DeduplicateKnownLocationsPreserveOrder(list)` |
| 4988 | local | `SaveInstanceKnownLocation` | `local function SaveInstanceKnownLocation(fromPos, toPos)` |
| 5025 | local | `CloneKnownLocationDestination` | `local function CloneKnownLocationDestination(loc)` |
| 5036 | local | `BuildKnownLocationEntries` | `local function BuildKnownLocationEntries()` |
| 5042 | local | `addEntry` | `local function addEntry(entry)` |
| 5157 | local | `EntryContainsQuery` | `local function EntryContainsQuery(entry, query)` |
| 5173 | local | `EntryMatchesFilters` | `local function EntryMatchesFilters(entry, ui)` |
| 5193 | local | `ResolveKnownLocationAbsoluteIndex` | `local function ResolveKnownLocationAbsoluteIndex(entry)` |
| 5204 | local | `ResolveKnownLocationStoredSourceIndex` | `local function ResolveKnownLocationStoredSourceIndex(entry)` |
| 5224 | local | `PushHistorySnapshot` | `local function PushHistorySnapshot(reason)` |
| 5239 | local | `DisableCarboniteQuestAutoTrack` | `local function DisableCarboniteQuestAutoTrack(reason)` |
| 5275 | local | `HandleQueueBecameNonEmpty` | `local function HandleQueueBecameNonEmpty(reason, wasEmpty)` |
| 5281 | assigned | `RouteToKnownLocation` | `RouteToKnownLocation = function(index)` |
| 5320 | assigned | `SaveQueueAsKnownRoute` | `SaveQueueAsKnownRoute = function()` |
| 5321 | local | `SafePr` | `local function SafePr(msg)` |
| 5352 | assigned | `onRefreshExtraCheckboxes` | `onRefreshExtraCheckboxes = function(checkboxByKey, setZoneFieldEnabled)` |
| 5377 | assigned | `onSave` | `onSave = function(meta)` |
| 5507 | assigned | `SelectKnownLocation` | `SelectKnownLocation = function(index)` |
| 5513 | local | `DeleteKnownLocationEntry` | `local function DeleteKnownLocationEntry(entry)` |
| 5569 | local | `TrimEditorMetadataValue` | `local function TrimEditorMetadataValue(value)` |
| 5573 | assigned | `CloneLearnedTransport` | `CloneLearnedTransport = function(edge)` |
| 5581 | local | `ShowKnownPointEditorPopup` | `local function ShowKnownPointEditorPopup(sourceIndex, loc, titleText)` |
| 5663 | local | `BuildCycleButton` | `local function BuildCycleButton(parent, width, height, values, initialValue, formatValue)` |
| 5671 | local | `applyIndex` | `local function applyIndex(idx)` |
| 5681 | method | `btn:GetSelectedValue` | `function btn:GetSelectedValue()` |
| 5685 | method | `btn:SetSelectedValue` | `function btn:SetSelectedValue(value)` |
| 5747 | local | `SetEditorCheckboxEnabled` | `local function SetEditorCheckboxEnabled(checkbox, enabled)` |
| 5754 | local | `RefreshEditorTypeState` | `local function RefreshEditorTypeState()` |
| 5851 | local | `flushPending` | `local function flushPending()` |
| 6051 | assigned | `ShowKnownLocationEditorPopup` | `ShowKnownLocationEditorPopup = function(sourceIndex)` |
| 6054 | local | `BuildTransportEditorEntry` | `local function BuildTransportEditorEntry(storedIndex, edge)` |
| 6075 | local | `OpenUnifiedEditor` | `local function OpenUnifiedEditor(storedIndex, entry)` |
| 6139 | assigned | `ImportWaypointsFromText` | `ImportWaypointsFromText = function(text)` |
| 6199 | assigned | `ImportKnownLocationsFromText` | `ImportKnownLocationsFromText = function(text)` |
| 6216 | local | `flushPending` | `local function flushPending()` |
| 6297 | assigned | `ShowWaypointImportPopup` | `ShowWaypointImportPopup = function()` |
| 6408 | assigned | `ShowKnownLocationExportPopup` | `ShowKnownLocationExportPopup = function(textBlob)` |
| 6521 | assigned | `ShowKnownLocationImportPopup` | `ShowKnownLocationImportPopup = function()` |
| 6631 | local | `ReleaseKnownLocationsSearchFocus` | `local function ReleaseKnownLocationsSearchFocus()` |
| 6648 | local | `GetDisplayNameForPoint` | `local function GetDisplayNameForPoint(pt)` |
| 6653 | assigned | `RefreshKnownLocationsFrame` | `RefreshKnownLocationsFrame = function()` |
| 6819 | assigned | `ExportKnownLocations` | `ExportKnownLocations = function()` |
| 6856 | local | `RestoreKnownLocationsSelectionAfterDelete` | `local function RestoreKnownLocationsSelectionAfterDelete(previousIndex)` |
| 6873 | local | `QueueKnownLocationsSearchFocus` | `local function QueueKnownLocationsSearchFocus()` |
| 6910 | assigned | `ShowKnownLocationsFrame` | `ShowKnownLocationsFrame = function()` |
| 7179 | method | `CustomWaypoints_ToggleKnownLocations` | `function CustomWaypoints_ToggleKnownLocations()` |
| 7183 | method | `CustomWaypoints_SaveHere` | `function CustomWaypoints_SaveHere()` |
| 7187 | method | `CW_DELETE_SELECTED_KNOWN_LOCATION` | `function CW_DELETE_SELECTED_KNOWN_LOCATION()` |
| 7191 | method | `CustomWaypoints_DeleteSelectedKnownLocation` | `function CustomWaypoints_DeleteSelectedKnownLocation()` |
| 7212 | local | `TryAutoBindCommand` | `local function TryAutoBindCommand(bindingName, desiredKeys, debugName)` |
| 7235 | assigned | `EnsureKnownLocationsBinding` | `EnsureKnownLocationsBinding = function()` |
| 7244 | assigned | `EnsureDeleteSelectedKnownLocationBinding` | `EnsureDeleteSelectedKnownLocationBinding = function()` |
| 7270 | assigned | `EnsureSaveHereBinding` | `EnsureSaveHereBinding = function()` |
| 7298 | local | `EnsureUi` | `local function EnsureUi()` |
| 7374 | local | `MakeButton` | `local function MakeButton(textLabel, x, y, command)` |
| 7434 | local | `MakeCheckbox` | `local function MakeCheckbox(textLabel, x, y, onClick)` |
| 7514 | local | `ResetDeathAutoRouteCycle` | `local function ResetDeathAutoRouteCycle()` |
| 7520 | local | `ClonePersistentInstanceContext` | `local function ClonePersistentInstanceContext(pt)` |
| 7528 | local | `CaptureDeathInstanceContext` | `local function CaptureDeathInstanceContext()` |
| 7542 | local | `ClearCorpseInstanceContext` | `local function ClearCorpseInstanceContext()` |
| 7549 | local | `EnsureInterfaceOptionsPanel` | `local function EnsureInterfaceOptionsPanel()` |
| 7571 | local | `MakePanelCheckbox` | `local function MakePanelCheckbox(textLabel, x, y, onClick)` |
| 7640 | local | `InstallSaveHereHotkey` | `local function InstallSaveHereHotkey()` |
| 7647 | local | `InstallUndoRedoBindings` | `local function InstallUndoRedoBindings()` |
| 7702 | local | `CanAssignKey` | `local function CanAssignKey(key, boundTo)` |
| 7745 | local | `ToggleUi` | `local function ToggleUi()` |
| 7758 | local | `CoerceSavedBoolean` | `local function CoerceSavedBoolean(v, defaultVal)` |
| 7770 | assigned | `EnsureDb` | `EnsureDb = function()` |
| 7792 | method | `FindSimilarKnownInstance` | `function FindSimilarKnownInstance(toPos)` |
| 7806 | method | `FindFallbackKnownInstanceByNames` | `function FindFallbackKnownInstanceByNames(pos)` |
| 7811 | local | `add` | `local function add(name)` |
| 7841 | method | `FindBestSavedInstanceForDeath` | `function FindBestSavedInstanceForDeath(pos)` |
| 7847 | method | `RouteToSavedInstanceLocation` | `function RouteToSavedInstanceLocation(loc, reason)` |
| 7871 | method | `ClearPendingDeathAutoRoute` | `function ClearPendingDeathAutoRoute()` |
| 7875 | method | `StartPendingDeathAutoRoute` | `function StartPendingDeathAutoRoute(delay, deathContext)` |
| 7893 | assigned | `GetPlayerWorldPos` | `GetPlayerWorldPos = function()` |
| 7911 | local | `BuildSyntheticInstancePos` | `local function BuildSyntheticInstancePos(maI)` |
| 7991 | local | `RememberPersistentInstanceContext` | `local function RememberPersistentInstanceContext(pt)` |
| 7997 | local | `RememberCorpseInstanceContext` | `local function RememberCorpseInstanceContext(pt)` |
| 8003 | local | `GetBestInstanceContextForDeathRouting` | `local function GetBestInstanceContextForDeathRouting()` |
| 8017 | method | `TryAutoRouteSavedInstanceOnDeath` | `function TryAutoRouteSavedInstanceOnDeath()` |
| 8044 | method | `PulsePendingDeathAutoRoute` | `function PulsePendingDeathAutoRoute()` |
| 8078 | method | `FindSimilarLearnedTransport` | `function FindSimilarLearnedTransport(fromPos, toPos)` |
| 8095 | method | `TouchLearnedTransport` | `function TouchLearnedTransport(edge, fromPos, toPos)` |
| 8114 | local | `IsModifierDown` | `local function IsModifierDown(name)` |
| 8122 | local | `GetDisplayedCapture` | `local function GetDisplayedCapture(map)` |
| 8213 | local | `BeginPendingTransport` | `local function BeginPendingTransport(reason, fromPos)` |
| 8248 | local | `ShouldTreatAsTransportTransition` | `local function ShouldTreatAsTransportTransition(fromPos, toPos, reason)` |
| 8291 | local | `IsLikelyLfgTeleportIntoInstance` | `local function IsLikelyLfgTeleportIntoInstance(fromPos, toPos, reason)` |
| 8333 | local | `ShowTransportConfirmationFrame` | `local function ShowTransportConfirmationFrame()` |
| 8387 | local | `ApplyPopupToggle` | `local function ApplyPopupToggle()` |
| 8393 | local | `RejectTransportConfirmation` | `local function RejectTransportConfirmation(self)` |
| 8510 | local | `RequestLearnedTransportConfirmation` | `local function RequestLearnedTransportConfirmation(fromPos, toPos, reason)` |
| 8600 | local | `ListLearnedTransports` | `local function ListLearnedTransports()` |
| 8612 | local | `ClearLearnedTransports` | `local function ClearLearnedTransports()` |
| 8619 | local | `PulseTransportDiscovery` | `local function PulseTransportDiscovery(elapsed)` |
| 8716 | local | `InstallCarboniteSclGuard` | `local function InstallCarboniteSclGuard()` |
| 8719 | local | `SafeSCL` | `local function SafeSCL(self, frm, lvl, seen)` |
| 8758 | local | `InstallCarboniteTravelHook` | `local function InstallCarboniteTravelHook()` |
| 8763 | assigned | `Nx.Tra.MaP` | `Nx.Tra.MaP = function(self, tra2, sMI, srX, srY, dMI, dsX, dsY, taT1)` |
| 8775 | local | `RestoreSnapshot` | `local function RestoreSnapshot(snapshot, reason)` |
| 8789 | assigned | `UndoHistory` | `UndoHistory = function()` |
| 8827 | assigned | `RedoHistory` | `RedoHistory = function()` |
| 8845 | assigned | `ClearCarboniteTargets` | `ClearCarboniteTargets = function(map)` |
| 8865 | assigned | `InvalidateRoute` | `InvalidateRoute = function(reason)` |
| 8874 | method | `CW.BuildTaxiKeyVariants` | `function CW.BuildTaxiKeyVariants(name)` |
| 8876 | local | `addVariant` | `local function addVariant(v)` |
| 8895 | method | `CW.MarkSessionKnownTaxi` | `function CW.MarkSessionKnownTaxi(name)` |
| 8909 | method | `CW.RefreshSessionKnownTaxisFromTaxiMap` | `function CW.RefreshSessionKnownTaxisFromTaxiMap()` |
| 8932 | method | `ResolveMapIdByName` | `function ResolveMapIdByName(name)` |
| 8945 | method | `BuildPointFromAnchor` | `function BuildPointFromAnchor(maI, zx, zy, label, edgeType)` |
| 8963 | method | `CW.NormalizeZoneLookupKey` | `function CW.NormalizeZoneLookupKey(name)` |
| 8979 | method | `CW.ZoneLookupKeysMatchLoosely` | `function CW.ZoneLookupKeysMatchLoosely(a, b)` |
| 8986 | method | `CW.BuildManualTransportLikeEdgeFromKnownLocation` | `function CW.BuildManualTransportLikeEdgeFromKnownLocation(loc)` |
| 9039 | method | `CW.ResolveMapIdBySmartName` | `function CW.ResolveMapIdBySmartName(name)` |
| 9092 | method | `CW.ParseZoneCoordinateNumber` | `function CW.ParseZoneCoordinateNumber(token)` |
| 9101 | method | `CW.ParseZoneAndCoordsFromSlashArgs` | `function CW.ParseZoneAndCoordsFromSlashArgs(rawMsg)` |
| 9123 | method | `CW.ParseCurrentMapCoordsFromSlashArgs` | `function CW.ParseCurrentMapCoordsFromSlashArgs(rawMsg)` |
| 9140 | method | `CW.AddWaypointOnCurrentMapCoords` | `function CW.AddWaypointOnCurrentMapCoords(zx, zy)` |
| 9214 | method | `CW.FormatZoneResolveMatches` | `function CW.FormatZoneResolveMatches(matches)` |
| 9228 | method | `CW.ResolveManualTransportDestinationByName` | `function CW.ResolveManualTransportDestinationByName(name)` |
| 9237 | local | `tryEdge` | `local function tryEdge(edge)` |
| 9290 | local | `DestinationMatchesResolvedTransportAlias` | `local function DestinationMatchesResolvedTransportAlias(dest, resolvedTransport)` |
| 9303 | method | `CW.AddWaypointFromZoneCoords` | `function CW.AddWaypointFromZoneCoords(zoneName, zx, zy)` |
| 9433 | method | `ResolveSouthKalimdorFallbackIds` | `function ResolveSouthKalimdorFallbackIds()` |
| 9459 | method | `BuildPointFromResolvedAnchor` | `function BuildPointFromResolvedAnchor(resolved, regionKey, pointKey, edgeType)` |
| 9468 | method | `BuildSouthKalimdorFallbackLeg` | `function BuildSouthKalimdorFallbackLeg(startPoint, destPoint, why)` |
| 9503 | local | `addResolved` | `local function addResolved(regionKey, pointKey)` |
| 9586 | assigned | `SyncQueueToCarbonite` | `SyncQueueToCarbonite = function(skipIfUnchanged, routeOverride)` |
| 9593 | local | `BuildSyncSignature` | `local function BuildSyncSignature(points)` |
| 9660 | local | `AddCurrentCursorWaypoint` | `local function AddCurrentCursorWaypoint()` |
| 9682 | local | `BuildDefaultWaypointName` | `local function BuildDefaultWaypointName(dest)` |
| 9687 | local | `ShowWaypointMetadataPopup` | `local function ShowWaypointMetadataPopup(opts)` |
| 9850 | local | `SetPopupZoneFieldEnabled` | `local function SetPopupZoneFieldEnabled(enabled)` |
| 9858 | local | `RefreshPopupExtraState` | `local function RefreshPopupExtraState()` |
| 9875 | assigned | `FocusMetadataBox` | `FocusMetadataBox = function(box)` |
| 9889 | assigned | `FocusNextMetadataBox` | `FocusNextMetadataBox = function(current, backwards)` |
| 9914 | assigned | `CommitWaypointMetadata` | `CommitWaypointMetadata = function()` |
| 9975 | local | `ListWaypoints` | `local function ListWaypoints()` |
| 9996 | assigned | `AddLabeledCurrentCursorWaypoint` | `AddLabeledCurrentCursorWaypoint = function()` |
| 10010 | assigned | `onSave` | `onSave = function(meta)` |
| 10033 | assigned | `AddCurrentLocationWaypoint` | `AddCurrentLocationWaypoint = function()` |
| 10060 | assigned | `AddCurrentLocationWithMetadataPopup` | `AddCurrentLocationWithMetadataPopup = function()` |
| 10077 | assigned | `onSave` | `onSave = function(meta)` |
| 10100 | local | `InternalClearWaypoints` | `local function InternalClearWaypoints(silent)` |
| 10110 | local | `ClearWaypoints` | `local function ClearWaypoints()` |
| 10114 | local | `RemoveFirstWaypoint` | `local function RemoveFirstWaypoint(reason)` |
| 10128 | local | `GetCurrentSyncedRoutePoint` | `local function GetCurrentSyncedRoutePoint()` |
| 10143 | local | `AdvanceCurrentRouteTarget` | `local function AdvanceCurrentRouteTarget(reason)` |
| 10180 | local | `GetReachedFirstWaypointDistanceYards` | `local function GetReachedFirstWaypointDistanceYards()` |
| 10198 | local | `PulseAutoAdvance` | `local function PulseAutoAdvance()` |
| 10216 | local | `Probe` | `local function Probe()` |
| 10247 | assigned | `RouteSummary` | `RouteSummary = function()` |
| 10283 | assigned | `GraphSummary` | `GraphSummary = function()` |
| 10293 | assigned | `EnsureCarboniteMapButtons` | `EnsureCarboniteMapButtons = function()` |
| 10342 | local | `RefreshMapSaveRouteButton` | `local function RefreshMapSaveRouteButton()` |
| 10386 | method | `CW.HookMapClicks` | `function CW.HookMapClicks()` |
| 10447 | method | `CW.HookCarboniteClear` | `function CW.HookCarboniteClear()` |
| 10478 | method | `CW.ExportWaypoints` | `function CW.ExportWaypoints()` |
| 10508 | method | `CW.DebugFlightMaster` | `function CW.DebugFlightMaster(name)` |
| 10516 | local | `norm` | `local function norm(n)` |
| 10584 | method | `CW.TrimDestinationSearchText` | `function CW.TrimDestinationSearchText(value)` |
| 10591 | method | `CW.DestinationSearchMatchScore` | `function CW.DestinationSearchMatchScore(query, ...)` |
| 10631 | method | `CW.AddDestinationSearchCandidate` | `function CW.AddDestinationSearchCandidate(candidates, query, sourcePriority, candidate, ...)` |
| 10641 | method | `CW.FormatDestinationSearchCandidate` | `function CW.FormatDestinationSearchCandidate(candidate)` |
| 10653 | method | `CW.PrintDestinationSearchAmbiguity` | `function CW.PrintDestinationSearchAmbiguity(query, candidates)` |
| 10665 | method | `CW.CollectKnownDestinationSearchCandidates` | `function CW.CollectKnownDestinationSearchCandidates(candidates, query)` |
| 10715 | method | `CW.DecodeCarboniteFavoriteDestination` | `function CW.DecodeCarboniteFavoriteDestination(typ, dat)` |
| 10735 | method | `CW.CollectCarboniteFavoriteCandidates` | `function CW.CollectCarboniteFavoriteCandidates(candidates, query)` |
| 10740 | local | `scanFolder` | `local function scanFolder(folder, folderPath)` |
| 10769 | method | `CW.AddCarboniteGuidePointCandidate` | `function CW.AddCarboniteGuidePointCandidate(candidates, query, guideType, name, maI, zx, zy, extraText)` |
| 10789 | method | `CW.CollectCarboniteGuideCandidates` | `function CW.CollectCarboniteGuideCandidates(candidates, query)` |
| 10863 | method | `CW.SearchDestinationKeyword` | `function CW.SearchDestinationKeyword(query)` |
| 10884 | method | `CW.RouteToDestinationSearchCandidate` | `function CW.RouteToDestinationSearchCandidate(candidate, query)` |
| 10940 | method | `CW.SelectDestinationSearchCandidate` | `function CW.SelectDestinationSearchCandidate(index)` |
| 10948 | method | `CW.SetDestinationSearchPage` | `function CW.SetDestinationSearchPage(page)` |
| 10972 | method | `CW.RefreshDestinationSearchFrame` | `function CW.RefreshDestinationSearchFrame()` |
| 11134 | method | `CW.SubmitDestinationSearchFrame` | `function CW.SubmitDestinationSearchFrame()` |
| 11149 | method | `CW.ShowDestinationSearchFrame` | `function CW.ShowDestinationSearchFrame(initialQuery, initialCandidates)` |
| 11328 | method | `CW.TryRouteByDestinationKeyword` | `function CW.TryRouteByDestinationKeyword(query)` |
| 11348 | assigned | `SlashHandler` | `SlashHandler = function(msg)` |
| 11506 | assigned | `ScheduleLoginQueueSyncIfNeeded` | `ScheduleLoginQueueSyncIfNeeded = function()` |
| 11512 | assigned | `TryPendingLoginQueueSync` | `TryPendingLoginQueueSync = function()` |
| 11525 | method | `OnEvent` | `function OnEvent(_, event)` |
| 11617 | method | `OnUpdate` | `function OnUpdate(_, elapsed)` |
