///|
/// A renderer-neutral identity for every semantic thing that can receive
/// attention or interaction in the Energy Valley. The bridge deliberately
/// stays package-local while the world compiler contract is being proven.
priv enum EcosystemPlaceKind {
  EcosystemCivicBuilding
  EcosystemAmbientBuilding
  EcosystemCustomBuilding
  EcosystemMetroStation
  EcosystemPublicRealm
  EcosystemLandmark
} derive(Debug, Eq)

///|
priv enum EcosystemAffordanceKind {
  EcosystemInspect
  EcosystemEnter
  EcosystemWork
  EcosystemExchange
  EcosystemRest
  EcosystemObserve
  EcosystemTravel
  EcosystemPublish
  EcosystemGather
} derive(Debug, Eq)

///|
priv struct EcosystemGridPoint {
  x : Int
  y : Int
} derive(Debug, Eq)

///|
priv struct EcosystemFootprint {
  x : Int
  y : Int
  width : Int
  depth : Int
} derive(Debug, Eq)

///|
priv struct EcosystemTrait {
  key : String
  value : String
  salience : Int
} derive(Debug, Eq)

///|
/// Attention is split by channel so a future camera, resident brain, or
/// activity feed can decide why a place matters instead of relying on one
/// opaque popularity score. All values are clamped to 0..100.
priv struct EcosystemAttentionProfile {
  visual : Int
  social : Int
  activity : Int
  urgency : Int
  novelty : Int
} derive(Debug, Eq)

///|
/// Stable resource binding carried by the geographic source. Dynamic task,
/// agent, health, and activity facts belong exclusively to `TownSnapshot` and
/// the runtime overlay; keeping them out of this type makes it impossible for
/// a cached world to retain a stale "live" claim.
priv struct EcosystemPlaceRuntimeBinding {
  runtime_key : String?
} derive(Debug, Eq)

///|
priv struct EcosystemPlace {
  id : String
  source_id : String
  name : String
  kind : EcosystemPlaceKind
  district : String
  style : String
  footprint : EcosystemFootprint
  anchor : EcosystemGridPoint
  traits : Array[EcosystemTrait]
  attention : EcosystemAttentionProfile
  runtime : EcosystemPlaceRuntimeBinding
} derive(Debug, Eq)

///|
/// `threshold` is the point on the place boundary; `access_point` is the road
/// or public-space point a resident reaches before crossing that threshold.
priv struct EcosystemEntrance {
  id : String
  place_id : String
  label : String
  threshold : EcosystemGridPoint
  access_point : EcosystemGridPoint
  direction : String
  portal_kind : String
  primary : Bool
  accessible : Bool
} derive(Debug, Eq)

///|
/// A frontage is an explicit semantic edge between a place portal and the
/// same road cell rendered and used by the current pathfinder.
priv struct EcosystemRoadFrontage {
  id : String
  place_id : String
  entrance_id : String
  road_cell_id : String
  road_class : String
  road_mask : Int
  distance : Int
  direct : Bool
} derive(Debug, Eq)

///|
/// A pedestrian spur is the physical, cardinal path between an indirect
/// doorway and the shared road graph. The path always starts at the entrance
/// threshold and ends on `road_cell_id`; direct frontages intentionally do not
/// allocate a second path over an already-adjacent road.
priv struct EcosystemPedestrianSpur {
  id : String
  place_id : String
  entrance_id : String
  road_cell_id : String
  path : Array[EcosystemGridPoint]
  distance : Int
} derive(Debug, Eq)

///|
/// Typed road facts are emitted once so rendering, navigation, and future
/// simulation code can converge on the same connectivity contract.
priv struct EcosystemRoadCell {
  id : String
  x : Int
  y : Int
  road_class : String
  road_mask : Int
  bridge : Bool
  custom : Bool
  streetlight : Bool
  street_tree : Bool
  boardwalk_mask : Int
} derive(Debug, Eq)

///|
priv struct EcosystemWorldAffordance {
  id : String
  kind : EcosystemAffordanceKind
  place_id : String?
  anchor : EcosystemGridPoint
  capacity : Int
  attention_weight : Int
  enabled : Bool
  evidence : String
} derive(Debug, Eq)

///|
/// Compatibility snapshot over the existing mutable tile world. It does not
/// mutate generation or rendering; it contains only spatial/program facts so
/// runtime refreshes cannot contaminate or invalidate the static world cache.
priv struct EcosystemWorldSnapshot {
  schema : String
  seed : UInt
  cols : Int
  rows : Int
  places : Array[EcosystemPlace]
  entrances : Array[EcosystemEntrance]
  road_frontages : Array[EcosystemRoadFrontage]
  pedestrian_spurs : Array[EcosystemPedestrianSpur]
  roads : Array[EcosystemRoadCell]
  road_network : @energy_valley_contract.RoadNetwork
  affordances : Array[EcosystemWorldAffordance]
} derive(Debug, Eq)

///|
priv struct EcosystemFrontageCandidate {
  threshold : EcosystemGridPoint
  road : EcosystemGridPoint
  path : Array[EcosystemGridPoint]
  direction : String
  distance : Int
  direct : Bool
} derive(Debug, Eq)

///|
fn ecosystem_world_schema() -> String {
  "moontown.energy-valley.ecosystem.v1"
}

///|
fn ecosystem_int_abs(value : Int) -> Int {
  if value < 0 {
    -value
  } else {
    value
  }
}

///|
fn ecosystem_clamp_attention(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 100 {
    100
  } else {
    value
  }
}

///|
fn ecosystem_point(x : Int, y : Int) -> EcosystemGridPoint {
  { x, y }
}

///|
fn ecosystem_id_fragment(value : String) -> String {
  value
  .to_lower()
  .replace_all(old="/", new="-")
  .replace_all(old=":", new="-")
  .replace_all(old="_", new="-")
  .replace_all(old=" ", new="-")
}

///|
fn ecosystem_scoped_id(scope : String, durable_key : String) -> String {
  "\{scope}/\{ecosystem_id_fragment(durable_key)}"
}

///|
fn ecosystem_road_cell_id(x : Int, y : Int) -> String {
  ecosystem_scoped_id("road-node", "\{x}-\{y}")
}

