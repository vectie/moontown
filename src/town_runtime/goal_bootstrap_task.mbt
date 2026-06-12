///|
fn bootstrap_ingest_task(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
) -> @moonbook.BookTask {
  if is_wenyu_valley_goal(goal) {
    @build_pipeline.wenyu_bootstrap_ingest_task(entry, goal)
  } else {
    @research_quality.research_bootstrap_ingest_task(entry, goal)
  }
}
