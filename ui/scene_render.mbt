///|
pub struct SceneRenderNode {
  key : String
  title : String
  class_name : String
  x : Int
  y : Int
  width : Int
  height : Int
  asset_paths : Array[String]
  lines : Array[String]
} derive(Show, Eq)

///|
pub struct SceneRenderModel {
  title : String
  width : Int
  height : Int
  background_path : String
  alerts : Array[String]
  nodes : Array[SceneRenderNode]
} derive(Show, Eq)

///|
pub fn build_scene_render(model : DashboardModel) -> SceneRenderModel {
  let nodes = model.town_map.map(place => {
    key: place.key,
    title: place.title,
    class_name: class_name_for_kind(place.kind),
    x: place.x,
    y: place.y,
    width: place.width,
    height: place.height,
    asset_paths: place.asset_paths,
    lines: place.lines,
  })
  {
    title: model.title,
    width: model.scene_layout.width,
    height: model.scene_layout.height,
    background_path: model.scene_layout.background.path,
    alerts: model.alerts.map(alert => "[\{alert.level}] \{alert.text}"),
    nodes,
  }
}

///|
pub fn render_scene_html(scene : SceneRenderModel) -> String {
  let builder = StringBuilder::new()
  builder.write_string("<section class=\"moontown-scene-shell\">\n")
  builder.write_string(
    "  <div class=\"moontown-scene\" data-title=\"\{escape_html(scene.title)}\" style=\"width:\{scene.width}px;height:\{scene.height}px;\">\n",
  )
  builder.write_string(
    "    <img class=\"scene-background\" src=\"\{escape_html(scene.background_path)}\" alt=\"\{escape_html(scene.title)} background\" />\n",
  )
  if !scene.alerts.is_empty() {
    builder.write_string("    <aside class=\"scene-alerts\">\n")
    for alert in scene.alerts {
      builder.write_string("      <p>\{escape_html(alert)}</p>\n")
    }
    builder.write_string("    </aside>\n")
  }
  for node in scene.nodes {
    builder.write_string(
      "    <article class=\"scene-node \{node.class_name}\" data-node=\"\{escape_html(node.key)}\" style=\"left:\{node.x}px;top:\{node.y}px;width:\{node.width}px;height:\{node.height}px;\">\n",
    )
    for asset_path in node.asset_paths {
      builder.write_string(
        "      <img class=\"scene-asset\" src=\"\{escape_html(asset_path)}\" alt=\"\{escape_html(node.title)} asset\" />\n",
      )
    }
    builder.write_string("      <div class=\"scene-card\">\n")
    builder.write_string("        <h3>\{escape_html(node.title)}</h3>\n")
    for line in node.lines {
      builder.write_string("        <p>\{escape_html(line)}</p>\n")
    }
    builder.write_string("      </div>\n")
    builder.write_string("    </article>\n")
  }
  builder.write_string("  </div>\n")
  builder.write_string("</section>\n")
  builder.to_string()
}

///|
fn class_name_for_kind(kind : SceneAreaKind) -> String {
  match kind {
    CityHall => "node-city-hall"
    BookHouse => "node-book-house"
    WorkerYard => "node-worker-yard"
    AnomalyCorner => "node-anomaly-corner"
    Gate => "node-gate"
  }
}

///|
fn escape_html(raw : String) -> String {
  let builder = StringBuilder::new()
  for char in raw {
    match char {
      '<' => builder.write_string("&lt;")
      '>' => builder.write_string("&gt;")
      '&' => builder.write_string("&amp;")
      '"' => builder.write_string("&quot;")
      '\'' => builder.write_string("&#39;")
      _ => builder.write_char(char)
    }
  }
  builder.to_string()
}
