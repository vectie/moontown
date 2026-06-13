///|
pub async fn research_quality_gaps(
  entry : @moonbook.BookCatalogEntry,
) -> Array[String] {
  @research_quality.research_quality_gaps_from_observation(
    entry,
    research_quality_observation(entry),
  )
}

///|
pub async fn research_quality_observation(
  entry : @moonbook.BookCatalogEntry,
) -> @research_quality.ResearchQualityObservation {
  let root = @moonbook.workspace_root(entry)
  let topic = @research_quality.quality_topic_for_entry(entry)
  let aliases = @research_quality.research_topic_page_aliases(topic)
  let summary = Some(@moonbook.summarize_state(entry)) catch { _ => None }
  {
    root,
    missing_required_paths: @support.workspace_missing_relative_paths(
      root,
      @research_quality.research_quality_required_paths(entry),
    ),
    has_research_source_marker: has_research_source_marker(root),
    readiness: match summary {
      Some(summary) =>
        Some(@research_quality.ResearchReadiness::from_summary(summary))
      None => None
    },
    brief: @support.read_optional_text(
      "\{root}/raw/bootstrap/synthesis-brief.md",
    ),
    overview: @support.read_optional_text("\{root}/wiki/synthesis/overview.md"),
    search_log: @support.read_optional_text(
      "\{root}/raw/bootstrap/search-log.md",
    ),
    source_screen: @support.read_optional_text(
      "\{root}/raw/bootstrap/source-screen.md",
    ),
    tool_blockers: @support.read_optional_text(
      "\{root}/raw/bootstrap/tool-blockers.md",
    ),
    deep_report: @support.read_optional_text(
      "\{root}/raw/bootstrap/deep-report.md",
    ),
    reference_output: @support.read_optional_text(
      "\{root}/raw/bootstrap/REFERENCE_OUTPUT.md",
    ),
    has_runtime_entity_contamination: has_external_topic_runtime_entity_contamination(
      root,
    ),
    has_topic_entity_page: directory_has_topic_named_page(
      root, "wiki/entities", aliases,
    ),
    has_topic_concept_page: directory_has_topic_named_page(
      root, "wiki/concepts", aliases,
    ),
    has_topic_source_page: directory_has_topic_source_page(root, aliases),
    generated_site: read_optional_file(
      "\{root}/\{@policy.default_generated_site_projection_path()}",
    ),
    generated_site_read_error: file_read_error(
      "\{root}/\{@policy.default_generated_site_projection_path()}",
    ),
    site_entry: read_optional_file("\{root}/book/site/index.html"),
    site_entry_read_error: file_read_error("\{root}/book/site/index.html"),
  }
}

///|
async fn has_external_topic_runtime_entity_contamination(root : String) -> Bool {
  for name in ["moonclaw", "moonbook", "moontown"] {
    if @fs.exists("\{root}/wiki/entities/\{name}.md") {
      return true
    }
  }
  false
}

///|
async fn directory_has_topic_named_page(
  root : String,
  relative_dir : String,
  aliases : Array[String],
) -> Bool {
  let listed = @integration.run_checked("find", [
    "\{root}/\{relative_dir}",
    "-type",
    "f",
    "-name",
    "*.md",
  ]) catch {
    _ => return false
  }
  for path in listed.stdout.split("\n") {
    let file = path.trim()
    if file.is_empty() {
      continue
    }
    let lower_name = path_basename(file.to_owned()).to_lower()
    for page_alias in aliases {
      if lower_name.contains(page_alias) {
        return true
      }
    }
  }
  false
}

///|
async fn directory_has_topic_source_page(
  root : String,
  aliases : Array[String],
) -> Bool {
  let listed = @integration.run_checked("find", [
    "\{root}/wiki/sources",
    "-type",
    "f",
    "-name",
    "*.md",
  ]) catch {
    _ => return false
  }
  for path in listed.stdout.split("\n") {
    let file = path.trim()
    if file.is_empty() {
      continue
    }
    let lower_name = path_basename(file.to_owned()).to_lower()
    let lower_content = @fs.read_file(file).text().to_lower() catch { _ => "" }
    for page_alias in aliases {
      if lower_name.contains(page_alias) || lower_content.contains(page_alias) {
        return true
      }
    }
  }
  false
}

///|
async fn has_research_source_marker(root : String) -> Bool {
  let listed = @integration.run_checked("find", [
    "\{root}/wiki/sources",
    "-type",
    "f",
    "-name",
    "*.md",
  ]) catch {
    _ => return false
  }
  for path in listed.stdout.split("\n") {
    let file = path.trim()
    if file.is_empty() {
      continue
    }
    let content = @fs.read_file(file).text() catch { _ => continue }
    if content.contains("Source type: verified source digest") ||
      content.contains("Evidence Matrix") ||
      content.contains("Claim ID") {
      return true
    }
  }
  false
}

///|
async fn read_optional_file(path : String) -> String? {
  guard @fs.exists(path) else { return None }
  Some(@fs.read_file(path).text()) catch {
    _ => None
  }
}

///|
async fn file_read_error(path : String) -> Bool {
  guard @fs.exists(path) else { return false }
  let _ = @fs.read_file(path) catch { _ => return true }
  false
}

///|
fn path_basename(value : String) -> String {
  @path.Path::basename(value).to_owned()
}