///|
fn ecosystem_custom_place_id(building : GoldenValleyBuilding) -> String {
  let durable_key = golden_valley_nonempty_authored_id(building).unwrap_or(
    "custom-\{building.x}-\{building.y}-\{building.style}",
  )
  ecosystem_scoped_id("place", durable_key)
}

///|
fn ecosystem_ambient_place_name(kind : String, x : Int, y : Int) -> String {
  let label = match kind {
    "tower" => "研发塔楼"
    "block" => "城市街坊"
    "row" => "沿街建筑"
    "courtyard" => "庭院社区"
    "lowrise" => "低层社区"
    "campus" => "研发园区"
    "civic" => "公共服务楼"
    "industrial" => "实验工坊"
    _ => "能源谷建筑"
  }
  "\{label} · \{x},\{y}"
}

///|
fn ecosystem_metro_station_id(station : MetroStation) -> String {
  match station.name {
    "未来科学城站" =>
      ecosystem_scoped_id("place", "metro-line17-future-science-city")
    "未来科学城北站" =>
      ecosystem_scoped_id("place", "metro-line17-future-science-city-north")
    _ =>
      ecosystem_scoped_id(
        "place",
        "metro-line17-station-\{station.x.floor().to_int()}-\{station.y.floor().to_int()}",
      )
  }
}

///|
fn ecosystem_affordance_key(kind : EcosystemAffordanceKind) -> String {
  match kind {
    EcosystemInspect => "inspect"
    EcosystemEnter => "enter"
    EcosystemWork => "work"
    EcosystemExchange => "exchange"
    EcosystemRest => "rest"
    EcosystemObserve => "observe"
    EcosystemTravel => "travel"
    EcosystemPublish => "publish"
    EcosystemGather => "gather"
  }
}

///|
fn ecosystem_effective_terrain(
  world : ExactEnergyValleyWorld,
  custom_buildings : Array[GoldenValleyBuilding],
  custom_roads : Array[String],
  custom_parks : Array[String],
  x : Int,
  y : Int,
) -> String {
  if x < 0 || x >= world.cols || y < 0 || y >= world.rows {
    return "void"
  }
  for building in custom_buildings {
    if golden_valley_building_contains(building, x, y) {
      return "plaza"
    }
  }
  let key = golden_valley_tile_key(x, y)
  let generated = world.tiles[y][x].terrain
  if custom_roads.contains(key) {
    if generated == "water" || generated == "bridge" {
      "bridge"
    } else {
      "road"
    }
  } else if custom_parks.contains(key) {
    "forest"
  } else {
    generated
  }
}

///|
fn ecosystem_is_road(terrain : String) -> Bool {
  terrain == "road" || terrain == "bridge"
}

///|
fn ecosystem_road_mask_at(
  world : ExactEnergyValleyWorld,
  custom_buildings : Array[GoldenValleyBuilding],
  custom_roads : Array[String],
  custom_parks : Array[String],
  x : Int,
  y : Int,
) -> Int {
  let mut mask = 0
  let neighbors = [(x, y - 1), (x + 1, y), (x, y + 1), (x - 1, y)]
  for index, neighbor in neighbors {
    if ecosystem_is_road(
        ecosystem_effective_terrain(
          world,
          custom_buildings,
          custom_roads,
          custom_parks,
          neighbor.0,
          neighbor.1,
        ),
      ) {
      mask = mask | (1 << index)
    }
  }
  mask
}

///|
fn ecosystem_road_class_at(
  world : ExactEnergyValleyWorld,
  custom_roads : Array[String],
  x : Int,
  y : Int,
) -> String {
  if custom_roads.contains(golden_valley_tile_key(x, y)) {
    "custom"
  } else {
    let tile = world.tiles[y][x]
    if tile.terrain == "bridge" {
      "bridge"
    } else if tile.base_terrain == "road-major" {
      "major"
    } else {
      "local"
    }
  }
}

///|
fn ecosystem_threshold_for_road(
  footprint : EcosystemFootprint,
  road : EcosystemGridPoint,
) -> EcosystemGridPoint {
  let max_x = footprint.x + footprint.width - 1
  let max_y = footprint.y + footprint.depth - 1
  let threshold_x = if road.x < footprint.x {
    footprint.x
  } else if road.x > max_x {
    max_x
  } else {
    road.x
  }
  let threshold_y = if road.y < footprint.y {
    footprint.y
  } else if road.y > max_y {
    max_y
  } else {
    road.y
  }
  { x: threshold_x, y: threshold_y }
}

///|
fn ecosystem_road_direction(
  footprint : EcosystemFootprint,
  road : EcosystemGridPoint,
) -> String {
  if road.y < footprint.y {
    "north"
  } else if road.x >= footprint.x + footprint.width {
    "east"
  } else if road.y >= footprint.y + footprint.depth {
    "south"
  } else if road.x < footprint.x {
    "west"
  } else {
    "linked"
  }
}

///|
fn ecosystem_add_frontage_candidate(
  candidates : Array[EcosystemFrontageCandidate],
  candidate : EcosystemFrontageCandidate,
) -> Unit {
  if !candidates.any(item => {
      item.road.x == candidate.road.x && item.road.y == candidate.road.y
    }) {
    candidates.push(candidate)
  }
}

///|
fn ecosystem_footprint_contains(
  footprint : EcosystemFootprint,
  x : Int,
  y : Int,
) -> Bool {
  x >= footprint.x &&
  x < footprint.x + footprint.width &&
  y >= footprint.y &&
  y < footprint.y + footprint.depth
}

///|
fn ecosystem_road_network_node_lookup(
  road_network : @energy_valley_contract.RoadNetwork,
) -> Map[String, @energy_valley_contract.RoadNode] {
  let result : Map[String, @energy_valley_contract.RoadNode] = Map([])
  for node in road_network.nodes {
    if node.id.scope() == "road-node" {
      result[golden_valley_tile_key(node.grid.column, node.grid.row)] = node
    }
  }
  result
}

///|
fn ecosystem_road_network_node_at(
  road_nodes : Map[String, @energy_valley_contract.RoadNode],
  x : Int,
  y : Int,
) -> @energy_valley_contract.RoadNode? {
  road_nodes.get(golden_valley_tile_key(x, y))
}

