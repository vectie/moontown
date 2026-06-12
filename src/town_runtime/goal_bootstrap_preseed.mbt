///|
async fn preseed_goal_bootstrap_inputs(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
) -> Unit {
  if entry.id.has_prefix("research-") {
    preseed_reference_style_inputs(entry, objective)
  }
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(_) => {
      @civic_runtime.write_wenyu_civic_workspace_seed(entry, objective)
      return
    }
    None => ()
  }
  if !entry.id.has_prefix("wenyu-") {
    return
  }
  @build_pipeline.preseed_wenyu_goal_inputs(
    entry,
    objective,
    moontown_repo_root(),
  )
}
