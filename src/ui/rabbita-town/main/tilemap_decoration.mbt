///|
fn tile_object_asset(kind : String) -> String {
  match kind {
    "tree-large" => "tilemap/objects/tree_large.png"
    "tree-small" => "tilemap/objects/tree_small.png"
    "bush" => "tilemap/objects/bush.png"
    "flower-patch" => "tilemap/objects/flower_patch.png"
    "lamp" => "tilemap/objects/lamp.png"
    _ => "tilemap/objects/bush.png"
  }
}

///|
fn render_tile_object(
  grid_x : Int,
  grid_y : Int,
  kind : String,
) -> @rabbita.Html {
  let style = [
    "left: \{iso_tile_left(grid_x, grid_y)}px",
    "top: \{iso_tile_top(grid_x, grid_y) - 22}px",
    "--object-image: url('\{tile_object_asset(kind)}')",
  ]
  div(class="tile-object tile-object-\{kind}", style~, no_children())
}

///|
fn should_place_tile_object(grid_x : Int, grid_y : Int) -> Bool {
  let kind = tile_kind_at(grid_x, grid_y)
  if kind == "river" ||
    kind == "river-bank" ||
    kind == "bridge" ||
    kind == "lake" ||
    kind == "road" ||
    kind == "road-major" ||
    kind == "urban" ||
    kind == "urban-dense" ||
    kind == "campus" ||
    kind == "farm" ||
    kind == "field" ||
    kind == "plaza-stone" {
    return false
  }
  (kind == "forest" && (grid_x * 17 + grid_y * 31) % 19 == 0) ||
  (kind == "wetland" && (grid_x * 7 + grid_y * 19) % 31 == 0) ||
  (grid_x * 17 + grid_y * 31) % 71 == 0 ||
  (grid_x + grid_y * 5) % 97 == 0
}

///|
fn tile_object_kind_at(grid_x : Int, grid_y : Int) -> String {
  if (grid_x * 17 + grid_y * 31) % 47 == 0 {
    if (grid_x + grid_y) % 3 == 0 {
      "tree-large"
    } else {
      "tree-small"
    }
  } else if (grid_x * 7 + grid_y * 19) % 61 == 0 {
    "bush"
  } else {
    "flower-patch"
  }
}

///|
fn render_reference_haze(
  class_suffix : String,
  left : Int,
  top : Int,
  width : Int,
  height : Int,
) -> @rabbita.Html {
  let style = [
    "left: \{left}px",
    "top: \{top}px",
    "width: \{width}px",
    "height: \{height}px",
  ]
  div(
    class="reference-haze reference-haze-\{class_suffix}",
    style~,
    no_children(),
  )
}
