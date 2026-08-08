///|
/// Player avatar: creation wizard, on-map embodied resident, and movement
/// (click-to-walk along the road graph + WASD/arrow stepping). The player's
/// render position is a pure function of motion + wall-clock animation time,
/// so the 30fps canvas loop never needs to write back into the model.
let player_walk_speed = 2.4

///|
let player_avatar_colors = [
  "#f2c94c", "#34d399", "#38bdf8", "#f472b6", "#a78bfa", "#fb923c",
]

///|
extern "js" fn golden_follow_camera(world_x : Double, world_y : Double) -> Unit =
  #| (worldX, worldY) => {
  #|   const civicZoom = globalThis.innerWidth < 640
  #|     ? 0.34
  #|     : globalThis.innerWidth < 1100 || globalThis.innerHeight < 800
  #|       ? 0.42
  #|       : 0.5;
  #|   globalThis.__moontownGoldenValleyCamera ||= {
  #|     x: 1792, y: 3200, z: civicZoom,
  #|   };
  #|   const camera = globalThis.__moontownGoldenValleyCamera;
  #|   camera.x = (worldX - worldY) * 32;
  #|   camera.y = (worldX + worldY) * 16;
  #| }

///|
/// WASD / arrow keys drive hidden direction buttons so movement stays inside
/// the Elm message loop. Auto-repeat keydown gives continuous walking.
extern "js" fn install_player_walk_keys() -> Unit =
  #| () => {
  #|   if (globalThis.__moontownPlayerWalkKeys) return;
  #|   globalThis.__moontownPlayerWalkKeys = true;
  #|   globalThis.addEventListener("keydown", event => {
  #|     const target = event.target;
  #|     if (target?.matches?.("input, textarea, select") ||
  #|         target?.isContentEditable) return;
  #|     const labels = {
  #|       w: "向屏幕上走", ArrowUp: "向屏幕上走",
  #|       s: "向屏幕下走", ArrowDown: "向屏幕下走",
  #|       a: "向屏幕左走", ArrowLeft: "向屏幕左走",
  #|       d: "向屏幕右走", ArrowRight: "向屏幕右走",
  #|     };
  #|     const label = labels[event.key] ||
  #|       labels[event.key?.toLowerCase?.() || ""];
  #|     if (!label) return;
  #|     const button = globalThis.document?.querySelector(
  #|       `button[aria-label="${label}"]`,
  #|     );
  #|     if (button) {
  #|       event.preventDefault();
  #|       button.click();
  #|     }
  #|   });
  #| }

///|
/// Distance the player has walked along the current motion path, clamped so
/// the resident stops exactly at the destination.
fn player_path_length(path : Array[(Double, Double)]) -> Double {
  let mut total = 0.0
  for index in 0..<path.length() {
    if index == 0 {
      continue
    }
    let (ax, ay) = path[index - 1]
    let (bx, by) = path[index]
    let dx = bx - ax
    let dy = by - ay
    total += (dx * dx + dy * dy).sqrt()
  }
  total
}

///|
fn player_point_along(
  path : Array[(Double, Double)],
  distance : Double,
) -> (Double, Double) {
  if path.is_empty() {
    return (0.0, 0.0)
  }
  if path.length() == 1 {
    return path[0]
  }
  let mut remaining = distance
  for index in 1..<path.length() {
    let (ax, ay) = path[index - 1]
    let (bx, by) = path[index]
    let dx = bx - ax
    let dy = by - ay
    let segment = (dx * dx + dy * dy).sqrt()
    if segment > 0.0 && remaining <= segment {
      let ratio = remaining / segment
      return (ax + dx * ratio, ay + dy * ratio)
    }
    remaining -= segment
  }
  path[path.length() - 1]
}

///|
fn player_idle_position(model : Model) -> (Double, Double)? {
  match model.player {
    Some(_) =>
      match model.player_position {
        Some(position) => Some((position.x, position.y))
        None => Some(player_home_position(model))
      }
    None => None
  }
}

///|
/// Current render position: interpolated along the motion path by elapsed
/// animation seconds; idle players stand at their final tile.
fn player_current_position(model : Model) -> (Double, Double)? {
  match model.player_motion {
    Some(motion) => {
      let elapsed = golden_animation_seconds() - motion.started_seconds
      if elapsed < 0.0 {
        return Some((motion.from_x, motion.from_y))
      }
      let walked = elapsed * player_walk_speed
      let total = player_path_length(motion.path)
      if walked >= total {
        Some(player_point_along(motion.path, total))
      } else {
        Some(player_point_along(motion.path, walked))
      }
    }
    None => player_idle_position(model)
  }
}

///|
fn player_moving(model : Model) -> Bool {
  match model.player_motion {
    Some(motion) => {
      let elapsed = golden_animation_seconds() - motion.started_seconds
      elapsed * player_walk_speed < player_path_length(motion.path)
    }
    None => false
  }
}

///|
/// Spawn point: the road nearest the Social Square entrance when available,
/// else the road nearest map center. Authored building footprints can cover
/// several logical tiles, so spawning at the raw entrance can leave every
/// one-tile direction blocked after the Wenyu map migration.
fn player_home_position(model : Model) -> (Double, Double) {
  let seed = active_energy_valley_seed()
  let buildings = golden_valley_buildings(active_energy_valley_seed())
  let preferred = match
    golden_valley_building_for_identity(buildings, "social-square") {
    Some(salon) =>
      (
        salon.x.to_double() + salon.width.to_double() / 2.0,
        (salon.y + salon.depth + 1).to_double(),
      )
    None => (96.5, 72.5)
  }
  match
    nearest_road_tile(
      model,
      seed,
      preferred.0.floor().to_int(),
      preferred.1.floor().to_int(),
    ) {
    Some((x, y)) => (x.to_double() + 0.5, y.to_double() + 0.5)
    None => preferred
  }
}

