///|
/// Immutable renderer facts derived only from `TownSnapshot`. These records
/// deliberately contain presentation geometry, never mutable UI state. The
/// canvas may choose colors and animation, but it cannot rediscover roads,
/// buildings, entrances or identities from the legacy tile generator.
priv struct TownCanvasRoadCell {
  node_id : @energy_valley_contract.StableId
  x : Int
  y : Int
  mask : Int
  road_class : @energy_valley_contract.RoadClass
  bridge : Bool
} derive(Debug, Eq)

///|
fn town_canvas_road_class_priority(
  road_class : @energy_valley_contract.RoadClass,
) -> Int {
  match road_class {
    @energy_valley_contract.Bridge => 6
    @energy_valley_contract.Arterial => 5
    @energy_valley_contract.Collector => 4
    @energy_valley_contract.Local => 3
    @energy_valley_contract.Service => 2
    @energy_valley_contract.Footpath => 1
  }
}

///|
fn town_snapshot_canvas_cols(
  snapshot : @energy_valley_contract.TownSnapshot,
) -> Int {
  (snapshot.world.bounds.maximum.x - snapshot.world.bounds.minimum.x)
  .ceil()
  .to_int()
  .max(1)
}

///|
fn town_snapshot_canvas_rows(
  snapshot : @energy_valley_contract.TownSnapshot,
) -> Int {
  (snapshot.world.bounds.maximum.y - snapshot.world.bounds.minimum.y)
  .ceil()
  .to_int()
  .max(1)
}

///|
fn town_canvas_stronger_road_class(
  current : @energy_valley_contract.RoadClass,
  candidate : @energy_valley_contract.RoadClass,
) -> @energy_valley_contract.RoadClass {
  if town_canvas_road_class_priority(candidate) >
    town_canvas_road_class_priority(current) {
    candidate
  } else {
    current
  }
}

///|
fn town_canvas_road_key(x : Int, y : Int) -> String {
  "\{x}:\{y}"
}

///|
fn town_snapshot_canvas_roads(
  snapshot : @energy_valley_contract.TownSnapshot,
) -> Array[TownCanvasRoadCell] {
  let source_nodes : Map[
    @energy_valley_contract.StableId,
    @energy_valley_contract.RoadNode,
  ] = Map([])
  let classes : Map[
    @energy_valley_contract.StableId,
    @energy_valley_contract.RoadClass,
  ] = Map([])
  let masks : Map[@energy_valley_contract.StableId, Int] = Map([])
  for node in snapshot.world.road_network.nodes {
    if node.id.scope() == "road-node" {
      source_nodes[node.id] = node
      classes[node.id] = @energy_valley_contract.Local
      masks[node.id] = 0
    }
  }
  for segment in snapshot.world.road_network.segments {
    // Pedestrian spurs are rendered as paths, not full road diamonds. Their
    // geometry remains in this same network and is consumed separately.
    if segment.road_class is @energy_valley_contract.Footpath {
      continue
    }
    for node_id in [segment.from_node_id, segment.to_node_id] {
      if source_nodes.contains(node_id) {
        classes[node_id] = town_canvas_stronger_road_class(
          classes.get(node_id).unwrap_or(@energy_valley_contract.Local),
          segment.road_class,
        )
      }
    }
    match
      (
        source_nodes.get(segment.from_node_id),
        source_nodes.get(segment.to_node_id),
      ) {
      (Some(from), Some(to)) => {
        let delta_x = to.grid.column - from.grid.column
        let delta_y = to.grid.row - from.grid.row
        let bits = match (delta_x, delta_y) {
          (0, -1) => (1, 4)
          (1, 0) => (2, 8)
          (0, 1) => (4, 1)
          (-1, 0) => (8, 2)
          _ => (0, 0)
        }
        if bits.0 != 0 {
          masks[from.id] = masks.get(from.id).unwrap_or(0) | bits.0
          masks[to.id] = masks.get(to.id).unwrap_or(0) | bits.1
        }
      }
      _ => ()
    }
  }
  let result : Array[TownCanvasRoadCell] = []
  for node in snapshot.world.road_network.nodes {
    if node.id.scope() != "road-node" {
      continue
    }
    let road_class = classes
      .get(node.id)
      .unwrap_or(@energy_valley_contract.Local)
    result.push({
      node_id: node.id,
      x: node.grid.column,
      y: node.grid.row,
      mask: masks.get(node.id).unwrap_or(0),
      road_class,
      bridge: road_class is @energy_valley_contract.Bridge,
    })
  }
  result
}

