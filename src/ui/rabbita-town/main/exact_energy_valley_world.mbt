///|
/// The canvas world is an adapter over the original 256 × 144 Wenyu semantic
/// map. Terrain comes from the authored reference labels plus the procedural
/// Energy Valley grammar; civic buildings use the same collision-aware
/// placement process as the original large-map renderer.
pub fn exact_energy_valley_cols() -> Int {
  tilemap_grid_width()
}

///|
pub fn exact_energy_valley_rows() -> Int {
  tilemap_grid_height()
}

///|
pub fn exact_energy_valley_default_seed() -> UInt {
  default_energy_valley_seed.reinterpret_as_uint()
}

///|
pub(all) struct ExactEnergyValleyTile {
  mut terrain : String
  mut base_terrain : String
  mut generated_terrain : String
  mut district : String
  variation : Double
  mut building_id : String?
  mut river_flow : Double?
  mut road_mask : Int?
  mut structure : String?
  mut structure_floors : Int?
  mut structure_width : Int?
  mut structure_depth : Int?
} derive(Debug)

///|
pub(all) struct ExactEnergyValleyBuilding {
  id : String
  archetype : String
  module_key : String
  name : String
  glyph : String
  style : String
  x : Int
  y : Int
  width : Int
  depth : Int
  entrance_x : Int
  entrance_y : Int
  floors : Int
  vitality : Double
} derive(Debug)

///|
pub(all) struct ExactEnergyValleyLandmarks {
  civic_core_x : Int
  civic_core_y : Int
  river_crossing_y : Int
  feeder_head_x : Int
  bridge_columns : Array[Int]
  south_arterial_y : Int
} derive(Debug)

///|
pub(all) struct ExactEnergyValleyWorld {
  seed : UInt
  cols : Int
  rows : Int
  tiles : Array[Array[ExactEnergyValleyTile]]
  buildings : Array[ExactEnergyValleyBuilding]
  landmarks : ExactEnergyValleyLandmarks
} derive(Debug)

///|
pub fn ExactEnergyValleyWorld::tile_at(
  self : ExactEnergyValleyWorld,
  x : Int,
  y : Int,
) -> ExactEnergyValleyTile? {
  if x < 0 || x >= self.cols || y < 0 || y >= self.rows {
    None
  } else {
    Some(self.tiles[y][x])
  }
}

///|
pub fn ExactEnergyValleyWorld::terrain_at(
  self : ExactEnergyValleyWorld,
  x : Int,
  y : Int,
) -> String? {
  match self.tile_at(x, y) {
    Some(tile) => Some(tile.terrain)
    None => None
  }
}

///|
pub fn ExactEnergyValleyWorld::variation_at(
  self : ExactEnergyValleyWorld,
  x : Int,
  y : Int,
) -> Double? {
  match self.tile_at(x, y) {
    Some(tile) => Some(tile.variation)
    None => None
  }
}

///|
pub fn ExactEnergyValleyWorld::structure_at(
  self : ExactEnergyValleyWorld,
  x : Int,
  y : Int,
) -> (String, Int)? {
  match self.tile_at(x, y) {
    Some(tile) =>
      match (tile.structure, tile.structure_floors) {
        (Some(kind), Some(floors)) => Some((kind, floors))
        _ => None
      }
    None => None
  }
}

///|
fn ExactEnergyValleyWorld::structure_footprint_at(
  self : ExactEnergyValleyWorld,
  x : Int,
  y : Int,
) -> (String, Int, Int, Int)? {
  match self.tile_at(x, y) {
    Some(tile) =>
      match
        (
          tile.structure,
          tile.structure_floors,
          tile.structure_width,
          tile.structure_depth,
        ) {
        (Some(kind), Some(floors), Some(width), Some(depth)) =>
          Some((kind, floors, width, depth))
        _ => None
      }
    None => None
  }
}

///|
pub fn ExactEnergyValleyWorld::building_for_module(
  self : ExactEnergyValleyWorld,
  module_key : String,
) -> ExactEnergyValleyBuilding? {
  for building in self.buildings {
    if building.module_key == module_key {
      return Some(building)
    }
  }
  None
}

///|
fn exact_energy_valley_template(
  id : String,
  title : String,
  district : String,
  building_kind : String,
  grid_x : Int,
  grid_y : Int,
  footprint_w : Int,
  footprint_h : Int,
) -> WenyuTownModule {
  {
    id,
    enabled: true,
    title,
    book_id: id,
    district,
    building_kind,
    grid_x,
    grid_y,
    footprint_w,
    footprint_h,
    display_w: footprint_w * 32,
    display_h: footprint_h * 24,
    entrance_x: grid_x,
    entrance_y: grid_y + footprint_h,
    interior_kind: building_kind,
    style_family: "wenyu-reference",
    asset_base: "",
    protocol_pattern: "",
    use_case: "",
    agent_flow: "arrive / work / review / depart",
    summary: title,
  }
}

