import {
  ENERGY_VALLEY_OSM_BLOCK_GRAPH_SNAPSHOT,
  WENYU_REFERENCE_BUILDINGS_SNAPSHOT,
  RUNTIME_TEXT_SNAPSHOTS,
  WENYU_REFERENCE_INTERSECTIONS_SNAPSHOT,
  WENYU_REFERENCE_LABELS_SNAPSHOT,
  WENYU_REFERENCE_ROADS_SNAPSHOT,
  WENYU_TOWN_MODULES_SNAPSHOT,
  KNOWLEDGE_DOMAIN_CATALOG_SNAPSHOT,
} from './runtime_snapshot_manifest.js'
import {
  loadJsonGlobal,
  refreshTextSnapshot,
} from './runtime_snapshot_fetch.js'
const RUNTIME_REFRESH_INTERVAL_MS = 5000

export async function refreshRuntimeSnapshots() {
  await Promise.all(RUNTIME_TEXT_SNAPSHOTS.map(refreshTextSnapshot))
}

export function startRuntimeSnapshotRefresh() {
  if (globalThis.__moontownTownSnapshotRefreshTimer) {
    clearInterval(globalThis.__moontownTownSnapshotRefreshTimer)
  }
  globalThis.__moontownTownSnapshotRefreshTimer = setInterval(
    refreshRuntimeSnapshots,
    RUNTIME_REFRESH_INTERVAL_MS,
  )
}

export async function loadWenyuReferenceLabels() {
  await loadJsonGlobal(WENYU_REFERENCE_LABELS_SNAPSHOT)
}

export function indexWenyuReferenceBuildingComponents() {
  const snapshot = globalThis.__wenyuReferenceBuildings
  const width = snapshot?.tileGrid?.width
  const height = snapshot?.tileGrid?.height
  const rows = snapshot?.labelRows
  const supportedSchema =
    snapshot?.schema === 'moontown.wenyu_reference_buildings.v4' ||
    snapshot?.schema === 'moontown.wenyu_reference_building_anchors.v1'
  if (
    !supportedSchema ||
    width !== 256 ||
    height !== 144 ||
    !Array.isArray(rows) ||
    rows.length !== height ||
    rows.some(row => typeof row !== 'string' || row.length !== width)
  ) {
    globalThis.__wenyuReferenceBuildingComponentRows = null
    return
  }

  const codeForKind = {
    lowrise: 'l',
    row: 'r',
    block: 'b',
    tower: 't',
    courtyard: 'q',
    campus: 'c',
    civic: 'v',
    industrial: 'i',
  }
  const componentRows = Array.from(
    { length: height },
    () => Array(width).fill(null),
  )
  const typedCodes = new Set(Object.values(codeForKind))
  let componentIndex = 0
  for (let startY = 0; startY < height; startY += 1) {
    for (let startX = 0; startX < width; startX += 1) {
      const code = rows[startY][startX]
      if (!typedCodes.has(code) || componentRows[startY][startX] != null) {
        continue
      }

      const cells = [[startX, startY]]
      componentRows[startY][startX] = false
      let minX = startX
      let minY = startY
      for (let cursor = 0; cursor < cells.length; cursor += 1) {
        const [x, y] = cells[cursor]
        minX = Math.min(minX, x)
        minY = Math.min(minY, y)
        for (const [nextX, nextY] of [
          [x + 1, y],
          [x - 1, y],
          [x, y + 1],
          [x, y - 1],
        ]) {
          if (
            nextX >= 0 &&
            nextX < width &&
            nextY >= 0 &&
            nextY < height &&
            rows[nextY][nextX] === code &&
            componentRows[nextY][nextX] == null
          ) {
            componentRows[nextY][nextX] = false
            cells.push([nextX, nextY])
          }
        }
      }

      for (const [x, y] of cells) {
        componentRows[y][x] = {
          index: componentIndex,
          anchorX: minX,
          anchorY: minY,
        }
      }
      componentIndex += 1
    }
  }
  globalThis.__wenyuReferenceBuildingComponentRows = componentRows
}

export async function loadWenyuReferenceBuildings() {
  await loadJsonGlobal(WENYU_REFERENCE_BUILDINGS_SNAPSHOT)
  indexWenyuReferenceBuildingComponents()
}

