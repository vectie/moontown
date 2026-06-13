///|
async fn book_persist_summary(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> String {
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) =>
      if @civic_runtime.is_civic_service_execution(execution) {
        return @civic_runtime.civic_persist_summary(service, execution)
      }
    None => ()
  }
  @research_quality_runtime.research_persist_summary(entry, execution)
}

///|
fn book_persist_artifacts(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> Array[String] {
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) =>
      if @civic_runtime.is_civic_service_execution(execution) {
        return @civic_runtime.civic_persist_artifacts(service, execution)
      }
    None => ()
  }
  @research_quality_runtime.research_persist_artifacts(entry, execution)
}

///|
async fn book_persist_memory_candidates(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> Array[@moonbook.MemoryCandidate] {
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) =>
      if @civic_runtime.is_civic_service_execution(execution) {
        return @civic_runtime.civic_persist_memory_candidates(
          service, execution,
        )
      }
    None => ()
  }
  @research_quality_runtime.research_persist_memory_candidates(entry, execution)
}
