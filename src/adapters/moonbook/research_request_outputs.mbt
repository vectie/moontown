///|
fn research_quality_bar_bullet() -> String {
  "- Quality bar: every major claim must trace to either a fetched web source, a local file path, or an explicit blocker explaining why the source could not be inspected."
}

///|
fn research_depth_target_bullet() -> String {
  research_bullet("Depth target", [
    "For complex external, comparative, route-map, or technology research, `\{research_deep_report_path()}` should target \{research_policy_deep_dossier_word_target()}.",
    "This applies when the screened source base has enough evidence.",
    "If the source base cannot support that depth, write the exact source-class blocker rather than padding.",
  ])
}

///|
fn research_reference_style_bullet(display : String) -> String {
  research_bullet("Reference style", [
    "If `raw/bootstrap/REFERENCE_STYLE.md` or `raw/bootstrap/REFERENCE_OUTPUT.md` exists, match its depth, length, and section discipline.",
    "Also match its language, tables, and visualization standard.",
    "Treat it as a style target and candidate search-taxonomy source only, not evidence for \{display}.",
  ])
}

///|
fn research_bullet(label : String, clauses : Array[String]) -> String {
  "- \{label}: \{clauses.join(" ")}"
}

///|
fn research_raw_output_bullets() -> String {
  research_raw_bootstrap_artifact_bullets("  ").join("\n")
}

///|
fn research_materialization_output_bullets() -> String {
  [
    "  - at least one substantive page under `wiki/sources/`", "  - at least one substantive page under `wiki/entities/`",
    "  - at least one substantive page under `wiki/concepts/`", "  - at least one substantive page under `wiki/synthesis/`",
    "  - `wiki/index.md` and `wiki/log.md` updated consistently",
  ].join("\n")
}
