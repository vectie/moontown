///|
/// Scene-v1 uses a dimetric orthographic ground camera: world X=(32,16),
/// Y=(-32,16), with screen-vertical walls. Widths are WORLD units, never pixels.
/// The reviewed geography is immutable; these rules own only presentation.
fn town_scene_road_width(rank : String) -> Double {
  match rank {
    "primary" => 1.50
    "secondary" => 1.15
    _ => 0.80
  }
}

///|
/// A bounded architectural scale vocabulary; square footprints preserve the
/// authored camera without stretching or rotating the pre-rendered sprites.
fn town_scene_building_span(style : String) -> Int {
  match style {
    "lowrise" | "tower" => 3
    "courtyard" | "row" | "block" => 4
    _ => 5
  }
}

///|
/// Buildings share a material kit within each neighborhood. Variation comes
/// from stable coordinates, not the number of previously accepted candidates.
/// Tall silhouettes are accents, not one in every seven randomly filled lots.
fn town_scene_neighborhood_style(x : Int, y : Int) -> String {
  let district = energy_valley_mod(x / 48 + y / 36, 4)
  let accent = energy_valley_mod(x * 31 + y * 17, 11)
  match district {
    0 => if accent < 8 { "lowrise" } else { "courtyard" }
    1 => if accent < 8 { "campus" } else { "block" }
    2 => if accent == 0 { "tower" } else { "block" }
    _ => if accent < 8 { "courtyard" } else { "lowrise" }
  }
}

///|
/// Low-frequency, deterministic ground variation. A tile hash makes a noisy
/// checkerboard; neighboring samples of this field belong to the same lawn.
fn town_scene_ground_variation(x : Int, y : Int) -> Double {
  (
    golden_math_sin(x.to_double() * 0.085) +
    golden_math_sin(y.to_double() * 0.11)
  ) *
  0.25 +
  0.5
}

///|
/// Downsample background woodland into readable canopies; explicit planted
/// trees keep their exact identity and are never culled by this visual LOD.
fn town_scene_background_tree_visible(x : Int, y : Int) -> Bool {
  energy_valley_mod(x * 13 + y * 7, 3) == 0
}

///|
/// A coprime permutation visits every coarse lot once, distributed across the
/// whole map. A row-major scan spends a bounded infill budget in the north.
fn town_scene_infill_site(
  index : Int,
  phase_x : Int,
  phase_y : Int,
) -> (Int, Int) {
  let slot = energy_valley_mod(index * 137, 32 * 18)
  (2 + slot % 32 * 8 + phase_x * 2, 2 + slot / 32 * 8 + phase_y * 2)
}
