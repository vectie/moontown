///|
extern "js" fn authoritative_transport_test_begin_without_transport() -> Unit =
  #| () => {
  #|   const names = [
  #|     "__moontownEnergyValleyTransport",
  #|     "__wenyuReferenceLabels",
  #|     "__wenyuReferenceRoadGraph",
  #|     "__wenyuReferenceBuildings",
  #|     "__wenyuReferenceBuildingComponentRows",
  #|   ];
  #|   globalThis.__moontownAuthoritativeTransportTestDescriptors = new Map(
  #|     names.map(name => [
  #|       name,
  #|       Object.getOwnPropertyDescriptor(globalThis, name),
  #|     ]),
  #|   );
  #|   delete globalThis.__moontownEnergyValleyTransport;
  #| }

///|
extern "js" fn authoritative_transport_test_install_reference() -> Bool =
  #| () => {
  #|   const fs = require("node:fs");
  #|   const path = require("node:path");
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
  #|     return null;
  #|   };
  #|   const labels = read("wenyu_reference_labels.json");
  #|   const roads = read("wenyu_reference_roads.json");
  #|   const buildings = read("wenyu_reference_buildings.json");
  #|   if (!labels || !roads || !buildings) return false;
  #|   globalThis.__wenyuReferenceLabels = labels;
  #|   globalThis.__wenyuReferenceRoadGraph = roads;
  #|   globalThis.__wenyuReferenceBuildings = buildings;
  #|   const codeForKind = {
  #|     lowrise: "l", row: "r", block: "b", tower: "t",
  #|     courtyard: "q", campus: "c", civic: "v", industrial: "i",
  #|   };
  #|   const componentRows = Array.from(
  #|     { length: buildings.tileGrid.height },
  #|     () => Array(buildings.tileGrid.width).fill(null),
  #|   );
  #|   for (let index = 0; index < buildings.components.length; index += 1) {
  #|     const component = buildings.components[index];
  #|     const code = codeForKind[component.type];
  #|     const bbox = component.bbox;
  #|     if (!code || !bbox) continue;
  #|     for (let y = bbox.minY; y <= bbox.maxY; y += 1) {
  #|       for (let x = bbox.minX; x <= bbox.maxX; x += 1) {
  #|         if (buildings.labelRows[y]?.[x] === code && !componentRows[y][x]) {
  #|           componentRows[y][x] = {
  #|             index, anchorX: bbox.minX, anchorY: bbox.minY,
  #|           };
  #|         }
  #|       }
  #|     }
  #|   }
  #|   globalThis.__wenyuReferenceBuildingComponentRows = componentRows;
  #|   return true;
  #| }

///|
extern "js" fn authoritative_transport_test_install() -> Bool =
  #| () => {
  #|   const fs = require("node:fs");
  #|   const path = require("node:path");
  #|   const roots = [
  #|     path.resolve(process.cwd(), "../assets/tilemap"),
  #|     path.resolve(process.cwd(), "src/ui/assets/tilemap"),
  #|   ];
  #|   for (const root of roots) {
  #|     const candidate = path.join(root, "energy-valley-transport-v1.json");
  #|     if (fs.existsSync(candidate)) {
  #|       globalThis.__moontownEnergyValleyTransport = JSON.parse(
  #|         fs.readFileSync(candidate, "utf8"),
  #|       );
  #|       return true;
  #|     }
  #|   }
  #|   return false;
  #| }

///|
extern "js" fn authoritative_transport_test_restore() -> Unit =
  #| () => {
  #|   const descriptors =
  #|     globalThis.__moontownAuthoritativeTransportTestDescriptors;
  #|   if (!descriptors) return;
  #|   for (const [name, descriptor] of descriptors) {
  #|     if (descriptor) {
  #|       Object.defineProperty(globalThis, name, descriptor);
  #|     } else {
  #|       delete globalThis[name];
  #|     }
  #|   }
  #|   delete globalThis.__moontownAuthoritativeTransportTestDescriptors;
  #| }