export async function loadWenyuReferenceRoads() {
  await loadJsonGlobal(WENYU_REFERENCE_ROADS_SNAPSHOT)
}

const ENERGY_VALLEY_OSM_BLOCK_GRAPH_METRICS = Object.freeze({
  intersections: 338,
  routingNodes: 157,
  totalNodes: 495,
  edges: 775,
  components: 11,
  cycleRank: 291,
  bridges: 22,
  bridgeSpanVertices: 59,
  t: 181,
  cross: 57,
  complex: 100,
  high: 153,
  medium: 121,
  review: 64,
})

export function validateEnergyValleyOsmBlockGraph(snapshot) {
  const expected = ENERGY_VALLEY_OSM_BLOCK_GRAPH_METRICS
  const metrics = snapshot?.metrics
  const points = snapshot?.points
  const routingNodes = snapshot?.graph?.routingNodes
  const edges = snapshot?.graph?.edges
  if (
    snapshot?.schema !== 'moontown.energy-valley.osm_block_graph.v1' ||
    snapshot?.runtimeEligible !== false ||
    snapshot?.provenance?.source !== 'OpenStreetMap' ||
    snapshot?.provenance?.license !== 'ODbL-1.0' ||
    snapshot?.calibration?.rotationDegrees !== 22.924436871 ||
    snapshot?.calibration?.scaleMetresPerTile !== 37.86186326908114 ||
    snapshot?.calibration?.rmsTiles !== 0.476397 ||
    snapshot?.tileGrid?.width !== 256 ||
    snapshot?.tileGrid?.height !== 144 ||
    snapshot?.tileGrid?.coordinateUnit !== 'millitile' ||
    metrics?.intersections !== expected.intersections ||
    metrics?.routingNodes !== expected.routingNodes ||
    metrics?.totalNodes !== expected.totalNodes ||
    metrics?.edges !== expected.edges ||
    metrics?.components !== expected.components ||
    metrics?.cycleRank !== expected.cycleRank ||
    metrics?.bridges !== expected.bridges ||
    metrics?.bridgeSpanVertices !== expected.bridgeSpanVertices ||
    metrics?.kinds?.t !== expected.t ||
    metrics?.kinds?.cross !== expected.cross ||
    metrics?.kinds?.complex !== expected.complex ||
    metrics?.confidence?.high !== expected.high ||
    metrics?.confidence?.medium !== expected.medium ||
    metrics?.confidence?.review !== expected.review ||
    !Array.isArray(points) || points.length !== expected.intersections ||
    !Array.isArray(routingNodes) ||
    routingNodes.length !== expected.routingNodes ||
    !Array.isArray(edges) || edges.length !== expected.edges
  ) {
    return false
  }

  const endpoints = new Map()
  const coordinates = new Set()
  const pointIds = new Set()
  const kindCounts = { t: 0, cross: 0, complex: 0 }
  const confidenceCounts = { high: 0, medium: 0, review: 0 }
  for (const point of points) {
    const coordinate = `${point?.xMillis}:${point?.yMillis}`
    if (
      !/^intersection-[0-9]{3}$/.test(point?.id || '') ||
      pointIds.has(point.id) || coordinates.has(coordinate) ||
      !Number.isInteger(point?.xMillis) ||
      point.xMillis < 0 || point.xMillis > 256000 ||
      !Number.isInteger(point?.yMillis) ||
      point.yMillis < 0 || point.yMillis > 144000 ||
      !['t', 'cross', 'complex'].includes(point?.kind) ||
      !Number.isInteger(point?.degree) ||
      point.degree < 1 || point.degree > 12 ||
      !['high', 'medium', 'review'].includes(
        point?.semanticEvidence?.confidence,
      )
    ) {
      return false
    }
    pointIds.add(point.id)
    coordinates.add(coordinate)
    endpoints.set(point.id, point)
    kindCounts[point.kind] += 1
    confidenceCounts[point.semanticEvidence.confidence] += 1
  }
  if (
    kindCounts.t !== expected.t || kindCounts.cross !== expected.cross ||
    kindCounts.complex !== expected.complex ||
    confidenceCounts.high !== expected.high ||
    confidenceCounts.medium !== expected.medium ||
    confidenceCounts.review !== expected.review
  ) {
    return false
  }

  for (const node of routingNodes) {
    const coordinate = `${node?.xMillis}:${node?.yMillis}`
    if (
      typeof node?.id !== 'string' || !node.id || endpoints.has(node.id) ||
      coordinates.has(coordinate) ||
      !Number.isInteger(node?.xMillis) ||
      node.xMillis < 0 || node.xMillis > 256000 ||
      !Number.isInteger(node?.yMillis) ||
      node.yMillis < 0 || node.yMillis > 144000 ||
      !['map-boundary', 'road-terminal'].includes(node?.reason)
    ) {
      return false
    }
    coordinates.add(coordinate)
    endpoints.set(node.id, node)
  }

  const edgeIds = new Set()
  const graphNodes = new Set()
  const adjacency = new Map()
  const edgeDegrees = new Map()
  let bridgeCount = 0
  let bridgeSpanVertices = 0
  const connect = (from, to) => {
    if (!adjacency.has(from)) adjacency.set(from, new Set())
    adjacency.get(from).add(to)
  }
  for (const edge of edges) {
    const path = edge?.pathMillis
    if (
      !/^edge-[0-9]{4}$/.test(edge?.id || '') || edgeIds.has(edge.id) ||
      !endpoints.has(edge?.from) || !endpoints.has(edge?.to) ||
      edge.from === edge.to || !Array.isArray(path) || path.length < 2 ||
      !['high', 'medium', 'review'].includes(edge?.confidence) ||
      !Array.isArray(edge?.bridgeSpans)
    ) {
      return false
    }
    for (const point of path) {
      if (
        !Array.isArray(point) || point.length !== 2 ||
        !Number.isInteger(point[0]) || point[0] < 0 || point[0] > 256000 ||
        !Number.isInteger(point[1]) || point[1] < 0 || point[1] > 144000
      ) {
        return false
      }
    }
    const from = endpoints.get(edge.from)
    const to = endpoints.get(edge.to)
    if (
      path[0][0] !== from.xMillis || path[0][1] !== from.yMillis ||
      path[path.length - 1][0] !== to.xMillis ||
      path[path.length - 1][1] !== to.yMillis
    ) {
      return false
    }
    let previousTo = -1
    for (const span of edge.bridgeSpans) {
      if (
        !Number.isInteger(span?.fromIndex) ||
        !Number.isInteger(span?.toIndex) ||
        span.fromIndex < 0 || span.fromIndex >= span.toIndex ||
        span.toIndex >= path.length || span.fromIndex <= previousTo
      ) {
        return false
      }
      previousTo = span.toIndex
      bridgeCount += 1
      bridgeSpanVertices += span.toIndex - span.fromIndex + 1
    }
    edgeIds.add(edge.id)
    graphNodes.add(edge.from)
    graphNodes.add(edge.to)
    edgeDegrees.set(edge.from, (edgeDegrees.get(edge.from) || 0) + 1)
    edgeDegrees.set(edge.to, (edgeDegrees.get(edge.to) || 0) + 1)
    connect(edge.from, edge.to)
    connect(edge.to, edge.from)
  }
  if (
    edgeIds.size !== expected.edges || graphNodes.size !== expected.totalNodes ||
    bridgeCount !== expected.bridges ||
    bridgeSpanVertices !== expected.bridgeSpanVertices ||
    points.some(point => !graphNodes.has(point.id)) ||
    routingNodes.some(node => !graphNodes.has(node.id))
  ) {
    return false
  }
  for (const point of points) {
    if ((edgeDegrees.get(point.id) || 0) !== point.degree) return false
  }
  let components = 0
  const visited = new Set()
  for (const start of graphNodes) {
    if (visited.has(start)) continue
    components += 1
    const pending = [start]
    visited.add(start)
    for (let index = 0; index < pending.length; index += 1) {
      for (const neighbor of adjacency.get(pending[index]) || []) {
        if (!visited.has(neighbor)) {
          visited.add(neighbor)
          pending.push(neighbor)
        }
      }
    }
  }
  return components === expected.components &&
    expected.cycleRank === expected.edges - expected.totalNodes + components
}

