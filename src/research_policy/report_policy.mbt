///|
pub fn report_target_words() -> String {
  deep_dossier_word_target()
}

///|
pub fn report_quality_floor_words() -> String {
  quality_floor_words()
}

///|
pub fn report_min_included_sources() -> String {
  min_included_sources()
}

///|
pub fn report_preferred_included_sources() -> String {
  preferred_included_sources()
}

///|
pub fn report_reference_line_ratio() -> String {
  reference_line_ratio()
}

///|
pub fn report_reference_line_buffer() -> String {
  reference_line_buffer()
}

///|
pub fn report_reference_inputs() -> Array[String] {
  [
    "- `\{reference_style_context_page()}`",
    "- `\{reference_output_context_page()}`",
    "- `\{reference_source_hints_context_page()}`",
    "- `raw/bootstrap/REFERENCE_VISUAL_PATH.txt`",
  ]
}

///|
pub fn report_reference_length_rule() -> String {
  "- if the reference report is hundreds of lines long, write a hundreds-of-lines report rather than a short executive brief; when `REFERENCE_STYLE.md` reports the line count and `source-screen.md` has at least \{report_min_included_sources()} included sources, target at least \{report_reference_line_ratio()} of the reference line count plus a \{report_reference_line_buffer()}"
}

///|
pub fn report_no_reference_rule_section() -> String {
  [
    "",
    "## No-Reference Deep Research Rule",
    "",
    "When no reference report is supplied, do not fall back to a short default report.",
    "",
    "- Use this skill as the quality authority.",
    "- With \{report_min_included_sources()} or more included inspected sources, write toward the \{report_target_words()} dossier target.",
    "- With fewer than \{report_min_included_sources()} included inspected sources, write the strongest honest report and make the source-depth blocker explicit.",
    "- Prefer \{report_preferred_included_sources()} or more included inspected sources before claiming reference-grade depth.",
    "- Expand by asking researcher questions: what mechanism actually creates the advantage, what adoption filter blocks it, which route is only a supplement, what would change the thesis, and what second-order consequence matters.",
  ].join("\n")
}
