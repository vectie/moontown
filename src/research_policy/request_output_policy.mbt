///|
pub fn request_quality_bar_bullet() -> String {
  "- Quality bar: every major claim must trace to either a fetched web source, a local file path, or an explicit blocker explaining why the source could not be inspected."
}

///|
pub fn request_depth_target_bullet() -> String {
  request_policy_bullet("Depth target", [
    "For complex external, comparative, route-map, or technology research, `\{deep_report_path()}` should target \{deep_dossier_word_target()}.",
    "This applies when the screened source base has enough evidence.",
    "If the source base cannot support that depth, write the exact source-class blocker rather than padding.",
  ])
}

///|
pub fn request_reference_style_bullet(display : String) -> String {
  request_policy_bullet("Reference style", [
    "If `\{reference_style_context_page()}` or `\{reference_output_context_page()}` exists, match its depth, length, and section discipline.",
    "Also match its language, tables, and visualization standard.",
    "Treat it as a style target and candidate search-taxonomy source only, not evidence for \{display}.",
  ])
}

///|
fn request_policy_bullet(label : String, clauses : Array[String]) -> String {
  "- \{label}: \{clauses.join(" ")}"
}
