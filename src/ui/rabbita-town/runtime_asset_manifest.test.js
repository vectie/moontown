import assert from 'node:assert/strict'
import { readFile, stat } from 'node:fs/promises'
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
  assert.ok(pathSet.has('tilemap/wenyu_reference_intersections.json'))
  assert.ok(pathSet.has('tilemap/energy-valley-osm-block-graph-v1.json'))
  assert.equal(pathSet.has('tilemap/energy-valley-transport-v1.json'), false)
  assert.equal(
    pathSet.has('tilemap/georeference/wenyu-town-georef-v1.json'),
    false,
  )
  const springCivicModuleIds = [
    'ai-garden',
    'contest-express',
    'physical-bridge',
    'policy-hall',
    'research-ai-agents',
    'research-ai-hardware',
    'research-embodied-robotics',
    'research-llm-training',
    'research-opc',
    'resident-twins',
    'social-square',
    'story-radar',
    'talent-avenue',
    'town-shell',
    'valley-market',
    'vitality-tower',
  ]
  for (const moduleId of springCivicModuleIds) {
    assert.ok(
      pathSet.has(
        `tilemap/buildings/moontown-spring-civic-v1/${moduleId}.png`,
      ),
      moduleId,
    )
  }
  assert.equal(springCivicModuleIds.length, 16)
  assert.equal(
    pathSet.has('tilemap/buildings/moontown-spring-civic-v1/manifest.json'),
    false,
  )
  assert.equal(
    [...pathSet].some(assetPath =>
      /moontown-spring-civic-v1\/(source-atlas|atlas-alpha)/.test(assetPath),
    ),
    false,
  )
  for (const style of [
    'block',
    'campus',
    'civic',
    'courtyard',
    'industrial',
    'lowrise',
    'row',
    'tower',
  ]) {
    for (let variant = 0; variant < 10; variant += 1) {
      assert.ok(
        pathSet.has(
          `tilemap/buildings/moontown-spring-ambient-v1/${style}-${variant}.webp`,
        ),
        `${style}-${variant}`,
      )
    }
  }
  assert.equal(
    pathSet.has('tilemap/buildings/moontown-spring-ambient-v1/manifest.json'),
    false,
  )
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

test('unreviewed geographic calibration remains authoring-only', async () => {
  const paths = await runtimeAssetPaths(assetRoot)
  assert.equal(paths.includes('tilemap/energy-valley-transport-v1.json'), false)
  assert.equal(
    paths.some(relativePath => relativePath.includes('/georeference/')),
    false,
  )
})

test('spring civic runtime pack has sixteen bounded transparent sprites', async () => {
  const paths = (await runtimeAssetPaths(assetRoot)).filter(assetPath =>
    assetPath.startsWith('tilemap/buildings/moontown-spring-civic-v1/'),
  )
  assert.equal(paths.length, 16)
  let totalBytes = 0
  for (const relativePath of paths) {
    const filePath = resolveRuntimeAssetPath(assetRoot, relativePath)
    const png = await readFile(filePath)
    totalBytes += (await stat(filePath)).size
    assert.deepEqual(
      [...png.subarray(0, 8)],
      [137, 80, 78, 71, 13, 10, 26, 10],
    )
    assert.equal(png.readUInt32BE(16), 1024, relativePath)
    assert.equal(png.readUInt32BE(20), 1024, relativePath)
    assert.equal(png[24], 8, relativePath)
    assert.equal(png[25], 6, relativePath)
  }
  assert.ok(
    totalBytes <= 12 * 1024 * 1024,
    `spring civic pack is ${totalBytes} bytes`,
  )
})

test('spring ambient runtime pack has eighty compact alpha WebPs', async () => {
  const paths = (await runtimeAssetPaths(assetRoot)).filter(assetPath =>
    assetPath.startsWith('tilemap/buildings/moontown-spring-ambient-v1/'),
  )
  assert.equal(paths.length, 80)
  let totalBytes = 0
  for (const relativePath of paths) {
    const filePath = resolveRuntimeAssetPath(assetRoot, relativePath)
    const webp = await readFile(filePath)
    totalBytes += (await stat(filePath)).size
    assert.equal(webp.subarray(0, 4).toString('ascii'), 'RIFF', relativePath)
    assert.equal(webp.subarray(8, 12).toString('ascii'), 'WEBP', relativePath)
    assert.equal(webp.subarray(12, 16).toString('ascii'), 'VP8X', relativePath)
    assert.notEqual(webp[20] & 0x10, 0, `${relativePath} has alpha`)
    const width = 1 + webp.readUIntLE(24, 3)
    const height = 1 + webp.readUIntLE(27, 3)
    assert.equal(width, 512, relativePath)
    assert.equal(height, 512, relativePath)
  }
  assert.ok(
    totalBytes <= 2.25 * 1024 * 1024,
    `spring ambient pack is ${totalBytes} bytes`,
  )
})

test('Wenyu component index preserves every reviewed roof anchor', async () => {
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
  assert.equal(
    snapshot.schema,
    'moontown.wenyu_reference_building_anchors.v1',
  )
  assert.equal(snapshot.evidenceMode, 'roof-provenance-anchor')
  assert.equal(labelCells, snapshot.anchors.length)
  assert.ok(labelCells >= 30 && labelCells <= 45)
  assert.equal(indexedCells, labelCells)

  const indexedComponents = new Map()
  for (let y = 0; y < snapshot.tileGrid.height; y += 1) {
    for (let x = 0; x < snapshot.tileGrid.width; x += 1) {
      const indexed = globalThis.__wenyuReferenceBuildingComponentRows[y][x]
      if (!indexed) continue
      const cells = indexedComponents.get(indexed.index) || []
      cells.push([x, y])
      indexedComponents.set(indexed.index, cells)
    }
  }
  assert.equal(indexedComponents.size, snapshot.components.length)
  for (const [index, cells] of indexedComponents) {
    const component = snapshot.components[index]
    assert.equal(cells.length, component.areaCells)
    assert.equal(Math.min(...cells.map(([x]) => x)), component.bbox.minX)
    assert.equal(Math.min(...cells.map(([, y]) => y)), component.bbox.minY)
    for (const [x, y] of cells) {
      const indexed = globalThis.__wenyuReferenceBuildingComponentRows[y][x]
      assert.equal(indexed.anchorX, component.bbox.minX)
      assert.equal(indexed.anchorY, component.bbox.minY)
    }
  }

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
