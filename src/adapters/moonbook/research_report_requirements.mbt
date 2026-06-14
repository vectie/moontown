///|
fn research_report_non_negotiable_output_section(display : String) -> String {
  [
    "",
    "## Non-Negotiable Output",
    "",
    "Always produce or revise `\{research_deep_report_path()}` when `\{research_evidence_matrix_path()}` exists.",
    "",
    "Hard requirements:",
    "",
    research_report_title_requirement(display),
    research_report_structure_requirement(),
    research_report_table_requirement(),
    research_report_diagram_requirement(),
    research_report_source_id_requirement(),
    research_report_limits_requirement(),
    research_report_process_caveat_requirement(),
    research_report_word_target_requirement(),
    "",
    "This word target is not a license to pad. Reach it through evidence-backed mechanism analysis, route-by-route judgement, adoption constraints, second-order implications, and source reliability work.",
  ].join("\n")
}

///|
fn research_report_title_requirement(display : String) -> String {
  "- title: the first heading must contain `Deep Research Analysis`; use `# \{display}: Deep Research Analysis` unless there is a strong reason to add a subtitle"
}

///|
fn research_report_structure_requirement() -> String {
  "- at least 8 `##` sections for a single-topic report\n- first `##` section: `## Executive Summary`"
}

///|
fn research_report_table_requirement() -> String {
  "- at least one comparison, evidence, roadmap, or maturity table"
}

///|
fn research_report_diagram_requirement() -> String {
  "- at least one Mermaid relationship, route, or decision diagram when relationships or routes matter"
}

///|
fn research_report_source_id_requirement() -> String {
  "- source IDs on strong claims"
}

///|
fn research_report_limits_requirement() -> String {
  "- a final `## Evidence and Limits` section"
}

///|
fn research_report_process_caveat_requirement() -> String {
  "- process/tool caveats only in the limits section unless they invalidate the thesis"
}

///|
fn research_report_word_target_requirement() -> String {
  "- for complex external, comparative, route-map, or technology research with enough screened sources: target \{@research_policy.report_target_words()}; \{@research_policy.report_quality_floor_words()} is the quality floor unless explicit source-depth blockers make that dishonest"
}

///|
fn research_report_required_inputs_section() -> String {
  let lines : Array[String] = ["", "## Required Inputs", ""]
  for path in research_ingest_required_raw_artifact_paths() {
    lines.push("- `\{path}`")
  }
  lines.push("- `wiki/sources/*.md`")
  lines.push("- `wiki/entities/*.md`")
  lines.push("- `wiki/concepts/*.md`")
  lines.push("- `wiki/synthesis/*.md`")
  lines.join("\n")
}
