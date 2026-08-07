///|
fn golden_valley_tile_key(x : Int, y : Int) -> String {
  "\{x}:\{y}"
}

///|
priv enum GoldenValleyPlacementBlock {
  PlacementOutOfBounds
  PlacementTransportOrWater
  PlacementProtectedWetland
  PlacementOutsideBuildableParcel
  PlacementUserPark
  PlacementOccupied
  PlacementNeedsRoad
  PlacementSiteContractRejected
} derive(Debug, Eq)

///|
fn golden_valley_building_contains(
  building : GoldenValleyBuilding,
  x : Int,
  y : Int,
) -> Bool {
  x >= building.x &&
  x < building.x + building.width &&
  y >= building.y &&
  y < building.y + building.depth
}

///|
fn golden_valley_contract_tile_footprint(
  x : Int,
  y : Int,
) -> @energy_valley_contract.Polygon {
  @energy_valley_contract.polygon([
    @energy_valley_contract.world_point(x.to_double(), y.to_double()),
    @energy_valley_contract.world_point((x + 1).to_double(), y.to_double()),
    @energy_valley_contract.world_point(
      (x + 1).to_double(),
      (y + 1).to_double(),
    ),
    @energy_valley_contract.world_point(x.to_double(), (y + 1).to_double()),
  ])
}

///|
fn golden_valley_contract_building_footprint(
  building : GoldenValleyBuilding,
) -> @energy_valley_contract.Polygon {
  @energy_valley_contract.polygon([
    @energy_valley_contract.world_point(
      building.x.to_double(),
      building.y.to_double(),
    ),
    @energy_valley_contract.world_point(
      (building.x + building.width).to_double(),
      building.y.to_double(),
    ),
    @energy_valley_contract.world_point(
      (building.x + building.width).to_double(),
      (building.y + building.depth).to_double(),
    ),
    @energy_valley_contract.world_point(
      building.x.to_double(),
      (building.y + building.depth).to_double(),
    ),
  ])
}

///|
fn golden_valley_contract_polygon_inside(
  container : @energy_valley_contract.Polygon,
  candidate : @energy_valley_contract.Polygon,
) -> Bool {
  candidate.vertices.all(vertex => container.contains_point(vertex))
}

///|
fn golden_valley_contract_place_at(
  world : @energy_valley_contract.CompiledTownWorld,
  x : Int,
  y : Int,
) -> @energy_valley_contract.Place? {
  let point = @energy_valley_contract.world_point(
    x.to_double() + 0.5,
    y.to_double() + 0.5,
  )
  for place in world.places {
    if place.footprint.contains_point(point) {
      return Some(place)
    }
  }
  None
}

///|
fn golden_valley_contract_building_place_at(
  world : @energy_valley_contract.CompiledTownWorld,
  x : Int,
  y : Int,
) -> @energy_valley_contract.Place? {
  let point = @energy_valley_contract.world_point(
    x.to_double() + 0.5,
    y.to_double() + 0.5,
  )
  for place in world.places {
    if place.kind is @energy_valley_contract.Building &&
      place.building is Some(_) &&
      place.footprint.contains_point(point) {
      return Some(place)
    }
  }
  None
}

///|
fn golden_valley_visual_building_for_place(
  place : @energy_valley_contract.Place,
) -> GoldenValleyBuilding? {
  match (place.building, town_canvas_place_bounds(place)) {
    (Some(profile), Some((x, y, width, depth))) => {
      let portal = place.primary_entrance()
      Some({
        authored_id: if place.provenance.kind
          is @energy_valley_contract.UserDelta {
          Some(place.id.local_key())
        } else {
          None
        },
        module_key: place.runtime_binding.map(binding => binding.resource_id),
        name: place.name,
        style: town_canvas_building_style(profile),
        x,
        y,
        width,
        depth,
        entrance_x: portal.map(value => value.position.x.floor().to_int()),
        entrance_y: portal.map(value => value.position.y.floor().to_int()),
        floors: profile.floors,
      })
    }
    _ => None
  }
}

///|
fn golden_valley_custom_building_for_place(
  model : Model,
  place : @energy_valley_contract.Place,
) -> GoldenValleyBuilding? {
  for building in energy_valley_model_buildings(model) {
    if ecosystem_contract_id(ecosystem_custom_place_id(building)) == place.id {
      return Some(building)
    }
  }
  None
}

