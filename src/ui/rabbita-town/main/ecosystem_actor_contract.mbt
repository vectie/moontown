///|
fn ecosystem_contract_actor_activity_kind(
  behavior : EcosystemBehavior,
) -> @energy_valley_contract.ActorActivityKind {
  match behavior {
    Coordinate => @energy_valley_contract.ActorCoordinate
    Research => @energy_valley_contract.ActorResearch
    Review => @energy_valley_contract.ActorReview
    Exchange => @energy_valley_contract.ActorExchange
    Observe => @energy_valley_contract.ActorObserve
    Learn => @energy_valley_contract.ActorLearn
    Browse => @energy_valley_contract.ActorBrowse
    Walk => @energy_valley_contract.ActorWalk
    Rest => @energy_valley_contract.ActorRest
    Deliver => @energy_valley_contract.ActorDeliver
    Celebrate => @energy_valley_contract.ActorCelebrate
  }
}

///|
fn ecosystem_contract_runtime_activity_kind(
  agent : EnergyValleyRuntimeAgent,
  work : EnergyValleyRuntimeWorkItem,
) -> @energy_valley_contract.ActorActivityKind {
  let raw = match golden_valley_optional_nonempty(agent.activityKind) {
    Some(value) => value
    None => work.activityKind.unwrap_or(work.status)
  }
  match raw.to_lower() {
    "researching" | "discovery" => @energy_valley_contract.ActorResearch
    "discussing" | "collaboration" => @energy_valley_contract.ActorExchange
    "reviewing" | "review" | "waiting_review" | "waiting" =>
      @energy_valley_contract.ActorReview
    "revising" | "revision_requested" => @energy_valley_contract.ActorRevise
    "returning" => @energy_valley_contract.ActorReturn
    "delivering" | "completed" => @energy_valley_contract.ActorDeliver
    "blocked" => @energy_valley_contract.ActorBlocked
    "failed" => @energy_valley_contract.ActorFailed
    "idle" => @energy_valley_contract.ActorIdle
    other => @energy_valley_contract.ActorCustom(other)
  }
}

///|
fn ecosystem_contract_runtime_actor_state(
  status : String,
) -> @energy_valley_contract.ActorStateKind {
  match status.to_lower() {
    "running" => @energy_valley_contract.ActorStateActive
    "waiting_review" => @energy_valley_contract.ActorStateWaitingReview
    "blocked" => @energy_valley_contract.ActorStateBlocked
    "failed" => @energy_valley_contract.ActorStateFailed
    "completed" => @energy_valley_contract.ActorStateCompleted
    "assigned" | "queued" => @energy_valley_contract.ActorStateAssigned
    _ => @energy_valley_contract.ActorStateIdle
  }
}

///|
fn ecosystem_contract_heading_degrees(
  from : (Double, Double),
  to : (Double, Double),
) -> Double {
  let dx = to.0 - from.0
  let dy = to.1 - from.1
  if dx.abs() >= dy.abs() {
    if dx >= 0.0 {
      0.0
    } else {
      180.0
    }
  } else if dy >= 0.0 {
    90.0
  } else {
    270.0
  }
}

///|
fn ecosystem_contract_road_node_at_point(
  world : @energy_valley_contract.CompiledTownWorld,
  point : (Double, Double),
) -> @energy_valley_contract.RoadNode? {
  for node in world.road_network.nodes {
    if (node.position.x - point.0).abs() < 0.001 &&
      (node.position.y - point.1).abs() < 0.001 {
      return Some(node)
    }
  }
  None
}

///|
priv struct EcosystemContractRouteLeg {
  from : (Double, Double)
  to : (Double, Double)
  origin_node_id : @energy_valley_contract.StableId?
  destination_node_id : @energy_valley_contract.StableId?
  road_segment_id : @energy_valley_contract.StableId?
}

///|
priv struct EcosystemContractRouteTopology {
  origin_node_id : @energy_valley_contract.StableId?
  destination_node_id : @energy_valley_contract.StableId?
  road_segment_id : @energy_valley_contract.StableId?
}

///|
let ecosystem_contract_route_topology_cache : Map[
  String,
  EcosystemContractRouteTopology,
] = Map([])

///|
fn ecosystem_contract_same_route_point(
  point : @energy_valley_contract.WorldPoint,
  value : (Double, Double),
) -> Bool {
  (point.x - value.0).abs() < 0.001 && (point.y - value.1).abs() < 0.001
}

