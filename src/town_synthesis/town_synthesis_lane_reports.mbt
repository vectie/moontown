///|
pub(all) struct TownSynthesisLaneReport {
  book_id : String
  report_text : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn first_deep_report_summary(
  plan : @roles.MayorGoalPlan,
  topic : String,
  lane_reports : Array[TownSynthesisLaneReport],
) -> String {
  match lane_entry_for_topic(plan, topic) {
    Some(entry) => {
      let report = lane_report_text(lane_reports, entry.id)
      if report.is_blank() {
        return "No deep report was available for this lane."
      }
      let body = @support.section_body(report, "## Executive Summary")
      let compact = @support.first_non_heading_paragraph(body)
      if compact.is_blank() {
        "Deep report exists, but no usable executive-summary paragraph was found."
      } else {
        @support.markdown_excerpt(compact, 520)
      }
    }
    None => "No matching lane was found."
  }
}

///|
fn render_lane_deep_report_for_topic(
  plan : @roles.MayorGoalPlan,
  topic : String,
  lane_reports : Array[TownSynthesisLaneReport],
) -> String {
  match lane_entry_for_topic(plan, topic) {
    Some(entry) => {
      let report = lane_report_text(lane_reports, entry.id)
      if report.is_blank() {
        return render_missing_deep_report_block(entry)
      }
      let body = @support.remove_first_markdown_title(report)
      let excerpt = @support.markdown_excerpt(
        @support.demote_markdown_headings(body),
        9000,
      )
      "\{excerpt}\n\nSource lane report: `\{@moonbook.workspace_root(entry)}/raw/bootstrap/deep-report.md`"
    }
    None => "- No lane report found for `\{topic}`."
  }
}

///|
fn lane_report_text(
  lane_reports : Array[TownSynthesisLaneReport],
  book_id : String,
) -> String {
  for report in lane_reports {
    if report.book_id == book_id {
      return report.report_text
    }
  }
  ""
}

///|
fn render_missing_deep_report_block(
  entry : @moonbook.BookCatalogEntry,
) -> String {
  "- Missing `raw/bootstrap/deep-report.md` for `\{entry.id}`. The town report cannot meet the MoonBook research-report skill standard until this lane emits a long-form report."
}
