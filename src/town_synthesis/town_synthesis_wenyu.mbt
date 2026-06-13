///|
fn is_wenyu_town_synthesis_plan(
  goal : String,
  plan : @roles.MayorGoalPlan,
) -> Bool {
  if @policy.wenyu_valley_goal_text(goal) {
    return true
  }
  for lane in plan.lanes {
    if @policy.catalog_entry_type(
        lane.entry.id,
        lane.entry.name,
        lane.entry.tags,
      ) ==
      @policy.civic_type() {
      return true
    }
  }
  false
}

///|
async fn render_wenyu_town_goal_synthesis(
  state : @core.TownState,
  goal : String,
  plan : @roles.MayorGoalPlan,
  lane_reports : Array[TownSynthesisLaneReport],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Wenyu Valley AI Innovation Town: Build Synthesis\n\n")
  builder.write_string("Goal: \{goal}\n\n")
  builder.write_string("Mayor plan: \{plan.summary}\n\n")
  builder.write_string("Output contract: `mayor.town_synthesis.v1`\n\n")
  builder.write_string("## Executive Summary\n\n")
  builder.write_string(render_wenyu_executive_summary(state, plan))
  builder.write_string("\n\n## Product Architecture\n\n")
  builder.write_string(render_wenyu_product_architecture(plan))
  builder.write_string("\n\n## Module Lanes\n\n")
  builder.write_string(render_wenyu_lane_briefs(plan, lane_reports))
  builder.write_string("\n\n## Evidence and Artifacts\n\n")
  builder.write_string(render_wenyu_artifact_matrix(state, plan))
  builder.write_string("\n\n## Implementation Readiness\n\n")
  builder.write_string(render_wenyu_readiness(state, plan))
  builder.write_string("\n\n## Next Build Plan\n\n")
  builder.write_string(render_wenyu_next_build_plan(plan))
  builder.write_string("\n\n## Limits\n\n")
  builder.write_string(
    "This synthesis is a mayor-level build handoff. It does not replace each MoonBook lane's `raw/bootstrap/deep-report.md`, `raw/bootstrap/evidence-matrix.md`, or `raw/bootstrap/marketing-brief.md`. Those lane artifacts remain the evidence source of truth.",
  )
  builder.to_string()
}
