import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import path from 'node:path'
import test from 'node:test'
import {
  AUTHORING_ONLY_ASSET_SEGMENTS,
  resolveRuntimeAssetPath,
  runtimeAssetPaths,
} from './runtime_asset_manifest.js'
import { indexWenyuReferenceBuildingComponents } from './runtime_snapshots.js'

const assetRoot = path.resolve(import.meta.dirname, '../assets')

test('runtime asset manifest covers modules, residents, and operating art', async () => {
  const paths = await runtimeAssetPaths(assetRoot)
  const pathSet = new Set(paths)
  assert.ok(pathSet.has('moonsuite-i18n.js'))
  const moduleConfig = JSON.parse(
    await readFile(
      path.join(assetRoot, 'tilemap/modules/wenyu-town-modules.json'),
      'utf8',
    ),
  )

  assert.ok(pathSet.has('tilemap/wenyu_reference_tilemap_iso.png'))
  assert.ok(pathSet.has('tilemap/wenyu_reference_buildings.json'))
  assert.ok(pathSet.has('moontown.svg'))
  assert.ok(pathSet.has('tilemap/districts/town_shell.png'))
  assert.ok(pathSet.has('tilemap/actors/roster/resident_0.png'))
  for (let index = 0; index < 64; index += 1) {
    assert.ok(
      pathSet.has(
        `tilemap/actors/roster/resident_${index}_walk_strip.png`,
      ),
    )
  }
  for (const module of moduleConfig.modules) {
    assert.ok(pathSet.has(module.asset_base), module.asset_base)
  }
})

test('Wenyu component index preserves every typed building cell', async () => {
  const snapshot = JSON.parse(
    await readFile(
      path.join(assetRoot, 'tilemap/wenyu_reference_buildings.json'),
      'utf8',
    ),
  )
  globalThis.__wenyuReferenceBuildings = snapshot
  indexWenyuReferenceBuildingComponents()

  const labelCells = snapshot.labelRows.reduce(
    (total, row) =>
      total + [...row].filter(code => code !== '.').length,
    0,
  )
  const indexedCells = globalThis.__wenyuReferenceBuildingComponentRows.reduce(
    (total, row) => total + row.filter(Boolean).length,
    0,
  )
  assert.equal(labelCells, 3327)
  assert.equal(indexedCells, labelCells)

  delete globalThis.__wenyuReferenceBuildings
  delete globalThis.__wenyuReferenceBuildingComponentRows
})

test('runtime asset resolution rejects traversal paths', () => {
  assert.throws(() => resolveRuntimeAssetPath(assetRoot, '../outside.png'))
  assert.throws(() => resolveRuntimeAssetPath(assetRoot, '..\\outside.png'))
  assert.throws(() => resolveRuntimeAssetPath(assetRoot, '/outside.png'))
})

test('runtime asset manifest excludes authoring-only inputs', async () => {
  const paths = await runtimeAssetPaths(assetRoot)
  for (const relativePath of paths) {
    const searchable = `/${relativePath}`
    for (const segment of AUTHORING_ONLY_ASSET_SEGMENTS) {
      assert.equal(searchable.includes(segment), false, relativePath)
    }
    assert.doesNotMatch(relativePath, /_walk_[2-4]\.png$/)
  }
})
