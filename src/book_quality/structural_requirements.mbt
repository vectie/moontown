///|
pub fn structural_required_relative_paths(
  entry : @moonbook.BookCatalogEntry,
) -> Array[String] {
  let kind = score_book_type(entry)
  let paths : Array[String] = [wiki_index_path(), projection_state_path()]
  for path in required_paths_for_book_type(kind) {
    push_unique_path(paths, path.relative)
  }
  for file in @policy.required_file_specs(@policy.policy_for_type(kind)) {
    if file.required {
      push_unique_path(paths, file.path)
    }
  }
  if kind == @policy.civic_type() {
    match @civic.wenyu_civic_service_for_book_id(entry.id) {
      Some(service) => {
        for relative in service.schema_pages {
          push_unique_path(paths, relative)
        }
        for relative in service.wiki_pages {
          push_unique_path(paths, relative)
        }
        for relative in service.review_queues {
          push_unique_path(paths, relative)
        }
        for path in civic_service_workspace_required_paths(service) {
          push_unique_path(paths, path.relative)
        }
      }
      None => ()
    }
  }
  paths
}

///|
fn push_unique_path(paths : Array[String], relative : String) -> Unit {
  if !paths.contains(relative) {
    paths.push(relative)
  }
}