///|
fn golden_valley_custom_building_at_model(
  model : Model,
  x : Int,
  y : Int,
) -> GoldenValleyBuilding? {
  let world = ecosystem_contract_world_for_model(
    model,
    active_energy_valley_seed(),
  )
  let point = @energy_valley_contract.world_point(
    x.to_double() + 0.5,
    y.to_double() + 0.5,
  )
  for place in world.places {
    if place.kind is @energy_valley_contract.Building &&
      place.footprint.contains_point(point) {
      match golden_valley_custom_building_for_place(model, place) {
        Some(building) => return Some(building)
        None => ()
      }
    }
  }
  None
}

///|
fn golden_valley_screen_to_tile(screen_x : Int, screen_y : Int) -> (Int, Int) {
  let width = golden_valley_canvas_width("energy-valley-canvas")
  let height = golden_valley_canvas_height("energy-valley-canvas")
  let zoom = golden_valley_camera_zoom()
  let projected_x = (screen_x.to_double() - width.to_double() / 2.0) / zoom +
    golden_valley_camera_x()
  let projected_y = (screen_y.to_double() - height.to_double() / 2.0) / zoom +
    golden_valley_camera_y()
  let world_x = (projected_x / 32.0 + projected_y / 16.0) / 2.0
  let world_y = (projected_y / 16.0 - projected_x / 32.0) / 2.0
  (world_x.floor().to_int(), world_y.floor().to_int())
}

///|
fn golden_valley_tool_cost(tool : EnergyTool) -> Int {
  match tool {
    RoadTool => 30
    ParkTool => 20
    ResearchTowerTool => 800
    LaboratoryTool => 500
    WorkshopTool => 400
    TalentHomeTool => 350
    InspectTool | DemolishTool => 0
  }
}

///|
fn golden_valley_custom_building(
  tool : EnergyTool,
  x : Int,
  y : Int,
  sequence : Int,
) -> GoldenValleyBuilding? {
  let scale = energy_valley_semantic_cells_per_planning_cell()
  let snapped_x = x / scale * scale
  let snapped_y = y / scale * scale
  let footprint = 2 * scale
  match tool {
    ResearchTowerTool =>
      Some({
        authored_id: None,
        module_key: None,
        name: "研发塔楼 \{sequence}",
        style: "custom-tower",
        x: snapped_x,
        y: snapped_y,
        width: footprint,
        depth: footprint,
        entrance_x: None,
        entrance_y: None,
        floors: 5,
      })
    LaboratoryTool =>
      Some({
        authored_id: None,
        module_key: None,
        name: "实验室 \{sequence}",
        style: "custom-lab",
        x: snapped_x,
        y: snapped_y,
        width: footprint,
        depth: footprint,
        entrance_x: None,
        entrance_y: None,
        floors: 2,
      })
    WorkshopTool =>
      Some({
        authored_id: None,
        module_key: None,
        name: "创新工坊 \{sequence}",
        style: "custom-hall",
        x: snapped_x,
        y: snapped_y,
        width: footprint,
        depth: footprint,
        entrance_x: None,
        entrance_y: None,
        floors: 2,
      })
    TalentHomeTool =>
      Some({
        authored_id: None,
        module_key: None,
        name: "人才公寓 \{sequence}",
        style: "custom-home",
        x: snapped_x,
        y: snapped_y,
        width: footprint,
        depth: footprint,
        entrance_x: None,
        entrance_y: None,
        floors: 3,
      })
    _ => None
  }
}

///|
fn golden_valley_contract_polygon_in_bounds(
  world : @energy_valley_contract.CompiledTownWorld,
  footprint : @energy_valley_contract.Polygon,
) -> Bool {
  footprint.vertices.all(vertex => world.bounds.contains(vertex))
}

///|
fn golden_valley_contract_buildable_parcel_for(
  world : @energy_valley_contract.CompiledTownWorld,
  footprint : @energy_valley_contract.Polygon,
) -> @energy_valley_contract.Parcel? {
  for parcel in world.parcels {
    if !golden_valley_contract_polygon_inside(parcel.boundary, footprint) {
      continue
    }
    match world.find_block(parcel.block_id) {
      Some(block) if block.parcelable =>
        for region in block.effective_buildable_regions() {
          if region.land_use == parcel.land_use &&
            golden_valley_contract_polygon_inside(region.boundary, footprint) {
            return Some(parcel)
          }
        }
      _ => ()
    }
  }
  None
}

