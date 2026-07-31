///|
test "template launch maps only owner-authored civic identities" {
  assert_eq(template_building_id("wenyu-policy-hall-triage"), "policy-hall")
  assert_eq(
    template_building_id("wenyu-broadcast-tower-story"),
    "broadcast-tower",
  )
  assert_eq(template_building_id("moonfish-daily-brief"), "")
  assert_true(
    template_dashboard_section("wenyu-social-square-match")
    is Some(DashboardSection::SocialCapitalSection),
  )
}

///|
test "template launch requires catalog and source pins before selecting a civic system" {
  let accepted = resolve_template_launch(
    "wenyu-policy-hall-triage",
    "1.0.0",
    town_template_catalog_id(),
    town_template_catalog_version(),
    town_template_catalog_digest(),
    template_source_digest("wenyu-policy-hall-triage"),
  )
  assert_true(accepted.state is TemplateLaunchAccepted)
  assert_eq(accepted.building_id, "policy-hall")
  let stale_catalog = resolve_template_launch(
    "wenyu-policy-hall-triage",
    "1.0.0",
    town_template_catalog_id(),
    town_template_catalog_version(),
    "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    template_source_digest("wenyu-policy-hall-triage"),
  )
  assert_true(stale_catalog.state is TemplateLaunchRejected)
  assert_eq(stale_catalog.building_id, "")
  assert_true(stale_catalog.dashboard_section is None)
  assert_true(stale_catalog.message.contains("rejected"))
  let stale_source = resolve_template_launch(
    "wenyu-policy-hall-triage",
    "1.0.0",
    town_template_catalog_id(),
    town_template_catalog_version(),
    town_template_catalog_digest(),
    "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
  )
  assert_true(stale_source.state is TemplateLaunchRejected)
  assert_eq(stale_source.template_id, "")
}

///|
test "an unpinned template id cannot select or highlight a civic system" {
  let rejected = resolve_template_launch(
    "wenyu-social-square-match", "", "", "", "", "",
  )
  assert_true(rejected.state is TemplateLaunchRejected)
  assert_eq(rejected.building_id, "")
  assert_true(rejected.dashboard_section is None)
}
