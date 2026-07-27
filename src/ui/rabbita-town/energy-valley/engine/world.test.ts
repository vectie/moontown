import assert from 'node:assert/strict'
import test from 'node:test'
import { nearestRoad } from './pathfind'
import {
  DEFAULT_VALLEY_SEED,
  archetype,
  createWorld,
  valleySeedLabel,
} from './world'

function fingerprint(seed: number): string {
  const world = createWorld(seed)
  const terrain = world.tiles.map(row =>
    row.map(tile => `${tile.terrain[0]}${tile.structure?.[0] ?? '-'}`).join(''),
  ).join('|')
  const buildings = world.buildings
    .map(building => `${building.moduleKey}:${building.tx},${building.ty}`)
    .join('|')
  return `${terrain}#${buildings}`
}

test('the same seed recreates the same valley while another seed changes it', () => {
  assert.equal(fingerprint(DEFAULT_VALLEY_SEED), fingerprint(DEFAULT_VALLEY_SEED))
  assert.notEqual(fingerprint(DEFAULT_VALLEY_SEED), fingerprint(DEFAULT_VALLEY_SEED + 1))
  assert.equal(valleySeedLabel(DEFAULT_VALLEY_SEED).length, 6)
})

test('generated variants preserve the Energy Valley spatial grammar', () => {
  const seeds = [
    1,
    42,
    DEFAULT_VALLEY_SEED,
    987654321,
    ...Array.from({ length: 64 }, (_, index) =>
      Math.imul(index + 1, 2654435761) >>> 0,
    ),
  ]
  for (const seed of seeds) {
    const world = createWorld(seed)
    const counts = new Map<string, number>()
    for (const tile of world.tiles.flat()) {
      counts.set(tile.terrain, (counts.get(tile.terrain) ?? 0) + 1)
      assert.equal(tile.generatedTerrain, tile.terrain)
    }

    assert.ok((counts.get('water') ?? 0) >= 250, `seed ${seed} lacks the river/lake system`)
    assert.ok((counts.get('wetland') ?? 0) >= 100, `seed ${seed} lacks wetland edges`)
    assert.ok((counts.get('field') ?? 0) >= 35, `seed ${seed} lacks the farm belt`)
    assert.ok((counts.get('forest') ?? 0) >= 500, `seed ${seed} lacks forest buffers`)
    assert.ok((counts.get('urban') ?? 0) >= 100, `seed ${seed} lacks dense urban fabric`)
    assert.equal(world.buildings.length, 13)
    assert.equal(new Set(world.buildings.map(building => building.moduleKey)).size, 13)
    for (const bridgeRow of world.landmarks.bridgeRows) {
      assert.ok(
        world.tiles[bridgeRow].some(tile => tile.terrain === 'bridge'),
        `seed ${seed} bridge corridor ${bridgeRow} misses water`,
      )
    }
    for (const building of world.buildings) {
      const arch = archetype(building.archetype)
      assert.ok(
        nearestRoad(world, building.tx, building.ty, arch.w, arch.h),
        `seed ${seed} leaves ${building.moduleKey} outside the road network`,
      )
    }
  }
})
