import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'
import {
  acceptEnergyValleyOsmBlockGraph,
  validateEnergyValleyOsmBlockGraph,
} from './runtime_snapshots.js'

const canonical = JSON.parse(
  await readFile(
    new URL(
      '../assets/tilemap/energy-valley-osm-block-graph-v1.json',
      import.meta.url,
    ),
    'utf8',
  ),
)

const fixture = () => structuredClone(canonical)

test('calibrated OSM block graph carries 338 connected intersections', () => {
  assert.equal(validateEnergyValleyOsmBlockGraph(fixture()), true)
  assert.deepEqual(canonical.metrics, {
    intersections: 338,
    routingNodes: 157,
    totalNodes: 495,
    edges: 775,
    components: 11,
    cycleRank: 291,
    bridges: 22,
    bridgeSpanVertices: 59,
    kinds: { t: 181, complex: 100, cross: 57 },
    confidence: { medium: 121, high: 153, review: 64 },
  })
  assert.equal(canonical.points.length, 338)
  assert.equal(new Set(canonical.points.map(point => point.id)).size, 338)
})

test('OSM block graph fails closed on topology and calibration drift', () => {
  const missingEdge = fixture()
  missingEdge.graph.edges.pop()
  assert.equal(validateEnergyValleyOsmBlockGraph(missingEdge), false)

  const endpointDrift = fixture()
  endpointDrift.graph.edges[0].pathMillis[0][0] += 1
  assert.equal(validateEnergyValleyOsmBlockGraph(endpointDrift), false)

  const scaleDrift = fixture()
  scaleDrift.calibration.scaleMetresPerTile += 1
  assert.equal(validateEnergyValleyOsmBlockGraph(scaleDrift), false)
})

test('OSM block graph acceptance publishes only a fully validated graph', () => {
  globalThis.__moontownEnergyValleyOsmBlockGraph = fixture()
  assert.equal(acceptEnergyValleyOsmBlockGraph(), true)
  assert.equal(globalThis.__moontownEnergyValleyOsmBlockGraphValidated, true)

  globalThis.__moontownEnergyValleyOsmBlockGraph = {
    ...fixture(),
    schema: 'wrong-schema',
  }
  assert.equal(acceptEnergyValleyOsmBlockGraph(), false)
  assert.equal(globalThis.__moontownEnergyValleyOsmBlockGraphValidated, false)
  assert.equal(globalThis.__moontownEnergyValleyOsmBlockGraph, null)
  delete globalThis.__moontownEnergyValleyOsmBlockGraph
  delete globalThis.__moontownEnergyValleyOsmBlockGraphValidated
})
