import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'
import {
  acceptWenyuReferenceIntersections,
  validateWenyuReferenceIntersectionPoints,
  validateWenyuReferenceIntersections,
} from './runtime_snapshots.js'

const canonicalIntersectionAsset = JSON.parse(
  await readFile(
    new URL(
      '../assets/tilemap/wenyu_reference_intersections.json',
      import.meta.url,
    ),
    'utf8',
  ),
)

function intersectionFixture() {
  return structuredClone(canonicalIntersectionAsset)
}

test('strict v2 fixture is accepted only as authoring preview evidence', () => {
  const fixture = intersectionFixture()
  assert.equal(fixture.schema, 'moontown.wenyu_reference_intersections.v2')
  assert.equal('previewBuildings' in fixture, false)
  assert.equal(
    fixture.previewGraph.method,
    'exact-seed 8-neighbor source-skeleton geodesics, unique-segment union, degree-not-two routing-node compression',
  )
  assert.deepEqual(fixture.previewGraph.metrics, {
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
  assert.equal(validateWenyuReferenceIntersectionPoints(intersectionFixture()), true)
  assert.equal(validateWenyuReferenceIntersections(intersectionFixture()), true)
  assert.equal(
    validateWenyuReferenceIntersections({
      ...intersectionFixture(),
      authoringCalibration: {
        ...intersectionFixture().authoringCalibration,
        runtimeEligible: true,
      },
    }),
    false,
  )
})

test('intersection validator rejects duplicate ids and coordinates', () => {
  const duplicateId = intersectionFixture()
  duplicateId.points[1].id = duplicateId.points[0].id
  assert.equal(validateWenyuReferenceIntersections(duplicateId), false)

  const duplicateCoordinate = intersectionFixture()
  duplicateCoordinate.points[1].xMillis = duplicateCoordinate.points[0].xMillis
  duplicateCoordinate.points[1].yMillis = duplicateCoordinate.points[0].yMillis
  assert.equal(validateWenyuReferenceIntersections(duplicateCoordinate), false)
})

test('intersection validator rejects kind, arm, and metric drift', () => {
  const wrongArms = intersectionFixture()
  wrongArms.points[0].externalArms = 4
  assert.equal(validateWenyuReferenceIntersections(wrongArms), false)

  const wrongMetrics = intersectionFixture()
  wrongMetrics.metrics.semanticConfidence.high = 32
  assert.equal(validateWenyuReferenceIntersections(wrongMetrics), false)
})

test('intersection confidence is derived from the locked distance thresholds', () => {
  const wrongConfidence = intersectionFixture()
  wrongConfidence.points[0].semanticEvidence.confidence = 'review'
  assert.equal(validateWenyuReferenceIntersections(wrongConfidence), false)

  const appliedCalibration = intersectionFixture()
  appliedCalibration.authoringCalibration.appliedToPoints = true
  assert.equal(validateWenyuReferenceIntersections(appliedCalibration), false)
})

test('acceptance clears invalid points instead of exposing them', () => {
  globalThis.__wenyuReferenceIntersections = {
    ...intersectionFixture(),
    schema: 'wrong-schema',
  }
  assert.equal(acceptWenyuReferenceIntersections(), false)
  assert.equal(globalThis.__wenyuReferenceIntersectionsValidated, false)
  assert.equal(
    globalThis.__wenyuReferenceIntersectionPreviewGraphValidated,
    false,
  )
  assert.equal(globalThis.__wenyuReferenceIntersections, null)
  delete globalThis.__wenyuReferenceIntersections
  delete globalThis.__wenyuReferenceIntersectionsValidated
  delete globalThis.__wenyuReferenceIntersectionPreviewGraphValidated
})

test('rejected v2 graph keeps valid points available for old-map fallback', () => {
  const invalidGraph = intersectionFixture()
  invalidGraph.previewGraph.metrics.waterConflicts = 1
  globalThis.__wenyuReferenceIntersections = invalidGraph

  assert.equal(acceptWenyuReferenceIntersections(), false)
  assert.equal(globalThis.__wenyuReferenceIntersectionsValidated, true)
  assert.equal(
    globalThis.__wenyuReferenceIntersectionPreviewGraphValidated,
    false,
  )
  assert.equal(globalThis.__wenyuReferenceIntersections, invalidGraph)

  delete globalThis.__wenyuReferenceIntersections
  delete globalThis.__wenyuReferenceIntersectionsValidated
  delete globalThis.__wenyuReferenceIntersectionPreviewGraphValidated
})

test('preview graph rejects topology, endpoint, bridge, and metric drift', () => {
  const unknownEndpoint = intersectionFixture()
  unknownEndpoint.previewGraph.edges[0].from = 'junction-999'
  assert.equal(validateWenyuReferenceIntersections(unknownEndpoint), false)

  const endpointDrift = intersectionFixture()
  endpointDrift.previewGraph.edges[0].pathMillis[0][0] += 1
  assert.equal(validateWenyuReferenceIntersections(endpointDrift), false)

  const duplicateEdge = intersectionFixture()
  duplicateEdge.previewGraph.edges[1].id = duplicateEdge.previewGraph.edges[0].id
  assert.equal(validateWenyuReferenceIntersections(duplicateEdge), false)

  const invalidBridge = intersectionFixture()
  invalidBridge.previewGraph.edges[0].bridgeSpans = [{
    fromIndex: 0,
    toIndex: invalidBridge.previewGraph.edges[0].pathMillis.length,
  }]
  assert.equal(validateWenyuReferenceIntersections(invalidBridge), false)

  const overlappingBridge = intersectionFixture()
  const bridgeEdge = overlappingBridge.previewGraph.edges.find(
    edge => edge.pathMillis.length >= 4,
  )
  assert.ok(bridgeEdge)
  bridgeEdge.bridgeSpans = [
    { fromIndex: 0, toIndex: 2 },
    { fromIndex: 2, toIndex: 3 },
  ]
  assert.equal(validateWenyuReferenceIntersections(overlappingBridge), false)

  const metricDrift = intersectionFixture()
  metricDrift.previewGraph.metrics.cycleRank += 1
  assert.equal(validateWenyuReferenceIntersections(metricDrift), false)

  const simplifiedChord = intersectionFixture()
  const chord = simplifiedChord.previewGraph.edges.find(
    edge => edge.pathMillis.length > 2,
  )
  assert.ok(chord)
  chord.pathMillis[1][0] = chord.pathMillis[0][0] + 155
  assert.equal(validateWenyuReferenceIntersections(simplifiedChord), false)

  const inventedMicrostep = intersectionFixture()
  const microstep = inventedMicrostep.previewGraph.edges.find(
    edge => edge.pathMillis.length > 2,
  )
  assert.ok(microstep)
  microstep.pathMillis[1][0] = microstep.pathMillis[0][0] + 1
  microstep.pathMillis[1][1] = microstep.pathMillis[0][1]
  assert.equal(validateWenyuReferenceIntersections(inventedMicrostep), false)

  const sourceLengthDrift = intersectionFixture()
  sourceLengthDrift.previewGraph.edges[0].sourceLengthPixels += 1
  assert.equal(validateWenyuReferenceIntersections(sourceLengthDrift), false)

  const overstatedConfidence = intersectionFixture()
  const confidenceByPoint = new Map(overstatedConfidence.points.map(point => [
    point.id,
    point.semanticEvidence.confidence,
  ]))
  const lowerConfidenceEdge = overstatedConfidence.previewGraph.edges.find(
    edge => ['medium', 'review'].includes(confidenceByPoint.get(edge.from)) ||
      ['medium', 'review'].includes(confidenceByPoint.get(edge.to)),
  )
  assert.ok(lowerConfidenceEdge)
  lowerConfidenceEdge.confidence = 'high'
  assert.equal(validateWenyuReferenceIntersections(overstatedConfidence), false)
})

test('routing nodes are strict, unique, in bounds, and used by the graph', () => {
  const fixture = intersectionFixture()
  if (!Array.isArray(fixture.previewGraph.routingNodes) ||
      fixture.previewGraph.routingNodes.length === 0) {
    assert.ok(true)
    return
  }

  const wrongReason = intersectionFixture()
  wrongReason.previewGraph.routingNodes[0].reason = 'runtime-shortcut'
  assert.equal(validateWenyuReferenceIntersections(wrongReason), false)

  const duplicateCoordinate = intersectionFixture()
  duplicateCoordinate.previewGraph.routingNodes[0].xMillis =
    duplicateCoordinate.points[0].xMillis
  duplicateCoordinate.previewGraph.routingNodes[0].yMillis =
    duplicateCoordinate.points[0].yMillis
  assert.equal(validateWenyuReferenceIntersections(duplicateCoordinate), false)
})

test('all source-skeleton branch intersections extend the visible set', () => {
  const fixture = intersectionFixture()
  const degreeById = new Map(
    fixture.previewGraph.routingNodes.map(node => [node.id, 0]),
  )
  for (const edge of fixture.previewGraph.edges) {
    if (degreeById.has(edge.from)) {
      degreeById.set(edge.from, degreeById.get(edge.from) + 1)
    }
    if (degreeById.has(edge.to)) {
      degreeById.set(edge.to, degreeById.get(edge.to) + 1)
    }
  }
  assert.equal(fixture.points.length + degreeById.size, 183)
  assert.deepEqual(
    [...degreeById.values()].sort((left, right) => left - right),
    [...Array(36).fill(3), ...Array(2).fill(4)],
  )
  assert.equal(
    new Set([
      ...fixture.points.map(point => `${point.xMillis},${point.yMillis}`),
      ...fixture.previewGraph.routingNodes.map(
        point => `${point.xMillis},${point.yMillis}`,
      ),
    ]).size,
    183,
  )
})

test('thirty curated lots keep a one-tile graph frontage and apron', () => {
  const placements = [
    [201, 5], [10, 119], [130, 130], [93, 22], [213, 98],
    [11, 50], [121, 74], [67, 119], [164, 43], [70, 68],
    [45, 19], [249, 70], [127, 37], [38, 84], [188, 86],
    [102, 133], [6, 77], [57, 41], [93, 63], [37, 61],
    [91, 43], [136, 54], [218, 16], [111, 13], [9, 97],
    [82, 133], [127, 114], [24, 70], [201, 91], [45, 73],
  ]
  const graphVertices = canonicalIntersectionAsset.previewGraph.edges.flatMap(
    edge => edge.pathMillis,
  )
  const graphCells = new Set(
    graphVertices.map(([x, y]) => `${Math.floor(x / 1000)},${Math.floor(y / 1000)}`),
  )
  assert.equal(placements.length, 30)
  for (const [x, y] of placements) {
    let frontage = false
    for (let yy = y - 1; yy <= y + 5; yy += 1) {
      for (let xx = x - 1; xx <= x + 5; xx += 1) {
        const onApron = xx === x - 1 || xx === x + 5 || yy === y - 1 || yy === y + 5
        const onGraph = graphCells.has(`${xx},${yy}`)
        if (!onApron) assert.equal(onGraph, false, `graph crosses ${x},${y}`)
        if (onApron && onGraph) frontage = true
      }
    }
    assert.equal(frontage, true, `lot ${x},${y} is not road-fronted`)
  }
  for (let leftIndex = 0; leftIndex < placements.length; leftIndex += 1) {
    for (let rightIndex = leftIndex + 1;
      rightIndex < placements.length; rightIndex += 1) {
      const [leftX, leftY] = placements[leftIndex]
      const [rightX, rightY] = placements[rightIndex]
      assert.ok(
        leftX + 6 < rightX ||
        rightX + 6 < leftX ||
        leftY + 6 < rightY ||
        rightY + 6 < leftY,
        `lots ${leftX},${leftY} and ${rightX},${rightY} overlap`,
      )
    }
  }
})

test('the single map view replaces stale presentation after graph validation', async () => {
  const [page, canvas, surface, bridge, preview, installations, hudCss] = await Promise.all([
    readFile(new URL('./main/energy_valley_page.mbt', import.meta.url), 'utf8'),
    readFile(new URL('./main/energy_valley_canvas.mbt', import.meta.url), 'utf8'),
    readFile(
      new URL(
        './main/energy_valley_intersection_reference.mbt',
        import.meta.url,
      ),
      'utf8',
    ),
    readFile(
      new URL(
        './main/wenyu_reference_intersection_bridge.mbt',
        import.meta.url,
      ),
      'utf8',
    ),
    readFile(
      new URL(
        './main/energy_valley_intersection_road_preview.mbt',
        import.meta.url,
      ),
      'utf8',
    ),
    readFile(
      new URL('./main/town_snapshot_installation_canvas.mbt', import.meta.url),
      'utf8',
    ),
    readFile(
      new URL('./styles/energy-valley-life-hud.css', import.meta.url),
      'utf8',
    ),
  ])
  const compile = page.indexOf('ecosystem_contract_town_snapshot(')
  const previewBranch = canvas.indexOf(
    'return draw_intersection_road_preview_frame(',
  )
  const normalLayers = canvas.indexOf(
    'golden_draw_day_night(context, width, height, hour)',
  )
  const overlay = canvas.indexOf(
    'intersection_reference_draw_points(context, width, height)',
  )
  const acceptedFrame = canvas.indexOf(
    'golden_valley_accept_canvas_frame_with_runtime_eligibility(',
  )

  assert.ok(compile >= 0)
  assert.doesNotMatch(page, /return render_energy_valley_intersection_reference_page/)
  assert.match(page, /render_golden_valley_canvas\(dispatch, snapshot, town_canvas_view\)/)
  assert.match(page, /render_energy_valley_tool_dock\(dispatch, model\)/)
  assert.match(page, /follow_enabled: model\.player_follow && !intersection_preview/)
  assert.match(
    page,
    /if intersection_preview \{\s+@html\.nothing\s+\} else \{\s+render_metro_legend/,
  )
  assert.match(
    page,
    /if intersection_preview \{\s+@html\.nothing\s+\} else \{\s+render_player_walk_buttons/,
  )
  assert.match(page, /render_intersection_reference_legend\(\)/)
  assert.match(
    page,
    /if model\.energy_intro_open \|\| intersection_preview \{\s+@html\.nothing\s+\} else \{\s+render_policy_hall_map_entry/,
  )

  assert.ok(previewBranch >= 0 && previewBranch < normalLayers)
  assert.ok(normalLayers >= 0 && normalLayers < overlay)
  assert.ok(overlay < acceptedFrame)
  assert.match(canvas, /energy_valley_intersection_reference_requested\(\)/)
  assert.match(canvas, /cameraOnly/)
  assert.match(canvas, /lifecycle\.cameraOnly \|\| moved/)
  assert.match(canvas, /const updateCoordinateReadout = event =>/)
  assert.match(
    canvas,
    /const worldX = \(projectedDifference \/ 32 \+ projectedSum \/ 16\) \/ 2/,
  )
  assert.match(
    canvas,
    /const worldY = \(projectedSum \/ 16 - projectedDifference \/ 32\) \/ 2/,
  )
  assert.match(canvas, /energy-valley-coordinate-readout/)
  assert.match(
    canvas,
    /if !view\.intersection_preview \{\s+install_player_walk_keys\(\)/,
  )
  assert.match(canvas, /let canvas_attrs = if view\.intersection_preview/)
  assert.match(canvas, /EnergyCanvasClick/)
  assert.match(canvas, /delete globalThis\.__moontownIntersectionStaticCanvas/)
  assert.match(canvas, /delete globalThis\.__moontownIntersectionWalkerEdges/)

  assert.match(surface, /reference_intersection_preview_graph_ready\(\)/)
  assert.match(surface, /reference_intersection_source_branch_count\(\)/)
  assert.match(bridge, /totalGraphNodes \?\? 0/)
  assert.match(bridge, /return verified \+ \(value\?\.previewGraph\?\.routingNodes/)
  assert.match(bridge, /degree === 3 \? "t" : degree === 4 \? "cross"/)
  assert.match(surface, /golden_screen_x\(x, y, viewport_width\)/)
  assert.match(surface, /golden_screen_y\(x, y, viewport_height\)/)
  assert.doesNotMatch(surface, /reference_tile_kind_at/)
  assert.doesNotMatch(surface, /draw_intersection_reference_canvas/)
  assert.doesNotMatch(surface, /render_intersection_reference_canvas/)
  assert.doesNotMatch(surface, /render_energy_valley_intersection_reference_page/)
  assert.doesNotMatch(surface, /golden_valley_clear_canvas_frame/)
  assert.doesNotMatch(surface, /\.on_click\(/)
  assert.doesNotMatch(surface, /class="metro-legend/)

  assert.match(preview, /reference_intersection_preview_graph_ready\(\)/)
  assert.match(preview, /golden_draw_intersection_road_preview_graph/)
  assert.match(preview, /intersection_road_view_draw_static_cache/)
  assert.match(preview, /intersection_road_view_commit_static_cache/)
  assert.match(preview, /intersection_road_preview_water_cache/)
  assert.match(preview, /Water retains its original animation/)
  assert.match(preview, /intersection_road_preview_installation_cache/)
  assert.match(preview, /intersection_road_preview_depth_cache/)
  assert.doesNotMatch(preview, /benchmark-skip/)
  assert.match(installations, /town_snapshot_installation_on_screen/)
  assert.match(installations, /let margin = 240\.0/)
  assert.match(preview, /edge\.bridgeSpans/)
  assert.match(preview, /golden_draw_tile\(/)
  assert.match(preview, /presentation_ready,\s+false,\s+terrain_override/)
  assert.doesNotMatch(preview, /town_snapshot_canvas_transport_base_terrain/)
  assert.match(canvas, /fn golden_canonical_old_map_terrain/)
  assert.match(canvas, /fn golden_draw_canonical_old_map_terrain/)
  assert.match(canvas, /else if terrain == "road"/)
  assert.match(canvas, /presentation_ready,\s+true,\s+None,\s+x,\s+y/)
  assert.match(preview, /intersection_road_view_stale_ground_cells/)
  assert.match(preview, /intersection_road_view_stale_ground_terrain/)
  assert.match(preview, /terrain_override/)
  assert.match(preview, /intersection_road_preview_installation_visible/)
  assert.match(preview, /golden_draw_town_snapshot_installations/)
  assert.match(preview, /intersection_road_preview_graph_walkers/)
  assert.match(preview, /reference_intersection_preview_graph_walker_coordinate/)
  assert.doesNotMatch(preview, /town_snapshot_canvas_agents/)
  assert.match(preview, /intersection_road_preview_buildings_by_depth/)
  assert.match(preview, /intersection_road_preview_curated_buildings/)
  assert.match(preview, /intersection_road_preview_building_land_cells/)
  assert.match(preview, /building_land_cells/)
  const lotLandOverride = preview.indexOf("match building_land_cells.get(key)")
  const staleRoadFallback = preview.indexOf("None if road is Some(_)")
  assert.ok(lotLandOverride >= 0)
  assert.ok(staleRoadFallback > lotLandOverride)
  assert.match(preview, /land_type/)
  assert.match(preview, /golden_draw_intersection_road_preview_building_lot/)
  assert.doesNotMatch(preview, /previewBuildings|PreviewBuildingsValidated/)
  assert.match(preview, /buildings\.sort_by\(\(left, right\) => left\.id\.compare\(right\.id\)\)/)
  assert.match(preview, /golden_draw_spring_civic_building_asset/)
  assert.match(preview, /golden_draw_intersection_road_preview_building_shadow/)
  assert.match(preview, /context\.clip\(\)/)
  assert.doesNotMatch(preview, /golden_draw_reference_building_shadow/)
  assert.match(preview, /town_snapshot_canvas_buildings/)
  assert.match(preview, /golden_draw_building\(/)
  assert.match(preview, /golden_draw_weather/)
  assert.match(preview, /golden_draw_day_night/)
  assert.match(preview, /golden_draw_energy_valley_coordinate_grid/)
  assert.match(preview, /golden_valley_clear_canvas_frame\(\)/)
  assert.doesNotMatch(
    preview,
    /golden_draw_(?:road_overlay_tile|bridge_detail|town_snapshot_metro|selected_town_snapshot_relations|active_ecosystem_exchanges|ecosystem_pedestrian_spurs|ecosystem_place_layer)/,
  )
  assert.doesNotMatch(preview, /golden_valley_accept_canvas_frame/)
  assert.match(hudCss, /\.intersection-reference-legend \{/)
  assert.match(hudCss, /\.intersection-reference-coordinate \{/)
  assert.match(hudCss, /right: calc\(12px \+ var\(--town-safe-right\)\);/)
  assert.match(
    hudCss,
    /\.intersection-reference-badge,\n\s+\.intersection-reference-detail \{\n\s+display: none;/,
  )
})
