///|
fn intersection_preview_test_installation(
  kind : @energy_valley_contract.InstallationKind,
  tags : ArrayView[String],
) -> @energy_valley_contract.Installation {
  @energy_valley_contract.installation(
    ecosystem_contract_scoped_id("installation", "preview-visibility-test"),
    "预览可见性测试",
    kind,
    @energy_valley_contract.installation_point(
      @energy_valley_contract.world_point(12.5, 12.5),
    ),
    ecosystem_contract_provenance(false),
    tags~,
  )
}

///|
fn intersection_preview_test_building(
  x : Int,
  y : Int,
  width : Int,
  depth : Int,
  depth_key : Int,
) -> IntersectionRoadPreviewBuilding {
  {
    id: "preview-building-test",
    style: "campus",
    asset_path: "/tilemap/buildings/moontown-spring-ambient-v1/campus-3.webp",
    x,
    y,
    width,
    depth,
    apron: 1,
    depth_key,
  }
}

///|
test "intersection road preview derived caches retain only the active key" {
  let active = intersection_preview_test_building(40, 50, 5, 5, 100)
  let cache : Map[String, Array[IntersectionRoadPreviewBuilding]] = {
    "stale-camera-a": [],
    "active-camera": [active],
    "stale-camera-b": [],
  }
  intersection_road_preview_retain_cache_key(cache, "active-camera")
  assert_eq(cache.length(), 1)
  assert_eq(cache.get("active-camera").map(items => items.length()), Some(1))
  assert_true(cache.get("stale-camera-a") is None)
  assert_true(cache.get("stale-camera-b") is None)

  intersection_road_preview_retain_cache_key(cache, "new-camera")
  assert_eq(cache.length(), 0)
}

///|
test "intersection road preview buildings use only fixed ambient assets" {
  assert_eq(
    intersection_road_preview_building_asset_path("campus", 3),
    Some("/tilemap/buildings/moontown-spring-ambient-v1/campus-3.webp"),
  )
  assert_eq(
    intersection_road_preview_building_asset_path("town-shell", 0),
    None,
  )
  assert_eq(intersection_road_preview_building_asset_path("campus", 10), None)
  assert_eq(
    intersection_road_preview_building_asset_path("../../escape", 0),
    None,
  )
}

///|
test "intersection road preview curates thirty stable apron lots" {
  let buildings = intersection_road_preview_curated_buildings()
  assert_eq(buildings.length(), 30)
  assert_eq(buildings[0].id, "building-01")
  assert_eq(buildings[29].id, "building-30")
  for building in buildings {
    assert_true(intersection_road_preview_building_geometry_valid(building))
    assert_true(
      building.style == "lowrise" ||
      building.style == "row" ||
      building.style == "block" ||
      building.style == "tower" ||
      building.style == "courtyard" ||
      building.style == "campus" ||
      building.style == "civic" ||
      building.style == "industrial",
    )
    assert_eq(building.width, 5)
    assert_eq(building.depth, 5)
    assert_eq(building.apron, 1)
    assert_eq(building.width + building.apron * 2, 7)
    assert_eq(building.depth + building.apron * 2, 7)
    assert_true(
      building.asset_path.contains(
        "/tilemap/buildings/moontown-spring-ambient-v1/",
      ),
    )
  }
  for index, building in buildings {
    for other_index in (index + 1)..<buildings.length() {
      assert_false(
        intersection_road_preview_buildings_overlap(
          building,
          buildings[other_index],
        ),
      )
    }
  }
}

///|
test "intersection road preview paints the complete rectangular lot" {
  let building = intersection_preview_test_building(40, 50, 5, 5, 100)
  let by_depth : Map[Int, Array[IntersectionRoadPreviewBuilding]] = {
    100: [building],
  }
  let cells = intersection_road_preview_building_land_cells(
    by_depth, "wbtest-complete-seven-by-seven-lot",
  )
  assert_eq(cells.length(), 49)
  for y in 49..<=55 {
    for x in 39..<=45 {
      assert_eq(cells.get(town_canvas_road_key(x, y)), Some("plaza"))
    }
  }
  assert_eq(cells.get(town_canvas_road_key(38, 50)), None)
  assert_eq(cells.get(town_canvas_road_key(46, 50)), None)
}

///|
test "intersection road preview buildings own explicit land types" {
  assert_eq(intersection_road_preview_building_land_type("campus"), "plaza")
  assert_eq(intersection_road_preview_building_land_type("courtyard"), "plaza")
  assert_eq(intersection_road_preview_building_land_type("civic"), "plaza")
  assert_eq(intersection_road_preview_building_land_type("tower"), "urban")
  assert_eq(intersection_road_preview_building_land_type("row"), "urban")
  assert_eq(intersection_road_preview_building_land_type("industrial"), "urban")
}

