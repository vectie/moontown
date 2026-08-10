import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import { readFile } from 'node:fs/promises'
import { test } from 'node:test'

const assetUrl = new URL(
  '../assets/tilemap/wenyu_reference_intersections.json',
  import.meta.url,
)
const sourceUrl = new URL(
  '../assets/tilemap/wenyu_topdown_semantic.png',
  import.meta.url,
)
const intersections = JSON.parse(await readFile(assetUrl, 'utf8'))

function countBy(values) {
  const counts = {}
  for (const value of values) counts[value] = (counts[value] ?? 0) + 1
  return counts
}

test('Wenyu intersections retain every source-verified branch complex', () => {
  assert.equal(
    intersections.schema,
    'moontown.wenyu_reference_intersections.v2',
  )
  assert.equal(intersections.runtimeEligible, false)
  assert.deepEqual(intersections.tileGrid, {
    width: 256,
    height: 144,
    coordinateUnit: 'millitile',
  })
  assert.equal(intersections.points.length, 145)
  assert.deepEqual(
    countBy(intersections.points.map(point => point.kind)),
    { t: 84, cross: 55, complex: 6 },
  )
  assert.deepEqual(
    countBy(intersections.points.map(point => point.externalArms)),
    { 3: 84, 4: 55, 5: 3, 6: 1, 8: 2 },
  )
  assert.equal(intersections.metrics.roofBlobsDiscarded, 2)
  assert.equal(intersections.metrics.points, 145)
})

test('all native coordinates are unique safe integer millitiles', () => {
  const ids = new Set()
  const sourcePixels = new Set()
  const nativePoints = new Set()
  for (const [index, point] of intersections.points.entries()) {
    assert.equal(point.id, `junction-${String(index).padStart(3, '0')}`)
    assert.ok(Number.isSafeInteger(point.xMillis))
    assert.ok(Number.isSafeInteger(point.yMillis))
    assert.ok(point.xMillis >= 0 && point.xMillis < 256000)
    assert.ok(point.yMillis >= 0 && point.yMillis < 144000)
    assert.ok(Number.isSafeInteger(point.sourcePixel.x))
    assert.ok(Number.isSafeInteger(point.sourcePixel.y))
    assert.ok(point.sourceHalfWidthPixels >= 1)
    assert.ok(point.sourceHalfWidthPixels < 12)
    assert.ok(point.junctionCorePixels >= 1)
    assert.equal(point.kind, point.externalArms === 3
      ? 't'
      : point.externalArms === 4
        ? 'cross'
        : 'complex')
    ids.add(point.id)
    sourcePixels.add(`${point.sourcePixel.x}:${point.sourcePixel.y}`)
    nativePoints.add(`${point.xMillis}:${point.yMillis}`)
  }
  assert.equal(ids.size, intersections.points.length)
  assert.equal(sourcePixels.size, intersections.points.length)
  assert.equal(nativePoints.size, intersections.points.length)
})

test('semantic labels grade confidence but never filter review points', () => {
  assert.equal(
    intersections.source.semanticLabels.role,
    'independent confidence only; never a point filter',
  )
  const confidenceCounts = countBy(
    intersections.points.map(point => point.semanticEvidence.confidence),
  )
  assert.deepEqual(confidenceCounts, { high: 31, medium: 62, review: 52 })
  for (const point of intersections.points) {
    const evidence = point.semanticEvidence
    assert.ok(Number.isSafeInteger(evidence.nearestDistanceMillis))
    assert.ok(['M', 'R', 'b'].includes(evidence.nearestCell.code))
    if (evidence.confidence === 'high') {
      assert.ok(evidence.nearestDistanceMillis <= 750)
    } else if (evidence.confidence === 'medium') {
      assert.ok(evidence.nearestDistanceMillis > 750)
      assert.ok(evidence.nearestDistanceMillis <= 2000)
    } else {
      assert.ok(evidence.nearestDistanceMillis > 2000)
    }
  }
})

test('source digest and georeference stay pinned as authoring-only evidence', async () => {
  const sourceDigest = createHash('sha256')
    .update(await readFile(sourceUrl))
    .digest('hex')
  assert.equal(
    sourceDigest,
    '10d09f3fb45da0e6dbcfb89dee19051df23d8be4b6b5e28aafbd51817c64d93b',
  )
  assert.equal(intersections.source.image.sha256, `sha256:${sourceDigest}`)
  assert.deepEqual(intersections.authoringCalibration, {
    source: 'asset://tilemap/georeference/wenyu-town-georef-v1.json',
    model: 'similarity',
    rotationDegrees: 22.924436871,
    metersPerTile: 37.86186326908114,
    fitRmsTiles: 0.476397,
    runtimeEligible: false,
    appliedToPoints: false,
    scope: 'authoring calibration only; no point transform or transport activation',
  })
})

