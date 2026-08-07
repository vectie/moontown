///|
extern "js" fn ecosystem_parcel_test_install_reference_assets_raw() -> Unit =
  #| () => {
  #|   const fs = require("node:fs");
  #|   const path = require("node:path");
  #|   const names = [
  #|     "__wenyuReferenceLabels",
  #|     "__wenyuReferenceRoadGraph",
  #|     "__wenyuReferenceBuildings",
  #|     "__wenyuReferenceBuildingComponentRows",
  #|   ];
  #|   globalThis.__moontownEcosystemParcelReferenceAssets ||= {
  #|     descriptors: new Map(
  #|       names.map(name => [
  #|         name,
  #|         Object.getOwnPropertyDescriptor(globalThis, name),
  #|       ]),
  #|     ),
  #|   };
  #|   const roots = [
  #|     path.resolve(process.cwd(), "../assets/tilemap"),
  #|     path.resolve(process.cwd(), "src/ui/assets/tilemap"),
  #|   ];
  #|   const read = name => {
  #|     for (const root of roots) {
  #|       const candidate = path.join(root, name);
  #|       if (fs.existsSync(candidate)) {
  #|         return JSON.parse(fs.readFileSync(candidate, "utf8"));
  #|       }
  #|     }
  #|     throw new Error("Wenyu test asset not found: " + name);
  #|   };
  #|   globalThis.__wenyuReferenceLabels = read("wenyu_reference_labels.json");
  #|   globalThis.__wenyuReferenceRoadGraph = read("wenyu_reference_roads.json");
  #| }

///|
extern "js" fn ecosystem_parcel_test_hide_reference_assets_raw() -> Unit =
  #| () => {
  #|   const names = [
  #|     "__wenyuReferenceLabels",
  #|     "__wenyuReferenceRoadGraph",
  #|     "__wenyuReferenceBuildings",
  #|     "__wenyuReferenceBuildingComponentRows",
  #|   ];
  #|   globalThis.__moontownEcosystemParcelReferenceAssets ||= {
  #|     descriptors: new Map(
  #|       names.map(name => [
  #|         name,
  #|         Object.getOwnPropertyDescriptor(globalThis, name),
  #|       ]),
  #|     ),
  #|   };
  #|   for (const name of names) delete globalThis[name];
  #| }

///|
extern "js" fn ecosystem_parcel_test_restore_reference_assets_raw() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownEcosystemParcelReferenceAssets;
  #|   if (!harness) return;
  #|   for (const [name, descriptor] of harness.descriptors) {
  #|     if (descriptor) {
  #|       Object.defineProperty(globalThis, name, descriptor);
  #|     } else {
  #|       delete globalThis[name];
  #|     }
  #|   }
  #|   delete globalThis.__moontownEcosystemParcelReferenceAssets;
  #| }

///|
extern "js" fn ecosystem_parcel_test_install_incoming_sentinels() -> Unit =
  #| () => {
  #|   const names = [
  #|     "__wenyuReferenceLabels",
  #|     "__wenyuReferenceRoadGraph",
  #|     "__wenyuReferenceBuildings",
  #|     "__wenyuReferenceBuildingComponentRows",
  #|   ];
  #|   const descriptors = new Map(
  #|     names.map(name => [
  #|       name,
  #|       Object.getOwnPropertyDescriptor(globalThis, name),
  #|     ]),
  #|   );
  #|   const values = new Map();
  #|   for (const name of names) {
  #|     const value = { sentinel: name };
  #|     values.set(name, value);
  #|     Object.defineProperty(globalThis, name, {
  #|       configurable: true,
  #|       writable: true,
  #|       value,
  #|     });
  #|   }
  #|   globalThis.__moontownEcosystemParcelIncomingSentinels = {
  #|     descriptors,
  #|     values,
  #|   };
  #| }

///|
extern "js" fn ecosystem_parcel_test_incoming_sentinels_preserved() -> Bool =
  #| () => {
  #|   const harness = globalThis.__moontownEcosystemParcelIncomingSentinels;
  #|   if (!harness) return false;
  #|   for (const [name, value] of harness.values) {
  #|     if (globalThis[name] !== value) return false;
  #|   }
  #|   return true;
  #| }