export function acceptEnergyValleyOsmBlockGraph() {
  const valid = validateEnergyValleyOsmBlockGraph(
    globalThis.__moontownEnergyValleyOsmBlockGraph,
  )
  globalThis.__moontownEnergyValleyOsmBlockGraphValidated = valid
  if (!valid) globalThis.__moontownEnergyValleyOsmBlockGraph = null
  return valid
}

export async function loadEnergyValleyOsmBlockGraph() {
  await loadJsonGlobal(ENERGY_VALLEY_OSM_BLOCK_GRAPH_SNAPSHOT)
  acceptEnergyValleyOsmBlockGraph()
}

const WENYU_INTERSECTION_METRICS = Object.freeze({
  points: 145,
  tJunctions: 84,
  crossIntersections: 55,
  complexIntersections: 6,
  high: 31,
  medium: 62,
  review: 52,
})

const WENYU_INTERSECTION_PREVIEW_GRAPH = Object.freeze({
  method:
    'exact-seed 8-neighbor source-skeleton geodesics, unique-segment union, degree-not-two routing-node compression',
  nodes: 145,
  routingNodes: 38,
  totalGraphNodes: 183,
  edges: 216,
  components: 1,
  cycleRank: 34,
  terminalsOmitted: 160,
  unrepresentedVerifiedArms: 193,
  bridges: 5,
  bridgeEvidenceVertices: 66,
  bridgeSpanVertices: 68,
  sourceSegments: 14141,
  enclosedBlocks: 34,
  waterConflicts: 0,
})

