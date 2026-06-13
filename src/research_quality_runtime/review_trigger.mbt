///|
pub async fn write_research_quality_review_trigger(
  entry : @moonbook.BookCatalogEntry,
  quality_gaps : Array[String],
  reason : String,
) -> Unit {
  guard @research_quality.research_quality_entry_is_research(entry) else {
    return
  }
  let path = @research_quality.research_quality_review_trigger_path(entry)
  @support.write_text_file(
    path,
    @research_quality.research_quality_review_trigger_markdown(
      quality_gaps, reason,
    ),
  )
}

///|
pub async fn write_research_quality_review_resolved(
  entry : @moonbook.BookCatalogEntry,
  reason : String,
) -> Unit {
  guard @research_quality.research_quality_entry_is_research(entry) else {
    return
  }
  let path = @research_quality.research_quality_review_trigger_path(entry)
  guard @fs.exists(path) else { return }
  @support.write_text_file(
    path,
    @research_quality.research_quality_review_resolved_markdown(reason),
  )
}
