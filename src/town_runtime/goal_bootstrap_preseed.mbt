///|
async fn preseed_goal_bootstrap_inputs(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
) -> Unit {
  if town_runtime_entry_is_research(entry) {
    preseed_reference_style_inputs(entry, objective)
  }
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(_) => {
      @civic_runtime.write_wenyu_civic_workspace_seed(entry, objective)
      return
    }
    None => ()
  }
  if !@civic.is_wenyu_build_book_entry(entry.id, entry.name, entry.tags) {
    return
  }
  @build_pipeline_runtime.preseed_wenyu_goal_inputs(
    entry,
    objective,
    current_repo_root(),
  )
}

///|
fn town_runtime_entry_is_research(entry : @moonbook.BookCatalogEntry) -> Bool {
  @policy.catalog_entry_type(entry.id, entry.name, entry.tags) ==
  @policy.research_type()
}