///|
fn ecosystem_spur_cell_can_cross(
  world : ExactEnergyValleyWorld,
  road_nodes : Map[String, @energy_valley_contract.RoadNode],
  custom_buildings : Array[GoldenValleyBuilding],
  custom_roads : Array[String],
  custom_parks : Array[String],
  footprint : EcosystemFootprint,
  x : Int,
  y : Int,
) -> Bool {
  if x < 0 || x >= world.cols || y < 0 || y >= world.rows {
    return false
  }
  if ecosystem_footprint_contains(footprint, x, y) {
    return false
  }
  if ecosystem_road_network_node_at(road_nodes, x, y) is Some(_) {
    return true
  }
  let terrain = ecosystem_effective_terrain(
    world, custom_buildings, custom_roads, custom_parks, x, y,
  )
  if terrain == "water" || terrain == "void" {
    return false
  }
  for building in custom_buildings {
    if golden_valley_building_contains(building, x, y) {
      return false
    }
  }
  let tile = world.tiles[y][x]
  tile.building_id is None && tile.structure is None
}

///|
fn ecosystem_reconstruct_spur_path(
  previous : Map[String, Int],
  columns : Int,
  start : Int,
  reached : Int,
) -> Array[EcosystemGridPoint] {
  let reversed : Array[Int] = []
  let mut cursor = reached
  while cursor >= 0 {
    reversed.push(cursor)
    if cursor == start {
      break
    }
    cursor = previous
      .get(golden_valley_tile_key(cursor % columns, cursor / columns))
      .unwrap_or(-1)
  }
  let result : Array[EcosystemGridPoint] = []
  let mut index = reversed.length() - 1
  while index >= 0 {
    let cell = reversed[index]
    result.push(ecosystem_point(cell % columns, cell / columns))
    index -= 1
  }
  result
}

///|
/// Finds the shortest walkable cardinal route from a doorway threshold to any
/// cell in the road graph, or to a specific authored road cell when supplied.
/// Building mass and water are barriers; parks and public realm remain valid
/// pedestrian space. Deterministic N/E/S/W expansion keeps the result stable
/// for a given Wenyu world and local delta. This deliberately has no unchecked
/// geometric fallback: a portal is unresolved when no walkable route exists.
fn ecosystem_shortest_spur_path(
  world : ExactEnergyValleyWorld,
  road_nodes : Map[String, @energy_valley_contract.RoadNode],
  custom_buildings : Array[GoldenValleyBuilding],
  custom_roads : Array[String],
  custom_parks : Array[String],
  footprint : EcosystemFootprint,
  threshold : EcosystemGridPoint,
  target_road : EcosystemGridPoint?,
) -> Array[EcosystemGridPoint]? {
  if threshold.x < 0 ||
    threshold.x >= world.cols ||
    threshold.y < 0 ||
    threshold.y >= world.rows {
    return None
  }
  let columns = world.cols
  let start = threshold.y * columns + threshold.x
  let queue : Array[Int] = [start]
  let seen : Map[String, Bool] = Map([])
  let previous : Map[String, Int] = Map([])
  seen[golden_valley_tile_key(threshold.x, threshold.y)] = true
  let directions = [(0, -1), (1, 0), (0, 1), (-1, 0)]
  let mut head = 0
  let mut reached = -1
  while head < queue.length() {
    let current = queue[head]
    head += 1
    let current_x = current % columns
    let current_y = current / columns
    let reached_road = ecosystem_road_network_node_at(
        road_nodes, current_x, current_y,
      )
      is Some(_)
    let reached_target = match target_road {
      None => true
      Some(target) => target.x == current_x && target.y == current_y
    }
    if reached_road && reached_target {
      reached = current
      break
    }
    for direction in directions {
      let next_x = current_x + direction.0
      let next_y = current_y + direction.1
      let next_key = golden_valley_tile_key(next_x, next_y)
      if !seen.contains(next_key) &&
        ecosystem_spur_cell_can_cross(
          world, road_nodes, custom_buildings, custom_roads, custom_parks, footprint,
          next_x, next_y,
        ) {
        seen[next_key] = true
        previous[next_key] = current
        queue.push(next_y * columns + next_x)
      }
    }
  }
  if reached < 0 {
    None
  } else {
    Some(ecosystem_reconstruct_spur_path(previous, columns, start, reached))
  }
}

///|
fn ecosystem_direct_frontage_candidates(
  road_nodes : Map[String, @energy_valley_contract.RoadNode],
  footprint : EcosystemFootprint,
) -> Array[EcosystemFrontageCandidate] {
  let result : Array[EcosystemFrontageCandidate] = []
  let sides : Array[(Int, Int, Int, String)] = []
  for x in footprint.x..<(footprint.x + footprint.width) {
    sides.push((x, footprint.y + footprint.depth, x, "south"))
  }
  for y in footprint.y..<(footprint.y + footprint.depth) {
    sides.push((footprint.x + footprint.width, y, y, "east"))
  }
  for x in footprint.x..<(footprint.x + footprint.width) {
    sides.push((x, footprint.y - 1, x, "north"))
  }
  for y in footprint.y..<(footprint.y + footprint.depth) {
    sides.push((footprint.x - 1, y, y, "west"))
  }
  for side in sides {
    let road = ecosystem_point(side.0, side.1)
    if ecosystem_road_network_node_at(road_nodes, road.x, road.y) is Some(_) {
      ecosystem_add_frontage_candidate(result, {
        threshold: ecosystem_threshold_for_road(footprint, road),
        road,
        path: [ecosystem_threshold_for_road(footprint, road), road],
        direction: side.3,
        distance: 1,
        direct: true,
      })
    }
  }
  result
}

