///|
extern "js" fn energy_valley_block_test_install_reference_assets() -> Unit =
  #| () => {
  #|   const fs = require("node:fs");
  #|   const path = require("node:path");
  #|   const names = [
  #|     "__wenyuReferenceLabels",
  #|     "__wenyuReferenceRoadGraph",
  #|     "__wenyuReferenceBuildings",
  #|   ];
  #|   globalThis.__moontownBlockLayoutReferenceDescriptors = new Map(
  #|     names.map(name => [name, Object.getOwnPropertyDescriptor(globalThis, name)]),
  #|   );
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
  #|   globalThis.__wenyuReferenceBuildings = read("wenyu_reference_buildings.json");
  #| }

///|
extern "js" fn energy_valley_block_test_restore_reference_assets() -> Unit =
  #| () => {
  #|   const saved = globalThis.__moontownBlockLayoutReferenceDescriptors;
  #|   if (!saved) return;
  #|   for (const [name, descriptor] of saved) {
  #|     if (descriptor) Object.defineProperty(globalThis, name, descriptor);
  #|     else delete globalThis[name];
  #|   }
  #|   delete globalThis.__moontownBlockLayoutReferenceDescriptors;
  #| }

///|
fn energy_valley_block_test_tiles(
  seed : Int,
) -> Array[Array[ExactEnergyValleyTile]] {
  let tiles : Array[Array[ExactEnergyValleyTile]] = []
  for y in 0..<exact_energy_valley_rows() {
    let row : Array[ExactEnergyValleyTile] = []
    for x in 0..<exact_energy_valley_cols() {
      row.push(exact_energy_valley_tile(seed, x, y))
    }
    tiles.push(row)
  }
  energy_valley_compile_reference_road_network(tiles, seed)
  tiles
}

///|
fn energy_valley_block_test_layout(seed : Int) -> EnergyValleyRoadBlockLayout {
  let tiles = energy_valley_block_test_tiles(seed)
  energy_valley_road_block_layout(
    seed,
    energy_valley_authoritative_road_network_from_tiles(tiles),
  )
}

///|
test "Wenyu buildings occupy one dry road block with shared spacing" {
  energy_valley_block_test_install_reference_assets()
  let seed = default_energy_valley_seed
  let layout = energy_valley_block_test_layout(seed)
  assert_eq(layout.blocks.length(), 75)
  let mut block_cell_count = 0
  for block in layout.blocks {
    block_cell_count += block.cells.length()
  }
  assert_eq(block_cell_count, 21078)
  assert_true(layout.regions.length() >= layout.blocks.length())

  let baseline_tiles = energy_valley_block_test_tiles(seed)
  let world = exact_energy_valley_generate_default()
  let ambient_blocks : Map[Int, Bool] = Map([])
  let placed_footprints : Array[EnergyValleyFootprint] = []
  let mut ambient_count = 0
  for y in 0..<world.rows {
    for x in 0..<world.cols {
      match world.structure_footprint_at(x, y) {
        None => ()
        Some((_, _, width, depth)) => {
          ambient_count += 1
          let identity = match
            energy_valley_road_block_layout_for_footprint(
              layout, x, y, width, depth,
            ) {
            Some(value) => value
            None => fail("ambient footprint crossed a road block or dry region")
          }
          assert_false(ambient_blocks.contains(identity.0))
          ambient_blocks[identity.0] = true
          placed_footprints.push({ x, y, width, height: depth })
          let building_id = world.tiles[y][x].building_id
          assert_true(
            building_id.unwrap_or("").has_prefix("ambient-wenyu-\{identity.0}-"),
          )
          for yy in y..<(y + depth) {
            for xx in x..<(x + width) {
              let tile = world.tiles[yy][xx]
              assert_eq(tile.building_id, building_id)
              assert_true(tile.terrain != "road")
              assert_true(tile.terrain != "bridge")
              assert_true(tile.terrain != "water")
              assert_true(tile.base_terrain != "wetland")
            }
          }
        }
      }
    }
  }
  assert_true(ambient_count >= 20)
  assert_true(ambient_count <= 41)
  assert_eq(ambient_count, ambient_blocks.length())

  for building in world.buildings {
    assert_true(
      energy_valley_road_block_layout_for_footprint(
        layout,
        building.x,
        building.y,
        building.width,
        building.depth,
      )
      is Some(_),
    )
    let mut buildable = 0
    for y in building.y..<(building.y + building.depth) {
      for x in building.x..<(building.x + building.width) {
        assert_eq(
          world.tiles[y][x].base_terrain,
          baseline_tiles[y][x].base_terrain,
        )
        if energy_valley_parcel_buildable_kind(world.tiles[y][x].base_terrain) {
          buildable += 1
        }
      }
    }
    assert_true(buildable * 2 >= building.width * building.depth)
    placed_footprints.push({
      x: building.x,
      y: building.y,
      width: building.width,
      height: building.depth,
    })
  }
  for left in 0..<placed_footprints.length() {
    for right in (left + 1)..<placed_footprints.length() {
      assert_false(
        energy_valley_footprints_overlap(
          placed_footprints[left],
          placed_footprints[right],
        ),
      )
    }
  }
  let snapshot = ecosystem_world_snapshot(world, [], [], [])
  let compiled = ecosystem_contract_world_from_snapshot(snapshot, seed)
  let contract_issues = @energy_valley_contract.validate_world(compiled)
  assert_eq(ecosystem_contract_issue_summary(contract_issues), "")
  let mut compiled_buildings = 0
  let unassigned_buildings : Array[String] = []
  for place in compiled.places {
    if place.building is Some(_) {
      compiled_buildings += 1
      if place.parcel_id is None {
        unassigned_buildings.push(place.id.to_string())
      }
    }
  }
  assert_true(unassigned_buildings.is_empty())
  assert_true(compiled_buildings >= ambient_count + world.buildings.length())
  energy_valley_block_test_restore_reference_assets()
}