///|
fn authoritative_transport_test_clear_caches() -> Unit {
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
fn authoritative_transport_test_same_world(
  left : ExactEnergyValleyWorld,
  right : ExactEnergyValleyWorld,
) -> Bool {
  if left.seed != right.seed ||
    left.cols != right.cols ||
    left.rows != right.rows ||
    left.buildings.length() != right.buildings.length() {
    return false
  }
  for y in 0..<left.rows {
    for x in 0..<left.cols {
      let a = left.tiles[y][x]
      let b = right.tiles[y][x]
      if a.terrain != b.terrain ||
        a.base_terrain != b.base_terrain ||
        a.generated_terrain != b.generated_terrain ||
        a.district != b.district ||
        a.variation != b.variation ||
        a.building_id != b.building_id ||
        a.river_flow != b.river_flow ||
        a.road_mask != b.road_mask ||
        a.structure != b.structure ||
        a.structure_floors != b.structure_floors ||
        a.structure_width != b.structure_width ||
        a.structure_depth != b.structure_depth {
        return false
      }
    }
  }
  for index, a in left.buildings {
    let b = right.buildings[index]
    if a.id != b.id ||
      a.archetype != b.archetype ||
      a.module_key != b.module_key ||
      a.name != b.name ||
      a.glyph != b.glyph ||
      a.style != b.style ||
      a.x != b.x ||
      a.y != b.y ||
      a.width != b.width ||
      a.depth != b.depth ||
      a.entrance_x != b.entrance_x ||
      a.entrance_y != b.entrance_y ||
      a.floors != b.floors ||
      a.vitality != b.vitality {
      return false
    }
  }
  left.landmarks.civic_core_x == right.landmarks.civic_core_x &&
  left.landmarks.civic_core_y == right.landmarks.civic_core_y &&
  left.landmarks.river_crossing_y == right.landmarks.river_crossing_y &&
  left.landmarks.feeder_head_x == right.landmarks.feeder_head_x &&
  left.landmarks.bridge_columns == right.landmarks.bridge_columns &&
  left.landmarks.south_arterial_y == right.landmarks.south_arterial_y
}

///|
test "transport changes presentation and Line 17 without replacing MoonTown" {
  authoritative_transport_test_begin_without_transport()
  assert_true(authoritative_transport_test_install_reference())
  authoritative_transport_test_clear_caches()
  let seed = 20260727
  let fallback = exact_energy_valley_generate_int(seed)
  let fallback_metro = metro_line17_path()
  assert_eq(fallback_metro[0], (139.5, 143.5))
  assert_false(authoritative_energy_valley_transport_ready())

  assert_true(authoritative_transport_test_install())
  assert_true(authoritative_energy_valley_transport_ready())
  assert_eq(
    authoritative_energy_valley_transport_digest(),
    "sha256:1c027120c077f569c183f6b1392a5839e20e9b36c080b95629ef86c3f548591e",
  )
  assert_eq(authoritative_energy_valley_transport_record_count(false), 280)
  assert_eq(authoritative_energy_valley_transport_record_count(true), 58)

  let transported = exact_energy_valley_generate_int(seed)
  assert_true(authoritative_transport_test_same_world(fallback, transported))

  let path = metro_line17_path()
  assert_eq(path.length(), 14)
  assert_eq(path[0], (124.829, 51.932))
  assert_eq(path[path.length() - 1], (113.857, 143.0))
  let stations = metro_line17_stations()
  assert_eq(stations.length(), 2)
  assert_eq(
    (stations[0].name, stations[0].x, stations[0].y),
    ("未来科学城北站", 125.0, 52.0),
  )
  assert_eq(
    (stations[1].name, stations[1].x, stations[1].y),
    ("未来科学城站", 126.5, 88.0),
  )
  assert_eq(metro_line17_station_exit_count(), 7)

  authoritative_transport_test_clear_caches()
  let snapshot = ecosystem_contract_town_snapshot(init_model(), seed)
  assert_false(
    snapshot.world.places.any(place => place.id.to_string().has_prefix("osm-")),
  )
  assert_false(
    @energy_valley_contract.has_errors(
      @energy_valley_contract.validate_world(snapshot.world),
    ),
  )
  let mut all_exact_entrances_visible = true
  let expected_exit_positions : Map[String, String] = Map([
    ("未来科学城北站 B 口", "125787:50546"),
    ("未来科学城北站 C 口", "124878:54470"),
    ("未来科学城北站 D 口", "122562:53739"),
    ("未来科学城站 A 口", "126097:87324"),
    ("未来科学城站 B 口", "128060:87197"),
    ("未来科学城站 C 口", "127371:88626"),
    ("未来科学城站 D 口", "126488:91946"),
  ])
  let distinct_exit_positions : Map[String, Bool] = Map([])
  let mut exact_exit_count = 0
  for installation in snapshot.world.installations {
    if installation.kind is @energy_valley_contract.TransitEntrance {
      match town_snapshot_installation_position(installation) {
        Some(point) => {
          let position_key = "\{(point.x * 1000.0).round().to_int()}:\{(point.y * 1000.0).round().to_int()}"
          assert_eq(
            expected_exit_positions.get(installation.label),
            Some(position_key),
          )
          distinct_exit_positions[position_key] = true
          exact_exit_count += 1
          let visible = town_snapshot_transit_entrance_visible(snapshot, point)
          all_exact_entrances_visible = all_exact_entrances_visible && visible
        }
        None => ()
      }
    }
  }
  assert_eq(exact_exit_count, 7)
  assert_eq(distinct_exit_positions.length(), 7)
  assert_true(all_exact_entrances_visible)
  assert_false(
    town_snapshot_transit_entrance_visible(
      snapshot,
      @energy_valley_contract.world_point(137.555, 84.529),
    ),
  )

  let mut hidden_fixed_road_furniture = false
  let mut visible_woodland_tree = false
  for installation in snapshot.world.installations {
    if town_snapshot_installation_tag(installation, "road-mask:") is Some(_) &&
      (
        installation.kind is @energy_valley_contract.Tree ||
        installation.kind is @energy_valley_contract.Light
      ) &&
      !(installation.provenance.kind is @energy_valley_contract.UserDelta) {
      assert_false(
        town_snapshot_installation_visible_with_transport(installation, true),
      )
      assert_true(
        town_snapshot_installation_visible_with_transport(installation, false),
      )
      hidden_fixed_road_furniture = true
    }
    if installation.kind is @energy_valley_contract.Tree &&
      town_snapshot_installation_tag(installation, "kind:") == Some("woodland") {
      assert_true(
        town_snapshot_installation_visible_with_transport(installation, true),
      )
      visible_woodland_tree = true
    }
  }
  assert_true(hidden_fixed_road_furniture)
  assert_true(visible_woodland_tree)
  let user_road_tree = @energy_valley_contract.installation(
    ecosystem_contract_scoped_id("installation", "user-road-tree-test"),
    "共建行道树",
    @energy_valley_contract.Tree,
    @energy_valley_contract.installation_point(
      @energy_valley_contract.world_point(12.5, 12.5),
    ),
    ecosystem_contract_provenance(true),
    tags=["road-mask:2", "side:1"],
  )
  assert_true(
    town_snapshot_installation_visible_with_transport(user_road_tree, true),
  )

  authoritative_transport_test_restore()
  authoritative_transport_test_clear_caches()
}