///|
fn ecosystem_nearest_road_candidate(
  world : ExactEnergyValleyWorld,
  road_network : @energy_valley_contract.RoadNetwork,
  road_nodes : Map[String, @energy_valley_contract.RoadNode],
  custom_buildings : Array[GoldenValleyBuilding],
  custom_roads : Array[String],
  custom_parks : Array[String],
  footprint : EcosystemFootprint,
  preferred : EcosystemGridPoint,
) -> EcosystemFrontageCandidate? {
  // The existing generator guarantees civic access and accepted custom
  // buildings are adjacent to roads. The exhaustive fallback gives every
  // legacy ambient structure an honest, explicitly indirect access link too.
  // Row-major tie breaking makes the selected node independent of iteration
  // order elsewhere in the compiler.
  let mut best : EcosystemFrontageCandidate? = None
  let mut best_distance = world.cols + world.rows + 1
  let mut best_preference = best_distance
  for node in road_network.nodes {
    if node.id.scope() != "road-node" {
      continue
    }
    let road = ecosystem_point(node.grid.column, node.grid.row)
    let threshold = ecosystem_threshold_for_road(footprint, road)
    let link_distance = ecosystem_int_abs(road.x - threshold.x) +
      ecosystem_int_abs(road.y - threshold.y)
    let preference = ecosystem_int_abs(road.x - preferred.x) +
      ecosystem_int_abs(road.y - preferred.y)
    if link_distance < best_distance ||
      (link_distance == best_distance && preference < best_preference) {
      best = Some({
        threshold,
        road,
        path: [],
        direction: ecosystem_road_direction(footprint, road),
        distance: link_distance,
        direct: link_distance == 1,
      })
      best_distance = link_distance
      best_preference = preference
    }
  }
  match best {
    None => None
    Some(candidate) => {
      let path = ecosystem_shortest_spur_path(
        world,
        road_nodes,
        custom_buildings,
        custom_roads,
        custom_parks,
        footprint,
        candidate.threshold,
        None,
      )
      match path {
        None => None
        Some(path) => {
          let road = path[path.length() - 1]
          let distance = path.length() - 1
          Some({
            threshold: candidate.threshold,
            road,
            path,
            direction: ecosystem_road_direction(footprint, road),
            distance,
            direct: distance <= 1,
          })
        }
      }
    }
  }
}

///|
fn ecosystem_building_access(
  world : ExactEnergyValleyWorld,
  road_network : @energy_valley_contract.RoadNetwork,
  road_nodes : Map[String, @energy_valley_contract.RoadNode],
  custom_buildings : Array[GoldenValleyBuilding],
  custom_roads : Array[String],
  custom_parks : Array[String],
  place_id : String,
  footprint : EcosystemFootprint,
  explicit_entrance : EcosystemGridPoint?,
) -> (
  Array[EcosystemEntrance],
  Array[EcosystemRoadFrontage],
  Array[EcosystemPedestrianSpur],
) {
  let candidates : Array[EcosystemFrontageCandidate] = []
  match explicit_entrance {
    Some(road) =>
      if ecosystem_road_network_node_at(road_nodes, road.x, road.y) is Some(_) {
        let threshold = ecosystem_threshold_for_road(footprint, road)
        match
          ecosystem_shortest_spur_path(
            world,
            road_nodes,
            custom_buildings,
            custom_roads,
            custom_parks,
            footprint,
            threshold,
            Some(road),
          ) {
          None => ()
          Some(path) => {
            let distance = path.length() - 1
            ecosystem_add_frontage_candidate(candidates, {
              threshold,
              road,
              path,
              direction: ecosystem_road_direction(footprint, road),
              distance,
              direct: distance <= 1,
            })
          }
        }
      }
    None => ()
  }
  for candidate in ecosystem_direct_frontage_candidates(road_nodes, footprint) {
    ecosystem_add_frontage_candidate(candidates, candidate)
  }
  if candidates.is_empty() {
    let preferred = explicit_entrance.unwrap_or({
      x: footprint.x + footprint.width / 2,
      y: footprint.y + footprint.depth,
    })
    match
      ecosystem_nearest_road_candidate(
        world, road_network, road_nodes, custom_buildings, custom_roads, custom_parks,
        footprint, preferred,
      ) {
      Some(candidate) => candidates.push(candidate)
      None => ()
    }
  }
  let entrances : Array[EcosystemEntrance] = []
  let frontages : Array[EcosystemRoadFrontage] = []
  let pedestrian_spurs : Array[EcosystemPedestrianSpur] = []
  for index, candidate in candidates {
    let entrance_id = ecosystem_scoped_id(
      "portal",
      "\{place_id}-road-\{candidate.road.x}-\{candidate.road.y}",
    )
    entrances.push({
      id: entrance_id,
      place_id,
      label: if index == 0 {
        "main"
      } else {
        "secondary"
      },
      threshold: candidate.threshold,
      access_point: candidate.road,
      direction: candidate.direction,
      portal_kind: "building-door",
      primary: index == 0,
      accessible: true,
    })
    frontages.push({
      id: entrance_id,
      place_id,
      entrance_id,
      road_cell_id: ecosystem_road_cell_id(candidate.road.x, candidate.road.y),
      road_class: ecosystem_road_class_at(
        world,
        custom_roads,
        candidate.road.x,
        candidate.road.y,
      ),
      road_mask: ecosystem_road_mask_at(
        world,
        custom_buildings,
        custom_roads,
        custom_parks,
        candidate.road.x,
        candidate.road.y,
      ),
      distance: candidate.distance,
      direct: candidate.direct,
    })
    if !candidate.direct && candidate.path.length() >= 2 {
      pedestrian_spurs.push({
        id: ecosystem_scoped_id("pedestrian-spur", entrance_id),
        place_id,
        entrance_id,
        road_cell_id: ecosystem_road_cell_id(candidate.road.x, candidate.road.y),
        path: candidate.path,
        distance: candidate.distance,
      })
    }
  }
  (entrances, frontages, pedestrian_spurs)
}

///|
fn ecosystem_canonical_runtime_key(key : String) -> String {
  match key {
    "vitality-dashboard" => "vitality-tower"
    "broadcast-tower" => "story-radar"
    other => other
  }
}

///|
fn ecosystem_runtime_key_matches(left : String, right : String) -> Bool {
  ecosystem_canonical_runtime_key(left) ==
  ecosystem_canonical_runtime_key(right)
}

///|
fn ecosystem_place_runtime_binding(
  runtime_key : String?,
) -> EcosystemPlaceRuntimeBinding {
  { runtime_key, }
}

///|
fn ecosystem_footprint_near_terrain(
  world : ExactEnergyValleyWorld,
  custom_buildings : Array[GoldenValleyBuilding],
  custom_roads : Array[String],
  custom_parks : Array[String],
  footprint : EcosystemFootprint,
  terrain : String,
  radius : Int,
) -> Bool {
  for y in (footprint.y - radius)..<(footprint.y + footprint.depth + radius) {
    for x in (footprint.x - radius)..<(footprint.x + footprint.width + radius) {
      if ecosystem_effective_terrain(
          world, custom_buildings, custom_roads, custom_parks, x, y,
        ) ==
        terrain {
        return true
      }
    }
  }
  false
}

