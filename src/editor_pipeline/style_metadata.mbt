///|
pub fn style_title(style_id : String) -> String {
  match style_id {
    "white-tech-pavilion" => "White Tech Pavilion"
    "wenyu-pixel-backup" => "Wenyu Pixel Backup"
    "shape-label-workbench" => "Shape Label Workbench"
    _ => label_from_slug(style_id)
  }
}

///|
pub fn style_asset_ref(style_id : String) -> String {
  match style_id {
    "white-tech-pavilion" =>
      "ui/assets/tilemap/buildings/white-tech-pavilion/alpha"
    "wenyu-pixel-backup" => "ui/assets/tilemap/buildings/wenyu"
    "shape-label-workbench" => "ui/assets/tilemap/buildings/wenyu_shape"
    _ => "ui/assets/tilemap/buildings"
  }
}

///|
fn label_from_slug(value : String) -> String {
  let parts = value.split("-")
  let words : Array[String] = []
  for part in parts {
    if part.is_empty() {
      continue
    }
    let first = part[0:1].to_upper().to_owned()
    let rest = if part.length() > 1 { part[1:].to_owned() } else { "" }
    words.push(first + rest)
  }
  if words.is_empty() {
    value
  } else {
    words.join(" ")
  }
}
