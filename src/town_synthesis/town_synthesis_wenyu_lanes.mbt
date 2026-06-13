///|
fn render_wenyu_lane_briefs(
  plan : @roles.MayorGoalPlan,
  lane_reports : Array[TownSynthesisLaneReport],
) -> String {
  let builder = StringBuilder::new()
  for lane in plan.lanes {
    builder.write_string("### \{lane.entry.name}\n\n")
    builder.write_string("Objective: \{lane.objective}\n\n")
    let report = lane_report_text(lane_reports, lane.entry.id)
    let summary = @support.section_body(report, "## Executive Summary")
    let compact = @support.first_non_heading_paragraph(summary)
    if compact.is_blank() {
      builder.write_string(
        "No executive-summary paragraph was found in this lane's deep report.\n\n",
      )
    } else {
      builder.write_string(@support.markdown_excerpt(compact, 900))
      builder.write_string("\n\n")
    }
  }
  builder.to_string().trim().to_owned()
}