function exactIntersectionMetrics(metrics) {
  return metrics?.points === WENYU_INTERSECTION_METRICS.points &&
    metrics?.tJunctions === WENYU_INTERSECTION_METRICS.tJunctions &&
    metrics?.crossIntersections ===
      WENYU_INTERSECTION_METRICS.crossIntersections &&
    metrics?.complexIntersections ===
      WENYU_INTERSECTION_METRICS.complexIntersections &&
    metrics?.roofBlobsDiscarded === 2 &&
    metrics?.externalArmCounts?.['3'] === 84 &&
    metrics?.externalArmCounts?.['4'] === 55 &&
    metrics?.externalArmCounts?.['5'] === 3 &&
    metrics?.externalArmCounts?.['6'] === 1 &&
    metrics?.externalArmCounts?.['8'] === 2 &&
    metrics?.semanticConfidence?.high === WENYU_INTERSECTION_METRICS.high &&
    metrics?.semanticConfidence?.medium ===
      WENYU_INTERSECTION_METRICS.medium &&
    metrics?.semanticConfidence?.review === WENYU_INTERSECTION_METRICS.review
}

export function validateWenyuReferenceIntersectionPoints(snapshot) {
  if (
    ![
      'moontown.wenyu_reference_intersections.v1',
      'moontown.wenyu_reference_intersections.v2',
    ].includes(snapshot?.schema) ||
    snapshot?.tileGrid?.width !== 256 ||
    snapshot?.tileGrid?.height !== 144 ||
    snapshot?.tileGrid?.coordinateUnit !== 'millitile' ||
    snapshot?.runtimeEligible !== false ||
    snapshot?.source?.image?.path !==
      'asset://tilemap/wenyu_topdown_semantic.png' ||
    snapshot?.source?.image?.sha256 !==
      'sha256:10d09f3fb45da0e6dbcfb89dee19051df23d8be4b6b5e28aafbd51817c64d93b' ||
    snapshot?.source?.image?.width !== 1672 ||
    snapshot?.source?.image?.height !== 941 ||
    snapshot?.source?.semanticLabels?.path !==
      'asset://tilemap/wenyu_reference_labels.json' ||
    snapshot?.source?.semanticLabels?.sha256 !==
      'sha256:9b93cc1b9c55aa26ec5e2e21b177aea4cba97940e2a78fea06d36d04d84f6d89' ||
    snapshot?.source?.semanticLabels?.schema !==
      'moontown.wenyu_reference_labels.v3' ||
    snapshot?.source?.semanticLabels?.role !==
      'independent confidence only; never a point filter' ||
    JSON.stringify(snapshot?.source?.semanticLabels?.roadCodes) !==
      '["M","R","b"]' ||
    snapshot?.authoringCalibration?.source !==
      'asset://tilemap/georeference/wenyu-town-georef-v1.json' ||
    snapshot?.authoringCalibration?.model !== 'similarity' ||
    snapshot?.authoringCalibration?.rotationDegrees !== 22.924436871 ||
    snapshot?.authoringCalibration?.metersPerTile !== 37.86186326908114 ||
    snapshot?.authoringCalibration?.fitRmsTiles !== 0.476397 ||
    snapshot?.authoringCalibration?.runtimeEligible !== false ||
    snapshot?.authoringCalibration?.appliedToPoints !== false ||
    snapshot?.authoringCalibration?.scope !==
      'authoring calibration only; no point transform or transport activation' ||
    snapshot?.detector?.roofBlobHalfWidthMinimumPixels !== 12 ||
    snapshot?.detector?.semanticConfidenceThresholdsMillis?.highMaximum !==
      750 ||
    snapshot?.detector?.semanticConfidenceThresholdsMillis?.mediumMaximum !==
      2000 ||
    !exactIntersectionMetrics(snapshot?.metrics) ||
    !Array.isArray(snapshot?.points) ||
    snapshot.points.length !== WENYU_INTERSECTION_METRICS.points
  ) {
    return false
  }

  const ids = new Set()
  const coordinates = new Set()
  const kinds = { t: 0, cross: 0, complex: 0 }
  const armCounts = { 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0 }
  const confidence = { high: 0, medium: 0, review: 0 }
  for (const point of snapshot.points) {
    const kindArmsValid =
      (point?.kind === 't' && point?.externalArms === 3) ||
      (point?.kind === 'cross' && point?.externalArms === 4) ||
      (point?.kind === 'complex' &&
        point?.externalArms >= 5 && point?.externalArms <= 8)
    const distance = point?.semanticEvidence?.nearestDistanceMillis
    const expectedConfidence = distance <= 750
      ? 'high'
      : distance <= 2000 ? 'medium' : 'review'
    const nearestCell = point?.semanticEvidence?.nearestCell
    if (
      !/^junction-[0-9]{3}$/.test(point?.id || '') ||
      !Number.isInteger(point?.xMillis) ||
      point.xMillis < 0 ||
      point.xMillis >= 256000 ||
      !Number.isInteger(point?.yMillis) ||
      point.yMillis < 0 ||
      point.yMillis >= 144000 ||
      !Number.isInteger(point?.sourcePixel?.x) ||
      point.sourcePixel.x < 0 ||
      point.sourcePixel.x >= 1672 ||
      !Number.isInteger(point?.sourcePixel?.y) ||
      point.sourcePixel.y < 0 ||
      point.sourcePixel.y >= 941 ||
      !Number.isInteger(point?.externalArms) ||
      !kindArmsValid ||
      !Number.isInteger(point?.sourceHalfWidthPixels) ||
      point.sourceHalfWidthPixels < 1 ||
      point.sourceHalfWidthPixels >= 12 ||
      !Number.isInteger(point?.junctionCorePixels) ||
      point.junctionCorePixels < 1 ||
      !Number.isInteger(distance) ||
      distance < 0 ||
      point?.semanticEvidence?.confidence !== expectedConfidence ||
      !Number.isInteger(nearestCell?.x) ||
      nearestCell.x < 0 ||
      nearestCell.x >= 256 ||
      !Number.isInteger(nearestCell?.y) ||
      nearestCell.y < 0 ||
      nearestCell.y >= 144 ||
      !['M', 'R', 'b'].includes(nearestCell?.code)
    ) {
      return false
    }
    const coordinate = `${point.xMillis}:${point.yMillis}`
    if (ids.has(point.id) || coordinates.has(coordinate)) {
      return false
    }
    ids.add(point.id)
    coordinates.add(coordinate)
    kinds[point.kind] += 1
    armCounts[point.externalArms] += 1
    confidence[point.semanticEvidence.confidence] += 1
  }

  return kinds.t === snapshot.metrics.tJunctions &&
    kinds.cross === snapshot.metrics.crossIntersections &&
    kinds.complex === snapshot.metrics.complexIntersections &&
    armCounts[3] === snapshot.metrics.externalArmCounts['3'] &&
    armCounts[4] === snapshot.metrics.externalArmCounts['4'] &&
    armCounts[5] === snapshot.metrics.externalArmCounts['5'] &&
    armCounts[6] === snapshot.metrics.externalArmCounts['6'] &&
    armCounts[7] === 0 &&
    armCounts[8] === snapshot.metrics.externalArmCounts['8'] &&
    confidence.high === snapshot.metrics.semanticConfidence.high &&
    confidence.medium === snapshot.metrics.semanticConfidence.medium &&
    confidence.review === snapshot.metrics.semanticConfidence.review
}

