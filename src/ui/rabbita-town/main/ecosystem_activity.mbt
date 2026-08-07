///|
priv enum EcosystemResidentPhase {
  EcosystemTraveling
  EcosystemArriving
  EcosystemInside
  EcosystemUnreachable
} derive(Debug, Eq)

///|
/// A resident journey is computed from the resident's semantic schedule and
/// the shared road graph. The sprite consumes this route record; the contract
/// compiler projects it into `TownSnapshot.actor_presences`, which is the sole
/// occupancy authority used by place surfaces.
priv struct EcosystemResidentActivity {
  resident_id : String
  resident_name : String
  role : String
  role_label : String
  sprite_index : Int
  source_place_id : String
  place_id : String
  behavior : EcosystemBehavior
  short_label : String
  detail : String
  interaction_label : String
  phase : EcosystemResidentPhase
  progress_per_mille : Int
  route : Array[(Double, Double)]
  position : (Double, Double)?
  facing_left : Bool
  started_tick : Int
  transition_tick : Int
} derive(Debug)

///|
fn ecosystem_schedule_position(
  profile : EcosystemPreviewResidentProfile,
  tick : Int,
) -> (Int, EcosystemScheduleBeat, Int) {
  let total = ecosystem_schedule_total(profile)
  let phase = ecosystem_positive_mod(tick + profile.phase_offset, total)
  let mut cursor = 0
  for index, beat in profile.schedule {
    let duration = beat.duration_ticks.max(1)
    if phase < cursor + duration {
      return (index, beat, tick - (phase - cursor))
    }
    cursor += duration
  }
  (0, profile.schedule[0], tick)
}

///|
fn ecosystem_activity_role(index : Int) -> String {
  if index == 0 {
    "mayor"
  } else if index < 4 {
    "keeper"
  } else if index < 9 {
    "researcher"
  } else {
    "resident"
  }
}

///|
fn ecosystem_activity_travel_ticks(beat : EcosystemScheduleBeat) -> Int {
  (beat.duration_ticks / 4).clamp(min=3, max=6)
}

///|
fn ecosystem_activity_progress(elapsed : Int, travel_ticks : Int) -> Int {
  if travel_ticks <= 0 {
    1000
  } else {
    (elapsed.max(0) * 1000 / travel_ticks).clamp(min=0, max=1000)
  }
}

///|
fn ecosystem_activity_position(
  path : Array[(Double, Double)],
  progress_per_mille : Int,
) -> ((Double, Double), Bool)? {
  if path.is_empty() {
    return None
  }
  if path.length() == 1 {
    return Some((path[0], false))
  }
  let route_distance = (path.length() - 1).to_double()
  let distance = (route_distance *
  progress_per_mille.min(998).to_double() /
  1000.0).max(0.0)
  match golden_valley_path_point(path, distance) {
    None => None
    Some(point) => {
      let next_distance = (distance + 0.12).min(route_distance - 0.001)
      let next = golden_valley_path_point(path, next_distance).unwrap_or(point)
      Some((point, golden_valley_path_direction_is_left(point, next)))
    }
  }
}

///|
/// Contract routes are stable across animation frames and change only when the
/// compiled world or a portal pair changes. Empty cached paths represent an
/// unresolved route without repeatedly traversing the full Wenyu graph.
let ecosystem_activity_route_cache : Map[String, Array[(Double, Double)]] = Map([],
)