///|
fn exact_energy_valley_builtin_templates() -> Array[WenyuTownModule] {
  [
    exact_energy_valley_template(
      "town-shell", "Town Shell", "civic-core", "town-shell", 128, 72, 8, 6,
    ),
    exact_energy_valley_template(
      "policy-hall", "Policy Hall", "civic-core", "policy-hall", 114, 66, 7, 5,
    ),
    exact_energy_valley_template(
      "vitality-dashboard", "Vitality Tower", "civic-core", "vitality-dashboard",
      142, 65, 5, 5,
    ),
    exact_energy_valley_template(
      "contest-express", "Contest Express", "north-innovation", "contest-express",
      101, 57, 7, 5,
    ),
    exact_energy_valley_template(
      "broadcast-tower", "Story Radar", "north-innovation", "broadcast-tower", 111,
      50, 5, 5,
    ),
    exact_energy_valley_template(
      "resident-twins", "Resident Twin Homes", "west-community", "resident-twins",
      97, 84, 7, 5,
    ),
    exact_energy_valley_template(
      "ai-garden", "AI Science Garden", "lake-learning", "ai-garden", 112, 87, 7,
      6,
    ),
    exact_energy_valley_template(
      "social-square", "Social Square", "lake-exchange", "social-square", 131, 87,
      8, 6,
    ),
    exact_energy_valley_template(
      "research-embodied-robotics", "Robotics Lab", "lake-exchange", "research-embodied-robotics",
      122, 104, 8, 6,
    ),
    exact_energy_valley_template(
      "research-ai-agents", "AI Agents Lab", "lake-exchange", "research-ai-agents",
      138, 101, 7, 6,
    ),
    exact_energy_valley_template(
      "talent-avenue", "Talent Avenue", "south-showcase", "talent-avenue", 154, 92,
      10, 5,
    ),
    exact_energy_valley_template(
      "valley-market", "Valley Market", "south-showcase", "valley-market", 168, 108,
      8, 5,
    ),
    exact_energy_valley_template(
      "physical-bridge", "Physical Bridge", "east-river", "physical-bridge", 179,
      80, 8, 5,
    ),
    exact_energy_valley_template(
      "research-opc", "OPC Research", "west-research", "research-opc", 85, 70, 6,
      5,
    ),
    exact_energy_valley_template(
      "research-llm-training", "LLM Training Lab", "north-research", "research-llm-training",
      142, 51, 8, 6,
    ),
    exact_energy_valley_template(
      "research-ai-hardware", "AI Hardware Lab", "east-research", "research-ai-hardware",
      155, 71, 8, 6,
    ),
  ]
}

///|
fn exact_energy_valley_module_templates() -> Array[WenyuTownModule] {
  let configured = parse_bootstrap_wenyu_modules()
  if configured.is_empty() {
    exact_energy_valley_builtin_templates()
  } else {
    configured
  }
}

///|
fn exact_energy_valley_canvas_terrain(kind : String) -> String {
  match kind {
    "river" | "lake" => "water"
    "road-major" | "road" => "road"
    "farm" | "field" => "field"
    "grass-flower-pink" | "grass-flower-yellow" | "grass-light" => "meadow"
    "urban-dense" | "urban" => "urban"
    "campus" => "plaza"
    other => other
  }
}

///|
fn exact_energy_valley_procedural_structure(
  seed : Int,
  x : Int,
  y : Int,
  kind : String,
) -> (String, Int)? {
  if kind != "urban-dense" && kind != "urban" && kind != "campus" {
    return None
  }
  let parcel_size = if kind == "campus" { 3 } else { 2 }
  let parcel_x = x / parcel_size
  let parcel_y = y / parcel_size
  let phase_x = energy_valley_variation(seed, x / 12, y / 12, 419, 5)
  let phase_y = energy_valley_variation(seed, x / 12, y / 12, 421, 5)
  if energy_valley_mod(x + phase_x, 5) == 0 ||
    energy_valley_mod(y + phase_y, 5) == 0 {
    return None
  }
  let density = if kind == "urban-dense" {
    70
  } else if kind == "urban" {
    62
  } else {
    48
  }
  if energy_valley_variation(seed, parcel_x, parcel_y, 431, 100) >= density {
    return None
  }
  let roll = energy_valley_variation(seed, parcel_x, parcel_y, 433, 100)
  let floors = energy_valley_variation(seed, parcel_x, parcel_y, 439, 5)
  if kind == "urban-dense" {
    if roll < 14 {
      Some(("tower", 5 + floors))
    } else if roll < 58 {
      Some(("block", 2 + floors % 3))
    } else if roll < 84 {
      Some(("row", 2 + floors % 3))
    } else {
      Some(("courtyard", 2 + floors % 2))
    }
  } else if kind == "urban" {
    if roll < 46 {
      Some(("lowrise", 1 + floors % 2))
    } else if roll < 76 {
      Some(("row", 1 + floors % 3))
    } else {
      Some(("courtyard", 1 + floors % 2))
    }
  } else if roll < 62 {
    Some(("campus", 1 + floors % 2))
  } else if roll < 84 {
    Some(("civic", 2 + floors % 2))
  } else {
    Some(("industrial", 1 + floors % 2))
  }
}