function exactPreviewGraphMetrics(metrics, graphNodeCount, components) {
  const expected = WENYU_INTERSECTION_PREVIEW_GRAPH
  return metrics?.nodes === expected.nodes &&
    metrics?.routingNodes === expected.routingNodes &&
    metrics?.totalGraphNodes === expected.totalGraphNodes &&
    metrics?.edges === expected.edges &&
    metrics?.components === expected.components &&
    metrics?.cycleRank === expected.cycleRank &&
    metrics?.terminalsOmitted === expected.terminalsOmitted &&
    metrics?.unrepresentedVerifiedArms ===
      expected.unrepresentedVerifiedArms &&
    metrics?.bridges === expected.bridges &&
    metrics?.bridgeEvidenceVertices === expected.bridgeEvidenceVertices &&
    metrics?.bridgeSpanVertices === expected.bridgeSpanVertices &&
    metrics?.sourceSegments === expected.sourceSegments &&
    metrics?.enclosedBlocks === expected.enclosedBlocks &&
    metrics?.waterConflicts === expected.waterConflicts &&
    metrics.totalGraphNodes === graphNodeCount &&
    metrics.components === components &&
    metrics.cycleRank ===
      metrics.edges - metrics.totalGraphNodes + metrics.components &&
    metrics.enclosedBlocks === metrics.cycleRank
}

