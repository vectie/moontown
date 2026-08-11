///|
enum TemplateLaunchState {
  TemplateLaunchAbsent
  TemplateLaunchAccepted
  TemplateLaunchRejected
} derive(Eq)

///|
struct TemplateLaunchSelection {
  state : TemplateLaunchState
  template_id : String
  building_id : String
  dashboard_section : DashboardSection?
  message : String
}

///|
fn town_template_catalog_id() -> String {
  "moontown.civic-templates"
}

///|
fn town_template_catalog_version() -> String {
  "1.0.0"
}

///|
fn town_template_catalog_digest() -> String {
  "sha256:55a224e6dca810fcb35b48255fab7b29ce4d381e7d1f9624fcb6694f4f901594"
}

///|
fn template_source_digest(template_id : String) -> String {
  match template_id {
    "wenyu-policy-hall-triage" =>
      "sha256:2b3838b4651ddc070f382de90308a7e906dd0452da0f8be639ae7f296c593b35"
    "wenyu-contest-express-review" =>
      "sha256:a59c9a3fcf28745b528e20b3bec964d0def9f7de33637f8627c45957a8d698ed"
    "wenyu-social-square-match" =>
      "sha256:e5df9c6266ed8195e59d891dfd26b17c5e864f58efe2c32e9e363cadeecd7c49"
    "wenyu-vitality-dashboard-watch" =>
      "sha256:88f9d8ae8b1b09640febdc408c562efd2e845a0ea2aede9c35b28f932f6f67dd"
    "wenyu-ai-garden-learning" =>
      "sha256:e37b3ed7a5b542004731bb7c00c2c015ba8263540fbd9d03162ac26a01614531"
    "wenyu-broadcast-tower-story" =>
      "sha256:7b394f9a0cad402ef6ecfa170f15a5a055629521da0639c4c57e85aeca4f3ad9"
    _ => ""
  }
}

///|
fn template_building_id(template_id : String) -> String {
  match template_id {
    "wenyu-policy-hall-triage" => "policy-hall"
    "wenyu-contest-express-review" => "contest-express"
    "wenyu-social-square-match" => "social-square"
    "wenyu-vitality-dashboard-watch" => "vitality-dashboard"
    "wenyu-ai-garden-learning" => "ai-garden"
    "wenyu-broadcast-tower-story" => "broadcast-tower"
    _ => ""
  }
}

///|
fn template_dashboard_section(template_id : String) -> DashboardSection? {
  match template_id {
    "wenyu-policy-hall-triage" => Some(DashboardSection::DistrictSystems)
    "wenyu-contest-express-review" => Some(DashboardSection::CivicQuestsSection)
    "wenyu-social-square-match" => Some(DashboardSection::SocialCapitalSection)
    "wenyu-vitality-dashboard-watch" => Some(DashboardSection::DistrictSystems)
    "wenyu-ai-garden-learning" => Some(DashboardSection::CivicQuestsSection)
    "wenyu-broadcast-tower-story" => Some(DashboardSection::CivicQuestsSection)
    _ => None
  }
}

///|
fn resolve_template_launch(
  template_id : String,
  template_version : String,
  catalog_id : String,
  catalog_version : String,
  catalog_digest : String,
  source_digest : String,
) -> TemplateLaunchSelection {
  let requested = template_id.trim().to_owned()
  if requested == "" &&
    template_version == "" &&
    catalog_id == "" &&
    catalog_version == "" &&
    catalog_digest == "" &&
    source_digest == "" {
    return {
      state: TemplateLaunchAbsent,
      template_id: "",
      building_id: "",
      dashboard_section: None,
      message: "",
    }
  }
  let expected_source_digest = template_source_digest(requested)
  let valid = expected_source_digest != "" &&
    template_version == "1.0.0" &&
    catalog_id == town_template_catalog_id() &&
    catalog_version == town_template_catalog_version() &&
    catalog_digest == town_template_catalog_digest() &&
    source_digest == expected_source_digest
  if valid {
    {
      state: TemplateLaunchAccepted,
      template_id: requested,
      building_id: template_building_id(requested),
      dashboard_section: template_dashboard_section(requested),
      message: "Template preview verified. MoonTown opened the installed civic reference without creating an instance. Use the highlighted system only for review.",
    }
  } else {
    {
      state: TemplateLaunchRejected,
      template_id: "",
      building_id: "",
      dashboard_section: None,
      message: "Template selection rejected: its version or digest does not match MoonTown's installed catalog. Return to MoonDesk and refresh templates.",
    }
  }
}

///|
fn initial_template_launch() -> TemplateLaunchSelection {
  resolve_template_launch(
    current_browser_query_param("template").trim().to_owned(),
    current_browser_query_param("template_version").trim().to_owned(),
    current_browser_query_param("template_catalog").trim().to_owned(),
    current_browser_query_param("template_catalog_version").trim().to_owned(),
    current_browser_query_param("template_catalog_digest").trim().to_owned(),
    current_browser_query_param("template_source_digest").trim().to_owned(),
  )
}

///|
fn initial_template_id() -> String {
  let launch = initial_template_launch()
  if launch.state == TemplateLaunchAccepted {
    launch.template_id
  } else {
    ""
  }
}

///|
fn template_launch_requested() -> Bool {
  initial_template_launch().state != TemplateLaunchAbsent
}

///|
fn initial_template_launch_status() -> String {
  initial_template_launch().message
}
