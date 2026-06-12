///|
fn research_report_target_words() -> String {
  research_policy_deep_dossier_word_target()
}

///|
fn research_report_quality_floor_words() -> String {
  research_policy_quality_floor_words()
}

///|
fn research_report_min_included_sources() -> String {
  research_policy_min_included_sources()
}

///|
fn research_report_preferred_included_sources() -> String {
  research_policy_preferred_included_sources()
}

///|
fn research_report_reference_line_ratio() -> String {
  research_policy_reference_line_ratio()
}

///|
fn research_report_reference_line_buffer() -> String {
  research_policy_reference_line_buffer()
}

///|
fn research_report_reference_inputs() -> Array[String] {
  [
    "- `raw/bootstrap/REFERENCE_STYLE.md`", "- `raw/bootstrap/REFERENCE_OUTPUT.md`",
    "- `raw/bootstrap/REFERENCE_SOURCE_HINTS.md`", "- `raw/bootstrap/REFERENCE_VISUAL_PATH.txt`",
  ]
}

///|
fn research_report_reference_length_rule() -> String {
  "- if the reference report is hundreds of lines long, write a hundreds-of-lines report rather than a short executive brief; when `REFERENCE_STYLE.md` reports the line count and `source-screen.md` has at least \{research_report_min_included_sources()} included sources, target at least \{research_report_reference_line_ratio()} of the reference line count plus a \{research_report_reference_line_buffer()}"
}

///|
fn research_report_no_reference_rule_section() -> String {
  [
    "",
    "## No-Reference Deep Research Rule",
    "",
    "When no reference report is supplied, do not fall back to a short default report.",
    "",
    "- Use this skill as the quality authority.",
    "- With \{research_report_min_included_sources()} or more included inspected sources, write toward the \{research_report_target_words()} dossier target.",
    "- With fewer than \{research_report_min_included_sources()} included inspected sources, write the strongest honest report and make the source-depth blocker explicit.",
    "- Prefer \{research_report_preferred_included_sources()} or more included inspected sources before claiming reference-grade depth.",
    "- Expand by asking researcher questions: what mechanism actually creates the advantage, what adoption filter blocks it, which route is only a supplement, what would change the thesis, and what second-order consequence matters.",
  ].join("\n")
}
