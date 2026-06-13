///|
pub fn deep_report_quality_gaps(
  entry : @moonbook.BookCatalogEntry,
  report : String,
) -> Array[String] {
  let gaps : Array[String] = []
  let lower = report.to_lower()
  let topic = quality_topic_for_entry(entry)
  if !lower.contains("deep research analysis") &&
    !report.contains("深度研究分析") {
    gaps.push("deep report title does not declare `Deep Research Analysis`")
  }
  if !research_text_contains_topic(lower, topic) {
    gaps.push("deep report is not lane-specific for `\{topic}`")
  }
  if is_external_quality_topic(topic) {
    for gap in external_domain_report_gaps(topic, lower) {
      gaps.push(gap)
    }
  }
  let section_count = count_markdown_sections(report)
  if section_count < 8 {
    gaps.push(
      "deep report has only \{section_count} top-level sections; expected at least 8",
    )
  }
  if !lower.contains("## executive summary") {
    gaps.push("deep report is missing `## Executive Summary`")
  }
  if !markdown_has_table(report) {
    gaps.push("deep report is missing at least one comparison/evidence table")
  }
  if !lower.contains("```mermaid") {
    gaps.push("deep report is missing a Mermaid relationship diagram")
  }
  if contains_process_heavy_research_text(lower) {
    gaps.push("deep report still reads like a run log instead of research")
  }
  gaps
}

///|
fn reference_report_length_gaps(
  reference_output : String?,
  report : String,
) -> Array[String] {
  let gaps : Array[String] = []
  match reference_output {
    Some(reference) => {
      let reference_lines = count_text_lines(reference)
      let report_lines = count_text_lines(report)
      if reference_lines >= 200 && report_lines * 10 < reference_lines * 6 {
        gaps.push(
          "deep report has \{report_lines} lines, far shorter than the \{reference_lines}-line reference output; expected at least 60% of reference length for reference-matched research",
        )
      }
    }
    None => ()
  }
  gaps
}

///|
fn is_external_quality_topic(topic : String) -> Bool {
  match topic {
    "moontown" | "moonbook" | "moonclaw" => false
    _ => true
  }
}

///|
fn external_domain_report_gaps(topic : String, lower : String) -> Array[String] {
  let gaps : Array[String] = []
  if lower.contains("github.com/vectie/\{topic}") ||
    lower.contains("/workspace/\{topic}") {
    gaps.push(
      "external-domain report incorrectly treats the lane as a Vectie/local repository",
    )
  }
  if lower.contains("moonbit package") || lower.contains("moon.mod.json") {
    gaps.push(
      "external-domain report incorrectly treats the lane as a MoonBit software package",
    )
  }
  if topic == "opc" {
    if lower.contains("vectie/opc") ||
      lower.contains("github.com/vectie/opc") ||
      lower.contains("/workspace/opc") {
      gaps.push(
        "OPC report incorrectly treats the lane as a Vectie/local repository",
      )
    }
    if lower.contains("moonbit package") || lower.contains("moon.mod.json") {
      gaps.push(
        "OPC report incorrectly treats the lane as a MoonBit software package",
      )
    }
    if !lower.contains("one person company") &&
      !lower.contains("one-person company") {
      gaps.push(
        "OPC report does not anchor the topic as One Person Company research",
      )
    }
  }
  gaps
}
