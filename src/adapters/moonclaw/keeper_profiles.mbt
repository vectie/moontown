///|
pub fn keeper_profile_for_task(task : @moonbook.BookTask) -> String {
  if @dispatch.research_bootstrap_book_task(task) {
    return "moontown_research_bootstrap_worker"
  }
  match task.kind {
    "standing-watch" => "wiki_ingest_controller"
    "implementation-backlog"
    | "code-patch"
    | "image-asset"
    | "projection-schema"
    | "test-fix" => "wenyu_build_controller"
    "ingest" | "ingest-followup" => "wiki_ingest_controller"
    "review" | "planning" => "wiki_lint_controller"
    "analysis" | "synthesis" => "wiki_query_controller"
    _ => "wiki_query_controller"
  }
}

///|
pub fn keeper_profile_for_entry_task(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
) -> String {
  let book_type = @policy.catalog_entry_type(entry.id, entry.name, entry.tags)
  if book_type == @policy.planbook_type() {
    return "planbook_repair_worker"
  }
  if book_type == @policy.civic_type() {
    return "wenyu_civic_service_worker"
  }
  keeper_profile_for_task(task)
}
