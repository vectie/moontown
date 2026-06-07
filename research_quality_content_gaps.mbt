///|
async fn research_content_quality_gaps(
  entry : @moonbook.BookCatalogEntry,
  root : String,
) -> Array[String] {
  let gaps : Array[String] = []
  let topic = quality_topic_for_entry(entry)
  let brief_path = "\{root}/raw/bootstrap/synthesis-brief.md"
  let overview_path = "\{root}/wiki/synthesis/overview.md"
  let search_log_path = "\{root}/raw/bootstrap/search-log.md"
  let source_screen_path = "\{root}/raw/bootstrap/source-screen.md"
  let tool_blockers_path = "\{root}/raw/bootstrap/tool-blockers.md"
  let brief = read_optional_text(brief_path)
  let overview = read_optional_text(overview_path)
  let search_log = read_optional_text(search_log_path)
  let source_screen = read_optional_text(source_screen_path)
  let tool_blockers = read_optional_text(tool_blockers_path)
  match brief {
    Some(text) => {
      let lower = text.to_lower()
      if !research_text_contains_topic(lower, topic) {
        gaps.push("synthesis brief is not lane-specific for `\{topic}`")
      }
      if lower.contains("require model/web enrichment") ||
        lower.contains("provisional findings") {
        gaps.push("synthesis brief still reports provisional-only research")
      }
    }
    None => ()
  }
  match overview {
    Some(text) => {
      let lower = text.to_lower()
      if lower.contains("web evidence is still provisional") ||
        lower.contains("should be refined by later review") {
        gaps.push("wiki synthesis still declares unresolved research review")
      }
    }
    None => ()
  }
  match search_log {
    Some(text) => {
      let lower = text.to_lower()
      if lower.contains("may enrich it later") {
        gaps.push("search log has only a planned/enrichment-pending web pass")
      }
    }
    None => ()
  }
  match source_screen {
    Some(text) => {
      let lower = text.to_lower()
      if lower.contains("provisional web candidates") &&
        !lower.contains("fetched web evidence") &&
        !lower.contains("verified web evidence") {
        gaps.push("web candidates were listed but not fetched and screened")
      }
      for gap in source_depth_quality_gaps(topic, text) {
        gaps.push(gap)
      }
      for
        gap in source_discovery_fallback_gaps(
          topic,
          search_log.unwrap_or(""),
          text,
          tool_blockers.unwrap_or(""),
        ) {
        gaps.push(gap)
      }
    }
    None => ()
  }
  let deep_report_path = "\{root}/raw/bootstrap/deep-report.md"
  match read_optional_text(deep_report_path) {
    Some(text) => {
      for gap in deep_report_quality_gaps(entry, text) {
        gaps.push(gap)
      }
      for
        gap in deep_report_word_count_gaps(
          topic,
          text,
          source_screen.unwrap_or(""),
        ) {
        gaps.push(gap)
      }
      for gap in reference_report_length_gaps(root, text) {
        gaps.push(gap)
      }
    }
    None => gaps.push("missing `raw/bootstrap/deep-report.md`")
  }
  for gap in research_wiki_materialization_gaps(entry, root, topic) {
    gaps.push(gap)
  }
  for gap in research_generated_site_gaps(root, topic) {
    gaps.push(gap)
  }
  gaps
}