///|
extern "js" fn ecosystem_parcel_test_remove_incoming_sentinels() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownEcosystemParcelIncomingSentinels;
  #|   if (!harness) return;
  #|   for (const [name, descriptor] of harness.descriptors) {
  #|     if (descriptor) {
  #|       Object.defineProperty(globalThis, name, descriptor);
  #|     } else {
  #|       delete globalThis[name];
  #|     }
  #|   }
  #|   delete globalThis.__moontownEcosystemParcelIncomingSentinels;
  #| }

///|
fn ecosystem_parcel_test_clear_compiler_caches() -> Unit {
  golden_valley_world_cache.clear()
  energy_valley_base_contract_world_cache.clear()
  town_life_world_base_road_cells_cache.clear()
  ecosystem_world_snapshot_cache.clear()
  ecosystem_contract_world_cache.clear()
  ecosystem_contract_world_validation_failed_cache.clear()
  ecosystem_contract_world_validation_summary_cache.clear()
  ecosystem_contract_world_validation_issues_cache.clear()
  ecosystem_contract_snapshot_validation_failed_cache.clear()
  ecosystem_contract_snapshot_validation_summary_cache.clear()
  ecosystem_contract_terrain_kind_lookup_cache.clear()
  ecosystem_contract_terrain_walkable_lookup_cache.clear()
}

///|
fn ecosystem_parcel_test_install_reference_assets() -> Unit {
  ecosystem_parcel_test_install_reference_assets_raw()
  ecosystem_parcel_test_clear_compiler_caches()
}

///|
fn ecosystem_parcel_test_hide_reference_assets() -> Unit {
  ecosystem_parcel_test_hide_reference_assets_raw()
  ecosystem_parcel_test_clear_compiler_caches()
}

///|
fn ecosystem_parcel_test_reset_reference_assets() -> Unit {
  ecosystem_parcel_test_restore_reference_assets_raw()
  ecosystem_parcel_test_clear_compiler_caches()
}

///|
fn ecosystem_parcel_test_fixture(
  seed : Int,
) -> (
  EcosystemWorldSnapshot,
  @energy_valley_contract.CompiledTownWorld,
  @energy_valley_contract.ParcelPlan,
) {
  ecosystem_parcel_test_install_reference_assets()
  let snapshot = ecosystem_world_snapshot(golden_valley_world(seed), [], [], [])
  let compiled = ecosystem_contract_world_from_snapshot(snapshot, seed)
  let plan : @energy_valley_contract.ParcelPlan = {
    compiler_version: "wenyu-parcel-adoption-v2",
    layout_seed: compiled.layout_seed,
    land_blocks: compiled.land_blocks,
    parcels: compiled.parcels,
    programs: compiled.parcel_programs,
    assignments: compiled.parcel_program_assignments,
  }
  (snapshot, compiled, plan)
}

///|
test "base contract cache follows reference asset lifecycle" {
  let seed = 20260727
  ecosystem_parcel_test_install_incoming_sentinels()
  ecosystem_parcel_test_hide_reference_assets()
  assert_false(reference_tile_snapshot_ready())
  assert_false(reference_road_graph_snapshot_ready())
  let fallback = energy_valley_base_contract_world_for_seed(seed)
  assert_true(energy_valley_base_contract_world_cache.contains(seed))

  ecosystem_parcel_test_install_reference_assets()
  assert_true(reference_tile_snapshot_ready())
  assert_true(reference_road_graph_snapshot_ready())
  assert_false(energy_valley_base_contract_world_cache.contains(seed))
  let reference = energy_valley_base_contract_world_for_seed(seed)
  assert_eq(reference.land_blocks.length(), 75)
  assert_true(reference.blueprint_digest != fallback.blueprint_digest)

  ecosystem_parcel_test_reset_reference_assets()
  let incoming_preserved = ecosystem_parcel_test_incoming_sentinels_preserved()
  let base_cache_cleared = !energy_valley_base_contract_world_cache.contains(
    seed,
  )
  ecosystem_parcel_test_remove_incoming_sentinels()
  ecosystem_parcel_test_clear_compiler_caches()
  assert_true(incoming_preserved)
  assert_true(base_cache_cleared)
}

