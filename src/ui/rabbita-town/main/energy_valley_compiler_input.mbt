///|
/// Compatibility DTO at the typed-Wenyu/compiler boundary. Production Canvas
/// never reads this record; the world compiler translates it into a semantic
/// `Place` with a `BuildingProfile` before rendering or interaction.
priv struct GoldenValleyBuilding {
  /// Stable identity for a player-authored map delta. Generated civic
  /// buildings leave this empty and keep using their runtime module key.
  authored_id : String?
  module_key : String?
  name : String
  style : String
  x : Int32
  y : Int32
  width : Int32
  depth : Int32
  entrance_x : Int32?
  entrance_y : Int32?
  floors : Int32
} derive(ToJson, FromJson)

///|
let golden_valley_world_cache : Map[Int32, ExactEnergyValleyWorld] = Map([])

///|
/// Typed Wenyu generation is a compiler input, not a renderer-owned world.
fn golden_valley_world(seed : Int32) -> ExactEnergyValleyWorld {
  match golden_valley_world_cache.get(seed) {
    Some(world) => world
    None => {
      let world = exact_energy_valley_generate_int(seed)
      // The active seed is one compiler authority. Keeping every previously
      // previewed seed retains a complete generated map graph indefinitely.
      golden_valley_world_cache.clear()
      golden_valley_world_cache[seed] = world
      world
    }
  }
}

///|
fn golden_valley_cols() -> Int32 {
  exact_energy_valley_cols()
}

///|
fn golden_valley_rows() -> Int32 {
  exact_energy_valley_rows()
}

///|
fn golden_valley_buildings(seed : Int32) -> Array[GoldenValleyBuilding] {
  golden_valley_world(seed).buildings.map(building => {
    authored_id: None,
    module_key: Some(building.module_key),
    name: building.name,
    style: if building.style == "plaza-bld" {
      "plaza"
    } else {
      building.style
    },
    x: building.x,
    y: building.y,
    width: building.width,
    depth: building.depth,
    entrance_x: Some(building.entrance_x),
    entrance_y: Some(building.entrance_y),
    floors: building.floors,
  })
}