test('preview graph is a connected non-overlapping exact-source union', () => {
  const graph = intersections.previewGraph
  assert.equal(
    graph.method,
    'exact-seed 8-neighbor source-skeleton geodesics, unique-segment union, degree-not-two routing-node compression',
  )
  assert.deepEqual(graph.metrics, {
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
    waterConflicts: 0,
    sourceSegments: 14141,
    enclosedBlocks: 34,
  })

  const pointById = new Map(intersections.points.map(point => [point.id, point]))
  const coordinateById = new Map(
    intersections.points.map(point => [point.id, [point.xMillis, point.yMillis]]),
  )
  assert.equal(graph.routingNodes.length, 38)
  for (const [index, node] of graph.routingNodes.entries()) {
    assert.equal(node.id, `routing-${String(index).padStart(3, '0')}`)
    assert.equal(node.reason, 'source-branch')
    assert.ok(Number.isSafeInteger(node.xMillis))
    assert.ok(Number.isSafeInteger(node.yMillis))
    assert.ok(node.xMillis >= 0 && node.xMillis < 256000)
    assert.ok(node.yMillis >= 0 && node.yMillis < 144000)
    assert.equal(coordinateById.has(node.id), false)
    coordinateById.set(node.id, [node.xMillis, node.yMillis])
  }

  const degrees = new Map([...coordinateById.keys()].map(id => [id, 0]))
  const endpointPairs = new Set()
  const physicalSegments = new Set()
  const confidenceCounts = {}
  let bridgeSpans = 0
  let bridgeSpanVertices = 0
  for (const [index, edge] of graph.edges.entries()) {
    assert.equal(edge.id, `edge-${String(index).padStart(3, '0')}`)
    assert.ok(coordinateById.has(edge.from))
    assert.ok(coordinateById.has(edge.to))
    assert.ok(edge.from < edge.to)
    const endpointPair = `${edge.from}:${edge.to}`
    assert.equal(endpointPairs.has(endpointPair), false)
    endpointPairs.add(endpointPair)
    degrees.set(edge.from, degrees.get(edge.from) + 1)
    degrees.set(edge.to, degrees.get(edge.to) + 1)
    assert.deepEqual(edge.pathMillis[0], coordinateById.get(edge.from))
    assert.deepEqual(edge.pathMillis.at(-1), coordinateById.get(edge.to))
    assert.equal(edge.sourceLengthPixels, edge.pathMillis.length - 1)
    assert.ok(['high', 'medium', 'review'].includes(edge.confidence))
    confidenceCounts[edge.confidence] =
      (confidenceCounts[edge.confidence] ?? 0) + 1
    for (let pathIndex = 1; pathIndex < edge.pathMillis.length; pathIndex += 1) {
      const first = edge.pathMillis[pathIndex - 1]
      const second = edge.pathMillis[pathIndex]
      const deltaX = Math.abs(first[0] - second[0])
      const deltaY = Math.abs(first[1] - second[1])
      assert.ok([0, 153, 154].includes(deltaX))
      assert.ok([0, 153, 154].includes(deltaY))
      assert.notDeepEqual([deltaX, deltaY], [0, 0])
      const firstKey = `${first[0]},${first[1]}`
      const secondKey = `${second[0]},${second[1]}`
      const segment = firstKey < secondKey
        ? `${firstKey}:${secondKey}`
        : `${secondKey}:${firstKey}`
      assert.equal(physicalSegments.has(segment), false)
      physicalSegments.add(segment)
    }
    let previousEnd = -1
    for (const span of edge.bridgeSpans) {
      assert.ok(span.fromIndex > previousEnd)
      assert.ok(span.fromIndex < span.toIndex)
      assert.ok(span.toIndex < edge.pathMillis.length)
      previousEnd = span.toIndex
      bridgeSpans += 1
      bridgeSpanVertices += span.toIndex - span.fromIndex + 1
    }
  }

  assert.equal(graph.edges.length, 216)
  assert.equal(physicalSegments.size, 14141)
  assert.equal(bridgeSpans, 5)
  assert.equal(bridgeSpanVertices, 68)
  assert.deepEqual(confidenceCounts, { medium: 79, high: 11, review: 126 })
  assert.ok([...degrees.values()].every(degree => degree > 0))
  assert.equal(
    graph.edges.length - coordinateById.size + graph.metrics.components,
    graph.metrics.cycleRank,
  )
  for (const [pointId, point] of pointById) {
    assert.ok(degrees.get(pointId) <= point.externalArms)
  }
  assert.equal(
    intersections.points.reduce(
      (total, point) => total + point.externalArms - degrees.get(point.id),
      0,
    ),
    graph.metrics.unrepresentedVerifiedArms,
  )
  assert.deepEqual(
    graph.edges
      .filter(edge => edge.bridgeSpans.length > 0)
      .map(({ id, from, to, bridgeSpans: spans }) => ({
        id,
        from,
        to,
        bridgeSpans: spans,
      })),
    [
      {
        id: 'edge-004',
        from: 'junction-002',
        to: 'junction-008',
        bridgeSpans: [{ fromIndex: 148, toIndex: 160 }],
      },
      {
        id: 'edge-036',
        from: 'junction-025',
        to: 'junction-030',
        bridgeSpans: [{ fromIndex: 27, toIndex: 29 }],
      },
      {
        id: 'edge-046',
        from: 'junction-036',
        to: 'junction-042',
        bridgeSpans: [{ fromIndex: 33, toIndex: 65 }],
      },
      {
        id: 'edge-093',
        from: 'junction-072',
        to: 'routing-007',
        bridgeSpans: [{ fromIndex: 63, toIndex: 68 }],
      },
      {
        id: 'edge-132',
        from: 'junction-098',
        to: 'junction-103',
        bridgeSpans: [{ fromIndex: 42, toIndex: 54 }],
      },
    ],
  )
})
