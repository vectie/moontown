///|
/// A runtime agent's evidence-backed position in canvas space. Only agents
/// from a live runtime projection are materialized by the collection helper
/// below; preview residents never enter this interaction layer.
priv struct RuntimeAgentMapPosition {
  agent_id : String
  screen_x : Double
  screen_y : Double
  depth : Int
}

///|
/// A runtime Agent follows the same semantic lifecycle as an ambient resident.
/// `RuntimeRouteUnreachable` is deliberately distinct from `RuntimeRouteInside`:
/// missing Place/portal/road evidence must never be presented as arrival.
priv enum RuntimeAgentRoutePhase {
  RuntimeRouteTraveling
  RuntimeRouteArriving
  RuntimeRouteInside
  RuntimeRouteUnreachable
} derive(Debug, Eq)

///|
/// One evidence-backed runtime journey. The route is the contract's
/// Place -> primary portal -> pedestrian RoadNetwork -> primary portal path.
/// A sprite position exists only while the Agent is actually outside.
priv struct RuntimeAgentJourney {
  phase : RuntimeAgentRoutePhase
  path : Array[(Double, Double)]
  position : (Double, Double)?
  facing_left : Bool
  progress_per_mille : Int
  since_tick : Int
} derive(Debug)

///|
/// Keep route timing identical to the canvas renderer. Centralizing the value
/// here also gives future renderer changes one named contract to reuse.
fn golden_valley_runtime_agent_route_speed(
  agent : EnergyValleyRuntimeAgent,
) -> Double {
  if agent.role == "worker" {
    2.6
  } else if agent.role == "mayor" {
    2.0
  } else {
    1.7
  }
}

///|
/// Resolve runtime building identities through the renderer-neutral ecosystem
/// bridge. Returning the semantic profile id lets runtime Agents reuse the
/// exact same typed-road query and route cache as ambient residents.
fn golden_valley_runtime_agent_semantic_place_id(
  world : @energy_valley_contract.CompiledTownWorld,
  building : GoldenValleyBuilding,
) -> @energy_valley_contract.StableId? {
  town_world_place_for_visual_building(world, building).map(place => place.id)
}

///|
let golden_valley_runtime_agent_route_cache : Map[
  String,
  Array[(Double, Double)],
] = Map([])

