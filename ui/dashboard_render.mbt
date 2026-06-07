///|
pub fn render_dashboard(model : DashboardModel) -> String {
  let builder = StringBuilder::new()
  builder.write_string("Dashboard / \{model.title}\n")
  for alert in model.alerts {
    builder.write_string("! [\{alert.level}] \{alert.text}\n")
  }
  render_dashboard_town_map(builder, model)
  render_dashboard_sections(builder, model.sections)
  builder.to_string()
}

///|
fn render_dashboard_town_map(
  builder : StringBuilder,
  model : DashboardModel,
) -> Unit {
  builder.write_string("\n## Town Map\n")
  builder.write_string(
    "- scene: \{model.scene_layout.width}x\{model.scene_layout.height} / \{model.scene_layout.background.path}\n",
  )
  for place in model.town_map {
    builder.write_string("- \{place.title}: \{place.subtitle}\n")
    builder.write_string(
      "  frame: \{place.x},\{place.y} \{place.width}x\{place.height} / kind=\{place.kind.to_string()}\n",
    )
    if !place.asset_paths.is_empty() {
      let assets_line = join_with_comma(place.asset_paths)
      builder.write_string("  assets: \{assets_line}\n")
    }
    for line in place.lines {
      builder.write_string("  \{line}\n")
    }
  }
}

///|
fn render_dashboard_sections(
  builder : StringBuilder,
  sections : Array[DashboardSection],
) -> Unit {
  for section in sections {
    builder.write_string("\n## \{section.title}\n")
    for line in section.lines {
      builder.write_string("- \{line}\n")
    }
  }
}

///|
fn join_with_comma(parts : Array[String]) -> String {
  let builder = StringBuilder::new()
  let mut index = 0
  for part in parts {
    if index > 0 {
      builder.write_string(", ")
    }
    builder.write_string(part)
    index += 1
  }
  builder.to_string()
}