///|
fn ecosystem_parcel_plan_buildable_area(
  plan : @energy_valley_contract.ParcelPlan,
) -> Double {
  let mut area = 0.0
  for block in plan.land_blocks {
    for region in block.buildable_regions {
      area += region.boundary.area()
    }
  }
  area
}

///|
fn ecosystem_parcel_buildable_tile_lookup(
  plan : @energy_valley_contract.ParcelPlan,
) -> Map[String, @energy_valley_contract.LandUse] raise {
  let result : Map[String, @energy_valley_contract.LandUse] = Map([])
  for block in plan.land_blocks {
    for region in block.buildable_regions {
      let left = region.boundary.vertices[0].x.to_int()
      let top = region.boundary.vertices[0].y.to_int()
      let right = region.boundary.vertices[2].x.to_int()
      let bottom = region.boundary.vertices[2].y.to_int()
      for y in top..<bottom {
        for x in left..<right {
          let key = golden_valley_tile_key(x, y)
          assert_false(result.contains(key))
          result[key] = region.land_use
        }
      }
    }
  }
  result
}

///|
fn ecosystem_parcel_expected_buildable_tile_lookup(
  snapshot : EcosystemWorldSnapshot,
  seed : Int,
) -> Map[String, Bool] {
  let result : Map[String, Bool] = Map([])
  let world = golden_valley_world(seed)
  let roads = ecosystem_parcel_road_lookup(snapshot)
  for block in ecosystem_parcel_planning_blocks(snapshot, seed) {
    for cell in block.cells {
      let key = golden_valley_tile_key(cell.x, cell.y)
      let terrain = world.tiles[cell.y][cell.x].terrain
      if !roads.contains(key) && terrain != "water" && terrain != "wetland" {
        result[key] = true
      }
    }
  }
  result
}

///|
/// Measure authored JSON land before the compiler accepts road repairs.
fn ecosystem_parcel_candidate_land_metrics(
  snapshot : EcosystemWorldSnapshot,
  seed : Int,
  mode : String,
) -> (Int, Int) {
  let shift_x = energy_valley_road_pattern_shift_x(seed)
  let shift_y = energy_valley_road_pattern_shift_y(seed)
  let mut region_count = 0
  let mut cell_count = 0
  for component in ecosystem_wenyu_reference_components(snapshot, seed) {
    let eligible : Map[String, Bool] = Map([])
    let cells = ecosystem_wenyu_shifted_component_cells(
      component,
      seed,
      snapshot.cols,
      snapshot.rows,
    )
    for cell in cells {
      let source_x = cell.x - shift_x
      let source_y = cell.y - shift_y
      let source_code = reference_tile_code_at(source_x, source_y)
      let barrier = match mode {
        "authored-open-water" => source_code == "r" || source_code == "l"
        _ => source_code == "r" || source_code == "l" || source_code == "w"
      }
      if !barrier {
        eligible[golden_valley_tile_key(cell.x, cell.y)] = true
      }
    }
    let visited : Map[String, Bool] = Map([])
    for start in cells {
      let start_key = golden_valley_tile_key(start.x, start.y)
      if !eligible.contains(start_key) || visited.contains(start_key) {
        continue
      }
      region_count += 1
      let queue : Array[EcosystemGridPoint] = [start]
      visited[start_key] = true
      let mut head = 0
      while head < queue.length() {
        let cell = queue[head]
        head += 1
        cell_count += 1
        for delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
          let next = ecosystem_point(cell.x + delta.0, cell.y + delta.1)
          let next_key = golden_valley_tile_key(next.x, next.y)
          if eligible.contains(next_key) && !visited.contains(next_key) {
            visited[next_key] = true
            queue.push(next)
          }
        }
      }
    }
  }
  (region_count, cell_count)
}

///|
fn ecosystem_parcel_block_ids(
  plan : @energy_valley_contract.ParcelPlan,
) -> Array[String] {
  let result : Array[String] = []
  for block in plan.land_blocks {
    result.push(block.id.to_string())
  }
  result
}

///|
fn ecosystem_parcel_first_nonpark_fragment(
  snapshot : EcosystemWorldSnapshot,
  seed : Int,
) -> EcosystemPlanningFragment {
  for block in ecosystem_parcel_planning_blocks(snapshot, seed) {
    for fragment in block.fragments {
      if fragment.land_use != @energy_valley_contract.Park {
        return fragment
      }
    }
  }
  abort("expected a non-park Wenyu buildable fragment")
}

