///|

///|
pub async fn render_town_goal_synthesis(
  state : @core.TownState,
  goal : String,
  plan : @roles.MayorGoalPlan,
  lane_reports : Array[TownSynthesisLaneReport],
) -> String {
  if is_wenyu_town_synthesis_plan(goal, plan) {
    return render_wenyu_town_goal_synthesis(state, goal, plan, lane_reports)
  }
  let builder = StringBuilder::new()
  builder.write_string(
    "# MoonTown, MoonBook, and MoonClaw: Deep Research Analysis\n\n",
  )
  builder.write_string("Goal: \{goal}\n\n")
  builder.write_string("Mayor plan: \{plan.summary}\n\n")
  builder.write_string("Output contract: `mayor.town_synthesis.v1`\n\n")
  builder.write_string("## Executive Summary\n\n")
  builder.write_string(render_town_report_executive_summary(plan, lane_reports))
  builder.write_string("\n\n")
  builder.write_string("## Ecosystem Overview and Foundational Context\n\n")
  builder.write_string(render_town_ecosystem_overview(plan))
  builder.write_string("\n\n")
  builder.write_string(
    "## MoonBook: Documentation and Knowledge Infrastructure\n\n",
  )
  builder.write_string(
    render_lane_deep_report_for_topic(plan, "moonbook", lane_reports),
  )
  builder.write_string(
    "\n\n## MoonClaw: Agent Runtime and Job Orchestration\n\n",
  )
  builder.write_string(
    render_lane_deep_report_for_topic(plan, "moonclaw", lane_reports),
  )
  builder.write_string(
    "\n\n## MoonTown: Orchestration Layer and Control Plane\n\n",
  )
  builder.write_string(
    render_lane_deep_report_for_topic(plan, "moontown", lane_reports),
  )
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
