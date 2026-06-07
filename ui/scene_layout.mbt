///|
pub fn default_town_scene_layout() -> TownSceneLayout {
  let background = default_scene_background_asset()
  {
    width: 1280,
    height: 720,
    background,
    areas: default_scene_areas(),
    assets: default_scene_assets(background),
  }
}
