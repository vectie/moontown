///|
pub fn default_registry_path() -> String {
  "assets/templates/books/templates.json"
}

///|
pub fn request_file_name() -> String {
  "book-template-requests.json"
}

///|
pub fn request_event_file_name() -> String {
  "book-template-request-events.jsonl"
}

///|
pub fn request_path_for_snapshot(snapshot_path : String) -> String {
  "\{@storage.snapshot_base_dir(snapshot_path)}/\{request_file_name()}"
}

///|
pub fn request_event_path_for_request(request_path : String) -> String {
  "\{@path.Path::dirname(request_path).to_string()}/\{request_event_file_name()}"
}
