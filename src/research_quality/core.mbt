///|
fn is_wenyu_book(entry : @moonbook.BookCatalogEntry) -> Bool {
  research_quality_entry_is_wenyu_support(entry)
}

///|
pub fn research_quality_gaps_from_observation(
  entry : @moonbook.BookCatalogEntry,
  observation : ResearchQualityObservation,
) -> Array[String] {
  if @civic.is_wenyu_civic_book_id(entry.id) {
    return []
  }
  if !research_quality_entry_is_research(entry) && !is_wenyu_book(entry) {
    return []
  }
  let gaps : Array[String] = []
  for relative in observation.missing_required_paths {
    gaps.push("missing `\{relative}`")
  }
  if !observation.has_research_source_marker {
    gaps.push("no verified research source digest marker in `wiki/sources/`")
  }
  match observation.readiness {
    Some(readiness) =>
      for gap in readiness.gaps {
        gaps.push(gap)
      }
    None => gaps.push("MoonBook summary unavailable for typed readiness")
  }
  for gap in research_content_quality_gaps_from_observation(entry, observation) {
    gaps.push(gap)
  }
  gaps
}

///|
pub fn research_quality_required_paths(
  entry : @moonbook.BookCatalogEntry,
) -> Array[String] {
  if is_wenyu_book(entry) {
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
}
