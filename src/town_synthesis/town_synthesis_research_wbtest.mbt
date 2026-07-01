///|
test "town synthesis comparative analysis preserves ecosystem boundary thesis" {
  let text = render_town_comparative_analysis()
  assert_true(text.contains("town-level deep report"))
  assert_true(text.contains("MoonBook contributes durable memory"))
  assert_true(text.contains("MoonClaw contributes bounded execution"))
  assert_true(text.contains("Moontown contributes planning"))
  assert_true(text.contains("coordinated agent-infrastructure stack"))
}

///|
test "town synthesis paths use storage-owned snapshot base" {
  assert_eq(
    town_synthesis_dir("town.json"),
    ".moonsuite/products/moontown/town-synthesis",
  )
  assert_eq(
    town_synthesis_dir("/tmp/moontown/town.json"),
    "/tmp/moontown/town-synthesis",
  )
}

///|
test "town synthesis overview renders lane count and relationship diagram" {
  let mayor = @roles.Mayor::new()
  let plan = mayor.plan_goal(
    @moonbook.default_catalog(),
    "research moontown, moonbook, and moonclaw",
  )
  let overview = render_town_ecosystem_overview(plan)
  assert_true(overview.contains("raw/bootstrap/deep-report.md"))
  assert_true(overview.contains("clean separation of concerns"))
  assert_true(overview.contains("```mermaid"))
  assert_true(overview.contains("Moontown mayor"))
  assert_true(overview.contains("3 isolated research lanes"))
}

///|
test "town synthesis integration table keeps stable layer ordering" {
  let topics = town_research_topics()
  assert_eq(topics.length(), 3)
  assert_eq(topics[0], "moonbook")
  assert_eq(topics[1], "moonclaw")
  assert_eq(topics[2], "moontown")
  assert_eq(town_report_executive_topic_prefix("moonbook"), "- MoonBook: ")
  let row = town_report_integration_table_row("moonclaw", "research-moonclaw")
  assert_true(row.has_prefix("| MoonClaw | research-moonclaw |"))
  assert_true(row.contains("agent runtime"))
  assert_true(row.contains("structured evidence"))
  assert_true(row.has_suffix("|\n"))
  assert_true(
    town_report_integration_table_header().contains(
      "| Layer | Project | Primary Responsibility | Town-Level Interpretation |",
    ),
  )
}

///|
test "town synthesis technical resources render lane-owned artifacts" {
  let mayor = @roles.Mayor::new()
  let plan = mayor.plan_goal(
    @moonbook.default_catalog(),
    "research moontown, moonbook, and moonclaw",
  )
  let row = town_report_technical_resource_row(plan.lanes[0].entry)
  assert_true(row.contains(plan.lanes[0].entry.id))
  assert_true(row.contains("raw/bootstrap/deep-report.md"))
  assert_true(row.contains("raw/bootstrap/evidence-matrix.md"))
  assert_true(row.contains(@policy.default_generated_site_projection_path()))
  assert_true(
    town_report_technical_quality_standard().contains("research-report"),
  )
}

///|
test "town synthesis status verdicts separate complete and interim states" {
  assert_eq(
    town_report_status_counts_sentence(3, 0, 0, 0),
    "The latest town run has 3 completed lanes, 0 running lanes, 0 review-queued lanes, and 0 failed lanes. ",
  )
  assert_true(town_report_final_status_verdict().contains("strong enough"))
  assert_true(town_report_interim_status_verdict().contains("interim"))
  assert_true(town_report_reading_surface_note().contains("deep report"))
}
