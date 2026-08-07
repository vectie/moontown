///|
fn golden_valley_semantic_road_node_at(
  world : @energy_valley_contract.CompiledTownWorld,
  x : Int,
  y : Int,
) -> @energy_valley_contract.RoadNode? {
  for node in world.road_network.nodes {
    // Pedestrian spur nodes may share a threshold coordinate with a road
    // cell. Only source road nodes represent the public carriageway raster.
    if node.id.scope() == "road-node" &&
      node.grid.column == x &&
      node.grid.row == y {
      return Some(node)
    }
  }
  None
}

///|
/// Public walkability is no longer reconstructed from a rendered terrain
/// string. The exact node set accepted into `CompiledTownWorld` is the only
/// road occupancy truth used by placement, player movement and Agents.
fn golden_valley_walkable(model : Model, seed : Int, x : Int, y : Int) -> Bool {
  golden_valley_semantic_road_node_at(
    ecosystem_contract_world_for_model(model, seed),
    x,
    y,
  )
  is Some(_)
}

///|
fn golden_valley_semantic_node_for_building(
  model : Model,
  seed : Int,
  building : GoldenValleyBuilding,
) -> @energy_valley_contract.RoadNode? {
  let world = ecosystem_contract_world_for_model(model, seed)
  match town_world_place_for_visual_building(world, building) {
    None => None
    Some(place) =>
      match place.primary_entrance() {
        Some(portal) =>
          match portal.road_node_id {
            Some(node_id) => world.road_network.find_node(node_id)
            None => None
          }
        None => None
      }
  }
}

///|
fn golden_valley_nearest_road(
  model : Model,
  seed : Int,
  building : GoldenValleyBuilding,
) -> (Int, Int)? {
  golden_valley_semantic_node_for_building(model, seed, building).map(node => {
    (node.grid.column, node.grid.row)
  })
}

///|
fn golden_valley_road_path(
  model : Model,
  seed : Int,
  start : (Int, Int),
  destination : (Int, Int),
) -> Array[(Double, Double)]? {
  let world = ecosystem_contract_world_for_model(model, seed)
  match
    (
      golden_valley_semantic_road_node_at(world, start.0, start.1),
      golden_valley_semantic_road_node_at(world, destination.0, destination.1),
    ) {
    (Some(origin), Some(target)) =>
      world.road_network
      .shortest_path(
        origin.id,
        target.id,
        mode=@energy_valley_contract.Pedestrian,
      )
      .map(nodes => {
        let result : Array[(Double, Double)] = []
        for node in nodes {
          result.push((node.position.x, node.position.y))
        }
        result
      })
    _ => None
  }
}

///|
fn golden_valley_building_road_path(
  model : Model,
  seed : Int,
  from : GoldenValleyBuilding,
  destination : GoldenValleyBuilding,
) -> Array[(Double, Double)]? {
  match
    (
      golden_valley_nearest_road(model, seed, from),
      golden_valley_nearest_road(model, seed, destination),
    ) {
    (Some(start), Some(end)) => golden_valley_road_path(model, seed, start, end)
    _ => None
  }
}

///|
fn golden_valley_path_point(
  path : Array[(Double, Double)],
  distance : Double,
) -> (Double, Double)? {
  if path.length() < 2 || distance >= (path.length() - 1).to_double() {
    return None
  }
  let clamped = if distance < 0.0 { 0.0 } else { distance }
  let index = clamped.floor().to_int()
  let fraction = clamped - index.to_double()
  let current = path[index]
  let next = path[index + 1]
  Some(
    (
      current.0 + (next.0 - current.0) * fraction,
      current.1 + (next.1 - current.1) * fraction,
    ),
  )
}

///|
fn golden_valley_commute_point(
  path : Array[(Double, Double)],
  elapsed_seconds : Double,
  speed : Double,
  phase_offset : Double,
  dwell_seconds : Double,
) -> (Double, Double)? {
  if path.length() < 2 {
    return None
  }
  let route_distance = (path.length() - 1).to_double()
  let cycle_distance = route_distance * 2.0 + dwell_seconds * speed * 2.0
  let travelled = elapsed_seconds * speed + phase_offset
  let cycle_index = (travelled / cycle_distance).floor()
  let phase = travelled - cycle_index * cycle_distance
  let dwell_distance = dwell_seconds * speed
  if phase < route_distance {
    golden_valley_path_point(path, phase)
  } else if phase < route_distance + dwell_distance {
    None
  } else if phase < route_distance * 2.0 + dwell_distance {
    let inbound = route_distance - (phase - route_distance - dwell_distance)
    golden_valley_path_point(
      path,
      if inbound >= route_distance {
        route_distance - 0.001
      } else {
        inbound
      },
    )
  } else {
    None
  }
}
