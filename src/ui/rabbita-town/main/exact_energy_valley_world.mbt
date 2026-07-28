///|
/// The preserved TypeScript Energy Valley generator uses a 56 × 52 planning
/// grid. This port intentionally keeps the same terrain names and row-major
/// generation order so the canvas can adopt it without a translation layer.
pub fn exact_energy_valley_cols() -> Int {
  56
}

///|
pub fn exact_energy_valley_rows() -> Int {
  52
}

///|
pub fn exact_energy_valley_default_seed() -> UInt {
  20260727U
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
  floors : Int
  vitality : Double
} derive(Debug)

///|
pub(all) struct ExactEnergyValleyLandmarks {
  civic_core_x : Int
  civic_core_y : Int
  lake_x : Double
  lake_y : Double
  lake_radius_x : Double
  lake_radius_y : Double
  bridge_rows : Array[Int]
  main_river_mean_x : Double
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
priv struct ExactEnergyValleyRandom {
  mut state : UInt
}

///|
fn ExactEnergyValleyRandom::next_u32(self : ExactEnergyValleyRandom) -> UInt {
  self.state = self.state + 0x6d2b79f5U
  let mut value = (self.state ^ (self.state >> 15)) * (self.state | 1U)
  value = (value + (value ^ (value >> 7)) * (value | 61U)) ^ value
  value ^ (value >> 14)
}

///|
fn ExactEnergyValleyRandom::next(self : ExactEnergyValleyRandom) -> Double {
  self.next_u32().to_double() / 4294967296.0
}

///|
priv struct ExactEnergyValleyGrammar {
  seed : UInt
  phase : Double
  phase2 : Double
  river_mean_x : Double
  river_amplitude : Double
  lake_x : Double
  lake_y : Double
  lake_radius_x : Double
  lake_radius_y : Double
  tributary_base_y : Double
  bridge_rows : Array[Int]
  civic_core_x : Int
  civic_core_y : Int
}

///|
fn exact_energy_valley_normalize_seed(seed : UInt) -> UInt {
  if seed == 0U {
    exact_energy_valley_default_seed()
  } else {
    seed
  }
}

///|
fn exact_energy_valley_grammar(seed : UInt) -> ExactEnergyValleyGrammar {
  let normalized = exact_energy_valley_normalize_seed(seed)
  let random : ExactEnergyValleyRandom = { state: normalized }
  let jitter = fn(amount : Double) { (random.next() * 2.0 - 1.0) * amount }
  // Keep these lets sequential: they preserve the reference RNG call order.
  let bridge_a = 11 + jitter(2.0).round().to_int()
  let bridge_b = 27 + jitter(2.0).round().to_int()
  let bridge_c = 42 + jitter(2.0).round().to_int()
  let phase = random.next() * 6.283185307179586
  let phase2 = random.next() * 6.283185307179586
  let river_mean_x = 43.0 + jitter(1.5)
  let river_amplitude = 3.8 + random.next() * 1.2
  let lake_x = 28.0 + jitter(1.8)
  let lake_y = 31.0 + jitter(1.5)
  let lake_radius_x = 6.0 + random.next() * 1.2
  let lake_radius_y = 3.6 + random.next() * 0.8
  let tributary_base_y = 12.5 + jitter(1.5)
  let civic_core_x = 21 + jitter(1.0).round().to_int()
  let civic_core_y = 23 + jitter(1.0).round().to_int()
  {
    seed: normalized,
    phase,
    phase2,
    river_mean_x,
    river_amplitude,
    lake_x,
    lake_y,
    lake_radius_x,
    lake_radius_y,
    tributary_base_y,
    bridge_rows: [bridge_a, bridge_b, bridge_c],
    civic_core_x,
    civic_core_y,
  }
}

///|
extern "js" fn exact_energy_valley_sin(value : Double) -> Double =
  #| (value) => Math.sin(value)

///|
extern "js" fn exact_energy_valley_hypot(x : Double, y : Double) -> Double =
  #| (x, y) => Math.hypot(x, y)

///|
fn exact_energy_valley_main_river_x(
  y : Int,
  grammar : ExactEnergyValleyGrammar,
) -> Double {
  grammar.river_mean_x +
  grammar.river_amplitude *
  exact_energy_valley_sin(y.to_double() / 7.2 + grammar.phase) +
  1.35 * exact_energy_valley_sin(y.to_double() / 2.9 + grammar.phase2)
}

///|
fn exact_energy_valley_lake_distance(
  x : Int,
  y : Int,
  grammar : ExactEnergyValleyGrammar,
) -> Double {
  let dx = (x.to_double() - grammar.lake_x) / grammar.lake_radius_x
  let dy = (y.to_double() - grammar.lake_y) / grammar.lake_radius_y
  exact_energy_valley_hypot(dx, dy)
}

///|
fn exact_energy_valley_main_river_half_width(
  y : Int,
  grammar : ExactEnergyValleyGrammar,
) -> Double {
  2.15 + 0.45 * exact_energy_valley_sin(y.to_double() / 4.2 + grammar.phase)
}

///|
fn exact_energy_valley_tributary_y(
  x : Int,
  grammar : ExactEnergyValleyGrammar,
) -> Double {
  grammar.tributary_base_y +
  x.to_double() * 0.24 +
  1.5 * exact_energy_valley_sin(x.to_double() / 5.1 + grammar.phase2)
}

///|
fn exact_energy_valley_outlet_y(
  x : Int,
  grammar : ExactEnergyValleyGrammar,
) -> Double {
  let denominator = if grammar.river_mean_x - grammar.lake_x < 1.0 {
    1.0
  } else {
    grammar.river_mean_x - grammar.lake_x
  }
  let progress = (x.to_double() - grammar.lake_x) / denominator
  grammar.lake_y +
  progress * 2.6 +
  exact_energy_valley_sin(x.to_double() / 2.7 + grammar.phase) * 0.55
}

///|
fn exact_energy_valley_water_at(
  x : Int,
  y : Int,
  grammar : ExactEnergyValleyGrammar,
) -> Bool {
  let river = (x.to_double() - exact_energy_valley_main_river_x(y, grammar)).abs() <=
    exact_energy_valley_main_river_half_width(y, grammar)
  let lake_noise = 0.08 *
    exact_energy_valley_sin(
      x.to_double() * 1.7 + y.to_double() * 0.8 + grammar.phase,
    )
  let lake = exact_energy_valley_lake_distance(x, y, grammar) <=
    1.0 + lake_noise
  let tributary_end = grammar.lake_x - grammar.lake_radius_x * 0.45
  let tributary = x.to_double() <= tributary_end &&
    (y.to_double() - exact_energy_valley_tributary_y(x, grammar)).abs() <=
    1.05 + 0.2 * exact_energy_valley_sin(x.to_double() + grammar.phase)
  let outlet = x.to_double() >= grammar.lake_x + grammar.lake_radius_x * 0.35 &&
    x.to_double() <= grammar.river_mean_x + 2.0 &&
    (y.to_double() - exact_energy_valley_outlet_y(x, grammar)).abs() <= 1.1
  river || lake || tributary || outlet
}

///|
fn exact_energy_valley_district_at(
  x : Int,
  y : Int,
  grammar : ExactEnergyValleyGrammar,
) -> String {
  if exact_energy_valley_water_at(x, y, grammar) {
    "river-corridor"
  } else if x >= 31 &&
    x.to_double() < grammar.river_mean_x - 2.0 &&
    y >= 9 &&
    y <= 24 {
    "farm-belt"
  } else if (x.to_double() - exact_energy_valley_main_river_x(y, grammar)).abs() <
    5.0 {
    "river-corridor"
  } else if exact_energy_valley_lake_distance(x, y, grammar) < 1.8 {
    if y.to_double() < grammar.lake_y {
      "lake-learning"
    } else {
      "lake-exchange"
    }
  } else if x < 12 && y > 26 {
    "west-community"
  } else if y < 15 && x >= 10 && x <= 34 {
    "north-innovation"
  } else if y > 37 && x >= 23 && x <= 40 {
    "south-showcase"
  } else if x >= 10 && x <= 33 && y >= 15 && y <= 37 {
    "civic-core"
  } else {
    "forest-buffer"
  }
}

///|
fn exact_energy_valley_near_water(
  x : Int,
  y : Int,
  grammar : ExactEnergyValleyGrammar,
  radius : Double,
) -> Bool {
  let r = radius.ceil().to_int()
  let first_y = if y - r < 0 { 0 } else { y - r }
  let last_y = if y + r >= exact_energy_valley_rows() {
    exact_energy_valley_rows() - 1
  } else {
    y + r
  }
  let first_x = if x - r < 0 { 0 } else { x - r }
  let last_x = if x + r >= exact_energy_valley_cols() {
    exact_energy_valley_cols() - 1
  } else {
    x + r
  }
  for yy in first_y..<=last_y {
    for xx in first_x..<=last_x {
      let dx = (xx - x).to_double()
      let dy = (yy - y).to_double()
      if exact_energy_valley_hypot(dx, dy) <= radius &&
        exact_energy_valley_water_at(xx, yy, grammar) {
        return true
      }
    }
  }
  false
}

///|
fn exact_energy_valley_natural_tiles(
  grammar : ExactEnergyValleyGrammar,
) -> Array[Array[ExactEnergyValleyTile]] {
  let random : ExactEnergyValleyRandom = { state: grammar.seed ^ 0x71f3a5c9U }
  let tiles : Array[Array[ExactEnergyValleyTile]] = []
  for y in 0..<exact_energy_valley_rows() {
    let row : Array[ExactEnergyValleyTile] = []
    for x in 0..<exact_energy_valley_cols() {
      let district = exact_energy_valley_district_at(x, y, grammar)
      let variation = random.next()
      let mut terrain = "grass"
      if exact_energy_valley_water_at(x, y, grammar) {
        terrain = "water"
      } else if exact_energy_valley_near_water(x, y, grammar, 1.55) &&
        random.next() < 0.72 {
        terrain = "wetland"
      } else if district == "farm-belt" {
        terrain = if (x + y / 2) % 7 == 0 { "meadow" } else { "field" }
      } else {
        let edge = {
          let horizontal = if x < exact_energy_valley_cols() - 1 - x {
            x
          } else {
            exact_energy_valley_cols() - 1 - x
          }
          let vertical = if y < exact_energy_valley_rows() - 1 - y {
            y
          } else {
            exact_energy_valley_rows() - 1 - y
          }
          if horizontal < vertical {
            horizontal
          } else {
            vertical
          }
        }
        let forest_chance = if edge < 4 {
          0.68
        } else if district == "forest-buffer" {
          0.34
        } else if exact_energy_valley_near_water(x, y, grammar, 3.4) {
          0.22
        } else {
          0.035
        }
        if random.next() < forest_chance {
          terrain = "forest"
        } else if random.next() < 0.18 {
          terrain = "meadow"
        }
      }
      row.push({
        terrain,
        base_terrain: terrain,
        generated_terrain: terrain,
        district,
        variation,
        building_id: None,
        river_flow: if terrain == "water" {
          Some(x.to_double() * 0.31 + y.to_double() * 0.57)
        } else {
          None
        },
        road_mask: None,
        structure: None,
        structure_floors: None,
      })
    }
    tiles.push(row)
  }
  tiles
}

///|
priv struct ExactEnergyValleyPoint {
  x : Int
  y : Int
}

///|
fn exact_energy_valley_set_road(
  tiles : Array[Array[ExactEnergyValleyTile]],
  x : Int,
  y : Int,
  allow_bridge : Bool,
) -> Unit {
  if x < 0 ||
    x >= exact_energy_valley_cols() ||
    y < 0 ||
    y >= exact_energy_valley_rows() {
    return
  }
  let tile = tiles[y][x]
  if tile.terrain == "water" && !allow_bridge {
    return
  }
  tile.terrain = if tile.terrain == "water" { "bridge" } else { "road" }
}

///|
fn exact_energy_valley_draw_road_line(
  tiles : Array[Array[ExactEnergyValleyTile]],
  points : Array[ExactEnergyValleyPoint],
  allow_bridge : Bool,
) -> Unit {
  for index in 1..<points.length() {
    let mut x = points[index - 1].x
    let mut y = points[index - 1].y
    let end = points[index]
    while x != end.x || y != end.y {
      exact_energy_valley_set_road(tiles, x, y, allow_bridge)
      if x != end.x {
        x += if end.x > x { 1 } else { -1 }
      } else if y != end.y {
        y += if end.y > y { 1 } else { -1 }
      }
    }
    exact_energy_valley_set_road(tiles, end.x, end.y, allow_bridge)
  }
}

///|
fn exact_energy_valley_create_roads(
  tiles : Array[Array[ExactEnergyValleyTile]],
  grammar : ExactEnergyValleyGrammar,
) -> Unit {
  for y in grammar.bridge_rows {
    exact_energy_valley_draw_road_line(
      tiles,
      [{ x: 3, y }, { x: exact_energy_valley_cols() - 4, y }],
      true,
    )
  }
  for x in [8, 15, 23, 31, 37] {
    exact_energy_valley_draw_road_line(
      tiles,
      [{ x, y: 6 }, { x, y: exact_energy_valley_rows() - 6 }],
      false,
    )
  }
  for y in [17, 22, 34, 38] {
    exact_energy_valley_draw_road_line(
      tiles,
      [{ x: 7, y }, { x: 39, y }],
      false,
    )
  }
  exact_energy_valley_draw_road_line(
    tiles,
    [{ x: 4, y: 7 }, { x: 12, y: 7 }, { x: 12, y: 13 }, { x: 20, y: 13 }],
    false,
  )
  exact_energy_valley_draw_road_line(
    tiles,
    [
      { x: 18, y: 30 },
      { x: 18, y: 35 },
      { x: 25, y: 35 },
      { x: 25, y: 39 },
      { x: 33, y: 39 },
    ],
    false,
  )
}

///|
fn exact_energy_valley_road_walkable(
  tiles : Array[Array[ExactEnergyValleyTile]],
  x : Int,
  y : Int,
) -> Bool {
  if x < 0 ||
    x >= exact_energy_valley_cols() ||
    y < 0 ||
    y >= exact_energy_valley_rows() {
    false
  } else {
    tiles[y][x].terrain == "road" || tiles[y][x].terrain == "bridge"
  }
}

///|
fn exact_energy_valley_refresh_road_masks(
  tiles : Array[Array[ExactEnergyValleyTile]],
) -> Unit {
  for y in 0..<exact_energy_valley_rows() {
    for x in 0..<exact_energy_valley_cols() {
      if !exact_energy_valley_road_walkable(tiles, x, y) {
        continue
      }
      let mut mask = 0
      if exact_energy_valley_road_walkable(tiles, x, y - 1) {
        mask = mask | 1
      }
      if exact_energy_valley_road_walkable(tiles, x + 1, y) {
        mask = mask | 2
      }
      if exact_energy_valley_road_walkable(tiles, x, y + 1) {
        mask = mask | 4
      }
      if exact_energy_valley_road_walkable(tiles, x - 1, y) {
        mask = mask | 8
      }
      tiles[y][x].road_mask = Some(mask)
    }
  }
}

///|
priv struct ExactEnergyValleyArchetype {
  name : String
  glyph : String
  width : Int
  depth : Int
  floors : Int
  style : String
}

///|
fn exact_energy_valley_archetype(id : String) -> ExactEnergyValleyArchetype {
  match id {
    "town-shell" =>
      {
        name: "市政厅",
        glyph: "政",
        width: 3,
        depth: 3,
        floors: 2,
        style: "hall",
      }
    "vitality" =>
      {
        name: "活力塔",
        glyph: "塔",
        width: 2,
        depth: 2,
        floors: 7,
        style: "tower",
      }
    "ai-garden" =>
      {
        name: "AI科学花园",
        glyph: "园",
        width: 3,
        depth: 3,
        floors: 1,
        style: "garden",
      }
    "talent" =>
      {
        name: "人才大道",
        glyph: "才",
        width: 3,
        depth: 2,
        floors: 3,
        style: "plaza-bld",
      }
    "contest" =>
      {
        name: "众创大厅",
        glyph: "创",
        width: 2,
        depth: 2,
        floors: 3,
        style: "lab",
      }
    "policy" =>
      {
        name: "政策大厅",
        glyph: "策",
        width: 2,
        depth: 2,
        floors: 2,
        style: "hall",
      }
    "social" =>
      {
        name: "社交广场",
        glyph: "交",
        width: 3,
        depth: 3,
        floors: 1,
        style: "plaza-bld",
      }
    "market" =>
      {
        name: "山谷市集",
        glyph: "市",
        width: 3,
        depth: 2,
        floors: 1,
        style: "market",
      }
    "twins" =>
      {
        name: "居民双子楼",
        glyph: "居",
        width: 2,
        depth: 2,
        floors: 4,
        style: "home",
      }
    "radar" =>
      {
        name: "故事雷达",
        glyph: "雷达",
        width: 2,
        depth: 2,
        floors: 2,
        style: "radar",
      }
    "c-lab" =>
      {
        name: "实验室",
        glyph: "实",
        width: 2,
        depth: 2,
        floors: 2,
        style: "custom-lab",
      }
    "c-home" =>
      {
        name: "人才公寓",
        glyph: "寓",
        width: 2,
        depth: 2,
        floors: 3,
        style: "custom-home",
      }
    _ =>
      {
        name: "市政厅",
        glyph: "政",
        width: 3,
        depth: 3,
        floors: 2,
        style: "hall",
      }
  }
}

///|
priv struct ExactEnergyValleyCivicPlacement {
  archetype : String
  module_key : String
  district : String
  anchor_x : Int
  anchor_y : Int
}

///|
fn exact_energy_valley_civic_specs(
  grammar : ExactEnergyValleyGrammar,
) -> Array[ExactEnergyValleyCivicPlacement] {
  let jitter_x = grammar.civic_core_x - 21
  let jitter_y = grammar.civic_core_y - 23
  [
    {
      archetype: "town-shell",
      module_key: "town-shell",
      district: "civic-core",
      anchor_x: 17 + jitter_x,
      anchor_y: 22 + jitter_y,
    },
    {
      archetype: "vitality",
      module_key: "vitality-tower",
      district: "civic-core",
      anchor_x: 24 + jitter_x,
      anchor_y: 18 + jitter_y,
    },
    {
      archetype: "policy",
      module_key: "policy-hall",
      district: "civic-core",
      anchor_x: 13 + jitter_x,
      anchor_y: 25 + jitter_y,
    },
    {
      archetype: "contest",
      module_key: "contest-express",
      district: "north-innovation",
      anchor_x: 18 + jitter_x,
      anchor_y: 14 + jitter_y,
    },
    {
      archetype: "radar",
      module_key: "story-radar",
      district: "north-innovation",
      anchor_x: 10 + jitter_x,
      anchor_y: 10 + jitter_y,
    },
    {
      archetype: "twins",
      module_key: "resident-twins",
      district: "west-community",
      anchor_x: 8,
      anchor_y: 31 + jitter_y,
    },
    {
      archetype: "twins",
      module_key: "resident-twins-b",
      district: "west-community",
      anchor_x: 11,
      anchor_y: 37 + jitter_y,
    },
    {
      archetype: "ai-garden",
      module_key: "ai-garden",
      district: "lake-learning",
      anchor_x: 20 + jitter_x,
      anchor_y: 29 + jitter_y,
    },
    {
      archetype: "social",
      module_key: "social-square",
      district: "lake-exchange",
      anchor_x: 27 + jitter_x,
      anchor_y: 34 + jitter_y,
    },
    {
      archetype: "c-lab",
      module_key: "energy-lab",
      district: "lake-exchange",
      anchor_x: 31 + jitter_x,
      anchor_y: 30 + jitter_y,
    },
    {
      archetype: "talent",
      module_key: "talent-avenue",
      district: "south-showcase",
      anchor_x: 24 + jitter_x,
      anchor_y: 40 + jitter_y,
    },
    {
      archetype: "market",
      module_key: "valley-market",
      district: "south-showcase",
      anchor_x: 32 + jitter_x,
      anchor_y: 40 + jitter_y,
    },
    {
      archetype: "c-home",
      module_key: "talent-flat",
      district: "south-showcase",
      anchor_x: 37 + jitter_x,
      anchor_y: 37 + jitter_y,
    },
  ]
}

///|
fn exact_energy_valley_placement_clear(
  tiles : Array[Array[ExactEnergyValleyTile]],
  buildings : Array[ExactEnergyValleyBuilding],
  archetype_id : String,
  candidate_x : Int,
  candidate_y : Int,
) -> Bool {
  let archetype = exact_energy_valley_archetype(archetype_id)
  if candidate_x < 1 ||
    candidate_y < 1 ||
    candidate_x + archetype.width >= exact_energy_valley_cols() - 1 ||
    candidate_y + archetype.depth >= exact_energy_valley_rows() - 1 {
    return false
  }
  for y in candidate_y..<(candidate_y + archetype.depth) {
    for x in candidate_x..<(candidate_x + archetype.width) {
      let tile = tiles[y][x]
      if tile.building_id is Some(_) ||
        tile.terrain == "water" ||
        tile.terrain == "bridge" ||
        tile.terrain == "road" {
        return false
      }
    }
  }
  for building in buildings {
    if candidate_x < building.x + building.width + 1 &&
      candidate_x + archetype.width + 1 > building.x &&
      candidate_y < building.y + building.depth + 1 &&
      candidate_y + archetype.depth + 1 > building.y {
      return false
    }
  }
  for x in (candidate_x - 1)..<=(candidate_x + archetype.width) {
    for y in (candidate_y - 1)..<=(candidate_y + archetype.depth) {
      let edge = x == candidate_x - 1 ||
        x == candidate_x + archetype.width ||
        y == candidate_y - 1 ||
        y == candidate_y + archetype.depth
      if edge &&
        (tiles[y][x].terrain == "road" || tiles[y][x].terrain == "bridge") {
        return true
      }
    }
  }
  false
}

///|
priv struct ExactEnergyValleyCandidate {
  x : Int
  y : Int
  score : Double
}

///|
fn exact_energy_valley_find_placement(
  tiles : Array[Array[ExactEnergyValleyTile]],
  buildings : Array[ExactEnergyValleyBuilding],
  placement : ExactEnergyValleyCivicPlacement,
  random : ExactEnergyValleyRandom,
) -> ExactEnergyValleyCandidate {
  let candidates : Array[ExactEnergyValleyCandidate] = []
  let mut radius = 0
  while radius <= 9 && candidates.length() < 4 {
    for dy_index in 0..<(radius * 2 + 1) {
      let dy = dy_index - radius
      for dx_index in 0..<(radius * 2 + 1) {
        let dx = dx_index - radius
        let chebyshev = {
          let x_abs = if dx < 0 { -dx } else { dx }
          let y_abs = if dy < 0 { -dy } else { dy }
          if x_abs > y_abs {
            x_abs
          } else {
            y_abs
          }
        }
        if chebyshev != radius {
          continue
        }
        let x = placement.anchor_x + dx
        let y = placement.anchor_y + dy
        if !exact_energy_valley_placement_clear(
            tiles,
            buildings,
            placement.archetype,
            x,
            y,
          ) {
          continue
        }
        let district_penalty = if tiles[y][x].district == placement.district {
          0.0
        } else {
          4.0
        }
        candidates.push({
          x,
          y,
          score: exact_energy_valley_hypot(dx.to_double(), dy.to_double()) +
          district_penalty +
          random.next() * 0.45,
        })
      }
    }
    radius += 1
  }
  if candidates.length() == 0 {
    abort("Energy Valley grammar could not place \{placement.module_key}")
  }
  let mut best = candidates[0]
  for index in 1..<candidates.length() {
    if candidates[index].score < best.score {
      best = candidates[index]
    }
  }
  best
}

///|
fn exact_energy_valley_place_civic(
  tiles : Array[Array[ExactEnergyValleyTile]],
  buildings : Array[ExactEnergyValleyBuilding],
  placement : ExactEnergyValleyCivicPlacement,
  random : ExactEnergyValleyRandom,
) -> Unit {
  let archetype = exact_energy_valley_archetype(placement.archetype)
  let found = exact_energy_valley_find_placement(
    tiles, buildings, placement, random,
  )
  let id = "civic-\{placement.module_key}"
  let building : ExactEnergyValleyBuilding = {
    id,
    archetype: placement.archetype,
    module_key: placement.module_key,
    name: archetype.name,
    glyph: archetype.glyph,
    style: archetype.style,
    x: found.x,
    y: found.y,
    width: archetype.width,
    depth: archetype.depth,
    floors: archetype.floors,
    vitality: 55.0 + random.next() * 30.0,
  }
  for x in found.x..<(found.x + archetype.width) {
    for y in found.y..<(found.y + archetype.depth) {
      let tile = tiles[y][x]
      tile.terrain = "plaza"
      tile.base_terrain = "grass"
      tile.district = placement.district
      tile.building_id = Some(id)
      tile.structure = None
      tile.structure_floors = None
    }
  }
  buildings.push(building)
}

///|
fn exact_energy_valley_add_civic_plazas(
  tiles : Array[Array[ExactEnergyValleyTile]],
  buildings : Array[ExactEnergyValleyBuilding],
) -> Unit {
  for building in buildings {
    if building.module_key != "town-shell" &&
      building.module_key != "social-square" &&
      building.module_key != "talent-avenue" {
      continue
    }
    for y in (building.y - 1)..<=(building.y + building.depth) {
      for x in (building.x - 1)..<=(building.x + building.width) {
        let tile = tiles[y][x]
        if tile.building_id is Some(_) ||
          tile.terrain == "road" ||
          tile.terrain == "bridge" ||
          tile.terrain == "water" {
          continue
        }
        tile.terrain = "plaza"
        tile.base_terrain = "grass"
        tile.structure = None
        tile.structure_floors = None
      }
    }
  }
}

///|
fn exact_energy_valley_adjacent_to_road(
  tiles : Array[Array[ExactEnergyValleyTile]],
  x : Int,
  y : Int,
) -> Bool {
  tiles[y - 1][x].terrain == "road" ||
  tiles[y + 1][x].terrain == "road" ||
  tiles[y][x - 1].terrain == "road" ||
  tiles[y][x + 1].terrain == "road"
}

///|
fn exact_energy_valley_add_urban_fabric(
  tiles : Array[Array[ExactEnergyValleyTile]],
  seed : UInt,
) -> Unit {
  let random : ExactEnergyValleyRandom = { state: seed ^ 0xa53c9e17U }
  for y in 1..<(exact_energy_valley_rows() - 1) {
    for x in 1..<(exact_energy_valley_cols() - 1) {
      let tile = tiles[y][x]
      if tile.building_id is Some(_) ||
        !exact_energy_valley_adjacent_to_road(tiles, x, y) {
        continue
      }
      let density = match tile.district {
        "civic-core" => 0.76
        "north-innovation" => 0.43
        "west-community" => 0.34
        "south-showcase" => 0.46
        _ => 0.0
      }
      if density == 0.0 || random.next() > density {
        continue
      }
      if tile.terrain != "grass" && tile.terrain != "meadow" {
        continue
      }
      let roll = random.next()
      let structure = if roll < 0.48 {
        "lowrise"
      } else if roll < 0.70 {
        "row"
      } else if roll < 0.82 {
        "courtyard"
      } else if roll < 0.92 {
        "campus"
      } else {
        "tower"
      }
      tile.terrain = "urban"
      tile.structure = Some(structure)
      tile.structure_floors = Some(
        if structure == "tower" {
          4 + (random.next() * 4.0).floor().to_int()
        } else if structure == "campus" {
          2
        } else {
          1 + (random.next() * 3.0).floor().to_int()
        },
      )
    }
  }
}

///|
/// Generates the exact preserved Energy Valley terrain grammar for any
/// unsigned 32-bit seed. Seed zero follows the reference and selects the
/// canonical default seed.
pub fn exact_energy_valley_generate(seed : UInt) -> ExactEnergyValleyWorld {
  let grammar = exact_energy_valley_grammar(seed)
  let tiles = exact_energy_valley_natural_tiles(grammar)
  exact_energy_valley_create_roads(tiles, grammar)
  exact_energy_valley_refresh_road_masks(tiles)
  let buildings : Array[ExactEnergyValleyBuilding] = []
  let placement_random : ExactEnergyValleyRandom = {
    state: grammar.seed ^ 0x9e3779b9U,
  }
  for placement in exact_energy_valley_civic_specs(grammar) {
    exact_energy_valley_place_civic(
      tiles, buildings, placement, placement_random,
    )
  }
  exact_energy_valley_add_civic_plazas(tiles, buildings)
  exact_energy_valley_add_urban_fabric(tiles, grammar.seed)
  for row in tiles {
    for tile in row {
      tile.generated_terrain = tile.terrain
    }
  }
  {
    seed: grammar.seed,
    cols: exact_energy_valley_cols(),
    rows: exact_energy_valley_rows(),
    tiles,
    buildings,
    landmarks: {
      civic_core_x: grammar.civic_core_x,
      civic_core_y: grammar.civic_core_y,
      lake_x: grammar.lake_x,
      lake_y: grammar.lake_y,
      lake_radius_x: grammar.lake_radius_x,
      lake_radius_y: grammar.lake_radius_y,
      bridge_rows: grammar.bridge_rows.copy(),
      main_river_mean_x: grammar.river_mean_x,
    },
  }
}

///|
pub fn exact_energy_valley_generate_default() -> ExactEnergyValleyWorld {
  exact_energy_valley_generate(exact_energy_valley_default_seed())
}

///|
/// Int-facing convenience for the UI model. It mirrors the reference
/// `abs(trunc(seed)) >>> 0` normalization, including Int's minimum value.
pub fn exact_energy_valley_generate_int(seed : Int) -> ExactEnergyValleyWorld {
  let bits = seed.reinterpret_as_uint()
  let normalized = if seed < 0 { 0U - bits } else { bits }
  exact_energy_valley_generate(normalized)
}