///|
test "authoritative Wenyu rows compile exactly 75 stable top-level blocks" {
  let (snapshot, _, first) = ecosystem_parcel_test_fixture(20260727)
  let (_, _, second) = ecosystem_parcel_test_fixture(20260727)
  let (_, _, another_seed) = ecosystem_parcel_test_fixture(20260805)
  let reference_components = ecosystem_wenyu_reference_components(
    snapshot, 20260727,
  )
  let mut reference_cell_count = 0
  for component in reference_components {
    reference_cell_count += component.cells.length()
  }
  assert_eq(first, second)
  assert_eq(reference_components.length(), 75)
  assert_eq(reference_cell_count, 21078)
  assert_eq(first.land_blocks.length(), 75)
  assert_eq(
    ecosystem_parcel_block_ids(first),
    ecosystem_parcel_block_ids(second),
  )
  assert_eq(
    ecosystem_parcel_block_ids(first),
    ecosystem_parcel_block_ids(another_seed),
  )
  let seen : Map[String, Bool] = Map([])
  let mut nonparcelable_count = 0
  for block in first.land_blocks {
    let id = block.id.to_string()
    assert_true(id.has_prefix("land-block/wenyu-"))
    assert_false(seen.contains(id))
    seen[id] = true
    assert_eq(block.provenance.kind, @energy_valley_contract.WenyuReference)
    assert_eq(block.preservation, @energy_valley_contract.Fixed)
    assert_true(block.boundary.area() > 0.0)
    if block.parcelable {
      assert_true(block.buildable_regions.length() > 0)
    } else {
      nonparcelable_count += 1
      assert_true(block.buildable_regions.is_empty())
      assert_true(block.parcel_ids.is_empty())
    }
  }
  assert_eq(nonparcelable_count, 1)
  assert_eq(first.parcels.length(), first.assignments.length())
  ecosystem_parcel_test_reset_reference_assets()
}