///|
fn golden_valley_contract_node_is_street(
  world : @energy_valley_contract.CompiledTownWorld,
  node_id : @energy_valley_contract.StableId,
) -> Bool {
  world.road_network.segments.any(segment => {
    (segment.from_node_id == node_id || segment.to_node_id == node_id) &&
    segment.supports(@energy_valley_contract.ServiceVehicle)
  })
}

///|
fn golden_valley_contract_road_node_at(
  world : @energy_valley_contract.CompiledTownWorld,
  x : Int,
  y : Int,
) -> @energy_valley_contract.RoadNode? {
  for node in world.road_network.nodes {
    if node.grid.column == x &&
      node.grid.row == y &&
      golden_valley_contract_node_is_street(world, node.id) {
      return Some(node)
    }
  }
  None
}

///|
fn golden_valley_contract_road_candidate_connected(
  world : @energy_valley_contract.CompiledTownWorld,
  x : Int,
  y : Int,
) -> Bool {
  for delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
    match golden_valley_contract_road_node_at(world, x + delta.0, y + delta.1) {
      Some(node) if world.road_network.is_reachable_from_anchor(
          node.id,
          mode=@energy_valley_contract.ServiceVehicle,
        ) => return true
      _ => ()
    }
  }
  false
}

///|
fn golden_valley_contract_user_park_at(
  world : @energy_valley_contract.CompiledTownWorld,
  x : Int,
  y : Int,
) -> Bool {
  let id = ecosystem_contract_id(
    ecosystem_scoped_id("place", "public-park-\{x}-\{y}"),
  )
  match world.find_place(id) {
    Some(place) =>
      place.kind is @energy_valley_contract.Park &&
      place.footprint.contains_point(
        @energy_valley_contract.world_point(
          x.to_double() + 0.5,
          y.to_double() + 0.5,
        ),
      )
    None => false
  }
}

///|
fn golden_valley_tile_placement_block_in_world(
  world : @energy_valley_contract.CompiledTownWorld,
  x : Int,
  y : Int,
) -> GoldenValleyPlacementBlock? {
  let footprint = golden_valley_contract_tile_footprint(x, y)
  if !golden_valley_contract_polygon_in_bounds(world, footprint) {
    return Some(PlacementOutOfBounds)
  }
  if golden_valley_contract_user_park_at(world, x, y) {
    return Some(PlacementUserPark)
  }
  if golden_valley_contract_road_node_at(world, x, y) is Some(_) {
    return Some(PlacementTransportOrWater)
  }
  match ecosystem_contract_terrain_kind_at(world, x, y) {
    Some(@energy_valley_contract.Water) =>
      return Some(PlacementTransportOrWater)
    Some(@energy_valley_contract.Wetland) =>
      return Some(PlacementProtectedWetland)
    Some(@energy_valley_contract.Restricted) | None =>
      return Some(PlacementOutsideBuildableParcel)
    _ => ()
  }
  if golden_valley_contract_place_at(world, x, y) is Some(_) {
    return Some(PlacementOccupied)
  }
  if golden_valley_contract_buildable_parcel_for(world, footprint) is None {
    return Some(PlacementOutsideBuildableParcel)
  }
  None
}

///|
fn golden_valley_tile_placement_block(
  model : Model,
  x : Int,
  y : Int,
) -> GoldenValleyPlacementBlock? {
  let world = ecosystem_contract_world_for_model(
    model,
    active_energy_valley_seed(),
  )
  golden_valley_tile_placement_block_in_world(world, x, y)
}

///|
fn golden_valley_custom_building_has_road_access_in_world(
  world : @energy_valley_contract.CompiledTownWorld,
  building : GoldenValleyBuilding,
) -> Bool {
  for x in building.x..<(building.x + building.width) {
    for y in [building.y - 1, building.y + building.depth] {
      match golden_valley_contract_road_node_at(world, x, y) {
        Some(node) if world.road_network.is_reachable_from_anchor(
            node.id,
            mode=@energy_valley_contract.ServiceVehicle,
          ) => return true
        _ => ()
      }
    }
  }
  for y in building.y..<(building.y + building.depth) {
    for x in [building.x - 1, building.x + building.width] {
      match golden_valley_contract_road_node_at(world, x, y) {
        Some(node) if world.road_network.is_reachable_from_anchor(
            node.id,
            mode=@energy_valley_contract.ServiceVehicle,
          ) => return true
        _ => ()
      }
    }
  }
  false
}