///|
fn town_snapshot_canvas_road_at(
  roads : ArrayView[TownCanvasRoadCell],
  x : Int,
  y : Int,
) -> TownCanvasRoadCell? {
  for road in roads {
    if road.x == x && road.y == y {
      return Some(road)
    }
  }
  None
}

///|
fn town_snapshot_canvas_road_lookup(
  roads : ArrayView[TownCanvasRoadCell],
) -> Map[String, TownCanvasRoadCell] {
  let result : Map[String, TownCanvasRoadCell] = Map([])
  for road in roads {
    result[town_canvas_road_key(road.x, road.y)] = road
  }
  result
}

///|
fn town_snapshot_canvas_terrain(
  snapshot : @energy_valley_contract.TownSnapshot,
  road : TownCanvasRoadCell?,
  x : Int,
  y : Int,
) -> String {
  match road {
    Some(value) => if value.bridge { "bridge" } else { "road" }
    None =>
      match ecosystem_contract_terrain_kind_at(snapshot.world, x, y) {
        Some(@energy_valley_contract.Meadow) => "grass"
        Some(@energy_valley_contract.Woodland) => "forest"
        Some(@energy_valley_contract.Water) => "water"
        Some(@energy_valley_contract.Wetland) => "wetland"
        Some(@energy_valley_contract.Paving) => "plaza"
        Some(@energy_valley_contract.Restricted) => "grass"
        Some(@energy_valley_contract.Custom(label)) => label
        None => "void"
      }
  }
}

///|
fn town_snapshot_canvas_variation(
  snapshot : @energy_valley_contract.TownSnapshot,
  x : Int,
  y : Int,
) -> Double {
  (ecosystem_stable_hash("\{snapshot.world.blueprint_digest}:\{x}:\{y}").abs() %
  1000).to_double() /
  1000.0
}

///|
priv struct TownCanvasBuilding {
  place_id : @energy_valley_contract.StableId
  name : String
  style : String
  x : Int
  y : Int
  width : Int
  depth : Int
  entrance_x : Int?
  entrance_y : Int?
  floors : Int
  interior_seed : Int
  module_key : String?
  authored_id : String?
} derive(Debug, Eq)

///|
fn town_canvas_place_bounds(
  place : @energy_valley_contract.Place,
) -> (Int, Int, Int, Int)? {
  if place.footprint.vertices.is_empty() {
    return None
  }
  let mut minimum_x = place.footprint.vertices[0].x
  let mut minimum_y = place.footprint.vertices[0].y
  let mut maximum_x = minimum_x
  let mut maximum_y = minimum_y
  for vertex in place.footprint.vertices {
    minimum_x = minimum_x.min(vertex.x)
    minimum_y = minimum_y.min(vertex.y)
    maximum_x = maximum_x.max(vertex.x)
    maximum_y = maximum_y.max(vertex.y)
  }
  let x = minimum_x.floor().to_int()
  let y = minimum_y.floor().to_int()
  Some(
    (
      x,
      y,
      (maximum_x.ceil().to_int() - x).max(1),
      (maximum_y.ceil().to_int() - y).max(1),
    ),
  )
}