///|
fn ecosystem_footprint_near_metro(footprint : EcosystemFootprint) -> Bool {
  let center_x = footprint.x.to_double() + footprint.width.to_double() / 2.0
  let center_y = footprint.y.to_double() + footprint.depth.to_double() / 2.0
  metro_line17_stations().any(station => {
    ecosystem_int_abs((station.x - center_x).round().to_int()) +
    ecosystem_int_abs((station.y - center_y).round().to_int()) <=
    14
  })
}

///|
fn ecosystem_program_trait(style : String, runtime_key : String?) -> String {
  match runtime_key {
    Some("town-shell") | Some("policy-hall") => return "governance"
    Some("social-square") | Some("valley-market") => return "social"
    Some("ai-garden") => return "learning-garden"
    Some("talent-avenue") | Some("resident-twins") => return "residential"
    Some(key) if key.has_prefix("research-") => return "research"
    _ => ()
  }
  match style {
    "lab" | "custom-lab" | "industrial" => "research"
    "home" | "custom-home" | "row" | "lowrise" | "courtyard" => "residential"
    "market" | "plaza" | "garden" => "social"
    "tower" | "custom-tower" | "block" | "campus" => "workplace"
    _ => "mixed-use"
  }
}

///|
fn ecosystem_place_traits(
  world : ExactEnergyValleyWorld,
  custom_buildings : Array[GoldenValleyBuilding],
  custom_roads : Array[String],
  custom_parks : Array[String],
  district : String,
  style : String,
  source : String,
  floors : Int,
  runtime_key : String?,
  footprint : EcosystemFootprint,
  access : Array[EcosystemRoadFrontage],
) -> Array[EcosystemTrait] {
  let traits : Array[EcosystemTrait] = [
    { key: "district", value: district, salience: 35 },
    {
      key: "program",
      value: ecosystem_program_trait(style, runtime_key),
      salience: 75,
    },
    { key: "style", value: style, salience: 45 },
    { key: "source", value: source, salience: 20 },
    { key: "floors", value: floors.to_string(), salience: 30 },
  ]
  if access.is_empty() {
    traits.push({ key: "road-access", value: "unresolved", salience: 90 })
  } else if access.any(item => item.direct) {
    traits.push({ key: "road-access", value: "direct", salience: 65 })
  } else {
    traits.push({ key: "road-access", value: "linked", salience: 70 })
  }
  if ecosystem_footprint_near_terrain(
      world, custom_buildings, custom_roads, custom_parks, footprint, "water", 3,
    ) {
    traits.push({ key: "setting", value: "waterfront", salience: 82 })
  }
  if ecosystem_footprint_near_metro(footprint) {
    traits.push({ key: "mobility", value: "metro-adjacent", salience: 80 })
  }
  traits
}

///|
fn ecosystem_attention_for_place(
  kind : EcosystemPlaceKind,
  style : String,
  waterfront : Bool,
) -> EcosystemAttentionProfile {
  let base = match kind {
    EcosystemCivicBuilding => (64, 52, 48, 5, 54)
    EcosystemAmbientBuilding => (34, 24, 28, 0, 22)
    EcosystemCustomBuilding => (56, 42, 38, 0, 82)
    EcosystemMetroStation => (68, 62, 58, 8, 58)
    EcosystemPublicRealm => (48, 55, 24, 0, 42)
    EcosystemLandmark => (76, 38, 22, 0, 58)
  }
  let style_visual = match style {
    "tower" | "radar" => 18
    "garden" | "plaza" | "waterway" => 14
    _ => 0
  }
  let water_visual = if waterfront { 12 } else { 0 }
  {
    visual: ecosystem_clamp_attention(base.0 + style_visual + water_visual),
    social: ecosystem_clamp_attention(base.1),
    activity: ecosystem_clamp_attention(base.2),
    urgency: ecosystem_clamp_attention(base.3),
    novelty: ecosystem_clamp_attention(base.4),
  }
}

///|
fn ecosystem_append_affordance(
  result : Array[EcosystemWorldAffordance],
  kind : EcosystemAffordanceKind,
  place_id : String?,
  identity : String,
  anchor : EcosystemGridPoint,
  capacity : Int,
  attention_weight : Int,
  enabled : Bool,
  evidence : String,
) -> Unit {
  result.push({
    id: ecosystem_scoped_id(
      "slot",
      "\{identity}-\{ecosystem_affordance_key(kind)}",
    ),
    kind,
    place_id,
    anchor,
    capacity,
    attention_weight,
    enabled,
    evidence,
  })
}

///|
fn ecosystem_append_place_affordances(
  result : Array[EcosystemWorldAffordance],
  place : EcosystemPlace,
  entrances : Array[EcosystemEntrance],
) -> Unit {
  ecosystem_append_affordance(
    result,
    EcosystemInspect,
    Some(place.id),
    place.id,
    place.anchor,
    1,
    12,
    true,
    "semantic-place",
  )
  let place_entrances = entrances.filter(item => item.place_id == place.id)
  let accessible = place_entrances.any(item => item.accessible)
  if !place_entrances.is_empty() {
    let mut primary = place_entrances[0]
    for entrance in place_entrances {
      if entrance.primary {
        primary = entrance
        break
      }
    }
    ecosystem_append_affordance(
      result,
      EcosystemEnter,
      Some(place.id),
      place.id,
      primary.access_point,
      (place.footprint.width * place.footprint.depth).max(1),
      20,
      primary.accessible,
      "road-frontage",
    )
  }
  let program = ecosystem_program_trait(place.style, place.runtime.runtime_key)
  match place.kind {
    EcosystemCivicBuilding | EcosystemAmbientBuilding => {
      ecosystem_append_affordance(
        result,
        EcosystemWork,
        Some(place.id),
        place.id,
        place.anchor,
        (place.footprint.width * place.footprint.depth / 2).max(2),
        42,
        accessible,
        "place-program",
      )
      if program == "research" || program == "governance" || program == "social" {
        ecosystem_append_affordance(
          result,
          EcosystemExchange,
          Some(place.id),
          place.id,
          place.anchor,
          8,
          48,
          accessible,
          "place-program",
        )
      }
      if program == "residential" || program == "social" {
        ecosystem_append_affordance(
          result,
          EcosystemGather,
          Some(place.id),
          place.id,
          place.anchor,
          12,
          45,
          accessible,
          "place-program",
        )
      }
    }
    EcosystemCustomBuilding => {
      ecosystem_append_affordance(
        result,
        EcosystemWork,
        Some(place.id),
        place.id,
        place.anchor,
        8,
        55,
        accessible,
        "player-delta",
      )
      ecosystem_append_affordance(
        result,
        EcosystemPublish,
        Some(place.id),
        place.id,
        place.anchor,
        1,
        70,
        accessible,
        "knowledge-building",
      )
    }
    EcosystemMetroStation =>
      ecosystem_append_affordance(
        result,
        EcosystemTravel,
        Some(place.id),
        place.id,
        place.anchor,
        80,
        72,
        true,
        "line-17",
      )
    EcosystemPublicRealm => {
      let kind = if place.style == "bench" || place.style == "park" {
        EcosystemRest
      } else {
        EcosystemObserve
      }
      ecosystem_append_affordance(
        result,
        kind,
        Some(place.id),
        place.id,
        place.anchor,
        if place.style == "park" {
          12
        } else {
          2
        },
        44,
        true,
        "public-realm-rule",
      )
    }
    EcosystemLandmark =>
      ecosystem_append_affordance(
        result,
        EcosystemObserve,
        Some(place.id),
        place.id,
        place.anchor,
        12,
        58,
        true,
        "wenyu-landmark",
      )
  }
}