///|
fn player_current_tile(model : Model) -> (Int, Int) {
  match player_current_position(model) {
    Some((px, py)) => (px.floor().to_int(), py.floor().to_int())
    None => (96, 72)
  }
}

///|
/// A tile the player may stand on: in-bounds, not water/void, and not inside
/// a building footprint. Grass, forest edges, plazas and roads are all fine
/// for a walking resident.
fn player_tile_enterable(model : Model, seed : Int, x : Int, y : Int) -> Bool {
  let world = ecosystem_contract_world_for_model(model, seed)
  let point = @energy_valley_contract.world_point(
    x.to_double() + 0.5,
    y.to_double() + 0.5,
  )
  if !world.bounds.contains(point) {
    return false
  }
  match ecosystem_contract_terrain_kind_at(world, x, y) {
    None
    | Some(@energy_valley_contract.Water)
    | Some(@energy_valley_contract.Wetland)
    | Some(@energy_valley_contract.Restricted) => return false
    _ => ()
  }
  match golden_valley_semantic_road_node_at(world, x, y) {
    Some(node) =>
      if world.road_network.segments.any(segment => {
          segment.road_class is @energy_valley_contract.Bridge &&
          (segment.from_node_id == node.id || segment.to_node_id == node.id)
        }) {
        return false
      }
    _ => ()
  }
  if golden_valley_contract_building_place_at(world, x, y) is Some(_) {
    return false
  }
  true
}

///|
fn nearest_road_tile(
  model : Model,
  seed : Int,
  x : Int,
  y : Int,
) -> (Int, Int)? {
  for radius in 0..<14 {
    for dy in -radius..<=radius {
      for dx in -radius..<=radius {
        if dx.abs() != radius && dy.abs() != radius {
          continue
        }
        let nx = x + dx
        let ny = y + dy
        if golden_valley_walkable(model, seed, nx, ny) {
          return Some((nx, ny))
        }
      }
    }
  }
  None
}

///|
/// Start a walk to a target tile. The click is projected onto the nearest
/// road and movement is accepted only when the road graph contains a complete
/// route. This keeps the embodied player on the same authored Wenyu network
/// used by runtime agents; disconnected road islands never degrade into a
/// misleading cross-lot straight line.
fn player_begin_walk(model : Model, tx : Int, ty : Int) -> Model? {
  let seed = active_energy_valley_seed()
  if !player_tile_enterable(model, seed, tx, ty) {
    return None
  }
  let (cx, cy) = match player_current_position(model) {
    Some(pos) => pos
    None => player_home_position(model)
  }
  let path = match
    (
      nearest_road_tile(model, seed, cx.floor().to_int(), cy.floor().to_int()),
      nearest_road_tile(model, seed, tx, ty),
    ) {
    (Some(start_road), Some(goal_road)) =>
      match golden_valley_road_path(model, seed, start_road, goal_road) {
        Some(road_path) => {
          let full : Array[(Double, Double)] = [(cx, cy)]
          for point in road_path {
            if full[full.length() - 1] != point {
              full.push(point)
            }
          }
          full
        }
        None => return None
      }
    _ => return None
  }
  if path.length() < 2 {
    return None
  }
  let target = path[path.length() - 1]
  let positioned = town_life_set_player_position(
    model,
    Some({ x: target.0, y: target.1 }),
  )
  Some({
    ..positioned,
    player_motion: Some({
      from_x: cx,
      from_y: cy,
      to_x: target.0,
      to_y: target.1,
      started_seconds: golden_animation_seconds(),
      path,
    }),
  })
}

///|
fn player_step_direction_model(model : Model, dx : Int, dy : Int) -> Model {
  if model.player is None {
    return model
  }
  let (cx, cy) = player_current_tile(model)
  // Screen-space directions are diagonal in the isometric world. A Wenyu
  // building bucket can occupy several diagonal tiles beside an otherwise
  // valid road entrance. Search a widening cone in the requested direction
  // so every key remains useful beside large authored footprints while the
  // chosen destination still lies ahead of the resident.
  for forward in 1..<=8 {
    for lateral in 0..<forward {
      let tx = cx + dx * forward + dy * lateral
      let ty = cy + dy * forward - dx * lateral
      match player_begin_walk(model, tx, ty) {
        Some(next) => return track_event(next, "walk_step", "\{tx}:\{ty}")
        None => ()
      }
      if lateral == 0 {
        continue
      }
      let tx = cx + dx * forward - dy * lateral
      let ty = cy + dy * forward + dx * lateral
      match player_begin_walk(model, tx, ty) {
        Some(next) => return track_event(next, "walk_step", "\{tx}:\{ty}")
        None => ()
      }
    }
  }
  // A heavily built-up block can fill the entire nearby cone. Fall back to
  // the nearest road in that direction so keyboard movement never silently
  // stalls on a valid Wenyu road network.
  for distance in 9..<=18 {
    let tx = cx + dx * distance
    let ty = cy + dy * distance
    match player_begin_walk(model, tx, ty) {
      Some(next) => return track_event(next, "walk_step", "\{tx}:\{ty}")
      None => ()
    }
  }
  model
}

///|
fn player_avatar_color(model : Model) -> String {
  match model.player {
    Some(player) =>
      if player.color >= 0 && player.color < player_avatar_colors.length() {
        player_avatar_colors[player.color]
      } else {
        player_avatar_colors[0]
      }
    None => player_avatar_colors[0]
  }
}
