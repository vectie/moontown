///|
pub struct AlertBanner {
  level : String
  text : String
} derive(Debug, Eq)

///|
pub impl Show for AlertBanner with fn output(
  self : AlertBanner,
  logger : &Logger,
) -> Unit {
  logger.write_string("AlertBanner(level=\{self.level}, text=\{self.text})")
}

///|
pub struct DashboardSection {
  title : String
  lines : Array[String]
} derive(Debug, Eq)

///|
pub impl Show for DashboardSection with fn output(
  self : DashboardSection,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "DashboardSection(title=\{self.title}, lines=\{self.lines.length()})",
  )
}

///|
pub struct DashboardModel {
  title : String
  alerts : Array[AlertBanner]
  sections : Array[DashboardSection]
} derive(Debug, Eq)

///|
pub impl Show for DashboardModel with fn output(
  self : DashboardModel,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "DashboardModel(title=\{self.title}, alerts=\{self.alerts.length()}, sections=\{self.sections.length()})",
  )
}

///|
pub fn build_dashboard(
  town : @core.TownState,
  report : @health.HealthReport,
) -> DashboardModel {
  let alerts : Array[AlertBanner] = []
  for anomaly in report.anomalies {
    alerts.push({ level: "warning", text: anomaly.detail })
  }
  let sections = build_dashboard_sections(town, report)
  { title: town.config.name, alerts, sections }
}
