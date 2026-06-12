///|
async fn research_quality_gaps(
  entry : @moonbook.BookCatalogEntry,
) -> Array[String] {
  @research_quality.research_quality_gaps(entry)
}

///|
fn quality_topic_for_entry(entry : @moonbook.BookCatalogEntry) -> String {
  @research_quality.quality_topic_for_entry(entry)
}
