///|
pub(all) struct BookTemplateRequestProcessContext {
  request_base_dir : String
  event_path : String
  registry_path : String
  book_catalog_path : String
  standing_goal_path : String
  tick : Int
}

///|
pub fn book_template_request_process_context(
  request_path : String,
  event_path : String,
  registry_path : String,
  book_catalog_path : String,
  standing_goal_path : String,
  tick : Int,
) -> BookTemplateRequestProcessContext {
  {
    request_base_dir: @path.Path::dirname(request_path).to_string(),
    event_path,
    registry_path,
    book_catalog_path,
    standing_goal_path,
    tick,
  }
}
