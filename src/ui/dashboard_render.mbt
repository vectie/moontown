///|
pub fn render_dashboard(model : DashboardModel) -> String {
  let builder = StringBuilder::new()
  builder.write_string("Dashboard / \{model.title}\n")
  for alert in model.alerts {
    builder.write_string("! [\{alert.level}] \{alert.text}\n")
  }
  render_dashboard_sections(builder, model.sections)
  builder.to_string()
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
