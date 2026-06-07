///|
async fn render_town_report_executive_summary(
  plan : @roles.MayorGoalPlan,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string(town_report_stack_thesis())
  builder.write_string(town_report_lane_evidence_summary())
  builder.write_string(town_report_ecosystem_conclusion())
  for topic in town_research_topics() {
    builder.write_string(town_report_executive_topic_prefix(topic))
    builder.write_string(first_deep_report_summary(plan, topic))
    builder.write_string("\n")
  }
  builder.to_string()
}

///|
fn render_town_ecosystem_overview(plan : @roles.MayorGoalPlan) -> String {
  let builder = StringBuilder::new()
  builder.write_string(town_report_skill_quality_shift())
  builder.write_string(town_report_separation_overview())
  builder.write_string(town_report_ecosystem_diagram())
  builder.write_string(town_report_lane_count_quality_note(plan))
  builder.to_string()
}

///|
fn render_town_integration_section(plan : @roles.MayorGoalPlan) -> String {
  let builder = StringBuilder::new()
  builder.write_string(town_report_integration_thesis())
  builder.write_string(town_report_integration_table_header())
  for topic in town_research_topics() {
    match lane_entry_for_topic(plan, topic) {
      Some(entry) =>
        builder.write_string(town_report_integration_table_row(topic, entry.id))
      None => ()
    }
  }
  builder.write_string("\n")
  builder.write_string(town_report_boundary_failure_note())
  builder.to_string()
}

///|
fn render_town_technical_resources(plan : @roles.MayorGoalPlan) -> String {
  let builder = StringBuilder::new()
  builder.write_string(town_report_technical_evidence_policy())
  builder.write_string(town_report_technical_resource_table_header())
  for lane in plan.lanes {
    builder.write_string(town_report_technical_resource_row(lane.entry))
  }
  builder.write_string("\n")
  builder.write_string(town_report_technical_quality_standard())
  builder.to_string()
}

///|
fn render_town_comparative_analysis() -> String {
  [
    "Compared with a single generated marketing page, a town-level deep report must answer a different question:",
    "how do the projects work together, where do their boundaries sit, and what tradeoffs does the stack make?",
    "MoonBook contributes durable memory and report projection, MoonClaw contributes bounded execution and tool-backed evidence collection, and Moontown contributes planning, parallel decomposition, supervision, and acceptance.",
    "This makes the ecosystem closer to a coordinated agent-infrastructure stack than to a loose collection of utilities.",
  ].join(" ")
}

///|
fn render_town_status_and_trajectory(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> String {
  let builder = StringBuilder::new()
  let running_count = count_lanes_by_status(state, plan, "running")
  let complete_count = count_lanes_by_status(state, plan, "complete")
  let review_count = count_lanes_by_status(state, plan, "review queued")
  let failed_count = count_lanes_by_status(state, plan, "failed")
  builder.write_string(
    town_report_status_counts_sentence(
      complete_count, running_count, review_count, failed_count,
    ),
  )
  if review_count == 0 && failed_count == 0 && running_count == 0 {
    builder.write_string(town_report_final_status_verdict())
  } else {
    builder.write_string(town_report_interim_status_verdict())
  }
  builder.write_string(town_report_reading_surface_note())
  builder.to_string()
}

///|
fn town_research_topics() -> Array[String] {
  ["moonbook", "moonclaw", "moontown"]
}
