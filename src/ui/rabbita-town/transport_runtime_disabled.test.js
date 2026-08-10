import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'

async function source(path) {
  return await readFile(new URL(path, import.meta.url), 'utf8')
}

test('unreviewed geographic transport cannot activate during bootstrap', async () => {
  const bootstrap = await source('./bootstrap.js')

  assert.doesNotMatch(bootstrap, /loadEnergyValleyTransport/)
  assert.doesNotMatch(bootstrap, /energy-valley-transport-v1\.json/)
})

test('migration readiness remains owned by the three Wenyu references', async () => {
  const preferences = await source(
    './main/browser_energy_valley_preferences.mbt',
  )
  const start = preferences.indexOf(
    'fn browser_energy_valley_authoritative_reference_ready()',
  )
  const end = preferences.indexOf('\n///|', start + 4)
  const readiness = preferences.slice(start, end)

  assert.match(readiness, /reference_tile_snapshot_ready\(\)/)
  assert.match(readiness, /reference_road_graph_snapshot_ready\(\)/)
  assert.match(readiness, /reference_building_snapshot_ready\(\)/)
  assert.doesNotMatch(readiness, /transport/i)
})

test('metro entrance installations use navigable town portals', async () => {
  const installations = await source(
    './main/ecosystem_installation_compilation.mbt',
  )
  const start = installations.indexOf('if place.kind is')
  const end = installations.indexOf('\n  for road in snapshot.roads', start)
  const metroEntrances = installations.slice(start, end)

  assert.match(
    metroEntrances,
    /installation_point\(portal\.position\)/,
  )
  assert.doesNotMatch(
    metroEntrances,
    /metro_line17_station_exit_position/,
  )
})
