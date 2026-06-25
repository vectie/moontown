///|
fn visual_agent_grid(
  book_id : String,
  worker_id : String,
  phase : String,
  decorator : VisualDecoratorConfig,
) -> (Int, Int) {
  if visual_phase_is_recovery(phase) {
    return (142, 72)
  }
  if visual_phase_is_handoff(phase) {
    return (116, 70)
  }
  if phase == "waiting" {
    return (104, 84)
  }
  let seed = visual_hash("\{book_id}/\{worker_id}")
  let base = visual_book_grid(book_id, seed, decorator)
  let wiggle_x = seed % 7 - 3
  let wiggle_y = seed / 7 % 7 - 3
  (
    visual_clamp_grid_x(base.0 + wiggle_x),
    visual_clamp_grid_y(base.1 + wiggle_y),
  )
}

///|
fn visual_book_grid(
  book_id : String,
  seed : Int,
  decorator : VisualDecoratorConfig,
) -> (Int, Int) {
  match decorator.placement_for(book_id) {
    Some(placement) => (placement.grid_x, placement.grid_y)
    None => (72 + seed % 104, 42 + seed / 11 % 58)
  }
}

///|
fn visual_sprite_key(worker_id : String) -> String {
  "resident_\{visual_hash(worker_id) % 64}"
}

///|
fn visual_hash(text : String) -> Int {
  let mut value = 17
  for char in text {
    value = (value * 31 + char.to_int()) % 1_000_003
  }
  if value < 0 {
    -value
  } else {
    value
  }
}

///|
fn visual_clamp_grid_x(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 255 {
    255
  } else {
    value
  }
}

///|
fn visual_clamp_grid_y(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 143 {
    143
  } else {
    value
  }
}
