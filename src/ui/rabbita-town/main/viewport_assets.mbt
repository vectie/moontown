///|
fn render_asset(asset_path : String, title : String) -> @rabbita.Html {
  let asset_class = "scene-asset " + scene_asset_class(asset_path)
  img(class=asset_class, src=asset_path, alt="\{title} asset", loading="lazy")
}

///|
fn scene_asset_class(asset_path : String) -> String {
  if asset_path.contains("actors/") || asset_path.contains("tilemap/actors/") {
    "scene-actor-asset"
  } else if asset_path.contains("effects/") {
    "scene-effect-asset"
  } else if asset_path.contains("props/") {
    "scene-prop-asset"
  } else if asset_path.contains("_roof") {
    "scene-roof-asset " + scene_asset_variant_class(asset_path)
  } else {
    "scene-building-asset " + scene_asset_variant_class(asset_path)
  }
}

///|
fn scene_asset_variant_class(asset_path : String) -> String {
  if asset_path.contains("variant=coding") {
    "scene-asset-coding"
  } else if asset_path.contains("variant=finance") {
    "scene-asset-finance"
  } else if asset_path.contains("city_hall") {
    "scene-asset-civic"
  } else if asset_path.contains("worker_yard") {
    "scene-asset-worker"
  } else if asset_path.contains("districts/") {
    "scene-asset-district"
  } else {
    ""
  }
}
