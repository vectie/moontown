///|
priv struct WorkerAvatarPlacement {
  left : Int
  top : Int
}

///|
fn worker_avatar_placement(
  zone : @ui.SceneRenderNode,
  index : Int,
) -> WorkerAvatarPlacement {
  worker_avatar_placement_for_frame(
    zone.key,
    scene_node_left(zone),
    scene_node_top(zone),
    scene_node_width(zone),
    scene_node_height(zone),
    index,
  )
}

///|
fn worker_avatar_placement_for_frame(
  zone_key : String,
  zone_x : Int,
  zone_y : Int,
  zone_width : Int,
  zone_height : Int,
  index : Int,
) -> WorkerAvatarPlacement {
  match zone_key {
    "worker-yard" =>
      { left: zone_x + 72 + index % 5 * 38, top: zone_y + 20 + index / 5 * 34 }
    "city-hall" =>
      { left: zone_x + zone_width - 44, top: zone_y + zone_height - 62 }
    _ => {
      let slot = index % 6
      {
        left: worker_avatar_default_left(zone_x, zone_width, slot),
        top: worker_avatar_default_top(zone_y, zone_height, slot),
      }
    }
  }
}

///|
fn worker_avatar_default_left(
  zone_x : Int,
  zone_width : Int,
  slot : Int,
) -> Int {
  match slot {
    0 => zone_x + 8
    1 => zone_x + zone_width - 42
    2 => zone_x + zone_width / 2 - 24
    3 => zone_x + 34
    4 => zone_x + zone_width - 76
    _ => zone_x + zone_width / 2 + 30
  }
}

///|
fn worker_avatar_default_top(
  zone_y : Int,
  zone_height : Int,
  slot : Int,
) -> Int {
  match slot {
    0 => zone_y + zone_height - 46
    1 => zone_y + zone_height - 42
    2 => zone_y + zone_height - 74
    3 => zone_y + zone_height - 4
    4 => zone_y + zone_height - 2
    _ => zone_y + zone_height - 28
  }
}

///|
fn worker_avatar_left(zone : @ui.SceneRenderNode, index : Int) -> Int {
  worker_avatar_placement(zone, index).left
}

///|
fn worker_avatar_top(zone : @ui.SceneRenderNode, index : Int) -> Int {
  worker_avatar_placement(zone, index).top
}

///|
fn worker_avatar_initials(title : String) -> String {
  let builder = StringBuilder::new()
  let mut count = 0
  for token in title.split(" ") {
    if count >= 2 {
      break
    }
    if worker_avatar_initial_from_token(builder, token.to_owned()) {
      count += 1
    }
  }
  if count == 0 {
    "??"
  } else {
    builder.to_string()
  }
}

///|
fn worker_avatar_initial_from_token(
  builder : StringBuilder,
  token : String,
) -> Bool {
  let trimmed = token.trim()
  if trimmed.is_empty() {
    return false
  }
  for char in trimmed {
    builder.write_char(char)
    return true
  }
  false
}

///|
fn worker_status_class(status : @core.WorkerStatus) -> String {
  match status {
    Running => "worker-running"
    Waiting => "worker-waiting"
    Idle => "worker-idle"
    Blocked => "worker-blocked"
    Offline => "worker-offline"
  }
}

///|
priv struct WorkerWanderProfile {
  x1 : Int
  y1 : Int
  x2 : Int
  y2 : Int
  x3 : Int
  y3 : Int
}

///|
fn worker_wander_profile(index : Int) -> WorkerWanderProfile {
  match index % 6 {
    0 => { x1: 28, y1: -12, x2: 44, y2: 18, x3: -16, y3: 24 }
    1 => { x1: -24, y1: -10, x2: -42, y2: 16, x3: 22, y3: -24 }
    2 => { x1: 18, y1: 14, x2: 30, y2: -18, x3: -24, y3: 22 }
    3 => { x1: -30, y1: 8, x2: -48, y2: -14, x3: 26, y3: -18 }
    4 => { x1: 34, y1: -4, x2: 52, y2: 20, x3: -20, y3: -26 }
    _ => { x1: -18, y1: 16, x2: -28, y2: -22, x3: 18, y3: 18 }
  }
}

///|
fn worker_wander_x1(index : Int) -> Int {
  worker_wander_profile(index).x1
}

///|
fn worker_wander_y1(index : Int) -> Int {
  worker_wander_profile(index).y1
}

///|
fn worker_wander_x2(index : Int) -> Int {
  worker_wander_profile(index).x2
}

///|
fn worker_wander_y2(index : Int) -> Int {
  worker_wander_profile(index).y2
}

///|
fn worker_wander_x3(index : Int) -> Int {
  worker_wander_profile(index).x3
}

///|
fn worker_wander_y3(index : Int) -> Int {
  worker_wander_profile(index).y3
}

///|
fn worker_wander_duration(index : Int) -> Int {
  5200 + index % 5 * 640
}

///|
fn worker_roster_asset(index : Int) -> String {
  "tilemap/actors/roster/resident_\{index % 64}_walk_strip.png"
}
