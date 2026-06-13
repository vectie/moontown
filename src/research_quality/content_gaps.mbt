///|
fn research_content_quality_gaps_from_observation(
  entry : @moonbook.BookCatalogEntry,
  observation : ResearchQualityObservation,
) -> Array[String] {
  let gaps : Array[String] = []
  let topic = quality_topic_for_entry(entry)
  match observation.brief {
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
  match observation.overview {
    Some(text) => {
      let lower = text.to_lower()
      if lower.contains("web evidence is still provisional") ||
        lower.contains("should be refined by later review") {
        gaps.push("wiki synthesis still declares unresolved research review")
      }
    }
    None => ()
  }
  match observation.search_log {
    Some(text) => {
      let lower = text.to_lower()
      if lower.contains("may enrich it later") {
        gaps.push("search log has only a planned/enrichment-pending web pass")
      }
    }
    None => ()
  }
  match observation.source_screen {
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
          observation.search_log.unwrap_or(""),
          text,
          observation.tool_blockers.unwrap_or(""),
        ) {
        gaps.push(gap)
      }
    }
    None => ()
  }
  match observation.deep_report {
    Some(text) => {
      for gap in deep_report_quality_gaps(entry, text) {
        gaps.push(gap)
      }
      for
        gap in deep_report_word_count_gaps(
          topic,
          text,
          observation.source_screen.unwrap_or(""),
        ) {
        gaps.push(gap)
      }
      for
        gap in reference_report_length_gaps(observation.reference_output, text) {
        gaps.push(gap)
      }
    }
    None => gaps.push("missing `raw/bootstrap/deep-report.md`")
  }
  for
    gap in research_wiki_materialization_gaps_from_observation(
      entry, topic, observation,
    ) {
    gaps.push(gap)
  }
  for gap in research_generated_site_gaps_from_observation(topic, observation) {
    gaps.push(gap)
  }
  gaps
}
