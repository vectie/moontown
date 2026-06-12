///|
pub async fn research_wiki_materialization_gaps(
  entry : @moonbook.BookCatalogEntry,
  root : String,
  topic : String,
) -> Array[String] {
  ignore(entry)
  if !is_external_quality_topic(topic) {
    return []
  }
  let gaps : Array[String] = []
  if topic == "opc" {
    if has_external_topic_runtime_entity_contamination(root) {
      gaps.push(
        "OPC wiki materialization promoted Moon* runtime entities instead of only OPC domain entities",
      )
    }
    let aliases = topic_page_aliases(topic)
    if !directory_has_topic_named_page(root, "wiki/entities", aliases) {
      gaps.push(
        "missing OPC-specific durable entity page under `wiki/entities/`",
      )
    }
    if !directory_has_topic_named_page(root, "wiki/concepts", aliases) {
      gaps.push(
        "missing OPC-specific durable concept page under `wiki/concepts/`",
      )
    }
    if !directory_has_topic_source_page(root, aliases) {
      gaps.push(
        "missing OPC-specific durable source coverage under `wiki/sources/`",
      )
    }
  }
  gaps
}

///|
pub async fn research_generated_site_gaps(
  root : String,
  topic : String,
) -> Array[String] {
  if !is_external_quality_topic(topic) {
    return []
  }
  let gaps : Array[String] = []
  let generated_path = research_quality_generated_site_workspace_path(root)
  if !@fs.exists(generated_path) {
    gaps.push(
      "missing live generated marketing projection at `book/site/generated/index.html`",
    )
    return gaps
  }
  let html = @fs.read_file(generated_path).text() catch {
    _ => {
      gaps.push("generated marketing projection could not be read")
      return gaps
    }
  }
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
  for gap in research_site_entry_gaps(root, topic) {
    gaps.push(gap)
  }
  gaps
}

///|
async fn research_site_entry_gaps(
  root : String,
  topic : String,
) -> Array[String] {
  let gaps : Array[String] = []
  let entry_path = "\{root}/book/site/index.html"
  if !@fs.exists(entry_path) {
    gaps.push("missing default marketing entrypoint at `book/site/index.html`")
    return gaps
  }
  let html = @fs.read_file(entry_path).text() catch {
    _ => {
      gaps.push("default marketing entrypoint could not be read")
      return gaps
    }
  }
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
  gaps
}