///|
fn exact_energy_valley_grow_urban_fabric(
  tiles : Array[Array[ExactEnergyValleyTile]],
  seed : Int,
) -> Unit {
  energy_valley_grow_parcel_structures(tiles, seed)
}

///|
fn exact_energy_valley_building_style(module_key : String) -> String {
  match module_key {
    "vitality-dashboard" => "tower"
    "broadcast-tower" => "radar"
    "resident-twins" | "talent-avenue" => "home"
    "ai-garden" => "garden"
    "social-square" | "physical-bridge" => "plaza"
    "valley-market" => "market"
    id if id.has_prefix("research-") => "lab"
    _ => "hall"
  }
}

///|
fn exact_energy_valley_building_floors(module_key : String) -> Int {
  match module_key {
    "vitality-dashboard" => 7
    "broadcast-tower" => 5
    "town-shell" => 4
    "contest-express" | "resident-twins" | "talent-avenue" => 3
    "ai-garden" | "social-square" | "valley-market" => 1
    _ => 2
  }
}

///|
fn exact_energy_valley_building_name(
  module_key : String,
  fallback : String,
) -> String {
  match module_key {
    "town-shell" => "市政厅"
    "policy-hall" => "政策大厅"
    "vitality-dashboard" => "活力塔"
    "contest-express" => "众创大厅"
    "broadcast-tower" => "故事雷达"
    "resident-twins" => "居民双子楼"
    "ai-garden" => "AI科学花园"
    "social-square" => "社交广场"
    "research-embodied-robotics" => "具身智能实验室"
    "research-ai-agents" => "AI智能体实验室"
    "talent-avenue" => "人才大道"
    "valley-market" => "山谷市集"
    "physical-bridge" => "实体桥梁"
    "research-opc" => "OPC研究中心"
    "research-llm-training" => "LLM训练实验室"
    "research-ai-hardware" => "AI硬件实验室"
    _ => fallback
  }
}

///|
fn exact_energy_valley_buildings(
  seed : Int,
) -> Array[ExactEnergyValleyBuilding] {
  procedural_energy_valley_modules(exact_energy_valley_module_templates(), seed).map(civic => {
      id: "civic-\{civic.id}",
      archetype: civic.building_kind,
      module_key: match civic.id {
        "vitality-dashboard" => "vitality-tower"
        "broadcast-tower" => "story-radar"
        other => other
      },
      name: exact_energy_valley_building_name(civic.id, civic.title),
      glyph: "",
      style: exact_energy_valley_building_style(civic.id),
      x: civic.grid_x,
      y: civic.grid_y,
      width: civic.footprint_w,
      depth: civic.footprint_h,
      entrance_x: civic.entrance_x,
      entrance_y: civic.entrance_y,
      floors: exact_energy_valley_building_floors(civic.id),
      vitality: 0.78 +
      energy_valley_variation(seed, civic.grid_x, civic.grid_y, 409, 20).to_double() /
      100.0,
    },
  )
}

///|
fn exact_energy_valley_tile(
  seed : Int,
  x : Int,
  y : Int,
) -> ExactEnergyValleyTile {
  let kind = energy_valley_tile_kind_at(seed, x, y)
  let variation = energy_valley_variation(seed, x, y, 397, 1000).to_double() /
    1000.0
  {
    terrain: exact_energy_valley_canvas_terrain(kind),
    base_terrain: kind,
    generated_terrain: kind,
    district: energy_valley_district_at(seed, x, y),
    variation,
    building_id: None,
    river_flow: if kind == "river" || kind == "lake" {
      Some(0.55 + variation * 0.4)
    } else {
      None
    },
    road_mask: None,
    structure: None,
    structure_floors: None,
    structure_width: None,
    structure_depth: None,
  }
}

