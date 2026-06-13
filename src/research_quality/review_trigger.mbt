///|
pub fn research_quality_review_trigger_path(
  entry : @moonbook.BookCatalogEntry,
) -> String {
  "\{research_quality_bootstrap_raw_root(entry)}/QUALITY_REPAIR.md"
}

///|
pub fn research_quality_review_trigger_markdown(
  quality_gaps : Array[String],
  reason : String,
) -> String {
  [
    "# Research Review Trigger",
    "",
    "Moontown queued an in-place review/repair pass for this stable research book.",
    "",
    "Reason: \{reason}",
    "",
    "Quality gaps:",
    "",
    ..quality_gaps.map(fn(gap) { "- \{gap}" }),
    "",
    "Rules:",
    "- do not create a new v1/v2/v3/v4 book or alternate report file",
    "- keep the current raw/bootstrap envelope as context",
    "- revise `raw/bootstrap/deep-report.md` and companion artifacts in-place",
    "- if a gap is not fixable from screened evidence, explain the blocker explicitly",
  ].join("\n")
}

///|
pub fn research_quality_review_resolved_markdown(reason : String) -> String {
  [
    "# Research Review Trigger",
    "",
    "No active quality repair.",
    "",
    "Moontown rechecked this stable research book and found no remaining framework-level quality gaps.",
    "",
    "Reason: \{reason}",
    "",
    "Rules:",
    "- keep this file as historical repair audit context only",
    "- do not treat this file as a request to create a new v1/v2/v3/v4 book",
    "- do not enter repair mode from this file unless new active quality gaps are written below",
  ].join("\n")
}

///|
fn research_quality_bootstrap_raw_root(
  entry : @moonbook.BookCatalogEntry,
) -> String {
  "\{@moonbook.workspace_root(entry)}/raw/bootstrap"
}
