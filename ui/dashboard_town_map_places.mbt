///|
fn town_map_place_from_area(
  layout : TownSceneLayout,
  area : SceneArea,
  subtitle : String,
  lines : Array[String],
) -> TownMapPlace {
  {
    key: area.key,
    title: area.title,
    kind: area.kind,
    subtitle,
    x: area.x,
    y: area.y,
    width: area.width,
    height: area.height,
    asset_paths: resolve_asset_paths(layout, area.asset_keys),
    lines,
  }
}

///|
fn require_area(layout : TownSceneLayout, key : String) -> SceneArea {
  for area in layout.areas {
    if area.key == key {
      return area
    }
  }
  {
    key: "missing-\{key}",
    title: "Missing Area: \{key}",
    kind: AnomalyCorner,
    x: 0,
    y: 0,
    width: 160,
    height: 96,
    asset_keys: ["anomaly-signal"],
  }
}

///|
fn resolve_asset_paths(
  layout : TownSceneLayout,
  asset_keys : Array[String],
) -> Array[String] {
  let paths : Array[String] = []
  for asset_key in asset_keys {
    for asset in layout.assets {
      if asset.key == asset_key {
        paths.push(asset.path)
      }
    }
  }
  paths
}