///|
fn golden_valley_custom_building_has_road_access(
  model : Model,
  building : GoldenValleyBuilding,
) -> Bool {
  let world = ecosystem_contract_world_for_model(
    model,
    active_energy_valley_seed(),
  )
  golden_valley_custom_building_has_road_access_in_world(world, building)
}

///|
fn golden_valley_custom_placement_block_in_world(
  world : @energy_valley_contract.CompiledTownWorld,
  building : GoldenValleyBuilding,
) -> GoldenValleyPlacementBlock? {
  let footprint = golden_valley_contract_building_footprint(building)
  if !golden_valley_contract_polygon_in_bounds(world, footprint) {
    return Some(PlacementOutOfBounds)
  }
  for y in building.y..<(building.y + building.depth) {
    for x in building.x..<(building.x + building.width) {
      match golden_valley_tile_placement_block_in_world(world, x, y) {
        Some(block) => return Some(block)
        None => ()
      }
    }
  }
  if golden_valley_contract_buildable_parcel_for(world, footprint) is None {
    return Some(PlacementOutsideBuildableParcel)
  }
  if !golden_valley_custom_building_has_road_access_in_world(world, building) {
    return Some(PlacementNeedsRoad)
  }
  None
}

///|
fn golden_valley_custom_placement_block(
  model : Model,
  building : GoldenValleyBuilding,
) -> GoldenValleyPlacementBlock? {
  let world = ecosystem_contract_world_for_model(
    model,
    active_energy_valley_seed(),
  )
  golden_valley_custom_placement_block_in_world(world, building)
}

///|
fn golden_valley_custom_placement_clear(
  model : Model,
  building : GoldenValleyBuilding,
) -> Bool {
  golden_valley_custom_placement_block(model, building) is None
}

///|
fn golden_valley_reposition_custom_building(
  building : GoldenValleyBuilding,
  x : Int,
  y : Int,
) -> GoldenValleyBuilding {
  { ..building, x, y }
}

///|
fn golden_valley_resolve_custom_building(
  model : Model,
  requested : GoldenValleyBuilding,
) -> GoldenValleyBuilding? {
  let world = ecosystem_contract_world_for_model(
    model,
    active_energy_valley_seed(),
  )
  let scale = energy_valley_semantic_cells_per_planning_cell()
  let search_steps = 4
  for distance in 0..<=search_steps {
    for y_step in -distance..<=distance {
      for x_step in -distance..<=distance {
        if abs_int(x_step) + abs_int(y_step) != distance {
          continue
        }
        let candidate = golden_valley_reposition_custom_building(
          requested,
          requested.x + x_step * scale,
          requested.y + y_step * scale,
        )
        if golden_valley_custom_placement_block_in_world(world, candidate)
          is None {
          return Some(candidate)
        }
      }
    }
  }
  None
}

///|
fn golden_valley_placement_block_message(
  block : GoldenValleyPlacementBlock,
) -> String {
  match block {
    PlacementOutOfBounds => "建筑地块超出能源谷边界"
    PlacementTransportOrWater =>
      "建筑占地跨越道路或水域，请选择更开阔的临路空地"
    PlacementProtectedWetland =>
      "建筑占地包含湿地保护区，请换一处临路空地"
    PlacementOutsideBuildableParcel =>
      "此处不在道路围合的可建设地块内，请选择有明确边界的临路地块"
    PlacementUserPark => "此处已有人工林地，请先拆除再建设"
    PlacementOccupied => "此处已有建筑，请选择附近空地"
    PlacementNeedsRoad =>
      "附近没有可用的临路地块，请靠近道路选择或先铺路"
    PlacementSiteContractRejected =>
      "建筑站点未能接入统一地块与入口契约，请换一处临路地块"
  }
}

///|
fn golden_valley_canonical_building_active(
  model : Model,
  building : GoldenValleyBuilding,
) -> Bool {
  match golden_valley_nonempty_authored_id(building) {
    None => false
    Some(id) =>
      match town_life_world_current_incarnation(model, WorldBuilding, id) {
        Some(incarnation) =>
          match town_life_world_effective_payload(incarnation) {
            WorldBuildingPayload(active) =>
              ToJson::to_json(active).stringify() ==
              ToJson::to_json(building).stringify()
            _ => false
          }
        None => false
      }
  }
}