///|
/// Build a runtime route from semantic Places and their primary portals. The
/// delegated path query traverses `RoadNetwork` in pedestrian mode; it never
/// falls back to the legacy visual tile path or an unchecked Manhattan line.
fn golden_valley_runtime_agent_semantic_path(
  model : Model,
  seed : Int,
  agent : EnergyValleyRuntimeAgent,
) -> Array[(Double, Double)]? {
  let buildings = golden_valley_buildings(seed)
  for building in energy_valley_model_buildings(model) {
    buildings.push(building)
  }
  let destination = golden_valley_runtime_agent_destination(
    model.energy_valley_runtime,
    buildings,
    agent,
  )
  guard destination is Some(destination) else { return None }
  let origin = golden_valley_runtime_agent_origin(
    model.energy_valley_runtime,
    buildings,
    agent,
  )
  let world = ecosystem_contract_world_for_model(model, seed)
  let source_id = golden_valley_runtime_agent_semantic_place_id(world, origin)
  let destination_id = golden_valley_runtime_agent_semantic_place_id(
    world, destination,
  )
  match (source_id, destination_id) {
    (Some(source), Some(target)) => {
      let cache_key = "\{ecosystem_snapshot_cache_key(model, seed)}|runtime|\{source.to_string()}|\{target.to_string()}"
      match golden_valley_runtime_agent_route_cache.get(cache_key) {
        Some(cached) =>
          return if cached.is_empty() { None } else { Some(cached) }
        None => ()
      }
      let route = match (world.find_place(source), world.find_place(target)) {
        (Some(source_place), Some(target_place)) =>
          match
            (source_place.primary_entrance(), target_place.primary_entrance()) {
            (Some(source_portal), Some(target_portal)) =>
              match (source_portal.road_node_id, target_portal.road_node_id) {
                (Some(source_node), Some(target_node)) =>
                  match
                    world.road_network.shortest_path(
                      source_node,
                      target_node,
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
                      let endpoint = (
                        target_portal.position.x,
                        target_portal.position.y,
                      )
                      if points[points.length() - 1] != endpoint {
                        points.push(endpoint)
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
      if golden_valley_runtime_agent_route_cache.length() >= 96 {
        golden_valley_runtime_agent_route_cache.clear()
      }
      match route {
        Some(points) => {
          golden_valley_runtime_agent_route_cache[cache_key] = points
          Some(points)
        }
        None => {
          golden_valley_runtime_agent_route_cache[cache_key] = []
          None
        }
      }
    }
    _ => None
  }
}

///|
/// Runtime and ambient simulation ticks are different clock domains. The
/// runtime refresh records the current town tick once when evidence arrives;
/// reusing that value keeps presence stable without making a future runtime
/// daemon tick accidentally hide an otherwise active Agent.
fn golden_valley_runtime_agent_presence_since_tick(
  model : Model,
  agent : EnergyValleyRuntimeAgent,
) -> Int {
  match
    energy_valley_runtime_presence_clock_for_agent(
      model.energy_valley_runtime,
      agent,
    ) {
    Some(clock) => clock.started_at_tick.max(0)
    None => model.energy_valley_runtime.presence_started_at_tick.max(0)
  }
}

///|
fn golden_valley_runtime_agent_route_progress(
  route_distance : Double,
  travelled : Double,
) -> Int {
  if route_distance <= 0.0 {
    1000
  } else {
    (travelled * 1000.0 / route_distance)
    .floor()
    .to_int()
    .clamp(min=0, max=1000)
  }
}

///|
/// Pure lifecycle projection used by the renderer, hit testing and contract
/// adoption. Arrival owns the final route segment; after reaching the portal
/// the outdoor sprite disappears and the semantic presence becomes Inside.
fn golden_valley_runtime_agent_journey_at(
  model : Model,
  seed : Int,
  agent : EnergyValleyRuntimeAgent,
  elapsed_seconds : Double,
) -> RuntimeAgentJourney {
  let since_tick = golden_valley_runtime_agent_presence_since_tick(model, agent)
  match golden_valley_runtime_agent_semantic_path(model, seed, agent) {
    None =>
      {
        phase: RuntimeRouteUnreachable,
        path: [],
        position: None,
        facing_left: false,
        progress_per_mille: 0,
        since_tick,
      }
    Some(path) => {
      let route_distance = (path.length() - 1).max(0).to_double()
      let travelled = (elapsed_seconds.max(0.0) *
      golden_valley_runtime_agent_route_speed(agent)).max(0.0)
      let progress = golden_valley_runtime_agent_route_progress(
        route_distance, travelled,
      )
      if route_distance <= 0.0 || travelled >= route_distance {
        {
          phase: RuntimeRouteInside,
          path,
          position: None,
          facing_left: false,
          progress_per_mille: 1000,
          since_tick,
        }
      } else {
        let point = golden_valley_path_point(path, travelled)
        let phase = if travelled >= (route_distance - 1.0).max(0.0) {
          RuntimeRouteArriving
        } else {
          RuntimeRouteTraveling
        }
        {
          phase,
          path,
          position: point,
          facing_left: point
          .map(current => {
            golden_valley_assignment_faces_left(
              path,
              elapsed_seconds,
              golden_valley_runtime_agent_route_speed(agent),
              current,
            )
          })
          .unwrap_or(false),
          progress_per_mille: progress,
          since_tick,
        }
      }
    }
  }
}

///|
/// Resolve the current live journey once so the canvas can consume phase,
/// position and facing from the same record used by interaction hit testing.
fn golden_valley_runtime_agent_journey(
  model : Model,
  seed : Int,
  agent : EnergyValleyRuntimeAgent,
) -> RuntimeAgentJourney? {
  if !energy_valley_runtime_can_claim_active_work(model.energy_valley_runtime) {
    return None
  }
  Some(
    golden_valley_runtime_agent_journey_at(
      model,
      seed,
      agent,
      golden_valley_runtime_agent_motion_seconds(
        model.energy_valley_runtime,
        agent,
      ),
    ),
  )
}

///|
/// Pure route-position calculation used by interaction tests and by the live
/// clock wrapper. The caller supplies elapsed time so route geometry can be
/// verified without a browser clock.
fn golden_valley_runtime_agent_world_position_at(
  model : Model,
  seed : Int,
  agent : EnergyValleyRuntimeAgent,
  elapsed_seconds : Double,
) -> (Double, Double)? {
  golden_valley_runtime_agent_journey_at(model, seed, agent, elapsed_seconds).position
}

///|
/// Project the exact snapshot actor records drawn by Canvas into CSS-pixel
/// space; hit testing cannot drift from actor visibility, route position, or
/// the renderer's 24-runtime-agent cap.
/// `viewport_width` and `viewport_height` must be the canvas client dimensions,
/// matching `golden_valley_canvas_width/height`; device-pixel ratio is already
/// handled by the canvas context transform.
fn golden_valley_runtime_agent_map_positions_from_snapshot(
  snapshot : @energy_valley_contract.TownSnapshot,
  selected_actor_id : @energy_valley_contract.StableId?,
  viewport_width : Int,
  viewport_height : Int,
) -> Array[RuntimeAgentMapPosition] {
  let positions : Array[RuntimeAgentMapPosition] = []
  for
    record in town_snapshot_canvas_actor_records(
      snapshot, 0.0, true, selected_actor_id,
    ) {
    if record.actor_id.scope() != "runtime-agent" {
      continue
    }
    let point = (record.agent.x, record.agent.y)
    let screen_x = golden_screen_x(point.0, point.1, viewport_width)
    let screen_y = golden_screen_y(point.0, point.1, viewport_height)
    // Mirror the renderer's coarse culling boundary.
    if screen_x >= -30.0 &&
      screen_x <= viewport_width.to_double() + 30.0 &&
      screen_y >= -30.0 &&
      screen_y <= viewport_height.to_double() + 30.0 {
      positions.push({
        agent_id: record.actor_id.local_key(),
        screen_x,
        screen_y,
        depth: (point.0 + point.1 + 0.45).floor().to_int(),
      })
    }
  }
  positions
}

///|
/// Score a pointer against the visible sprite body. The renderer clamps agent
/// zoom to 0.32 and sprite height to 20..82 CSS pixels. A minimum 36 x 38 hit
/// area keeps overview-scale residents selectable without claiming empty map
/// far from the sprite.
fn golden_valley_runtime_agent_hit_score(
  pointer_x : Double,
  pointer_y : Double,
  sprite_x : Double,
  sprite_y : Double,
  camera_zoom : Double,
) -> Double? {
  let render_zoom = if camera_zoom < 0.32 { 0.32 } else { camera_zoom }
  let unclamped_height = 64.0 * render_zoom
  let sprite_height = if unclamped_height < 20.0 {
    20.0
  } else if unclamped_height > 82.0 {
    82.0
  } else {
    unclamped_height
  }
  let half_width = (sprite_height * 0.34).max(18.0)
  let hit_top = sprite_y - sprite_height - 6.0
  let hit_bottom = sprite_y + 12.0
  let dx = (pointer_x - sprite_x).abs()
  if dx > half_width || pointer_y < hit_top || pointer_y > hit_bottom {
    return None
  }
  let center_y = (hit_top + hit_bottom) / 2.0
  let half_height = (hit_bottom - hit_top) / 2.0
  let normalized_x = dx / half_width
  let normalized_y = (pointer_y - center_y).abs() / half_height
  Some(normalized_x * normalized_x + normalized_y * normalized_y)
}

///|
/// Return the id of the visible live runtime agent under a canvas pointer.
/// Nearest-body distance wins; depth and runtime order break visual overlaps in
/// the same direction as the renderer's depth pass. Stale/unavailable runtime
/// states always return `None`.
fn golden_valley_runtime_agent_hit_test_from_snapshot(
  snapshot : @energy_valley_contract.TownSnapshot,
  selected_actor_id : @energy_valley_contract.StableId?,
  viewport_width : Int,
  viewport_height : Int,
  pointer_x : Int,
  pointer_y : Int,
  camera_zoom : Double,
) -> String? {
  let mut best_id : String? = None
  let mut best_score = 1000000.0
  let mut best_depth = -1
  let mut order = 0
  let mut best_order = -1
  for
    position in golden_valley_runtime_agent_map_positions_from_snapshot(
      snapshot, selected_actor_id, viewport_width, viewport_height,
    ) {
    match
      golden_valley_runtime_agent_hit_score(
        pointer_x.to_double(),
        pointer_y.to_double(),
        position.screen_x,
        position.screen_y,
        camera_zoom,
      ) {
      None => ()
      Some(score) => {
        let closer = score < best_score - 0.000001
        let same_distance = (score - best_score).abs() <= 0.000001
        let visually_above = position.depth > best_depth ||
          (position.depth == best_depth && order > best_order)
        if closer || (same_distance && visually_above) {
          best_id = Some(position.agent_id)
          best_score = score
          best_depth = position.depth
          best_order = order
        }
      }
    }
    order += 1
  }
  best_id
}

///|
/// Convenience wrapper for the routed canvas click handler.
fn golden_valley_runtime_agent_at_canvas_point(
  model : Model,
  pointer_x : Int,
  pointer_y : Int,
) -> String? {
  match golden_valley_accepted_canvas_frame() {
    None => None
    Some(frame) if !frame.runtime_agent_interaction_enabled => None
    Some(frame) =>
      golden_valley_runtime_agent_hit_test_from_snapshot(
        frame.snapshot,
        town_snapshot_selected_actor_id(model.selection),
        golden_valley_canvas_width("energy-valley-canvas"),
        golden_valley_canvas_height("energy-valley-canvas"),
        pointer_x,
        pointer_y,
        golden_valley_camera_zoom(),
      )
  }
}