///|
test "intersection road preview building geometry owns its anchor and depth" {
  let building = intersection_preview_test_building(40, 50, 5, 5, 100)
  assert_true(intersection_road_preview_building_geometry_valid(building))
  assert_eq(intersection_road_preview_building_center(building), (42.5, 52.5))
  assert_false(
    intersection_road_preview_building_geometry_valid({
      ..building,
      depth_key: 99,
    }),
  )
  assert_false(
    intersection_road_preview_building_geometry_valid({ ..building, x: 252 }),
  )
  assert_false(
    intersection_road_preview_building_geometry_valid({ ..building, width: 0 }),
  )
  assert_false(
    intersection_road_preview_building_geometry_valid({ ..building, width: 4 }),
  )
  let equal_depth = [
    { ..building, id: "preview-building-z" },
    { ..building, id: "preview-building-a" },
  ]
  intersection_road_preview_sort_equal_depth(equal_depth)
  assert_eq(equal_depth[0].id, "preview-building-a")
  assert_eq(equal_depth[1].id, "preview-building-z")
}

///|
test "intersection road preview keeps image and vector building pools distinct" {
  let image = intersection_preview_test_building(40, 50, 5, 5, 100)
  let vector : IntersectionRoadPreviewBuilding = {
    ..image,
    id: "preview-vector-building-test",
    style: "home",
    asset_path: "",
  }
  assert_true(intersection_road_preview_building_geometry_valid(vector))
  let by_depth : Map[Int, Array[IntersectionRoadPreviewBuilding]] = {
    100: [image, vector],
  }
  assert_eq(intersection_road_preview_building_counts(by_depth), (1, 1))
}

///|
test "shared preview tile painter preserves canonical old-map terrain values" {
  let snapshot = ecosystem_contract_town_snapshot(init_model(), 20260727)
  let roads = town_snapshot_canvas_roads(snapshot)
  let lookup = town_snapshot_canvas_road_lookup(roads)
  for y in 0..<town_snapshot_canvas_rows(snapshot) {
    for x in 0..<town_snapshot_canvas_cols(snapshot) {
      let road = lookup.get(town_canvas_road_key(x, y))
      let road_visible = golden_canonical_old_map_road_visible(
        road, false, false,
      )
      assert_true(road_visible)
      assert_eq(
        golden_canonical_old_map_terrain(
          snapshot, lookup, road, road_visible, false, x, y,
        ),
        town_snapshot_canvas_terrain(snapshot, road, x, y),
      )
    }
  }

  // The real preview enters with the presentation asset ready. In that path,
  // an unranked semantic road is hidden, and both the normal Canvas and the
  // preview must resolve it to the same recovered neutral ground.
  let presentation_ready = true
  let mut unranked_road : TownCanvasRoadCell? = None
  for road in roads {
    if !road.custom && !road.bridge && unranked_road is None {
      unranked_road = Some(road)
    }
  }
  match unranked_road {
    Some(road) => {
      let road_visible = golden_native_road_rank_visible(
        ".",
        road.custom,
        presentation_ready,
        0.72,
      )
      assert_false(road_visible)
      let canonical_terrain = golden_canonical_old_map_terrain(
        snapshot,
        lookup,
        Some(road),
        road_visible,
        false,
        road.x,
        road.y,
      )
      assert_eq(
        canonical_terrain,
        town_snapshot_canvas_transport_terrain(
          snapshot,
          lookup,
          Some(road),
          road.x,
          road.y,
        ),
      )
      assert_true(canonical_terrain != "road")
    }
    None => fail("expected a non-bridge base road for preview terrain parity")
  }
}

///|
test "intersection road preview keeps scenery and suppresses transport ghosts" {
  for
    installation in [
      intersection_preview_test_installation(
        @energy_valley_contract.Boardwalk,
        [],
      ),
      intersection_preview_test_installation(@energy_valley_contract.Bench, []),
      intersection_preview_test_installation(@energy_valley_contract.Tree, [
        "kind:woodland",
      ]),
      intersection_preview_test_installation(@energy_valley_contract.Light, []),
      intersection_preview_test_installation(
        @energy_valley_contract.Custom("planter"),
        [],
      ),
    ] {
    assert_true(intersection_road_preview_installation_visible(installation))
  }
  for
    installation in [
      intersection_preview_test_installation(
        @energy_valley_contract.MetroAlignment,
        [],
      ),
      intersection_preview_test_installation(
        @energy_valley_contract.TransitEntrance,
        [],
      ),
      intersection_preview_test_installation(@energy_valley_contract.Signage, []),
      intersection_preview_test_installation(@energy_valley_contract.Tree, [
        "road-mask:2",
      ]),
      intersection_preview_test_installation(@energy_valley_contract.Light, [
        "road-mask:8",
      ]),
      intersection_preview_test_installation(
        @energy_valley_contract.Custom("road-marker"),
        [],
      ),
    ] {
    assert_false(intersection_road_preview_installation_visible(installation))
  }
}

///|
test "intersection road presentation keeps user planted road fixtures" {
  let fixture = intersection_preview_test_installation(
    @energy_valley_contract.Tree,
    ["road-mask:2"],
  )
  let fixture = { ..fixture, provenance: ecosystem_contract_provenance(true) }
  assert_true(intersection_road_preview_installation_visible(fixture))
}
