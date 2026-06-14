///|
fn research_report_reference_output_rule_section(display : String) -> String {
  [
    "",
    "## Reference Output Rule",
    "",
    "If these files exist, read them before writing:",
    "",
    @research_policy.report_reference_inputs().join("\n"),
    "",
    "Use reference material only as a style and quality benchmark:",
    "",
    "- match its approximate length class when evidence supports that length",
    "- match its section discipline, evidence density, table density, strategic conclusions, and visual-analysis ambition",
    @research_policy.report_reference_length_rule(),
    "- if evidence is narrower than the reference, expand by explaining mechanisms, route tradeoffs, adoption logic, bottlenecks, source reliability, and what evidence would change the thesis; do not pad with repeated definitions or unsupported facts",
    "- use route names, comparison axes, and visual dimensions found in the reference as candidate search and synthesis hypotheses when relevant, but verify each adopted route independently",
    "- use reference source hints only when `source-screen.md` or `evidence-matrix.md` shows they were inspected; unscreened hints belong in gaps, not claims",
    "- preserve its language choice when the user has not asked otherwise",
    "- never import its factual claims into \{display} unless independently supported by screened evidence",
    "- if the reference is stronger than the available evidence, state the evidence gap and write the strongest honest report instead of padding",
  ].join("\n")
}
