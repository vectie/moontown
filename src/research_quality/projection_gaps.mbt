///|
pub fn research_wiki_materialization_gaps_from_observation(
  entry : @moonbook.BookCatalogEntry,
  topic : String,
  observation : ResearchQualityObservation,
) -> Array[String] {
  ignore(entry)
  if !is_external_quality_topic(topic) {
    return []
  }
  let gaps : Array[String] = []
  if topic == "opc" {
    if observation.has_runtime_entity_contamination {
      gaps.push(
        "OPC wiki materialization promoted Moon* runtime entities instead of only OPC domain entities",
      )
    }
    if !observation.has_topic_entity_page {
      gaps.push(
        "missing OPC-specific durable entity page under `wiki/entities/`",
      )
    }
    if !observation.has_topic_concept_page {
      gaps.push(
        "missing OPC-specific durable concept page under `wiki/concepts/`",
      )
    }
    if !observation.has_topic_source_page {
      gaps.push(
        "missing OPC-specific durable source coverage under `wiki/sources/`",
      )
    }
  }
  gaps
}

///|
pub fn research_generated_site_gaps_from_observation(
  topic : String,
  observation : ResearchQualityObservation,
) -> Array[String] {
  if !is_external_quality_topic(topic) {
    return []
  }
  let gaps : Array[String] = []
  match observation.generated_site {
    None => {
      if observation.generated_site_read_error {
        gaps.push("generated marketing projection could not be read")
      } else {
        gaps.push(
          "missing live generated marketing projection at `book/site/generated/index.html`",
        )
      }
      return gaps
    }
    Some(html) => {
      let lower = html.to_lower()
      if lower.contains("llm wiki website") ||
        lower.contains("markdown. wiki. website.") ||
        lower.contains("turn a maintained knowledge workspace") {
        gaps.push(
          "generated marketing projection is still the generic MoonBook scaffold",
        )
      }
      if lower.contains("marketing brief needed") ||
        lower.contains("missing: raw/bootstrap") {
        gaps.push(
          "generated marketing projection is diagnostic instead of buyer-facing",
        )
      }
      if !projection_contains_topic(lower, topic) {
        gaps.push(
          "generated marketing projection is not topic-specific for `\{topic}`",
        )
      }
      if !lower.contains("deep research") ||
        (
          !lower.contains("deep research analysis") &&
          !html.contains("深度研究分析")
        ) ||
        !lower.contains("executive summary") ||
        !lower.contains("report-table") {
        gaps.push(
          "generated marketing projection does not embed the deep research article",
        )
      }
    }
  }
  for gap in research_site_entry_gaps_from_observation(topic, observation) {
    gaps.push(gap)
  }
  gaps
}

///|
fn research_site_entry_gaps_from_observation(
  topic : String,
  observation : ResearchQualityObservation,
) -> Array[String] {
  let gaps : Array[String] = []
  match observation.site_entry {
    None => {
      if observation.site_entry_read_error {
        gaps.push("default marketing entrypoint could not be read")
      } else {
        gaps.push(
          "missing default marketing entrypoint at `book/site/index.html`",
        )
      }
      return gaps
    }
    Some(html) => {
      let lower = html.to_lower()
      if lower.contains("llm wiki website") ||
        lower.contains("markdown. wiki. website.") ||
        lower.contains("turn a maintained knowledge workspace") {
        gaps.push(
          "default marketing entrypoint is still the generic MoonBook scaffold",
        )
      }
      if !lower.contains("./generated/index.html") &&
        !projection_contains_topic(lower, topic) {
        gaps.push(
          "default marketing entrypoint does not open a topic-specific generated projection",
        )
      }
    }
  }
  gaps
}
