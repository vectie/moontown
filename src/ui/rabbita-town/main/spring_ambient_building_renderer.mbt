///|
/// One bounded authored-skin choice for an ambient semantic building. Canvas
/// integration consumes only this pure value; loading, drawing, fallback, and
/// lifecycle ownership remain renderer concerns.
priv struct GoldenSpringAmbientBuildingAssetCandidate {
  asset_path : String
  variant : Int
} derive(Debug, Eq)

///|
fn golden_spring_ambient_style_supported(style : String) -> Bool {
  match style {
    "lowrise"
    | "row"
    | "block"
    | "tower"
    | "courtyard"
    | "campus"
    | "civic"
    | "industrial" => true
    _ => false
  }
}

///|
/// Resolve one of the eighty fixed runtime files. The style allowlist and
/// ten-value variant bound keep Canvas integration from constructing a
/// path from untrusted or unbounded world data.
fn golden_spring_ambient_asset_path_for_variant(
  style : String,
  variant : Int,
) -> String? {
  if !golden_spring_ambient_style_supported(style) ||
    variant < 0 ||
    variant >= 10 {
    None
  } else {
    Some(
      "/tilemap/buildings/moontown-spring-ambient-v1/\{style}-\{variant}.webp",
    )
  }
}

///|
/// Promote exactly two of every ten stable hash residues into the new variant
/// slots. The remaining eighty percent retain their previous modulo-eight
/// assignment, avoiding a full visual reroll when the pack grows.
fn golden_spring_ambient_building_variant_from_hash(hash : Int) -> Int {
  let promotion = energy_valley_mod(hash, 10)
  if promotion >= 8 {
    promotion
  } else {
    energy_valley_mod(hash, 8)
  }
}

///|
/// Stable semantic identity and the compiled parcel seed are the complete
/// visual DNA. Camera state, time, tick, collection order, and mutable display
/// coordinates intentionally cannot reroll a building's authored skin.
fn golden_spring_ambient_building_variant(
  style : String,
  place_id : @energy_valley_contract.StableId,
  interior_seed : Int,
) -> Int {
  golden_spring_ambient_building_variant_from_hash(
    ecosystem_stable_hash(
      "moontown-spring-ambient-v1:\{style}:\{place_id.to_string()}:\{interior_seed}",
    ),
  )
}

///|
fn golden_spring_ambient_building_eligible(
  building : TownCanvasBuilding,
  zoom : Double,
) -> Bool {
  building.module_key is None &&
  building.authored_id is None &&
  golden_spring_ambient_style_supported(building.style) &&
  zoom >= 0.18
}

///|
/// Landmark-bound and user-authored buildings are deliberately excluded.
/// Returning None leaves the caller's complete procedural renderer in charge.
fn golden_spring_ambient_building_asset_candidate(
  building : TownCanvasBuilding,
  zoom : Double,
) -> GoldenSpringAmbientBuildingAssetCandidate? {
  if !golden_spring_ambient_building_eligible(building, zoom) {
    return None
  }
  let variant = golden_spring_ambient_building_variant(
    building.style,
    building.place_id,
    building.interior_seed,
  )
  match golden_spring_ambient_asset_path_for_variant(building.style, variant) {
    Some(asset_path) => Some({ asset_path, variant })
    None => None
  }
}

///|
/// Convenience boundary for Canvas code that needs only the verified path.
fn golden_spring_ambient_building_asset_path(
  building : TownCanvasBuilding,
  zoom : Double,
) -> String? {
  match golden_spring_ambient_building_asset_candidate(building, zoom) {
    Some(candidate) => Some(candidate.asset_path)
    None => None
  }
}

///|
/// One precedence boundary for Canvas: a recognized landmark is the only skin
/// candidate for its building, even below ambient detail zoom or while that
/// image is loading. Ambient art is considered only when no landmark path
/// exists, and its own eligibility still excludes every module-bound place.
fn golden_spring_building_asset_path(
  building : TownCanvasBuilding,
  zoom : Double,
) -> String? {
  match golden_spring_civic_building_asset_path(building.module_key) {
    Some(asset_path) => Some(asset_path)
    None => golden_spring_ambient_building_asset_path(building, zoom)
  }
}
