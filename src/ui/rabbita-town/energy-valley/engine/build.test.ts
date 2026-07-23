import assert from 'node:assert/strict'
import test from 'node:test'
import {
  checkBuilding,
  checkRoad,
  demolishAt,
  placeBuilding,
} from './build'
import { createSim, updateSim } from './sim'
import { archetype, createWorld } from './world'

function findValidParcel() {
  const sim = createSim(createWorld())
  for (let y = 0; y < sim.world.tiles.length; y++) {
    for (let x = 0; x < sim.world.tiles[0].length; x++) {
      if (checkBuilding(sim, 'c-hall', x, y).valid) return { sim, x, y }
    }
  }
  throw new Error('expected at least one valid building parcel')
}

test('building placement charges budget, occupies its footprint, completes, and refunds half', () => {
  const { sim, x, y } = findValidParcel()
  const before = sim.metrics.budget
  const building = placeBuilding(sim, 'c-hall', x, y)
  assert.ok(building)
  assert.equal(sim.metrics.budget, before - archetype('c-hall').cost)

  for (let yy = y; yy < y + 2; yy++) {
    for (let xx = x; xx < x + 2; xx++) {
      assert.equal(sim.world.tiles[yy][xx].buildingId, building.id)
    }
  }

  updateSim(sim, 6.1)
  assert.equal(building.progress, 1)
  const beforeDemolish = sim.metrics.budget
  assert.equal(demolishAt(sim, x, y), true)
  assert.equal(sim.metrics.budget, beforeDemolish + 200)
})

test('building placement requires cleared grass or plaza beside the road network', () => {
  const { sim, x, y } = findValidParcel()
  sim.world.tiles[y][x].terrain = 'forest'
  assert.deepEqual(checkBuilding(sim, 'c-hall', x, y), {
    valid: false,
    reason: '需先清理林地',
    cost: 400,
  })
})

test('roads preserve civic plazas and price river crossings as bridges', () => {
  const sim = createSim(createWorld())
  const plaza = sim.world.tiles
    .flatMap((row, y) => row.map((tile, x) => ({ tile, x, y })))
    .find(cell => cell.tile.terrain === 'plaza' && !cell.tile.buildingId)
  assert.ok(plaza)
  assert.equal(checkRoad(sim, plaza.x, plaza.y).valid, false)

  const water = sim.world.tiles
    .flatMap((row, y) => row.map((tile, x) => ({ tile, x, y })))
    .find(cell => cell.tile.terrain === 'water' && !cell.tile.buildingId)
  assert.ok(water)
  assert.deepEqual(checkRoad(sim, water.x, water.y), { valid: true, cost: 120 })
})
