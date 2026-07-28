///|
fn golden_valley_tile_key(x : Int, y : Int) -> String {
  "\{x}:\{y}"
}

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
fn golden_valley_building_at_model(
  model : Model,
  x : Int,
  y : Int,
) -> GoldenValleyBuilding? {
  for building in model.energy_custom_buildings {
    if golden_valley_building_contains(building, x, y) {
      return Some(building)
    }
  }
  for building in golden_valley_buildings(active_energy_valley_seed()) {
    if golden_valley_building_contains(building, x, y) {
      return Some(building)
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
  match tool {
    ResearchTowerTool =>
      Some({
        name: "研发塔楼 \{sequence}",
        style: "custom-tower",
        x,
        y,
        width: 2,
        depth: 2,
        floors: 5,
      })
    LaboratoryTool =>
      Some({
        name: "实验室 \{sequence}",
        style: "custom-lab",
        x,
        y,
        width: 2,
        depth: 2,
        floors: 2,
      })
    WorkshopTool =>
      Some({
        name: "创新工坊 \{sequence}",
        style: "custom-hall",
        x,
        y,
        width: 2,
        depth: 2,
        floors: 2,
      })
    TalentHomeTool =>
      Some({
        name: "人才公寓 \{sequence}",
        style: "custom-home",
        x,
        y,
        width: 2,
        depth: 2,
        floors: 3,
      })
    _ => None
  }
}

///|
fn golden_valley_custom_placement_clear(
  model : Model,
  building : GoldenValleyBuilding,
) -> Bool {
  if building.x < 1 ||
    building.y < 1 ||
    building.x + building.width >= golden_valley_cols() - 1 ||
    building.y + building.depth >= golden_valley_rows() - 1 {
    return false
  }
  for y in building.y..<(building.y + building.depth) {
    for x in building.x..<(building.x + building.width) {
      let terrain = golden_valley_terrain(
        model,
        active_energy_valley_seed(),
        x,
        y,
      )
      if (terrain != "grass" && terrain != "meadow" && terrain != "plaza") ||
        golden_valley_building_at_model(model, x, y) is Some(_) {
        return false
      }
    }
  }
  for x in (building.x - 1)..<=(building.x + building.width) {
    for y in (building.y - 1)..<=(building.y + building.depth) {
      let on_edge = x == building.x - 1 ||
        x == building.x + building.width ||
        y == building.y - 1 ||
        y == building.y + building.depth
      if on_edge {
        let terrain = golden_valley_terrain(
          model,
          active_energy_valley_seed(),
          x,
          y,
        )
        if terrain == "road" || terrain == "bridge" {
          return true
        }
      }
    }
  }
  false
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
fn energy_valley_canvas_click_model(
  model : Model,
  screen_x : Int,
  screen_y : Int,
) -> Model {
  let (x, y) = golden_valley_screen_to_tile(screen_x, screen_y)
  if x < 0 || x >= golden_valley_cols() || y < 0 || y >= golden_valley_rows() {
    return { ..model, energy_toast: "这里不在能源谷范围内" }
  }
  match model.energy_tool {
    InspectTool =>
      match golden_valley_building_at_model(model, x, y) {
        None => { ..model, energy_selected_building: None, energy_toast: "" }
        Some(building) => {
          golden_focus_building_camera(
            building.x.to_double() + building.width.to_double() / 2.0,
            building.y.to_double() + building.depth.to_double() / 2.0,
          )
          {
            ..model,
            energy_board_open: false,
            energy_selected_building: Some(building),
            energy_toast: "",
          }
        }
      }
    RoadTool => {
      let key = golden_valley_tile_key(x, y)
      let terrain = golden_valley_terrain(
        model,
        active_energy_valley_seed(),
        x,
        y,
      )
      let cost = if terrain == "water" { 120 } else { 30 }
      if golden_valley_building_at_model(model, x, y) is Some(_) {
        { ..model, energy_toast: "先拆除建筑" }
      } else if terrain == "road" || terrain == "bridge" {
        { ..model, energy_toast: "已是道路" }
      } else if terrain == "urban" || terrain == "plaza" {
        { ..model, energy_toast: "道路仅可铺在自然地表或河面" }
      } else if model.energy_build_budget < cost {
        { ..model, energy_toast: "预算不足" }
      } else if model.energy_roads.contains(key) {
        model
      } else {
        {
          ..model,
          energy_roads: model.energy_roads + [key],
          energy_build_budget: model.energy_build_budget - cost,
          energy_toast: if terrain == "water" {
            "新桥贯通温榆河（-\{cost}）"
          } else {
            "道路已铺设（-\{cost}）"
          },
        }
      }
    }
    ParkTool => {
      let key = golden_valley_tile_key(x, y)
      let terrain = golden_valley_terrain(
        model,
        active_energy_valley_seed(),
        x,
        y,
      )
      if golden_valley_building_at_model(model, x, y) is Some(_) ||
        (terrain != "grass" && terrain != "meadow" && terrain != "field") {
        { ..model, energy_toast: "仅可改造草地、草甸或农田" }
      } else if model.energy_build_budget < 20 {
        { ..model, energy_toast: "预算不足" }
      } else if model.energy_parks.contains(key) {
        model
      } else {
        {
          ..model,
          energy_parks: model.energy_parks + [key],
          energy_build_budget: model.energy_build_budget - 20,
          energy_toast: "造林已完成（-20）",
        }
      }
    }
    DemolishTool => {
      let key = golden_valley_tile_key(x, y)
      let buildings = model.energy_custom_buildings.filter(building => {
        !golden_valley_building_contains(building, x, y)
      })
      let removed_building = buildings.length() <
        model.energy_custom_buildings.length()
      let mut refund = 0
      if removed_building {
        for building in model.energy_custom_buildings {
          if golden_valley_building_contains(building, x, y) {
            refund = golden_valley_building_refund(building)
          }
        }
      }
      let roads = model.energy_roads.filter(item => item != key)
      let parks = model.energy_parks.filter(item => item != key)
      if !removed_building &&
        roads.length() == model.energy_roads.length() &&
        parks.length() == model.energy_parks.length() {
        { ..model, energy_toast: "这里没有可拆除的内容" }
      } else {
        {
          ..model,
          energy_custom_buildings: buildings,
          energy_roads: roads,
          energy_parks: parks,
          energy_build_budget: model.energy_build_budget + refund,
          energy_selected_building: None,
          energy_toast: if refund > 0 {
            "建筑已拆除（+\{refund}）"
          } else {
            "该地块已拆除"
          },
        }
      }
    }
    ResearchTowerTool | LaboratoryTool | WorkshopTool | TalentHomeTool =>
      match
        golden_valley_custom_building(
          model.energy_tool,
          x,
          y,
          model.energy_custom_buildings.length() + 1,
        ) {
        None => model
        Some(building) => {
          let cost = golden_valley_tool_cost(model.energy_tool)
          if model.energy_build_budget < cost {
            { ..model, energy_toast: "预算不足" }
          } else if !golden_valley_custom_placement_clear(model, building) {
            {
              ..model,
              energy_toast: "此处与道路、水域或既有建筑冲突",
            }
          } else {
            {
              ..model,
              energy_custom_buildings: model.energy_custom_buildings +
              [building],
              energy_build_budget: model.energy_build_budget - cost,
              energy_selected_building: Some(building),
              energy_toast: "\{building.name} 已开工（-\{cost}）",
            }
          }
        }
      }
  }
}