function validatePreviewGraph(snapshot) {
  const routingNodes = snapshot?.previewGraph?.routingNodes
  if (
    snapshot?.schema !== 'moontown.wenyu_reference_intersections.v2' ||
    snapshot?.previewGraph?.method !==
      WENYU_INTERSECTION_PREVIEW_GRAPH.method ||
    !Array.isArray(routingNodes) ||
    routingNodes.length !== WENYU_INTERSECTION_PREVIEW_GRAPH.routingNodes ||
    !Array.isArray(snapshot?.previewGraph?.edges) ||
    snapshot.previewGraph.edges.length !== WENYU_INTERSECTION_PREVIEW_GRAPH.edges
  ) {
    return false
  }

  const points = new Map(snapshot.points.map(point => [point.id, point]))
  const endpoints = new Map(points)
  const endpointCoordinates = new Set(
    snapshot.points.map(point => `${point.xMillis}:${point.yMillis}`),
  )
  const declaredRoutingNodes = new Set()
  for (const node of routingNodes || []) {
    if (
      typeof node?.id !== 'string' ||
      !/^routing-[0-9]{3}$/.test(node.id) ||
      endpoints.has(node.id) ||
      !Number.isInteger(node?.xMillis) ||
      node.xMillis < 0 || node.xMillis >= 256000 ||
      !Number.isInteger(node?.yMillis) ||
      node.yMillis < 0 || node.yMillis >= 144000 ||
      node?.reason !== 'source-branch'
    ) {
      return false
    }
    const coordinate = `${node.xMillis}:${node.yMillis}`
    if (endpointCoordinates.has(coordinate)) return false
    endpoints.set(node.id, node)
    endpointCoordinates.add(coordinate)
    declaredRoutingNodes.add(node.id)
  }
  for (let index = 0; index < WENYU_INTERSECTION_PREVIEW_GRAPH.routingNodes;
    index += 1) {
    if (!declaredRoutingNodes.has(`routing-${String(index).padStart(3, '0')}`)) {
      return false
    }
  }
  const edgeIds = new Set()
  const endpointPairs = new Set()
  const graphNodes = new Set()
  const adjacency = new Map()
  const physicalSegments = new Set()
  const physicalVertices = new Map()
  let bridgeSpanVertexCount = 0
  let bridgeCount = 0
  const confidenceRank = { high: 0, medium: 1, review: 2 }
  const connect = (from, to) => {
    if (!adjacency.has(from)) adjacency.set(from, new Set())
    adjacency.get(from).add(to)
  }

  for (const edge of snapshot.previewGraph.edges) {
    const from = endpoints.get(edge?.from)
    const to = endpoints.get(edge?.to)
    const path = edge?.pathMillis
    const endpointPair = edge?.from < edge?.to
      ? `${edge.from}:${edge.to}`
      : `${edge?.to}:${edge?.from}`
    if (
      typeof edge?.id !== 'string' || !/^edge-[0-9]{3}$/.test(edge.id) ||
      edgeIds.has(edge.id) ||
      !from || !to || edge.from >= edge.to ||
      endpointPairs.has(endpointPair) ||
      !Array.isArray(path) || path.length < 2 ||
      !Number.isInteger(edge?.sourceLengthPixels) ||
      edge.sourceLengthPixels !== path.length - 1 ||
      !['high', 'medium', 'review'].includes(edge?.confidence) ||
      !Array.isArray(edge?.bridgeSpans)
    ) {
      return false
    }
    const pathVertices = new Set()
    for (let index = 0; index < path.length; index += 1) {
      const point = path[index]
      const previous = path[index - 1]
      const deltaX = index > 0 ? Math.abs(point?.[0] - previous?.[0]) : 0
      const deltaY = index > 0 ? Math.abs(point?.[1] - previous?.[1]) : 0
      if (
        !Array.isArray(point) || point.length !== 2 ||
        !Number.isInteger(point[0]) || point[0] < 0 || point[0] >= 256000 ||
        !Number.isInteger(point[1]) || point[1] < 0 || point[1] >= 144000 ||
        (index > 0 && (
          ![0, 153, 154].includes(deltaX) ||
          ![0, 153, 154].includes(deltaY) ||
          (deltaX === 0 && deltaY === 0)
        ))
      ) {
        return false
      }
      const vertex = `${point[0]}:${point[1]}`
      if (pathVertices.has(vertex)) return false
      pathVertices.add(vertex)
      const isEndpoint = index === 0 || index === path.length - 1
      const endpointId = index === 0
        ? edge.from
        : index === path.length - 1 ? edge.to : null
      if (!physicalVertices.has(vertex)) physicalVertices.set(vertex, [])
      physicalVertices.get(vertex).push({ isEndpoint, endpointId })
      if (index > 0) {
        const previousVertex = `${previous[0]}:${previous[1]}`
        const segment = previousVertex < vertex
          ? `${previousVertex}|${vertex}`
          : `${vertex}|${previousVertex}`
        if (physicalSegments.has(segment)) return false
        physicalSegments.add(segment)
      }
    }
    if (
      path[0][0] !== from.xMillis || path[0][1] !== from.yMillis ||
      path[path.length - 1][0] !== to.xMillis ||
      path[path.length - 1][1] !== to.yMillis
    ) {
      return false
    }
    const fromPoint = points.get(edge.from)
    const toPoint = points.get(edge.to)
    const knownEndpointConfidence = [fromPoint, toPoint]
      .filter(Boolean)
      .reduce(
        (rank, point) => Math.max(
          rank,
          confidenceRank[point.semanticEvidence.confidence],
        ),
        -1,
      )
    if (
      knownEndpointConfidence >= 0 &&
      confidenceRank[edge.confidence] < knownEndpointConfidence
    ) {
      return false
    }
    let previousTo = -1
    for (const span of edge.bridgeSpans) {
      if (
        !Number.isInteger(span?.fromIndex) ||
        !Number.isInteger(span?.toIndex) ||
        span.fromIndex < 0 || span.fromIndex >= span.toIndex ||
        span.toIndex >= path.length ||
        span.fromIndex <= previousTo
      ) {
        return false
      }
      previousTo = span.toIndex
      bridgeCount += 1
      bridgeSpanVertexCount += span.toIndex - span.fromIndex + 1
    }
    edgeIds.add(edge.id)
    endpointPairs.add(endpointPair)
    graphNodes.add(edge.from)
    graphNodes.add(edge.to)
    connect(edge.from, edge.to)
    connect(edge.to, edge.from)
  }

  for (const routingNode of declaredRoutingNodes) {
    if (!graphNodes.has(routingNode)) return false
  }
  for (let index = 0; index < WENYU_INTERSECTION_PREVIEW_GRAPH.edges;
    index += 1) {
    if (!edgeIds.has(`edge-${String(index).padStart(3, '0')}`)) return false
  }
  for (const uses of physicalVertices.values()) {
    if (uses.length <= 1) continue
    if (uses.some(use => !use.isEndpoint)) return false
    if (uses.some(use => use.endpointId !== uses[0].endpointId)) return false
  }
  const pointDegreeCounts = { 1: 0, 2: 0, 3: 0, 4: 0 }
  let unrepresentedVerifiedArms = 0
  for (const point of snapshot.points) {
    const degree = adjacency.get(point.id)?.size || 0
    if (degree < 1 || degree > point.externalArms || degree > 4) return false
    pointDegreeCounts[degree] += 1
    unrepresentedVerifiedArms += point.externalArms - degree
  }
  if (
    pointDegreeCounts[1] !== 22 || pointDegreeCounts[2] !== 76 ||
    pointDegreeCounts[3] !== 46 || pointDegreeCounts[4] !== 1 ||
    unrepresentedVerifiedArms !==
      WENYU_INTERSECTION_PREVIEW_GRAPH.unrepresentedVerifiedArms
  ) {
    return false
  }
  const routingDegreeCounts = { 3: 0, 4: 0 }
  for (const node of routingNodes) {
    const degree = adjacency.get(node.id)?.size || 0
    if (degree !== 3 && degree !== 4) return false
    routingDegreeCounts[degree] += 1
  }
  if (routingDegreeCounts[3] !== 36 || routingDegreeCounts[4] !== 2) {
    return false
  }

  let components = 0
  const visited = new Set()
  for (const start of graphNodes) {
    if (visited.has(start)) continue
    components += 1
    const pending = [start]
    visited.add(start)
    for (let index = 0; index < pending.length; index += 1) {
      for (const neighbor of adjacency.get(pending[index]) || []) {
        if (!visited.has(neighbor)) {
          visited.add(neighbor)
          pending.push(neighbor)
        }
      }
    }
  }

  return exactPreviewGraphMetrics(
    snapshot.previewGraph.metrics,
    graphNodes.size,
    components,
  ) && snapshot.previewGraph.metrics.bridges === bridgeCount &&
    snapshot.previewGraph.metrics.bridgeSpanVertices ===
      bridgeSpanVertexCount &&
    snapshot.previewGraph.metrics.sourceSegments === physicalSegments.size
}

