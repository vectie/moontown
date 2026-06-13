///|
pub fn structural_required_relative_paths(
  entry : @moonbook.BookCatalogEntry,
) -> Array[String] {
  let kind = score_book_type(entry)
  let paths : Array[String] = [wiki_index_path(), projection_state_path()]
  for path in structural_required_paths_for_type(kind) {
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
fn structural_required_paths_for_type(
  book_type : String,
) -> Array[BookQualityRequiredPath] {
  match book_type {
    type_ if type_ == @policy.research_type() => research_required_paths()
    type_ if type_ == @policy.course_type() => course_required_paths()
    type_ if type_ == @policy.planbook_type() => planbook_required_paths()
    type_ if type_ == @policy.cookbook_type() => cookbook_required_paths()
    type_ if type_ == @policy.civic_type() => civic_base_required_paths()
    type_ if type_ == @policy.operational_type() => operational_required_paths()
    _ =>
      [
        required_path(wiki_index_path(), 20),
        required_path(projection_state_path(), 15),
      ]
  }
}

///|
fn push_unique_path(paths : Array[String], relative : String) -> Unit {
  if !paths.contains(relative) {
    paths.push(relative)
  }
}