///|
fn golden_valley_canonical_road_active(model : Model, x : Int, y : Int) -> Bool {
  town_life_world_current_incarnation(
    model,
    WorldRoadCell,
    "road-cell-\{x}-\{y}",
  )
  is Some(_)
}

///|
fn golden_valley_canonical_park_active(model : Model, x : Int, y : Int) -> Bool {
  town_life_world_current_incarnation(
    model,
    WorldPark,
    energy_valley_saved_park_id(x, y),
  )
  is Some(_)
}

///|
fn golden_valley_place_custom_building_model(
  model : Model,
  x : Int,
  y : Int,
) -> Model {
  let sequence = golden_valley_next_free_authored_sequence(
    energy_valley_model_buildings(model),
    energy_valley_model_next_authored_building_sequence(model),
  )
  match golden_valley_custom_building(model.energy_tool, x, y, sequence) {
    None => model
    Some(requested) => {
      let cost = golden_valley_tool_cost(model.energy_tool)
      if energy_valley_model_budget(model) < cost {
        { ..model, energy_toast: "预算不足" }
      } else {
        match golden_valley_tile_placement_block(model, x, y) {
          Some(block) =>
            {
              ..model,
              energy_toast: golden_valley_placement_block_message(block),
            }
          None =>
            match golden_valley_resolve_custom_building(model, requested) {
              None =>
                {
                  ..model,
                  energy_toast: golden_valley_placement_block_message(
                    golden_valley_custom_placement_block(model, requested).unwrap_or(
                      PlacementNeedsRoad,
                    ),
                  ),
                }
              Some(building) => {
                let adjusted = building.x != requested.x ||
                  building.y != requested.y
                let (with_building, identified) = energy_valley_model_add_building_delta_with_identity(
                  model,
                  building,
                  energy_valley_model_budget(model) - cost,
                  energy_valley_model_next_authored_building_sequence(model),
                )
                let candidate = {
                  ..with_building,
                  energy_selected_building: Some(identified),
                  energy_toast: if adjusted {
                    "\{identified.name} 已开工（-\{cost}，已吸附到最近临路空地）"
                  } else {
                    "\{identified.name} 已开工（-\{cost}）"
                  },
                }
                if golden_valley_canonical_building_active(
                    candidate, identified,
                  ) {
                  candidate
                } else {
                  {
                    ..model,
                    energy_toast: golden_valley_placement_block_message(
                      PlacementSiteContractRejected,
                    ),
                  }
                }
              }
            }
        }
      }
    }
  }
}

///|
fn golden_valley_place_road_model(model : Model, x : Int, y : Int) -> Model {
  let world = ecosystem_contract_world_for_model(
    model,
    active_energy_valley_seed(),
  )
  let footprint = golden_valley_contract_tile_footprint(x, y)
  if !golden_valley_contract_polygon_in_bounds(world, footprint) {
    return { ..model, energy_toast: "这里不在能源谷范围内" }
  }
  if golden_valley_contract_road_node_at(world, x, y) is Some(_) {
    return { ..model, energy_toast: "已是道路" }
  }
  if golden_valley_contract_place_at(world, x, y) is Some(_) {
    return { ..model, energy_toast: "先拆除建筑或设施" }
  }
  let terrain = ecosystem_contract_terrain_kind_at(world, x, y)
  let cost = match terrain {
    Some(@energy_valley_contract.Water) => 120
    Some(@energy_valley_contract.Meadow)
    | Some(@energy_valley_contract.Woodland)
    | Some(@energy_valley_contract.Custom(_)) => 30
    _ => 0
  }
  match terrain {
    Some(@energy_valley_contract.Meadow)
    | Some(@energy_valley_contract.Woodland)
    | Some(@energy_valley_contract.Water)
    | Some(@energy_valley_contract.Custom(_)) => ()
    Some(@energy_valley_contract.Paving) =>
      return {
        ..model,
        energy_toast: "道路仅可铺在自然地表或河面",
      }
    Some(@energy_valley_contract.Wetland) =>
      return { ..model, energy_toast: "湿地保护区不可铺路" }
    Some(@energy_valley_contract.Restricted) | None =>
      return { ..model, energy_toast: "这里不在可铺路区域内" }
  }
  if energy_valley_model_budget(model) < cost {
    return { ..model, energy_toast: "预算不足" }
  }
  let key = golden_valley_tile_key(x, y)
  let current_roads = energy_valley_model_roads(model)
  if current_roads.contains(key) {
    return model
  }
  if !golden_valley_contract_road_candidate_connected(world, x, y) {
    return {
      ..model,
      energy_toast: "新道路必须与现有路网正交相连",
    }
  }
  let with_road = energy_valley_model_replace_roads_delta(
    model,
    current_roads + [key],
    energy_valley_model_budget(model) - cost,
  )
  let candidate = {
    ..with_road,
    energy_toast: if terrain is Some(@energy_valley_contract.Water) {
      "新桥贯通温榆河（-\{cost}）"
    } else {
      "道路已铺设（-\{cost}）"
    },
  }
  if golden_valley_canonical_road_active(candidate, x, y) {
    candidate
  } else {
    {
      ..model,
      energy_toast: "新道路未能接入统一路网，请从现有道路继续铺设",
    }
  }
}

