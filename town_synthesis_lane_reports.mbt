///|
async fn first_deep_report_summary(
  plan : @roles.MayorGoalPlan,
  topic : String,
) -> String {
  match lane_entry_for_topic(plan, topic) {
    Some(entry) => {
      let report = read_lane_deep_report(entry)
      if report.is_blank() {
        return "No deep report was available for this lane."
      }
      let body = section_body(report, "## Executive Summary")
      let compact = first_non_heading_paragraph(body)
      if compact.is_blank() {
        "Deep report exists, but no usable executive-summary paragraph was found."
      } else {
        markdown_excerpt(compact, 520)
      }
    }
    None => "No matching lane was found."
  }
}

///|
async fn render_lane_deep_report_for_topic(
  plan : @roles.MayorGoalPlan,
  topic : String,
) -> String {
  match lane_entry_for_topic(plan, topic) {
    Some(entry) => {
      let report = read_lane_deep_report(entry)
      if report.is_blank() {
        return render_missing_deep_report_block(entry)
      }
      let body = remove_first_markdown_title(report)
      let excerpt = markdown_excerpt(demote_markdown_headings(body), 9000)
      "\{excerpt}\n\nSource lane report: `\{@moonbook.workspace_root(entry)}/raw/bootstrap/deep-report.md`"
    }
    None => "- No lane report found for `\{topic}`."
  }
}

///|
fn render_missing_deep_report_block(
  entry : @moonbook.BookCatalogEntry,
) -> String {
  "- Missing `raw/bootstrap/deep-report.md` for `\{entry.id}`. The town report cannot meet the MoonBook research-report skill standard until this lane emits a long-form report."
}
