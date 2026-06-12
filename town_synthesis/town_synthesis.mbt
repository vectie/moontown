///|
pub async fn write_town_goal_synthesis(
  state : @core.TownState,
  goal : String,
  plan : @roles.MayorGoalPlan,
  snapshot_path : String,
) -> Unit {
  if plan.lanes.length() < 2 {
    return
  }
  let synthesis_dir = town_synthesis_dir(snapshot_path)
  let path = "\{synthesis_dir}/\{town_goal_slug(goal)}.md"
  let latest_path = "\{synthesis_dir}/latest.md"
  let content = render_town_goal_synthesis(state, goal, plan)
  @support.write_text_file(path, content)
  @support.write_text_file(latest_path, content)
  register_town_synthesis_execution(state, goal, plan, path)
  state.record_event(
    @core.TownEvent::new(
      id="event-town-synthesis-\{state.events.length()}",
      kind="synthesis",
      detail="Mayor wrote town-level synthesis for \{plan.lanes.length()} lanes: \{path}",
      related_task_id=Some(town_synthesis_task_id(goal)),
      related_book_id=Some("town"),
    ),
  )
}

///|
async fn render_town_goal_synthesis(
  state : @core.TownState,
  goal : String,
  plan : @roles.MayorGoalPlan,
) -> String {
  if is_wenyu_town_synthesis_plan(goal, plan) {
    return render_wenyu_town_goal_synthesis(state, goal, plan)
  }
  let builder = StringBuilder::new()
  builder.write_string(
    "# Moontown, MoonBook, and MoonClaw: Deep Research Analysis\n\n",
  )
  builder.write_string("Goal: \{goal}\n\n")
  builder.write_string("Mayor plan: \{plan.summary}\n\n")
  builder.write_string("Output contract: `mayor.town_synthesis.v1`\n\n")
  builder.write_string("## Executive Summary\n\n")
  builder.write_string(render_town_report_executive_summary(plan))
  builder.write_string("\n\n")
  builder.write_string("## Ecosystem Overview and Foundational Context\n\n")
  builder.write_string(render_town_ecosystem_overview(plan))
  builder.write_string("\n\n")
  builder.write_string(
    "## MoonBook: Documentation and Knowledge Infrastructure\n\n",
  )
  builder.write_string(render_lane_deep_report_for_topic(plan, "moonbook"))
  builder.write_string(
    "\n\n## MoonClaw: Agent Runtime and Job Orchestration\n\n",
  )
  builder.write_string(render_lane_deep_report_for_topic(plan, "moonclaw"))
  builder.write_string(
    "\n\n## Moontown: Orchestration Layer and Control Plane\n\n",
  )
  builder.write_string(render_lane_deep_report_for_topic(plan, "moontown"))
  builder.write_string(
    "\n\n## Inter-System Integration and Architectural Relationships\n\n",
  )
  builder.write_string(render_town_integration_section(plan))
  builder.write_string(
    "\n\n## Technical Documentation and Development Resources\n\n",
  )
  builder.write_string(render_town_technical_resources(plan))
  builder.write_string("\n\n## Comparative and Contextual Analysis\n\n")
  builder.write_string(render_town_comparative_analysis())
  builder.write_string("\n\n## Current Status and Development Trajectory\n\n")
  builder.write_string(render_town_status_and_trajectory(state, plan))
  builder.write_string("\n\n## Evidence and Limits\n\n")
  builder.write_string(render_town_evidence_and_limits(state, plan))
  builder.to_string()
}