///|
fn ecosystem_contract_route_topology(
  world : @energy_valley_contract.CompiledTownWorld,
  from : (Double, Double),
  to : (Double, Double),
) -> EcosystemContractRouteTopology {
  let cache_key = "\{world.blueprint_digest}|\{from.0},\{from.1}>\{to.0},\{to.1}"
  match ecosystem_contract_route_topology_cache.get(cache_key) {
    Some(cached) => return cached
    None => ()
  }
  let mut result : EcosystemContractRouteTopology = {
    origin_node_id: ecosystem_contract_road_node_at_point(world, from).map(node => {
      node.id
    }),
    destination_node_id: ecosystem_contract_road_node_at_point(world, to).map(node => {
      node.id
    }),
    road_segment_id: None,
  }
  for segment in world.road_network.segments {
    if !segment.supports(@energy_valley_contract.Pedestrian) ||
      segment.centerline.length() < 2 {
      continue
    }
    let first = segment.centerline[0]
    let last = segment.centerline[segment.centerline.length() - 1]
    if ecosystem_contract_same_route_point(first, from) &&
      ecosystem_contract_same_route_point(last, to) {
      result = {
        origin_node_id: Some(segment.from_node_id),
        destination_node_id: Some(segment.to_node_id),
        road_segment_id: Some(segment.id),
      }
      break
    }
    if segment.bidirectional &&
      ecosystem_contract_same_route_point(last, from) &&
      ecosystem_contract_same_route_point(first, to) {
      result = {
        origin_node_id: Some(segment.to_node_id),
        destination_node_id: Some(segment.from_node_id),
        road_segment_id: Some(segment.id),
      }
      break
    }
  }
  if ecosystem_contract_route_topology_cache.length() >= 2048 {
    ecosystem_contract_route_topology_cache.clear()
  }
  ecosystem_contract_route_topology_cache[cache_key] = result
  result
}

///|
fn ecosystem_contract_route_leg_at(
  world : @energy_valley_contract.CompiledTownWorld,
  path : Array[(Double, Double)],
  position : (Double, Double),
) -> EcosystemContractRouteLeg? {
  if path.length() < 2 {
    return None
  }
  let mut best_index = -1
  let mut best_distance_squared = 1.0e30
  for index in 1..<path.length() {
    let from = path[index - 1]
    let to = path[index]
    let dx = to.0 - from.0
    let dy = to.1 - from.1
    let length_squared = dx * dx + dy * dy
    if length_squared <= 0.0 {
      continue
    }
    let raw_ratio = ((position.0 - from.0) * dx + (position.1 - from.1) * dy) /
      length_squared
    let ratio = if raw_ratio < 0.0 {
      0.0
    } else if raw_ratio > 1.0 {
      1.0
    } else {
      raw_ratio
    }
    let projected_x = from.0 + dx * ratio
    let projected_y = from.1 + dy * ratio
    let distance_x = position.0 - projected_x
    let distance_y = position.1 - projected_y
    let distance_squared = distance_x * distance_x + distance_y * distance_y
    if distance_squared < best_distance_squared {
      best_distance_squared = distance_squared
      best_index = index
    }
  }
  if best_index < 1 {
    return None
  }
  let from = path[best_index - 1]
  let to = path[best_index]
  let topology = ecosystem_contract_route_topology(world, from, to)
  Some({
    from,
    to,
    origin_node_id: topology.origin_node_id,
    destination_node_id: topology.destination_node_id,
    road_segment_id: topology.road_segment_id,
  })
}

///|
fn ecosystem_contract_actor_route_position(
  world : @energy_valley_contract.CompiledTownWorld,
  path : Array[(Double, Double)],
  position : (Double, Double),
  progress_per_mille : Int,
) -> @energy_valley_contract.ActorRoutePosition {
  match ecosystem_contract_route_leg_at(world, path, position) {
    Some(leg) =>
      @energy_valley_contract.actor_route_position(
        @energy_valley_contract.world_point(position.0, position.1),
        progress_per_mille.clamp(min=0, max=1000),
        road_segment_id=leg.road_segment_id,
        origin_node_id=leg.origin_node_id,
        destination_node_id=leg.destination_node_id,
        heading_degrees=Some(
          ecosystem_contract_heading_degrees(leg.from, leg.to),
        ),
      )
    None => {
      let node_id = ecosystem_contract_road_node_at_point(world, position).map(node => {
        node.id
      })
      @energy_valley_contract.actor_route_position(
        @energy_valley_contract.world_point(position.0, position.1),
        progress_per_mille.clamp(min=0, max=1000),
        origin_node_id=node_id,
      )
    }
  }
}

