///|
pub(all) struct VisualDecoratorPlacement {
  book_id : String
  grid_x : Int
  grid_y : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct VisualDecoratorConfig {
  placements : Array[VisualDecoratorPlacement]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn VisualDecoratorConfig::empty() -> VisualDecoratorConfig {
  { placements: [] }
}

///|
pub fn VisualDecoratorConfig::placement_for(
  self : VisualDecoratorConfig,
  book_id : String,
) -> VisualDecoratorPlacement? {
  for placement in self.placements {
    if placement.book_id == book_id {
      return Some(placement)
    }
  }
  None
}

///|
struct VisualDecoratorModuleManifest {
  modules : Array[VisualDecoratorModuleEntry]
} derive(Debug, Eq, ToJson, FromJson)

///|
struct VisualDecoratorModuleEntry {
  enabled : Bool
  book_id : String
  grid_x : Int
  grid_y : Int
  entrance_x : Int
  entrance_y : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn visual_decorator_config_from_module_manifest(
  json : Json,
) -> VisualDecoratorConfig raise {
  let manifest : VisualDecoratorModuleManifest = @json.from_json(json)
  let placements : Array[VisualDecoratorPlacement] = []
  for entry in manifest.modules {
    if entry.enabled {
      placements.push({
        book_id: entry.book_id,
        grid_x: entry.entrance_x,
        grid_y: entry.entrance_y,
      })
    }
  }
  { placements, }
}