///|
fn town_canvas_building_style(
  profile : @energy_valley_contract.BuildingProfile,
) -> String {
  match profile.archetype {
    // Compatibility for compiled worlds produced before archetype and parcel
    // program became separate semantic fields.
    "research-lab" => "lab"
    "research-garden" | "park-commons" | "park-pavilion" => "garden"
    "street-homes" | "residential-court" => "home"
    "valley-market" | "waterfront-pavilion" => "market"
    "civic-court" | "mixed-court" | "civic-hall" => "hall"
    "transit-hall" | "transit-court" => "radar"
    style => style
  }
}

///|
/// Resolve a compatibility building view against the compiled product world.
/// Stable authored identity wins, then runtime binding, then exact compiled
/// footprint. This adapter is the only remaining boundary for UI records that
/// still carry `GoldenValleyBuilding`; callers never consult the legacy world
/// snapshot or reconstruct a second place catalogue.
fn town_world_place_for_visual_building(
  world : @energy_valley_contract.CompiledTownWorld,
  building : GoldenValleyBuilding,
) -> @energy_valley_contract.Place? {
  match golden_valley_nonempty_authored_id(building) {
    Some(_) => {
      let id = ecosystem_contract_id(ecosystem_custom_place_id(building))
      match world.find_place(id) {
        Some(place) => return Some(place)
        None => ()
      }
    }
    None => ()
  }
  let runtime_key = golden_valley_building_module_key(building)
  if !runtime_key.is_empty() {
    for place in world.places {
      match place.runtime_binding {
        Some(binding) =>
          if ecosystem_runtime_key_matches(binding.resource_id, runtime_key) {
            return Some(place)
          }
        _ => ()
      }
    }
  }
  for place in world.places {
    match town_canvas_place_bounds(place) {
      Some((x, y, width, depth)) =>
        if x == building.x &&
          y == building.y &&
          width == building.width &&
          depth == building.depth {
          return Some(place)
        }
      _ => ()
    }
  }
  None
}

///|
fn town_snapshot_place_for_visual_building(
  snapshot : @energy_valley_contract.TownSnapshot,
  building : GoldenValleyBuilding,
) -> @energy_valley_contract.Place? {
  town_world_place_for_visual_building(snapshot.world, building)
}

///|
fn town_snapshot_canvas_buildings(
  snapshot : @energy_valley_contract.TownSnapshot,
) -> Array[TownCanvasBuilding] {
  let result : Array[TownCanvasBuilding] = []
  for place in snapshot.world.places {
    match (place.kind, place.building, town_canvas_place_bounds(place)) {
      (
        @energy_valley_contract.Building,
        Some(profile),
        Some((x, y, width, depth)),
      ) => {
        let portal = place.primary_entrance()
        result.push({
          place_id: place.id,
          name: place.name,
          style: town_canvas_building_style(profile),
          x,
          y,
          width,
          depth,
          entrance_x: portal.map(value => value.position.x.floor().to_int()),
          entrance_y: portal.map(value => value.position.y.floor().to_int()),
          floors: profile.floors,
          interior_seed: profile.interior_seed,
          module_key: place.runtime_binding.map(binding => binding.resource_id),
          authored_id: if place.provenance.kind
            is @energy_valley_contract.UserDelta {
            Some(place.id.local_key())
          } else {
            None
          },
        })
      }
      _ => ()
    }
  }
  result
}

///|
/// A presentation-only compatibility view for the mature isometric massing
/// primitives. No placement, identity, routing or persistence decision may
/// consume this value; those operations use the semantic `Place` above.
fn TownCanvasBuilding::visual(
  self : TownCanvasBuilding,
) -> GoldenValleyBuilding {
  {
    authored_id: self.authored_id,
    module_key: self.module_key,
    name: self.name,
    style: self.style,
    x: self.x,
    y: self.y,
    width: self.width,
    depth: self.depth,
    entrance_x: self.entrance_x,
    entrance_y: self.entrance_y,
    floors: self.floors,
  }
}