///|
fn ecosystem_contract_ambient_actor_profile(
  activity : EcosystemResidentActivity,
) -> @energy_valley_contract.ActorProfile {
  @energy_valley_contract.actor_profile(
    ecosystem_contract_scoped_id("resident", activity.resident_id),
    activity.resident_name,
    activity.role_label,
    activity.role,
    activity.sprite_index.max(0),
    0,
    @energy_valley_contract.AmbientSimulation,
    @energy_valley_contract.ActorStateActive,
    ecosystem_contract_ambient_provenance(),
  )
}

///|
fn ecosystem_contract_runtime_actor_profile(
  agent : EnergyValleyRuntimeAgent,
  work : EnergyValleyRuntimeWorkItem,
  avatar_variant : Int,
) -> @energy_valley_contract.ActorProfile {
  @energy_valley_contract.actor_profile(
    ecosystem_contract_scoped_id("runtime-agent", agent.id),
    agent.name,
    agent.role,
    agent.role,
    avatar_variant.max(0),
    0,
    @energy_valley_contract.RuntimeEvidence,
    ecosystem_contract_runtime_actor_state(work.status),
    ecosystem_contract_runtime_provenance(),
  )
}

///|
fn ecosystem_contract_player_provenance() -> @energy_valley_contract.Provenance {
  @energy_valley_contract.provenance(
    "moontown-local-player",
    "v1",
    @energy_valley_contract.UserDelta,
    @energy_valley_contract.Free,
  )
}

///|
fn ecosystem_contract_nearest_player_place(
  world : @energy_valley_contract.CompiledTownWorld,
  position : (Double, Double),
) -> (@energy_valley_contract.Place, @energy_valley_contract.EntrancePortal)? {
  let mut best : (
    @energy_valley_contract.Place,
    @energy_valley_contract.EntrancePortal,
  )? = None
  let mut best_distance_squared = 1.0e30
  for place in world.places {
    match place.primary_entrance() {
      Some(portal) if portal.road_node_id is Some(_) => {
        let dx = position.0 - portal.position.x
        let dy = position.1 - portal.position.y
        let distance_squared = dx * dx + dy * dy
        if distance_squared < best_distance_squared {
          best_distance_squared = distance_squared
          best = Some((place, portal))
        }
      }
      _ => ()
    }
  }
  best
}

///|
fn ecosystem_contract_player_route(
  model : Model,
) -> (Array[(Double, Double)], Int) {
  match model.player_motion {
    Some(motion) if player_moving(model) => {
      let total = player_path_length(motion.path)
      let walked = ((golden_animation_seconds() - motion.started_seconds).max(
        0.0,
      ) *
      player_walk_speed).min(total)
      let progress = if total <= 0.0 {
        1000
      } else {
        (walked * 1000.0 / total).floor().to_int().clamp(min=0, max=999)
      }
      (motion.path, progress)
    }
    _ => ([], 1000)
  }
}

///|
fn ecosystem_contract_append_player_actor(
  model : Model,
  world : @energy_valley_contract.CompiledTownWorld,
  profiles : Array[@energy_valley_contract.ActorProfile],
  presences : Array[@energy_valley_contract.ActorPresence],
  presence_actor_ids : Map[@energy_valley_contract.StableId, Bool],
) -> Unit {
  guard model.player is Some(player) else { return }
  guard player_current_position(model) is Some(position) else { return }
  guard ecosystem_contract_nearest_player_place(world, position)
    is Some((place, portal)) else {
    return
  }
  let actor_id = ecosystem_contract_scoped_id("player", "local")
  if presence_actor_ids.contains(actor_id) {
    return
  }
  presence_actor_ids[actor_id] = true
  let moving = player_moving(model)
  let (route, progress) = ecosystem_contract_player_route(model)
  profiles.push(
    @energy_valley_contract.actor_profile(
      actor_id,
      player.name,
      if player.title.trim().is_empty() {
        player.persona
      } else {
        player.title
      },
      "resident",
      player.sprite_index.max(0),
      player.color.max(0),
      @energy_valley_contract.LocalEmbodiment,
      if moving {
        @energy_valley_contract.ActorStateActive
      } else {
        @energy_valley_contract.ActorStateIdle
      },
      ecosystem_contract_player_provenance(),
    ),
  )
  presences.push(
    @energy_valley_contract.actor_presence(
      actor_id,
      place.id,
      Some(portal.id),
      None,
      @energy_valley_contract.Approaching,
      if moving {
        "在能源谷路网上行走"
      } else {
        "在能源谷中探索"
      },
      0,
      None,
      ecosystem_contract_player_provenance(),
      route_position=Some(
        ecosystem_contract_actor_route_position(
          world, route, position, progress,
        ),
      ),
      activity_kind=if moving {
        @energy_valley_contract.ActorWalk
      } else {
        @energy_valley_contract.ActorIdle
      },
    ),
  )
}