///|
test "water derives nested land-region topology without renumbering 75 road blocks" {
  let seed = 20260727
  let (snapshot, _, plan) = ecosystem_parcel_test_fixture(seed)
  let planning_blocks = ecosystem_parcel_planning_blocks(snapshot, seed)
  let open_water_metrics = ecosystem_parcel_candidate_land_metrics(
    snapshot, seed, "authored-open-water",
  )
  let authored_hydrology_metrics = ecosystem_parcel_candidate_land_metrics(
    snapshot, seed, "authored-hydrology",
  )
  assert_eq(planning_blocks.length(), 75)
  assert_eq(plan.land_blocks.length(), 75)
  let world = golden_valley_world(seed)
  let roads = ecosystem_parcel_road_lookup(snapshot)
  let seen : Map[String, Bool] = Map([])
  let fragment_seen : Map[String, Bool] = Map([])
  let mut land_region_count = 0
  let mut land_region_cell_count = 0
  let mut split_block_count = 0
  let mut empty_block_count = 0
  for block in planning_blocks {
    land_region_count += block.land_regions.length()
    if block.land_regions.length() > 1 {
      split_block_count += 1
    }
    if block.land_regions.is_empty() {
      empty_block_count += 1
    }
    for region in block.land_regions {
      assert_true(region.boundary.area() > 0.0)
      for cell in region.cells {
        let key = golden_valley_tile_key(cell.x, cell.y)
        assert_false(seen.contains(key))
        seen[key] = true
        assert_false(roads.contains(key))
        let terrain = world.tiles[cell.y][cell.x].terrain
        assert_true(terrain != "water" && terrain != "wetland")
        land_region_cell_count += 1
      }
    }
    for fragment in block.fragments {
      for y in fragment.y..<(fragment.y + fragment.depth) {
        for x in fragment.x..<(fragment.x + fragment.width) {
          let key = golden_valley_tile_key(x, y)
          assert_true(seen.contains(key))
          assert_false(fragment_seen.contains(key))
          fragment_seen[key] = true
        }
      }
    }
  }
  let shift_x = energy_valley_road_pattern_shift_x(seed)
  let shift_y = energy_valley_road_pattern_shift_y(seed)
  let mut authored_hydrology_land_cell_count = 0
  let mut accepted_from_authored_hydrology_cell_count = 0
  let mut accepted_road_removed_cell_count = 0
  let mut generated_hydrology_removed_cell_count = 0
  let mut unexplained_removed_cell_count = 0
  for block in planning_blocks {
    for cell in block.cells {
      let source_code = reference_tile_code_at(
        cell.x - shift_x,
        cell.y - shift_y,
      )
      if source_code != "r" && source_code != "l" && source_code != "w" {
        authored_hydrology_land_cell_count += 1
        let key = golden_valley_tile_key(cell.x, cell.y)
        if !seen.contains(key) {
          if roads.contains(key) {
            accepted_road_removed_cell_count += 1
          } else {
            let terrain = world.tiles[cell.y][cell.x].terrain
            if terrain == "water" || terrain == "wetland" {
              generated_hydrology_removed_cell_count += 1
            } else {
              unexplained_removed_cell_count += 1
            }
          }
        }
      } else if seen.contains(golden_valley_tile_key(cell.x, cell.y)) {
        accepted_from_authored_hydrology_cell_count += 1
      }
    }
  }
  // The preliminary 87-region analysis came from an approximate water mask and
  // is intentionally not an architecture invariant. Authored JSON open water
  // produces 78 / 20,160; adding wetlands produces 80 / 20,083. The compiler
  // accepts 4 authored hydrology cells at repaired crossings,
  // expands the hydrology barrier by 125 cells, and removes 2 more accepted
  // road cells: 20,083 + 4 - 125 - 2 = 19,960. That land is split into 83
  // semantic regions, all nested under the 75 legal road blocks.
  assert_eq(open_water_metrics, (78, 20160))
  assert_eq(authored_hydrology_metrics, (80, 20083))
  assert_eq(authored_hydrology_land_cell_count, 20083)
  assert_eq(accepted_from_authored_hydrology_cell_count, 4)
  assert_eq(accepted_road_removed_cell_count, 2)
  assert_eq(generated_hydrology_removed_cell_count, 125)
  assert_eq(unexplained_removed_cell_count, 0)
  assert_eq(land_region_count, 83)
  assert_eq(land_region_cell_count, 19960)
  assert_true(split_block_count > 0)
  assert_eq(empty_block_count, 1)
  assert_eq(fragment_seen.length(), land_region_cell_count)
  assert_eq(
    seen.length(),
    ecosystem_parcel_expected_buildable_tile_lookup(snapshot, seed).length(),
  )
  ecosystem_parcel_test_reset_reference_assets()
}

///|
test "civic placement and final compilation share one authoritative road graph" {
  let seed = 20260727
  ecosystem_parcel_test_install_reference_assets()
  golden_valley_world_cache.clear()
  let world = golden_valley_world(seed)
  let placement_network = energy_valley_authoritative_road_network(seed)
  let snapshot = ecosystem_world_snapshot(world, [], [], [])
  let placement_nodes = placement_network.nodes.map(node => node.id.to_string())
  let compiled_nodes = snapshot.road_network.nodes.map(node => {
    node.id.to_string()
  })
  let placement_segments = placement_network.segments.map(segment => {
    segment.id.to_string()
  })
  let compiled_segments = snapshot.road_network.segments.map(segment => {
    segment.id.to_string()
  })
  assert_eq(placement_nodes, compiled_nodes)
  assert_eq(placement_segments, compiled_segments)
  for building in world.buildings {
    assert_true(
      placement_network.find_node(
        ecosystem_contract_id(
          ecosystem_road_cell_id(building.entrance_x, building.entrance_y),
        ),
      )
      is Some(_),
    )
    for y in building.y..<(building.y + building.depth) {
      for x in building.x..<(building.x + building.width) {
        assert_true(
          placement_network.find_node(
            ecosystem_contract_id(ecosystem_road_cell_id(x, y)),
          )
          is None,
        )
      }
    }
  }
  ecosystem_parcel_test_reset_reference_assets()
}

