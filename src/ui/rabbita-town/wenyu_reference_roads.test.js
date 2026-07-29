import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { test } from 'node:test'

const graph = JSON.parse(
  await readFile(
    new URL('../assets/tilemap/wenyu_reference_roads.json', import.meta.url),
    'utf8',
  ),
)

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
  assert.equal(visited.size, roadCount)
  assert.equal(graph.metrics.connectedComponents4, 1)
  assert.ok(graph.metrics.enclosedLandBlocks >= 50)
  assert.ok(graph.metrics.degreeTwoTurnPermille <= 200)
  assert.ok(
    graph.metrics.degreeTwoStraightTiles >
      graph.metrics.degreeTwoTurnTiles * 4,
  )
  assert.ok(graph.metrics.rawSemanticConnectedComponents4 > 900)
})