///|
fn ecosystem_make_place(
  world : ExactEnergyValleyWorld,
  custom_buildings : Array[GoldenValleyBuilding],
  custom_roads : Array[String],
  custom_parks : Array[String],
  id : String,
  source_id : String,
  name : String,
  kind : EcosystemPlaceKind,
  district : String,
  style : String,
  footprint : EcosystemFootprint,
  floors : Int,
  runtime_key : String?,
  access : Array[EcosystemRoadFrontage],
) -> EcosystemPlace {
  let runtime = ecosystem_place_runtime_binding(runtime_key)
  let waterfront = ecosystem_footprint_near_terrain(
    world, custom_buildings, custom_roads, custom_parks, footprint, "water", 3,
  )
  {
    id,
    source_id,
    name,
    kind,
    district,
    style,
    footprint,
    anchor: {
      x: footprint.x + footprint.width / 2,
      y: footprint.y + footprint.depth / 2,
    },
    traits: ecosystem_place_traits(
      world, custom_buildings, custom_roads, custom_parks, district, style, source_id,
      floors, runtime_key, footprint, access,
    ),
    attention: ecosystem_attention_for_place(kind, style, waterfront),
    runtime,
  }
}

///|
fn ecosystem_append_building_place(
  world : ExactEnergyValleyWorld,
  road_network : @energy_valley_contract.RoadNetwork,
  road_nodes : Map[String, @energy_valley_contract.RoadNode],
  custom_buildings : Array[GoldenValleyBuilding],
  custom_roads : Array[String],
  custom_parks : Array[String],
  places : Array[EcosystemPlace],
  entrances : Array[EcosystemEntrance],
  frontages : Array[EcosystemRoadFrontage],
  pedestrian_spurs : Array[EcosystemPedestrianSpur],
  id : String,
  source_id : String,
  name : String,
  kind : EcosystemPlaceKind,
  district : String,
  style : String,
  footprint : EcosystemFootprint,
  floors : Int,
  runtime_key : String?,
  explicit_entrance : EcosystemGridPoint?,
) -> Unit {
  let access = ecosystem_building_access(
    world, road_network, road_nodes, custom_buildings, custom_roads, custom_parks,
    id, footprint, explicit_entrance,
  )
  for entrance in access.0 {
    entrances.push(entrance)
  }
  for frontage in access.1 {
    frontages.push(frontage)
  }
  for spur in access.2 {
    pedestrian_spurs.push(spur)
  }
  places.push(
    ecosystem_make_place(
      world,
      custom_buildings,
      custom_roads,
      custom_parks,
      id,
      source_id,
      name,
      kind,
      district,
      style,
      footprint,
      floors,
      runtime_key,
      access.1,
    ),
  )
}

///|
fn ecosystem_append_metro_places(
  world : ExactEnergyValleyWorld,
  road_network : @energy_valley_contract.RoadNetwork,
  road_nodes : Map[String, @energy_valley_contract.RoadNode],
  custom_buildings : Array[GoldenValleyBuilding],
  custom_roads : Array[String],
  custom_parks : Array[String],
  places : Array[EcosystemPlace],
  entrances : Array[EcosystemEntrance],
  frontages : Array[EcosystemRoadFrontage],
  pedestrian_spurs : Array[EcosystemPedestrianSpur],
) -> Unit {
  for station in metro_line17_stations() {
    let id = ecosystem_metro_station_id(station)
    let station_x = station.x.floor().to_int()
    let station_y = station.y.floor().to_int()
    let footprint : EcosystemFootprint = {
      x: station_x,
      y: station_y,
      width: 1,
      depth: 1,
    }
    let station_frontages : Array[EcosystemRoadFrontage] = []
    for index, exit in station.exits {
      let preferred = ecosystem_point(
        exit.x.floor().to_int(),
        exit.y.floor().to_int(),
      )
      let candidate = ecosystem_nearest_road_candidate(
        world, road_network, road_nodes, custom_buildings, custom_roads, custom_parks,
        footprint, preferred,
      )
      let access_point = match candidate {
        Some(value) => value.road
        None => preferred
      }
      let threshold = ecosystem_point(station_x, station_y)
      let entrance_id = ecosystem_scoped_id(
        "portal",
        "\{id}-exit-\{exit.label}",
      )
      entrances.push({
        id: entrance_id,
        place_id: id,
        label: exit.label,
        threshold,
        access_point,
        direction: match candidate {
          Some(value) => value.direction
          None => "linked"
        },
        portal_kind: "metro-exit",
        primary: index == 0,
        accessible: candidate is Some(_),
      })
      match candidate {
        Some(value) => {
          let frontage : EcosystemRoadFrontage = {
            id: entrance_id,
            place_id: id,
            entrance_id,
            road_cell_id: ecosystem_road_cell_id(value.road.x, value.road.y),
            road_class: ecosystem_road_class_at(
              world,
              custom_roads,
              value.road.x,
              value.road.y,
            ),
            road_mask: ecosystem_road_mask_at(
              world,
              custom_buildings,
              custom_roads,
              custom_parks,
              value.road.x,
              value.road.y,
            ),
            distance: value.distance,
            direct: value.direct,
          }
          frontages.push(frontage)
          station_frontages.push(frontage)
          if !value.direct && value.path.length() >= 2 {
            pedestrian_spurs.push({
              id: ecosystem_scoped_id("pedestrian-spur", entrance_id),
              place_id: id,
              entrance_id,
              road_cell_id: frontage.road_cell_id,
              path: value.path,
              distance: value.distance,
            })
          }
        }
        None => ()
      }
    }
    places.push(
      ecosystem_make_place(
        world,
        custom_buildings,
        custom_roads,
        custom_parks,
        id,
        "metro-line17",
        station.name,
        EcosystemMetroStation,
        world.tiles[station_y][station_x].district,
        "metro-station",
        footprint,
        1,
        None,
        station_frontages,
      ),
    )
  }
}

