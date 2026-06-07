///|
async fn research_quality_gaps(
  entry : @moonbook.BookCatalogEntry,
) -> Array[String] {
  if @civic.is_wenyu_civic_book_id(entry.id) {
    return []
  }
  if !entry.id.has_prefix("research-") && !is_wenyu_book(entry) {
    return []
  }
  let root = @moonbook.workspace_root(entry)
  let required = if is_wenyu_book(entry) {
    [
      "raw/bootstrap/research-question.md", "raw/bootstrap/search-log.md", "raw/bootstrap/source-screen.md",
      "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/local-sources.md", "raw/bootstrap/synthesis-brief.md",
      "raw/bootstrap/marketing-brief.md", "raw/bootstrap/deep-report.md", "raw/bootstrap/WENYU_VALLEY_PRD.md",
      "mounted-sources/MANIFEST.md",
    ]
  } else {
    [
      "raw/bootstrap/research-question.md", "raw/bootstrap/search-log.md", "raw/bootstrap/source-screen.md",
      "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/local-sources.md", "raw/bootstrap/synthesis-brief.md",
      "raw/bootstrap/marketing-brief.md",
    ]
  }
  let gaps : Array[String] = []
  for relative in workspace_missing_relative_paths(root, required) {
    gaps.push("missing `\{relative}`")
  }
  if !has_research_source_marker(root) {
    gaps.push("no verified research source digest marker in `wiki/sources/`")
  }
  let summary = Some(@moonbook.summarize_state(entry)) catch { _ => None }
  match summary {
    Some(summary) => {
      let readiness = ResearchReadiness::from_summary(summary)
      for gap in readiness.gaps {
        gaps.push(gap)
      }
    }
    None => gaps.push("MoonBook summary unavailable for typed readiness")
  }
  for gap in research_content_quality_gaps(entry, root) {
    gaps.push(gap)
  }
  gaps
}