///|
fn golden_valley_place_park_model(model : Model, x : Int, y : Int) -> Model {
  let world = ecosystem_contract_world_for_model(
    model,
    active_energy_valley_seed(),
  )
  let footprint = golden_valley_contract_tile_footprint(x, y)
  if !golden_valley_contract_polygon_in_bounds(world, footprint) {
    return { ..model, energy_toast: "这里不在能源谷范围内" }
  }
  if golden_valley_contract_user_park_at(world, x, y) {
    return model
  }
  if golden_valley_contract_road_node_at(world, x, y) is Some(_) ||
    golden_valley_contract_place_at(world, x, y) is Some(_) ||
    ecosystem_contract_terrain_kind_at(world, x, y) !=
    Some(@energy_valley_contract.Meadow) {
    return { ..model, energy_toast: "仅可改造草地、草甸或农田" }
  }
  if golden_valley_contract_buildable_parcel_for(world, footprint) is None {
    return {
      ..model,
      energy_toast: "此处不在道路围合的可改造地块内",
    }
  }
  if energy_valley_model_budget(model) < 20 {
    return { ..model, energy_toast: "预算不足" }
  }
  let with_park = energy_valley_model_add_park_delta(
    model,
    x,
    y,
    energy_valley_model_budget(model) - 20,
  )
  let candidate = { ..with_park, energy_toast: "造林已完成（-20）" }
  if golden_valley_canonical_park_active(candidate, x, y) {
    candidate
  } else {
    {
      ..model,
      energy_toast: "林地未能接入统一地块契约，请换一处地块",
    }
  }
}

///|
fn golden_valley_building_refund(building : GoldenValleyBuilding) -> Int {
  let tool = match building.style {
    "tower" | "custom-tower" => ResearchTowerTool
    "lab" | "custom-lab" => LaboratoryTool
    "home" | "custom-home" => TalentHomeTool
    _ => WorkshopTool
  }
  (golden_valley_tool_cost(tool) + 1) / 2
}

///|
fn golden_valley_demolish_at_model(model : Model, x : Int, y : Int) -> Model {
  let world = ecosystem_contract_world_for_model(
    model,
    active_energy_valley_seed(),
  )
  let key = golden_valley_tile_key(x, y)
  let all_buildings = energy_valley_model_buildings(model)
  let removed = golden_valley_custom_building_at_model(model, x, y)
  let removed_buildings = match removed {
    Some(building) => [building]
    None => []
  }
  let refund = removed.map(golden_valley_building_refund).unwrap_or(0)
  let posts = knowledge_posts_after_demolition(
    model.posts,
    removed_buildings,
    all_buildings,
  )
  let removed_shared_post = model.posts.any(post => {
    post.mine &&
    post.published &&
    !posts.any(candidate => {
      candidate.incarnation_id == post.incarnation_id && candidate.id == post.id
    })
  })
  let removable_road = match golden_valley_contract_road_node_at(world, x, y) {
    Some(node) =>
      node.provenance.kind is @energy_valley_contract.UserDelta &&
      energy_valley_model_roads(model).contains(key)
    None => false
  }
  let removable_park = golden_valley_contract_user_park_at(world, x, y) &&
    energy_valley_model_parks(model).contains(key)
  if removed is None && !removable_road && !removable_park {
    return { ..model, energy_toast: "这里没有可拆除的内容" }
  }
  let after_building = match removed {
    Some(building) =>
      energy_valley_model_delete_building_delta(
        model,
        building,
        energy_valley_model_budget(model) + refund,
      )
    None => model
  }
  let after_road = if removable_road {
    energy_valley_model_replace_roads_delta(
      after_building,
      energy_valley_model_roads(after_building).filter(item => item != key),
      energy_valley_model_budget(after_building),
    )
  } else {
    after_building
  }
  let after_park = if removable_park {
    energy_valley_model_delete_park_delta(
      after_road,
      x,
      y,
      energy_valley_model_budget(after_road),
    )
  } else {
    after_road
  }
  let candidate = town_life_with_post_deletions(
    {
      ..after_park,
      energy_selected_building: None,
      energy_toast: if removed_shared_post {
        "建筑及本机知识条目已移除（+\{refund}）；已发出的分享链接无法远程撤回"
      } else if refund > 0 {
        "建筑已拆除（+\{refund}）"
      } else {
        "该地块已拆除"
      },
    },
    model.posts,
    posts,
  )
  if removable_road && golden_valley_canonical_road_active(candidate, x, y) {
    return {
      ..model,
      energy_toast: "这段道路仍连接建筑或共建路网，暂不能拆除",
    }
  }
  candidate
}