///|
fn ecosystem_append_landmark_places(
  world : ExactEnergyValleyWorld,
  custom_buildings : Array[GoldenValleyBuilding],
  custom_roads : Array[String],
  custom_parks : Array[String],
  places : Array[EcosystemPlace],
) -> Unit {
  let landmarks = [
    (
      ecosystem_scoped_id("place", "landmark-civic-core"),
      "civic-core",
      "能源谷核心",
      "civic-core",
      world.landmarks.civic_core_x,
      world.landmarks.civic_core_y,
    ),
    (
      ecosystem_scoped_id("place", "landmark-wenyu-waterway"),
      "wenyu-waterway",
      "温榆河水系",
      "waterway",
      world.landmarks.feeder_head_x,
      world.landmarks.river_crossing_y,
    ),
    (
      ecosystem_scoped_id("place", "landmark-south-arterial"),
      "south-arterial",
      "南部主廊道",
      "arterial",
      world.landmarks.civic_core_x,
      world.landmarks.south_arterial_y,
    ),
  ]
  for landmark in landmarks {
    let x = landmark.4.max(0).min(world.cols - 1)
    let y = landmark.5.max(0).min(world.rows - 1)
    let footprint : EcosystemFootprint = { x, y, width: 1, depth: 1 }
    places.push(
      ecosystem_make_place(
        world,
        custom_buildings,
        custom_roads,
        custom_parks,
        landmark.0,
        landmark.1,
        landmark.2,
        EcosystemLandmark,
        world.tiles[y][x].district,
        landmark.3,
        footprint,
        0,
        None,
        [],
      ),
    )
  }
}

///|
fn ecosystem_public_realm_place(
  world : ExactEnergyValleyWorld,
  custom_buildings : Array[GoldenValleyBuilding],
  custom_roads : Array[String],
  custom_parks : Array[String],
  x : Int,
  y : Int,
  feature : String,
  name : String,
) -> EcosystemPlace {
  let id = ecosystem_scoped_id("place", "public-\{feature}-\{x}-\{y}")
  ecosystem_make_place(
    world,
    custom_buildings,
    custom_roads,
    custom_parks,
    id,
    "public-realm-rule",
    name,
    EcosystemPublicRealm,
    world.tiles[y][x].district,
    feature,
    { x, y, width: 1, depth: 1 },
    0,
    None,
    [],
  )
}

///|
fn ecosystem_build_roads_and_public_realm(
  world : ExactEnergyValleyWorld,
  custom_buildings : Array[GoldenValleyBuilding],
  custom_roads : Array[String],
  custom_parks : Array[String],
  places : Array[EcosystemPlace],
  affordances : Array[EcosystemWorldAffordance],
) -> Array[EcosystemRoadCell] {
  let roads : Array[EcosystemRoadCell] = []
  let seed = world.seed.reinterpret_as_int()
  for y in 0..<world.rows {
    for x in 0..<world.cols {
      let terrain = ecosystem_effective_terrain(
        world, custom_buildings, custom_roads, custom_parks, x, y,
      )
      let tile = world.tiles[y][x]
      let occupied = tile.building_id is Some(_) ||
        custom_buildings.any(building => {
          golden_valley_building_contains(building, x, y)
        })
      let boardwalk_mask = golden_public_realm_boardwalk_mask(
        terrain,
        tile.district,
        ecosystem_effective_terrain(
          world,
          custom_buildings,
          custom_roads,
          custom_parks,
          x,
          y - 1,
        ),
        ecosystem_effective_terrain(
          world,
          custom_buildings,
          custom_roads,
          custom_parks,
          x + 1,
          y,
        ),
        ecosystem_effective_terrain(
          world,
          custom_buildings,
          custom_roads,
          custom_parks,
          x,
          y + 1,
        ),
        ecosystem_effective_terrain(
          world,
          custom_buildings,
          custom_roads,
          custom_parks,
          x - 1,
          y,
        ),
      )
      if ecosystem_is_road(terrain) {
        let road_mask = ecosystem_road_mask_at(
          world, custom_buildings, custom_roads, custom_parks, x, y,
        )
        let road_class = ecosystem_road_class_at(world, custom_roads, x, y)
        roads.push({
          id: ecosystem_road_cell_id(x, y),
          x,
          y,
          road_class,
          road_mask,
          bridge: terrain == "bridge",
          custom: custom_roads.contains(golden_valley_tile_key(x, y)),
          streetlight: golden_public_realm_streetlight_at(
            seed,
            x,
            y,
            terrain,
            road_mask,
            road_class == "major",
          ),
          street_tree: golden_public_realm_street_tree_at(
            seed, x, y, terrain, road_mask,
          ),
          boardwalk_mask,
        })
      }
      if boardwalk_mask != 0 {
        ecosystem_append_affordance(
          affordances,
          EcosystemObserve,
          None,
          "boardwalk-\{x}-\{y}",
          ecosystem_point(x, y),
          4,
          46,
          true,
          "wenyu-water-edge",
        )
      }
      let plaza_feature = golden_public_realm_plaza_feature(
        seed, x, y, terrain, occupied,
      )
      if plaza_feature == 1 {
        places.push(
          ecosystem_public_realm_place(
            world, custom_buildings, custom_roads, custom_parks, x, y, "bench", "街角长椅",
          ),
        )
      } else if plaza_feature == 2 {
        places.push(
          ecosystem_public_realm_place(
            world, custom_buildings, custom_roads, custom_parks, x, y, "planter",
            "街角花池",
          ),
        )
      }
      if custom_parks.contains(golden_valley_tile_key(x, y)) {
        places.push(
          ecosystem_public_realm_place(
            world, custom_buildings, custom_roads, custom_parks, x, y, "park", "共建林地",
          ),
        )
      }
    }
  }
  roads
}

