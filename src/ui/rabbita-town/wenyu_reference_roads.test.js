import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import { readFile } from 'node:fs/promises'
import { test } from 'node:test'

const graph = JSON.parse(
  await readFile(
    new URL('../assets/tilemap/wenyu_reference_roads.json', import.meta.url),
    'utf8',
  ),
)

const authoring = JSON.parse(
  await readFile(
    new URL('../../../scripts/wenyu-native-schematic-v1.json', import.meta.url),
    'utf8',
  ),
)

const semanticRoadCodes = new Set(['M', 'R', 'b'])

function rowsSha256(rows, trailingNewline) {
  return createHash('sha256')
    .update(rows.join('\n') + (trailingNewline ? '\n' : ''))
    .digest('hex')
}

function expandVertices(vertices) {
  const path = [vertices[0]]
  for (let index = 1; index < vertices.length; index += 1) {
    const [startX, startY] = vertices[index - 1]
    const [endX, endY] = vertices[index]
    assert.ok(startX === endX || startY === endY)
    assert.notDeepEqual(vertices[index - 1], vertices[index])
    const deltaX = startX === endX ? 0 : endX > startX ? 1 : -1
    const deltaY = startY === endY ? 0 : endY > startY ? 1 : -1
    let x = startX
    let y = startY
    while (x !== endX || y !== endY) {
      x += deltaX
      y += deltaY
      path.push([x, y])
    }
  }
  assert.equal(new Set(path.map(([x, y]) => `${x}:${y}`)).size, path.length)
  return path
}

test('compiled Wenyu roads form one block-separating cardinal graph', () => {
  assert.equal(graph.schema, 'moontown.wenyu_road_graph.v1')
  assert.equal(graph.tileGrid.width, 256)
  assert.equal(graph.tileGrid.height, 144)
  assert.equal(graph.rows.length, graph.tileGrid.height)
  assert.ok(graph.rows.every(row => row.length === graph.tileGrid.width))

  const roads = graph.rows.map(row =>
    [...row].map(code => code === 'M' || code === 'R' || code === 'b'))
  const start = []
  let roadCount = 0
  for (let y = 0; y < graph.tileGrid.height; y += 1) {
    for (let x = 0; x < graph.tileGrid.width; x += 1) {
      if (roads[y][x]) {
        roadCount += 1
        if (start.length === 0) start.push(x, y)
      }
    }
  }

  const queue = [start]
  const visited = new Set([start.join(':')])
  for (let index = 0; index < queue.length; index += 1) {
    const [x, y] = queue[index]
    for (const [dx, dy] of [[0, -1], [1, 0], [0, 1], [-1, 0]]) {
      const nextX = x + dx
      const nextY = y + dy
      const key = `${nextX}:${nextY}`
      if (
        nextX >= 0 &&
        nextX < graph.tileGrid.width &&
        nextY >= 0 &&
        nextY < graph.tileGrid.height &&
        roads[nextY][nextX] &&
        !visited.has(key)
      ) {
        visited.add(key)
        queue.push([nextX, nextY])
      }
    }
  }

  assert.equal(roadCount, graph.metrics.roadTiles)
  assert.equal(roadCount, 4168)
  assert.equal(visited.size, roadCount)
  assert.equal(graph.metrics.connectedComponents4, 1)
  assert.equal(graph.metrics.enclosedLandBlocks, 75)
  assert.ok(graph.metrics.degreeTwoTurnPermille <= 200)
  assert.ok(
    graph.metrics.degreeTwoStraightTiles >
      graph.metrics.degreeTwoTurnTiles * 4,
  )
  assert.ok(graph.metrics.rawSemanticConnectedComponents4 > 900)
})