///|
test "buildable regions conserve every enclosed non-road non-water tile" {
  let seed = 20260727
  let (snapshot, _, plan) = ecosystem_parcel_test_fixture(seed)
  let expected = ecosystem_parcel_expected_buildable_tile_lookup(snapshot, seed)
  let actual = ecosystem_parcel_buildable_tile_lookup(plan)
  assert_eq(actual.length(), expected.length())
  assert_eq(
    ecosystem_parcel_plan_buildable_area(plan),
    expected.length().to_double(),
  )
  for key, _ in expected {
    assert_true(actual.contains(key))
  }
  ecosystem_parcel_test_reset_reference_assets()
}

///|
test "buildable regions exclude every typed road water and wetland tile" {
  let seed = 20260727
  let (snapshot, _, plan) = ecosystem_parcel_test_fixture(seed)
  let actual = ecosystem_parcel_buildable_tile_lookup(plan)
  let roads = ecosystem_parcel_road_lookup(snapshot)
  let world = golden_valley_world(seed)
  for key, _ in actual {
    assert_false(roads.contains(key))
  }
  for y in 0..<world.rows {
    for x in 0..<world.cols {
      let terrain = world.tiles[y][x].terrain
      if terrain == "water" || terrain == "wetland" {
        assert_false(actual.contains(golden_valley_tile_key(x, y)))
      }
    }
  }
  ecosystem_parcel_test_reset_reference_assets()
}

///|
test "every compiled parcel receives one compatible semantic program" {
  let (_, _, plan) = ecosystem_parcel_test_fixture(20260727)
  for parcel in plan.parcels {
    let assignment = plan.find_assignment(parcel.id).unwrap()
    let program = plan.find_program(assignment.program_id).unwrap()
    assert_true(program.compatible_land_uses.contains(parcel.land_use))
    assert_true(parcel.allowed_programs.contains(program.id.to_string()))
    assert_eq(assignment.provenance.kind, @energy_valley_contract.Derived)
  }
  ecosystem_parcel_test_reset_reference_assets()
}

///|
test "a player road fragments buildable area without renumbering 75 blocks" {
  let seed = 20260727
  let (snapshot, _, base_plan) = ecosystem_parcel_test_fixture(seed)
  let fragment = ecosystem_parcel_first_nonpark_fragment(snapshot, seed)
  let road_x = fragment.x
  let road_y = fragment.y
  let custom_snapshot = ecosystem_world_snapshot(
    golden_valley_world(seed),
    [],
    [golden_valley_tile_key(road_x, road_y)],
    [],
  )
  let custom_world = ecosystem_contract_world_from_snapshot(
    custom_snapshot, seed,
  )
  let custom_plan : @energy_valley_contract.ParcelPlan = {
    compiler_version: "wenyu-parcel-adoption-v2",
    layout_seed: custom_world.layout_seed,
    land_blocks: custom_world.land_blocks,
    parcels: custom_world.parcels,
    programs: custom_world.parcel_programs,
    assignments: custom_world.parcel_program_assignments,
  }
  assert_eq(custom_plan.land_blocks.length(), 75)
  assert_eq(
    ecosystem_parcel_block_ids(custom_plan),
    ecosystem_parcel_block_ids(base_plan),
  )
  assert_eq(
    ecosystem_parcel_plan_buildable_area(base_plan) -
    ecosystem_parcel_plan_buildable_area(custom_plan),
    1.0,
  )
  assert_false(
    ecosystem_parcel_buildable_tile_lookup(custom_plan).contains(
      golden_valley_tile_key(road_x, road_y),
    ),
  )
  ecosystem_parcel_test_reset_reference_assets()
}