///|
fn ecosystem_activity_contract_path(
  model : Model,
  seed : Int,
  source_profile_id : String,
  destination_profile_id : String,
) -> Array[(Double, Double)]? {
  let world_key = ecosystem_snapshot_cache_key(model, seed)
  let cache_key = "\{world_key}|\{source_profile_id}|\{destination_profile_id}"
  match ecosystem_activity_route_cache.get(cache_key) {
    Some(path) => return if path.is_empty() { None } else { Some(path) }
    None => ()
  }
  let world = ecosystem_contract_world_for_model(model, seed)
  let source_id = ecosystem_contract_place_id_from_profile(source_profile_id)
  let destination_id = ecosystem_contract_place_id_from_profile(
    destination_profile_id,
  )
  let path = match
    (world.find_place(source_id), world.find_place(destination_id)) {
    (Some(source), Some(destination)) =>
      match (source.primary_entrance(), destination.primary_entrance()) {
        (Some(source_portal), Some(destination_portal)) =>
          match (source_portal.road_node_id, destination_portal.road_node_id) {
            (Some(source_node), Some(destination_node)) =>
              match
                world.road_network.shortest_path(
                  source_node,
                  destination_node,
                  mode=@energy_valley_contract.Pedestrian,
                ) {
                None => None
                Some(nodes) => {
                  let points : Array[(Double, Double)] = [
                    (source_portal.position.x, source_portal.position.y),
                  ]
                  for node in nodes {
                    let point = (node.position.x, node.position.y)
                    if points[points.length() - 1] != point {
                      points.push(point)
                    }
                  }
                  let destination_point = (
                    destination_portal.position.x,
                    destination_portal.position.y,
                  )
                  if points[points.length() - 1] != destination_point {
                    points.push(destination_point)
                  }
                  Some(points)
                }
              }
            _ => None
          }
        _ => None
      }
    _ => None
  }
  if ecosystem_activity_route_cache.length() >= 96 {
    ecosystem_activity_route_cache.clear()
  }
  match path {
    Some(points) => {
      ecosystem_activity_route_cache[cache_key] = points
      Some(points)
    }
    None => {
      ecosystem_activity_route_cache[cache_key] = []
      None
    }
  }
}

///|
fn ecosystem_activity_source_portal_position(
  model : Model,
  seed : Int,
  source_profile_id : String,
) -> (Double, Double)? {
  match
    ecosystem_contract_world_for_model(model, seed).find_place(
      ecosystem_contract_place_id_from_profile(source_profile_id),
    ) {
    None => None
    Some(place) =>
      place
      .primary_entrance()
      .map(portal => (portal.position.x, portal.position.y))
  }
}

///|
let ecosystem_resident_activity_cache : Map[
  String,
  Array[EcosystemResidentActivity],
] = Map([])

///|
fn ecosystem_resident_activities(
  model : Model,
  seed : Int,
) -> Array[EcosystemResidentActivity] {
  let activity_cache_key = "\{ecosystem_snapshot_cache_key(model, seed)}|tick:\{model.tick}"
  match ecosystem_resident_activity_cache.get(activity_cache_key) {
    Some(cached) => return cached
    None => ()
  }
  let result : Array[EcosystemResidentActivity] = []
  for index, profile in ecosystem_preview_resident_profiles() {
    let (beat_index, beat, started_tick) = ecosystem_schedule_position(
      profile,
      model.tick,
    )
    let previous_index = ecosystem_positive_mod(
      beat_index - 1,
      profile.schedule.length(),
    )
    let previous = profile.schedule[previous_index]
    let intention = ecosystem_preview_canvas_intention(model, index)
    let travel_ticks = ecosystem_activity_travel_ticks(beat)
    let elapsed = model.tick - started_tick
    let progress = ecosystem_activity_progress(elapsed, travel_ticks)
    let path = ecosystem_activity_contract_path(
      model,
      seed,
      previous.place_id,
      beat.place_id,
    )
    let position_and_facing = match path {
      Some(route) if elapsed < travel_ticks =>
        ecosystem_activity_position(route, progress)
      None =>
        ecosystem_activity_source_portal_position(
          model,
          seed,
          previous.place_id,
        ).map(point => (point, false))
      _ => None
    }
    let phase = if path is None {
      EcosystemUnreachable
    } else if elapsed >= travel_ticks {
      EcosystemInside
    } else if elapsed + 1 >= travel_ticks {
      EcosystemArriving
    } else {
      EcosystemTraveling
    }
    result.push({
      resident_id: profile.id,
      resident_name: profile.name,
      role: ecosystem_activity_role(index),
      role_label: profile.role,
      sprite_index: profile.sprite_index,
      source_place_id: previous.place_id,
      place_id: beat.place_id,
      behavior: intention.behavior,
      short_label: intention.short_label,
      detail: intention.detail,
      interaction_label: intention.interaction_label,
      phase,
      progress_per_mille: if path is None {
        0
      } else {
        progress
      },
      route: path.unwrap_or([]),
      position: position_and_facing.map(pair => pair.0),
      facing_left: position_and_facing.map(pair => pair.1).unwrap_or(false),
      started_tick,
      transition_tick: started_tick + beat.duration_ticks.max(1),
    })
  }
  ecosystem_resident_activity_cache.clear()
  ecosystem_resident_activity_cache[activity_cache_key] = result
  result
}
