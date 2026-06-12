///|
fn tile_asset_for_kind(kind : String) -> String {
  match kind {
    "grass-light" => "tilemap/tiles/grass_light.png"
    "grass-dark" => "tilemap/tiles/grass_dark.png"
    "grass-flower-pink" => "tilemap/tiles/grass_flower_pink.png"
    "grass-flower-yellow" => "tilemap/tiles/grass_flower_yellow.png"
    "river" => "tilemap/tiles/river_straight.png"
    "lake" => "tilemap/tiles/river_straight.png"
    "pond" => "tilemap/tiles/river_straight.png"
    "river-bank" => "tilemap/tiles/river_bank.png"
    "wetland" => "tilemap/tiles/river_bank.png"
    "dirt-path" => "tilemap/tiles/dirt_path.png"
    "road" => "tilemap/tiles/dirt_path.png"
    "road-major" => "tilemap/tiles/dirt_path.png"
    "farm" => "tilemap/tiles/grass_flower_yellow.png"
    "field" => "tilemap/tiles/grass_light.png"
    "forest" => "tilemap/tiles/grass_dark.png"
    "urban" => "tilemap/tiles/plaza_stone.png"
    "urban-dense" => "tilemap/tiles/plaza_stone.png"
    "campus" => "tilemap/tiles/plaza_stone.png"
    "plaza-stone" => "tilemap/tiles/plaza_stone.png"
    "bridge" => "tilemap/tiles/wood_bridge.png"
    _ => "tilemap/tiles/grass_plain.png"
  }
}

///|
fn tilemap_grid_width() -> Int {
  256
}

///|
fn tilemap_grid_height() -> Int {
  144
}

///|
fn tilemap_step_x() -> Int {
  18
}

///|
fn tilemap_step_y() -> Int {
  9
}

///|
fn tilemap_origin_x() -> Int {
  1180
}

///|
fn tilemap_origin_y() -> Int {
  18
}

///|
fn tilemap_scene_width() -> Int {
  tilemap_origin_x() + (tilemap_grid_width() - 1) * tilemap_step_x() + 144
}

///|
fn tilemap_scene_height() -> Int {
  tilemap_origin_y() +
  (tilemap_grid_width() + tilemap_grid_height() - 2) * tilemap_step_y() +
  120
}

///|
fn iso_tile_left(grid_x : Int, grid_y : Int) -> Int {
  tilemap_origin_x() + (grid_x - grid_y) * tilemap_step_x() - 22
}

///|
fn iso_tile_top(grid_x : Int, grid_y : Int) -> Int {
  tilemap_origin_y() + (grid_x + grid_y) * tilemap_step_y()
}

///|
fn render_iso_tile(grid_x : Int, grid_y : Int) -> @rabbita.Html {
  let kind = tile_kind_at(grid_x, grid_y)
  let style = [
    "left: \{iso_tile_left(grid_x, grid_y)}px",
    "top: \{iso_tile_top(grid_x, grid_y)}px",
    "--tile-image: url('\{tile_asset_for_kind(kind)}')",
  ]
  div(class="iso-tile iso-tile-\{kind}", style~, no_children())
}

///|
fn render_tilemap_raster_layer() -> @rabbita.Html {
  img(
    class="tilemap-raster-layer",
    src="tilemap/wenyu_reference_tilemap_iso.png",
    alt="Wenyu Valley rendered tilemap",
    loading="eager",
    no_children(),
  )
}

///|
fn render_tilemap_layer() -> @rabbita.Html {
  if standalone_viewport_requested() {
    return render_tilemap_raster_layer()
  }
  let children : Array[@rabbita.Html] = []
  for y in 0..<tilemap_grid_height() {
    for x in 0..<tilemap_grid_width() {
      children.push(render_iso_tile(x, y))
    }
  }
  for y in 0..<tilemap_grid_height() {
    for x in 0..<tilemap_grid_width() {
      if should_place_tile_object(x, y) {
        children.push(render_tile_object(x, y, tile_object_kind_at(x, y)))
      }
    }
  }
  children.push(render_tile_object(122, 78, "lamp"))
  children.push(render_tile_object(149, 94, "lamp"))
  children.push(render_tile_object(182, 84, "lamp"))
  children.push(render_reference_haze("north-west", 120, 40, 3600, 760))
  children.push(render_reference_haze("north-east", 8800, 20, 3200, 940))
  children.push(render_reference_haze("south-west", 0, 6500, 3600, 980))
  children.push(render_reference_haze("east", 10300, 3100, 2500, 1200))
  div(class="tilemap-layer", children)
}

///|
fn render_water_effect_layer() -> @rabbita.Html {
  if !standalone_viewport_requested() {
    return div(
      class="water-effect-layer water-effect-layer-empty",
      no_children(),
    )
  }
  div(class="water-effect-layer", [
    div(class="water-depth water-depth-main-river", no_children()),
    div(class="water-depth water-depth-central-lake", no_children()),
    div(class="water-depth water-depth-south-lake", no_children()),
    div(class="water-reflection water-reflection-north", no_children()),
    div(class="water-reflection water-reflection-center", no_children()),
    div(class="water-reflection water-reflection-south", no_children()),
    div(class="bridge-shadow bridge-shadow-north", no_children()),
    div(class="bridge-shadow bridge-shadow-center", no_children()),
    div(class="bridge-shadow bridge-shadow-south", no_children()),
  ])
}