///|
fn energy_valley_canvas_click_model(
  model : Model,
  screen_x : Int,
  screen_y : Int,
) -> Model {
  let (x, y) = golden_valley_screen_to_tile(screen_x, screen_y)
  match model.energy_tool {
    InspectTool =>
      match golden_valley_canvas_frame() {
        None =>
          { ..model, energy_toast: "地图帧尚未就绪，请稍后再试" }
        Some(snapshot) => {
          if !golden_valley_contract_polygon_in_bounds(
              snapshot.world,
              golden_valley_contract_tile_footprint(x, y),
            ) {
            return { ..model, energy_toast: "这里不在能源谷范围内" }
          }
          match town_snapshot_canvas_building_at_tile(snapshot, x, y) {
            None =>
              {
                ..model,
                selection: Overview,
                energy_selected_building: None,
                energy_toast: "",
              }
            Some(semantic_building) => {
              golden_focus_building_camera(
                semantic_building.x.to_double() +
                semantic_building.width.to_double() / 2.0,
                semantic_building.y.to_double() +
                semantic_building.depth.to_double() / 2.0,
              )
              {
                ..model,
                selection: Overview,
                energy_board_open: false,
                energy_selected_building: Some(semantic_building.visual()),
                energy_toast: "",
              }
            }
          }
        }
      }
    RoadTool
    | ParkTool
    | DemolishTool
    | ResearchTowerTool
    | LaboratoryTool
    | WorkshopTool
    | TalentHomeTool => {
      let world = ecosystem_contract_world_for_model(
        model,
        active_energy_valley_seed(),
      )
      if !golden_valley_contract_polygon_in_bounds(
          world,
          golden_valley_contract_tile_footprint(x, y),
        ) {
        return { ..model, energy_toast: "这里不在能源谷范围内" }
      }
      match model.energy_tool {
        RoadTool => golden_valley_place_road_model(model, x, y)
        ParkTool => golden_valley_place_park_model(model, x, y)
        DemolishTool => golden_valley_demolish_at_model(model, x, y)
        ResearchTowerTool | LaboratoryTool | WorkshopTool | TalentHomeTool =>
          golden_valley_place_custom_building_model(model, x, y)
        InspectTool => model
      }
    }
  }
}

///|
fn energy_valley_open_registered_building_model(
  model : Model,
  building_id : String,
) -> Model {
  let world = ecosystem_contract_world_for_model(
    model,
    active_energy_valley_seed(),
  )
  let buildings : Array[GoldenValleyBuilding] = []
  for place in world.places {
    if place.kind is @energy_valley_contract.Building {
      match golden_valley_custom_building_for_place(model, place) {
        Some(custom) => buildings.push(custom)
        None =>
          match golden_valley_visual_building_for_place(place) {
            Some(building) => buildings.push(building)
            None => ()
          }
      }
    }
  }
  match golden_valley_building_for_identity(buildings, building_id) {
    None =>
      {
        ..model,
        energy_toast: "The selected runtime building is not on this map.",
      }
    Some(building) => {
      golden_focus_building_camera(
        building.x.to_double() + building.width.to_double() / 2.0,
        building.y.to_double() + building.depth.to_double() / 2.0,
      )
      {
        ..model,
        energy_board_open: false,
        energy_selected_building: Some(building),
        energy_tool: InspectTool,
        energy_toast: "",
      }
    }
  }
}
