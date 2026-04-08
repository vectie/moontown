///|
pub struct AlertBanner {
  level : String
  text : String
} derive(Show, Eq)

///|
pub struct DashboardSection {
  title : String
  lines : Array[String]
} derive(Show, Eq)

///|
pub struct DashboardModel {
  title : String
  alerts : Array[AlertBanner]
  sections : Array[DashboardSection]
} derive(Show, Eq)

///|
pub fn build_dashboard(
  town : @core.TownState,
  report : @health.HealthReport,
) -> DashboardModel {
  let alerts : Array[AlertBanner] = []
  for anomaly in report.anomalies {
    alerts.push({ level: "warning", text: anomaly.detail })
  }
  let sections = [
    {
      title: "Books",
      lines: town.books.map(book => "\{book.id}: \{book.workspace_root}"),
    },
    {
      title: "Workers",
      lines: town.workers.map(worker => {
        "\{worker.id}: \{worker.status.to_string()}"
      }),
    },
    {
      title: "Tasks",
      lines: town.tasks.map(task => "\{task.id}: \{task.status.to_string()}"),
    },
  ]
  { title: town.config.name, alerts, sections }
}

///|
pub fn render_dashboard(model : DashboardModel) -> String {
  let builder = StringBuilder::new()
  builder.write_string("Dashboard / \{model.title}\n")
  for alert in model.alerts {
    builder.write_string("! [\{alert.level}] \{alert.text}\n")
  }
  for section in model.sections {
    builder.write_string("\n## \{section.title}\n")
    for line in section.lines {
      builder.write_string("- \{line}\n")
    }
  }
  builder.to_string()
}
