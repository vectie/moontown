///|
fn render_wenyu_executive_summary(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> String {
  let complete_count = count_lanes_by_status(state, plan, "complete")
  let running_count = count_lanes_by_status(state, plan, "running")
  let failed_count = count_lanes_by_status(state, plan, "failed")
  let builder = StringBuilder::new()
  builder.write_string(wenyu_parallel_lane_summary(plan))
  builder.write_string(wenyu_lane_input_summary())
  builder.write_string(
    wenyu_lane_status_summary(complete_count, running_count, failed_count),
  )
  builder.write_string("\n\n")
  builder.write_string(wenyu_product_build_map_summary())
  builder.to_string()
}

///|
fn wenyu_parallel_lane_summary(plan : @roles.MayorGoalPlan) -> String {
  "The mayor decomposed Wenyu Valley into \{plan.lanes.length()} isolated civic product books so the town can grow by parallel knowledge lanes instead of one overloaded wiki. "
}

///|
fn wenyu_lane_input_summary() -> String {
  "Each lane received the Wenyu PRD, the Wenyu vision, and a mounted source snapshot of MoonTown, MoonBook, MoonClaw, and Rabbita implementation files. "
}

///|
fn wenyu_lane_status_summary(
  complete_count : Int,
  running_count : Int,
  failed_count : Int,
) -> String {
  "The fresh run completed \{complete_count} lanes, left \{running_count} running, and recorded \{failed_count} failed lanes."
}