///|
fn ecosystem_world_snapshot(
  world : ExactEnergyValleyWorld,
  custom_buildings : Array[GoldenValleyBuilding],
  custom_roads : Array[String],
  custom_parks : Array[String],
) -> EcosystemWorldSnapshot {
  let places : Array[EcosystemPlace] = []
  let entrances : Array[EcosystemEntrance] = []
  let road_frontages : Array[EcosystemRoadFrontage] = []
  let pedestrian_spurs : Array[EcosystemPedestrianSpur] = []
  let affordances : Array[EcosystemWorldAffordance] = []
  // Road cells are compiler input for every doorway, not a late rendering
  // side effect. Public-realm pseudo-places are collected separately so the
  // historical place ordering remains buildings -> transit -> landmarks ->
  // public realm even though the authoritative graph is available first.
  let public_realm_places : Array[EcosystemPlace] = []
  let roads = ecosystem_build_roads_and_public_realm(
    world, custom_buildings, custom_roads, custom_parks, public_realm_places, affordances,
  )
  let road_network = ecosystem_contract_base_road_network(roads)
  let road_nodes = ecosystem_road_network_node_lookup(road_network)
  for building in world.buildings {
    ecosystem_append_building_place(
      world,
      road_network,
      road_nodes,
      custom_buildings,
      custom_roads,
      custom_parks,
      places,
      entrances,
      road_frontages,
      pedestrian_spurs,
      ecosystem_scoped_id("place", building.id),
      building.id,
      building.name,
      EcosystemCivicBuilding,
      world.tiles[building.y][building.x].district,
      building.style,
      {
        x: building.x,
        y: building.y,
        width: building.width,
        depth: building.depth,
      },
      building.floors,
      Some(building.module_key),
      Some(ecosystem_point(building.entrance_x, building.entrance_y)),
    )
  }
  // Ambient structures are anchored once in their footprint. Reading only
  // those anchors prevents the tile representation from duplicating places.
  for y in 0..<world.rows {
    for x in 0..<world.cols {
      match world.structure_footprint_at(x, y) {
        None => ()
        Some((style, floors, width, depth)) => {
          let source_id = world.tiles[y][x].building_id.unwrap_or(
            "ambient-\{x}-\{y}",
          )
          ecosystem_append_building_place(
            world,
            road_network,
            road_nodes,
            custom_buildings,
            custom_roads,
            custom_parks,
            places,
            entrances,
            road_frontages,
            pedestrian_spurs,
            ecosystem_scoped_id("place", source_id),
            source_id,
            ecosystem_ambient_place_name(style, x, y),
            EcosystemAmbientBuilding,
            world.tiles[y][x].district,
            style,
            { x, y, width, depth },
            floors,
            None,
            None,
          )
        }
      }
    }
  }
  for building in custom_buildings {
    let id = ecosystem_custom_place_id(building)
    let explicit = match (building.entrance_x, building.entrance_y) {
      (Some(x), Some(y)) => Some(ecosystem_point(x, y))
      _ => None
    }
    ecosystem_append_building_place(
      world,
      road_network,
      road_nodes,
      custom_buildings,
      custom_roads,
      custom_parks,
      places,
      entrances,
      road_frontages,
      pedestrian_spurs,
      id,
      "player-delta",
      building.name,
      EcosystemCustomBuilding,
      world.tiles[building.y][building.x].district,
      building.style,
      {
        x: building.x,
        y: building.y,
        width: building.width,
        depth: building.depth,
      },
      building.floors,
      building.module_key,
      explicit,
    )
  }
  ecosystem_append_metro_places(
    world, road_network, road_nodes, custom_buildings, custom_roads, custom_parks,
    places, entrances, road_frontages, pedestrian_spurs,
  )
  ecosystem_append_landmark_places(
    world, custom_buildings, custom_roads, custom_parks, places,
  )
  for place in public_realm_places {
    places.push(place)
  }
  for place in places {
    ecosystem_append_place_affordances(affordances, place, entrances)
  }
  {
    schema: ecosystem_world_schema(),
    seed: world.seed,
    cols: world.cols,
    rows: world.rows,
    places,
    entrances,
    road_frontages,
    pedestrian_spurs,
    roads,
    road_network,
    affordances,
  }
}

///|
/// Minimal adoption hook for the current TEA model. Consumers can call this
/// without knowing how localStorage overlays are represented.
fn ecosystem_world_snapshot_for_model(
  model : Model,
  seed : Int,
) -> EcosystemWorldSnapshot {
  let projected = energy_valley_validated_world_delta_projection(model, seed)
  ecosystem_world_snapshot(
    golden_valley_world(seed),
    projected.buildings,
    projected.roads,
    projected.parks,
  )
}

///|
fn ecosystem_place_by_id(
  snapshot : EcosystemWorldSnapshot,
  id : String,
) -> EcosystemPlace? {
  for place in snapshot.places {
    if place.id == id {
      return Some(place)
    }
  }
  None
}

///|
fn ecosystem_frontages_for_place(
  snapshot : EcosystemWorldSnapshot,
  place_id : String,
) -> Array[EcosystemRoadFrontage] {
  snapshot.road_frontages.filter(link => link.place_id == place_id)
}

///|
fn ecosystem_pedestrian_spur_for_entrance(
  snapshot : EcosystemWorldSnapshot,
  entrance_id : String,
) -> EcosystemPedestrianSpur? {
  for spur in snapshot.pedestrian_spurs {
    if spur.entrance_id == entrance_id {
      return Some(spur)
    }
  }
  None
}

///|
fn ecosystem_affordances_for_place(
  snapshot : EcosystemWorldSnapshot,
  place_id : String,
) -> Array[EcosystemWorldAffordance] {
  snapshot.affordances.filter(affordance => {
    affordance.place_id == Some(place_id)
  })
}
