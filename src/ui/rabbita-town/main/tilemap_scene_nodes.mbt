///|
fn reference_node_grid_x(key : String) -> Int {
  match key {
    "city-hall" => 61
    "worker-yard" => 72
    "book-wenyu-town-shell" => 49
    "book-wenyu-resident-twins" => 25
    "book-wenyu-policy-hall" => 56
    "book-wenyu-contest-express" => 66
    "book-wenyu-social-square" => 51
    "book-wenyu-talent-avenue" => 78
    "book-wenyu-vitality-dashboard" => 103
    "book-wenyu-ai-garden" => 23
    "book-wenyu-physical-bridge" => 91
    "anomaly-corner" => 116
    "gate" => 18
    _ => 58
  }
}

///|
fn reference_node_grid_y(key : String) -> Int {
  match key {
    "city-hall" => 32
    "worker-yard" => 50
    "book-wenyu-town-shell" => 24
    "book-wenyu-resident-twins" => 47
    "book-wenyu-policy-hall" => 17
    "book-wenyu-contest-express" => 57
    "book-wenyu-social-square" => 43
    "book-wenyu-talent-avenue" => 54
    "book-wenyu-vitality-dashboard" => 42
    "book-wenyu-ai-garden" => 13
    "book-wenyu-physical-bridge" => 37
    "anomaly-corner" => 25
    "gate" => 60
    _ => 36
  }
}

///|
fn scene_node_width(node : @ui.SceneRenderNode) -> Int {
  if !standalone_viewport_requested() {
    return node.width
  }
  match node.key {
    "city-hall" => 220
    "worker-yard" => 240
    "gate" => 140
    "anomaly-corner" => 150
    _ => 170
  }
}

///|
fn scene_node_height(node : @ui.SceneRenderNode) -> Int {
  if !standalone_viewport_requested() {
    return node.height
  }
  match node.key {
    "worker-yard" => 100
    "gate" => 58
    _ => 128
  }
}

///|
fn scene_node_left(node : @ui.SceneRenderNode) -> Int {
  if !standalone_viewport_requested() {
    return node.x
  }
  iso_tile_left(
    reference_node_grid_x(node.key),
    reference_node_grid_y(node.key),
  ) -
  scene_node_width(node) / 2 +
  22
}

///|
fn scene_node_top(node : @ui.SceneRenderNode) -> Int {
  if !standalone_viewport_requested() {
    return node.y
  }
  iso_tile_top(reference_node_grid_x(node.key), reference_node_grid_y(node.key)) -
  scene_node_height(node) +
  42
}