///|
fn exact_energy_valley_road_mask(
  tiles : Array[Array[ExactEnergyValleyTile]],
  x : Int,
  y : Int,
) -> Int {
  let mut mask = 0
  let neighbors = [(x, y - 1), (x + 1, y), (x, y + 1), (x - 1, y)]
  for index in 0..<neighbors.length() {
    let (neighbor_x, neighbor_y) = neighbors[index]
    if neighbor_x >= 0 &&
      neighbor_x < exact_energy_valley_cols() &&
      neighbor_y >= 0 &&
      neighbor_y < exact_energy_valley_rows() {
      let terrain = tiles[neighbor_y][neighbor_x].terrain
      if terrain == "road" || terrain == "bridge" {
        mask = mask | (1 << index)
      }
    }
  }
  mask
}

///|
fn exact_energy_valley_is_transport_or_water(terrain : String) -> Bool {
  terrain == "road" || terrain == "bridge" || terrain == "water"
}

///|
fn exact_energy_valley_reserve_civic_parcel(
  tiles : Array[Array[ExactEnergyValleyTile]],
  building : ExactEnergyValleyBuilding,
) -> Unit {
  for y in (building.y - 1)..<=(building.y + building.depth) {
    for x in (building.x - 1)..<=(building.x + building.width) {
      if x < 0 ||
        x >= exact_energy_valley_cols() ||
        y < 0 ||
        y >= exact_energy_valley_rows() {
        continue
      }
      let footprint = x >= building.x &&
        x < building.x + building.width &&
        y >= building.y &&
        y < building.y + building.depth
      let tile = tiles[y][x]
      if footprint {
        tile.terrain = "plaza"
        tile.base_terrain = "campus"
        tile.generated_terrain = "campus"
        tile.building_id = Some(building.id)
        tile.structure = None
        tile.structure_floors = None
        tile.structure_width = None
        tile.structure_depth = None
      } else if !exact_energy_valley_is_transport_or_water(tile.terrain) {
        // The one-tile campus apron visually joins each procedural civic
        // footprint to its ground without erasing an adjacent access road.
        tile.terrain = "plaza"
        tile.base_terrain = "campus"
        tile.generated_terrain = "campus"
        tile.structure = None
        tile.structure_floors = None
        tile.structure_width = None
        tile.structure_depth = None
      }
    }
  }
}

///|
pub fn exact_energy_valley_generate(seed : UInt) -> ExactEnergyValleyWorld {
  let normalized_seed = normalized_energy_valley_seed(
    if seed == 0U {
      default_energy_valley_seed
    } else {
      seed.reinterpret_as_int()
    },
  )
  let tiles : Array[Array[ExactEnergyValleyTile]] = []
  for y in 0..<exact_energy_valley_rows() {
    let row : Array[ExactEnergyValleyTile] = []
    for x in 0..<exact_energy_valley_cols() {
      row.push(exact_energy_valley_tile(normalized_seed, x, y))
    }
    tiles.push(row)
  }
  energy_valley_compile_reference_road_network(tiles, normalized_seed)
  energy_valley_prepare_semantic_ground(tiles)
  let buildings = exact_energy_valley_buildings(normalized_seed)
  for building in buildings {
    exact_energy_valley_reserve_civic_parcel(tiles, building)
  }
  exact_energy_valley_grow_urban_fabric(tiles, normalized_seed)
  energy_valley_compile_building_access(tiles, buildings)
  for y in 0..<exact_energy_valley_rows() {
    for x in 0..<exact_energy_valley_cols() {
      let terrain = tiles[y][x].terrain
      if terrain == "road" || terrain == "bridge" {
        tiles[y][x].road_mask = Some(exact_energy_valley_road_mask(tiles, x, y))
      }
    }
  }
  let grammar = energy_valley_grammar(normalized_seed)
  let bridge_columns : Array[Int] = []
  for x in 0..<exact_energy_valley_cols() {
    if energy_valley_bridge_at(normalized_seed, x, grammar.civic_road_y) {
      bridge_columns.push(x)
    }
  }
  {
    seed: normalized_seed.reinterpret_as_uint(),
    cols: exact_energy_valley_cols(),
    rows: exact_energy_valley_rows(),
    tiles,
    buildings,
    landmarks: {
      civic_core_x: grammar.civic_road_x,
      civic_core_y: grammar.civic_road_y,
      river_crossing_y: grammar.civic_road_y,
      feeder_head_x: energy_valley_main_river_center_x(normalized_seed, 7),
      bridge_columns,
      south_arterial_y: grammar.south_road_y,
    },
  }
}

///|
pub fn exact_energy_valley_generate_default() -> ExactEnergyValleyWorld {
  exact_energy_valley_generate(exact_energy_valley_default_seed())
}

///|
pub fn exact_energy_valley_generate_int(seed : Int) -> ExactEnergyValleyWorld {
  exact_energy_valley_generate(
    if seed < 0 {
      (-seed).reinterpret_as_uint()
    } else {
      seed.reinterpret_as_uint()
    },
  )
}