test('curated schematic ranks rebuild exactly from compact native vertices', () => {
  assert.equal(
    authoring.schema,
    'moontown.wenyu_native_schematic_authoring.v2',
  )
  assert.equal(graph.presentationRows.length, graph.tileGrid.height)
  assert.ok(
    graph.presentationRows.every(
      row => row.length === graph.tileGrid.width && !/[^.PSA]/.test(row),
    ),
  )

  const priority = { '.': 0, A: 1, S: 2, P: 3 }
  const rebuilt = graph.rows.map(row => [...row].map(() => '.'))
  const corridorCounts = { P: 0, S: 0, A: 0 }
  for (const corridor of authoring.corridors) {
    assert.ok(Object.hasOwn(corridorCounts, corridor.rank))
    corridorCounts[corridor.rank] += 1
    for (const [x, y] of expandVertices(corridor.vertices)) {
      assert.ok(semanticRoadCodes.has(graph.rows[y][x]))
      if (priority[corridor.rank] > priority[rebuilt[y][x]]) {
        rebuilt[y][x] = corridor.rank
      }
    }
  }
  assert.deepEqual(graph.presentationRows, rebuilt.map(row => row.join('')))
  assert.deepEqual(corridorCounts, { P: 3, S: 6, A: 0 })

  const counts = { P: 0, S: 0, A: 0, '.': 0 }
  let selectedSemanticRoads = 0
  let hiddenSemanticRoads = 0
  for (let y = 0; y < graph.tileGrid.height; y += 1) {
    for (let x = 0; x < graph.tileGrid.width; x += 1) {
      const rank = graph.presentationRows[y][x]
      const semanticRoad = semanticRoadCodes.has(graph.rows[y][x])
      counts[rank] += 1
      if (rank !== '.') {
        assert.equal(semanticRoad, true)
        selectedSemanticRoads += 1
      } else if (semanticRoad) {
        hiddenSemanticRoads += 1
      }
    }
  }
  assert.deepEqual(counts, { P: 131, S: 135, A: 0, '.': 36598 })
  assert.equal(selectedSemanticRoads, 266)
  assert.equal(hiddenSemanticRoads, 3902)
  assert.deepEqual(authoring.expectedPresentationCounts, {
    primaryTiles: 131,
    secondaryTiles: 135,
    accessTiles: 0,
  })
  assert.equal(graph.presentationMetrics.primaryTiles, counts.P)
  assert.equal(graph.presentationMetrics.secondaryTiles, counts.S)
  assert.equal(graph.presentationMetrics.accessTiles, counts.A)
  assert.equal(graph.presentationMetrics.presentationRoadTiles, 266)
  assert.equal(graph.presentationMetrics.hiddenSemanticRoadTiles, 3902)
  assert.equal(graph.presentationMetrics.connectedComponents4, 1)
  assert.equal(graph.presentationMetrics.largestComponent4, 266)
  assert.equal(graph.presentationMetrics.namedCorridors, 7)
  assert.deepEqual(graph.presentationMetrics.displayBounds, [96, 49, 159, 102])
  assert.equal(graph.presentationMetrics.displayCycleRank, 4)
  assert.equal(graph.presentationMetrics.enclosedDisplayBlocks, 2)
  assert.deepEqual(
    graph.presentationMetrics.largestEnclosedDisplayBlocks,
    [670, 414],
  )
  assert.deepEqual(graph.presentationMetrics.lod, {
    overview: {
      maxZoomMillis: 339,
      visibleCodes: ['P'],
      visibleRoadTiles: 131,
      semanticFallback: false,
    },
    district: {
      minZoomMillis: 340,
      maxZoomMillis: 579,
      visibleCodes: ['P', 'S'],
      visibleRoadTiles: 266,
      semanticFallback: false,
    },
    access: {
      minZoomMillis: 580,
      maxZoomMillis: 719,
      visibleCodes: ['P', 'S', 'A'],
      visibleRoadTiles: 266,
      semanticFallback: false,
    },
    close: {
      minZoomMillis: 720,
      visibleCodes: ['P', 'S', 'A'],
      visibleRoadTiles: 266,
      showStationExits: true,
      semanticFallback: false,
    },
  })
  assert.equal(graph.presentationLegend['.'].neverVisible, true)
  assert.equal(graph.presentationLegend.P.minZoomMillis, 0)
  assert.equal(graph.presentationLegend.S.minZoomMillis, 340)
  assert.equal(graph.presentationLegend.A.minZoomMillis, 580)
  assert.equal(graph.presentationProvenance.semanticCloseReveal, false)
  assert.notEqual(
    graph.presentationMetrics.lod.close.visibleRoadTiles,
    graph.metrics.roadTiles,
  )
})

test('semantic rows stay byte-identical while OSM runtime activation stays off', () => {
  const semanticDigest = rowsSha256(graph.rows, true)
  assert.equal(
    semanticDigest,
    '3ebc130c49b61969a7ee8620c792d9b6e51b48f565868af1ccdde85e0a3ba2b8',
  )
  assert.equal(
    authoring.expectedSemanticRowsSha256,
    `sha256:${semanticDigest}`,
  )
  assert.equal(
    graph.presentationProvenance.semanticRowsSha256,
    `sha256:${semanticDigest}`,
  )
  assert.equal(graph.presentationProvenance.semanticRowsUnchanged, true)
  assert.equal(graph.presentationProvenance.osmRuntimeActivated, false)
  assert.equal(graph.presentationProvenance.wholeMapTransformEligible, false)
  assert.equal('presentation' in graph, false)
  assert.equal(
    rowsSha256(graph.presentationRows, false),
    'f3d51e63ee2caf7bc1b9059b0cae8724253c2103a5b0c5fbd4d8cc802d2ffc18',
  )
})