///|
test "a player park becomes an exact Park subregion inside the same 75 blocks" {
  let seed = 20260727
  let (snapshot, _, base_plan) = ecosystem_parcel_test_fixture(seed)
  let fragment = ecosystem_parcel_first_nonpark_fragment(snapshot, seed)
  let park_x = fragment.x
  let park_y = fragment.y
  let custom_snapshot = ecosystem_world_snapshot(
    golden_valley_world(seed),
    [],
    [],
    [golden_valley_tile_key(park_x, park_y)],
  )
  let custom_world = ecosystem_contract_world_from_snapshot(
    custom_snapshot, seed,
  )
  let custom_plan : @energy_valley_contract.ParcelPlan = {
    compiler_version: "wenyu-parcel-adoption-v2",
    layout_seed: custom_world.layout_seed,
    land_blocks: custom_world.land_blocks,
    parcels: custom_world.parcels,
    programs: custom_world.parcel_programs,
    assignments: custom_world.parcel_program_assignments,
  }
  assert_eq(custom_plan.land_blocks.length(), 75)
  assert_eq(
    ecosystem_parcel_block_ids(custom_plan),
    ecosystem_parcel_block_ids(base_plan),
  )
  assert_eq(
    ecosystem_parcel_plan_buildable_area(custom_plan),
    ecosystem_parcel_plan_buildable_area(base_plan),
  )
  let center = @energy_valley_contract.world_point(
    park_x.to_double() + 0.5,
    park_y.to_double() + 0.5,
  )
  let park_parcels = custom_plan.parcels.filter(parcel => {
    parcel.land_use == @energy_valley_contract.Park &&
    parcel.boundary.contains_point(center)
  })
  assert_eq(park_parcels.length(), 1)
  let assignment = custom_plan.find_assignment(park_parcels[0].id).unwrap()
  assert_true(
    assignment.program_id.to_string().has_prefix("parcel-program/park-"),
  )
  let user_regions : Array[@energy_valley_contract.BuildableRegion] = []
  for block in custom_plan.land_blocks {
    for region in block.buildable_regions {
      if region.land_use == @energy_valley_contract.Park &&
        region.boundary.contains_point(center) {
        user_regions.push(region)
      }
    }
  }
  assert_eq(user_regions.length(), 1)
  assert_eq(user_regions[0].provenance.kind, @energy_valley_contract.UserDelta)
  ecosystem_parcel_test_reset_reference_assets()
}

///|
test "terrain regions losslessly cover the full Wenyu raster" {
  let seed = 20260727
  let (_, world, _) = ecosystem_parcel_test_fixture(seed)
  assert_true(world.terrain_regions.length() > 0)
  let mut area = 0.0
  for region in world.terrain_regions {
    area += region.boundary.area()
  }
  assert_eq(
    area,
    (exact_energy_valley_cols() * exact_energy_valley_rows()).to_double(),
  )
  let exact = golden_valley_world(seed)
  for y in 0..<exact.rows {
    for x in 0..<exact.cols {
      let kind = ecosystem_contract_terrain_kind_at(world, x, y)
      assert_true(kind is Some(_))
      if exact.tiles[y][x].terrain == "water" {
        assert_eq(kind, Some(@energy_valley_contract.Water))
        assert_eq(
          ecosystem_contract_terrain_walkable_at(world, x, y),
          Some(false),
        )
      }
    }
  }
  ecosystem_parcel_test_reset_reference_assets()
}

///|
test "bridge and arterial endpoint strength survives segment compilation" {
  let (snapshot, world, _) = ecosystem_parcel_test_fixture(20260727)
  let roads : Map[@energy_valley_contract.StableId, EcosystemRoadCell] = Map([])
  for road in snapshot.roads {
    roads[ecosystem_contract_id(road.id)] = road
  }
  let mut bridge_segments = 0
  for segment in world.road_network.segments {
    match (roads.get(segment.from_node_id), roads.get(segment.to_node_id)) {
      (Some(first), Some(second)) =>
        if first.bridge || second.bridge {
          bridge_segments += 1
          assert_eq(segment.road_class, @energy_valley_contract.Bridge)
          assert_true(segment.width_meters >= 12.0)
        }
      _ => ()
    }
  }
  assert_true(bridge_segments > 0)
  ecosystem_parcel_test_reset_reference_assets()
}

///|
test "placement rejection diagnostics are stable and sorted" {
  ecosystem_parcel_test_install_reference_assets()
  golden_valley_world_cache.clear()
  ecosystem_world_snapshot_cache.clear()
  ecosystem_contract_world_cache.clear()
  let model = init_model()
  let first = ecosystem_compiler_rejected_placements(model, 20260727)
  let second = ecosystem_compiler_rejected_placements(model, 20260727)
  assert_eq(first, second)
  for index in 1..<first.length() {
    assert_true(first[index - 1].id.compare(first[index].id) <= 0)
  }
  ecosystem_parcel_test_reset_reference_assets()
}
