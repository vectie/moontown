///|
pub fn report_non_negotiable_output_section(display : String) -> String {
  [
    "",
    "## Non-Negotiable Output",
    "",
    "Always produce or revise `\{deep_report_path()}` when `\{evidence_matrix_path()}` exists.",
    "",
    "Hard requirements:",
    "",
    report_title_requirement(display),
    report_structure_requirement(),
    report_table_requirement(),
    report_diagram_requirement(),
    report_source_id_requirement(),
    report_limits_requirement(),
    report_process_caveat_requirement(),
    report_word_target_requirement(),
    "",
    "This word target is not a license to pad. Reach it through evidence-backed mechanism analysis, route-by-route judgement, adoption constraints, second-order implications, and source reliability work.",
  ].join("\n")
}

///|
pub fn report_title_requirement(display : String) -> String {
  "- title: the first heading must contain `Deep Research Analysis`; use `# \{display}: Deep Research Analysis` unless there is a strong reason to add a subtitle"
}

///|
pub fn report_structure_requirement() -> String {
  "- at least 8 `##` sections for a single-topic report\n- first `##` section: `## Executive Summary`"
}

///|
pub fn report_table_requirement() -> String {
  "- at least one comparison, evidence, roadmap, or maturity table"
}

///|
pub fn report_diagram_requirement() -> String {
  "- at least one Mermaid relationship, route, or decision diagram when relationships or routes matter"
}

///|
pub fn report_source_id_requirement() -> String {
  "- source IDs on strong claims"
}

///|
pub fn report_limits_requirement() -> String {
  "- a final `## Evidence and Limits` section"
}

///|
pub fn report_process_caveat_requirement() -> String {
  "- process/tool caveats only in the limits section unless they invalidate the thesis"
}

///|
pub fn report_word_target_requirement() -> String {
  "- for complex external, comparative, route-map, or technology research with enough screened sources: target \{report_target_words()}; \{report_quality_floor_words()} is the quality floor unless explicit source-depth blockers make that dishonest"
}

///|
pub fn report_required_inputs_section() -> String {
  let lines : Array[String] = ["", "## Required Inputs", ""]
  for path in ingest_required_raw_artifact_paths() {
    lines.push("- `\{path}`")
  }
  lines.push("- `wiki/sources/*.md`")
  lines.push("- `wiki/entities/*.md`")
  lines.push("- `wiki/concepts/*.md`")
  lines.push("- `wiki/synthesis/*.md`")
  lines.join("\n")
}