export function validateWenyuReferenceIntersections(snapshot) {
  return validateWenyuReferenceIntersectionPoints(snapshot) &&
    validatePreviewGraph(snapshot)
}

export function acceptWenyuReferenceIntersections() {
  const snapshot = globalThis.__wenyuReferenceIntersections
  const pointsValid = validateWenyuReferenceIntersectionPoints(snapshot)
  const graphValid = pointsValid && validatePreviewGraph(snapshot)
  globalThis.__wenyuReferenceIntersectionsValidated = pointsValid
  globalThis.__wenyuReferenceIntersectionPreviewGraphValidated = graphValid
  if (!pointsValid) {
    globalThis.__wenyuReferenceIntersections = null
  }
  return graphValid
}

export async function loadWenyuReferenceIntersections() {
  await loadJsonGlobal(WENYU_REFERENCE_INTERSECTIONS_SNAPSHOT)
  acceptWenyuReferenceIntersections()
}

export async function loadWenyuTownModules() {
  await refreshTextSnapshot(WENYU_TOWN_MODULES_SNAPSHOT)
}

export async function loadKnowledgeDomainCatalog() {
  await refreshTextSnapshot(KNOWLEDGE_DOMAIN_CATALOG_SNAPSHOT)
  const text = globalThis.__moontownKnowledgeDomainCatalogJson || ''
  if (!text) {
    globalThis.__moontownKnowledgeDomainCatalogDigest = ''
    return
  }
  const bytes = new TextEncoder().encode(text)
  const digest = await globalThis.crypto.subtle.digest('SHA-256', bytes)
  const hex = Array.from(new Uint8Array(digest), byte =>
    byte.toString(16).padStart(2, '0')).join('')
  globalThis.__moontownKnowledgeDomainCatalogDigest = `sha256:${hex}`
}

globalThis.__moontownRefreshRuntimeSnapshots = refreshRuntimeSnapshots
