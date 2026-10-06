///|
priv enum WatchRequestMode {
  CadenceWatch
  LocalMaterialWatch
} derive(Eq)

///|
priv struct MaterialWatchSnapshot {
  sources : Array[String]
  intent : String
  acceptance : String
  next_action : String
  plan_path : String
  baseline_status : String?
} derive(FromJson)

///|
fn material_watch_source_paths(text : String) -> Array[String] {
  text
  .split("\n")
  .map(line => line.trim().to_owned())
  .filter(path => !path.is_empty())
  .to_array()
}

///|
// This checks draft shape only. The existing API verifies real files, Book
// containment, symlinks and lossless UTF-8 before accepting the watch.
fn material_watch_source_paths_ready(text : String) -> Bool {
  let sources = material_watch_source_paths(text)
  if sources.is_empty() {
    return false
  }
  let seen : Map[String, Bool] = Map([])
  for path in sources {
    if path.has_prefix("/") ||
      path.contains("\\") ||
      path.contains("\r") ||
      path
      .split("/")
      .any(part => part == ".." || part == "." || part.is_empty()) ||
      seen.contains(path) {
      return false
    }
    seen[path] = true
  }
  true
}

///|
fn material_watch_request_ready(model : Model) -> Bool {
  has_text(model.request_book_id) &&
  material_watch_source_paths_ready(model.request_material_sources) &&
  has_text(model.request_material_acceptance) &&
  has_text(model.request_material_next_action)
}

///|
// Both the command and regression tests use this exact UI-to-FFI boundary.
fn submit_operator_request_model_json(model : Model) -> @js.Promise {
  match model.request_watch_mode {
    CadenceWatch =>
      submit_operator_request_json(
        model.request_title,
        model.request_prompt,
        model.request_book_id,
        model.request_cadence,
        model.request_quality_threshold,
      )
    LocalMaterialWatch =>
      submit_local_material_request_json(
        model.request_title,
        model.request_prompt,
        model.request_book_id,
        model.request_cadence,
        model.request_quality_threshold,
        model.request_material_sources,
        model.request_material_acceptance,
        model.request_material_next_action,
      )
  }
}
