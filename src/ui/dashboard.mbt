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
pub struct TownMapPlace {
  key : String
  title : String
  kind : SceneAreaKind
  subtitle : String
  x : Int
  y : Int
  width : Int
  height : Int
  asset_paths : Array[String]
  lines : Array[String]
} derive(Debug, Eq)

///|
pub impl Show for TownMapPlace with fn output(
  self : TownMapPlace,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "TownMapPlace(key=\{self.key}, title=\{self.title}, kind=\{self.kind.to_string()}, x=\{self.x}, y=\{self.y}, width=\{self.width}, height=\{self.height}, assets=\{self.asset_paths.length()}, lines=\{self.lines.length()})",
  )
}

///|
pub struct DashboardModel {
  title : String
  alerts : Array[AlertBanner]
  scene_layout : TownSceneLayout
  town_map : Array[TownMapPlace]
  sections : Array[DashboardSection]
} derive(Debug, Eq)

///|
pub impl Show for DashboardModel with fn output(
  self : DashboardModel,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "DashboardModel(title=\{self.title}, alerts=\{self.alerts.length()}, town_map=\{self.town_map.length()}, sections=\{self.sections.length()})",
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
  let scene_layout = default_town_scene_layout()
  let town_map = build_town_map(scene_layout, town, report)
  let sections = build_dashboard_sections(town)
  { title: town.config.name, alerts, scene_layout, town_map, sections }
}