test('curated bridge ranks never add a non-native crossing', () => {
  const bridgeCounts = { P: 0, S: 0, A: 0, '.': 0 }
  let semanticBridges = 0
  for (let y = 0; y < graph.tileGrid.height; y += 1) {
    for (let x = 0; x < graph.tileGrid.width; x += 1) {
      if (graph.rows[y][x] !== 'b') continue
      semanticBridges += 1
      bridgeCounts[graph.presentationRows[y][x]] += 1
    }
  }
  assert.equal(semanticBridges, 161)
  assert.deepEqual(bridgeCounts, { P: 0, S: 0, A: 0, '.': 161 })
  assert.deepEqual(graph.presentationMetrics.bridgeTilesByRank, {
    primary: 0,
    secondary: 0,
    access: 0,
  })
})

test('Line 17 uses strict integer-millis native station and exit geometry', () => {
  assert.deepEqual(graph.line17, authoring.line17)
  assert.equal(graph.line17.path.length, 15)
  assert.deepEqual(graph.line17.path, [
    [125000, 52000],
    [123480, 55258],
    [121751, 58759],
    [121221, 60626],
    [121010, 62746],
    [119400, 72889],
    [116000, 87000],
    [115600, 93272],
    [115300, 96841],
    [115000, 100824],
    [114800, 103438],
    [114500, 121152],
    [114200, 135037],
    [114000, 140434],
    [113857, 143000],
  ])
  assert.deepEqual(graph.line17.lod, {
    pathMinZoomMillis: 0,
    stationMinZoomMillis: 160,
    exitMinZoomMillis: 720,
  })
  assert.equal(graph.line17.stations.length, 2)
  assert.deepEqual(
    graph.line17.stations.map(station => station.name),
    ['未来科学城北站', '未来科学城站'],
  )
  assert.deepEqual(
    graph.line17.stations.map(station => [
      station.xMillis,
      station.yMillis,
    ]),
    [[125000, 52000], [116000, 87000]],
  )
  assert.deepEqual(
    graph.line17.stations.map(station =>
      station.exits.map(exit => [
        exit.label,
        exit.destination,
        exit.xMillis,
        exit.yMillis,
      ]),
    ),
    [
      [
        ['B', '英才北一街', 125000, 51000],
        ['C', '英才北一街', 125000, 53000],
        ['D', '英才北一街', 124000, 49000],
      ],
      [
        ['A', '能源谷核心区', 116000, 87000],
        ['B', '能源谷核心区', 116000, 86000],
        ['C', '能源谷核心区', 115000, 87000],
        ['D', '能源谷核心区', 120000, 80000],
      ],
    ],
  )
  assert.ok(
    graph.line17.stations[0].yMillis < graph.line17.stations[1].yMillis,
  )

  let exitCount = 0
  for (const point of graph.line17.path) {
    assert.equal(point.length, 2)
    assert.ok(point.every(Number.isSafeInteger))
    assert.ok(point[0] >= 0 && point[0] < graph.tileGrid.width * 1000)
    assert.ok(point[1] >= 0 && point[1] < graph.tileGrid.height * 1000)
  }
  for (const station of graph.line17.stations) {
    assert.ok(Number.isSafeInteger(station.xMillis))
    assert.ok(Number.isSafeInteger(station.yMillis))
    assert.ok(
      graph.line17.path.some(
        ([x, y]) => x === station.xMillis && y === station.yMillis,
      ),
    )
    const points = new Set()
    for (const exit of station.exits) {
      exitCount += 1
      assert.ok(exit.label.length > 0)
      assert.ok(exit.destination.length > 0)
      assert.ok(Number.isSafeInteger(exit.xMillis))
      assert.ok(Number.isSafeInteger(exit.yMillis))
      assert.equal(exit.minZoomMillis, 720)
      const x = Math.floor(exit.xMillis / 1000)
      const y = Math.floor(exit.yMillis / 1000)
      assert.ok(semanticRoadCodes.has(graph.rows[y][x]))
      assert.notEqual(graph.presentationRows[y][x], '.')
      points.add(`${exit.xMillis}:${exit.yMillis}`)
    }
    assert.equal(points.size, station.exits.length)
  }
  assert.ok(semanticRoadCodes.has(graph.rows[52][125]))
  assert.equal(graph.presentationRows[52][125], 'P')
  assert.equal(graph.rows[87][116], 'M')
  assert.equal(graph.presentationRows[87][116], 'S')
  const southStationPathIndex = graph.line17.path.findIndex(
    ([x, y]) => x === 116000 && y === 87000,
  )
  assert.ok(southStationPathIndex >= 0)
  const postStationTail = graph.line17.path.slice(southStationPathIndex)
  for (let index = 1; index < postStationTail.length; index += 1) {
    assert.ok(postStationTail[index][0] < postStationTail[index - 1][0])
    assert.ok(postStationTail[index][1] > postStationTail[index - 1][1])
  }
  assert.equal(exitCount, 7)
  assert.equal(graph.presentationMetrics.line17PathPoints, 15)
  assert.equal(graph.presentationMetrics.line17Stations, 2)
  assert.equal(graph.presentationMetrics.line17Exits, 7)
})
