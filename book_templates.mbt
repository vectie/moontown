///|
pub fn default_book_template_registry_path() -> String {
  "templates/books/templates.json"
}

///|
pub fn default_book_template_request_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{@path.Path::dirname(snapshot_path).to_string()}/book-template-requests.json"
}

///|
pub fn default_book_template_request_event_path(
  request_path? : String = default_book_template_request_path(),
) -> String {
  "\{@path.Path::dirname(request_path).to_string()}/book-template-request-events.jsonl"
}

///|
pub async fn inspect_book_template_registry(
  registry_path? : String = default_book_template_registry_path(),
) -> BookTemplateRegistry {
  let templates = load_book_template_registry_file(registry_path)
  let missing : Array[String] = []
  if !@fs.exists(registry_path) {
    missing.push(registry_path)
  }
  for template in templates {
    if !@fs.exists(template.root) {
      missing.push(template.root)
    }
    if !template.install_example.trim().is_empty() &&
      !@fs.exists(template.install_example) {
      missing.push(template.install_example)
    }
    for required in template.required_paths {
      let path = "\{template.root}/\{required}"
      if !@fs.exists(path) {
        missing.push(path)
      }
    }
  }
  {
    registry_path,
    templates,
    missing_count: missing.length(),
    missing_paths: missing,
    ready: !templates.is_empty() && missing.is_empty(),
  }
}

///|
pub async fn install_book_template_config(
  template_id : String,
  config_path : String,
  registry_path? : String = default_book_template_registry_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> String {
  let registry = inspect_book_template_registry(registry_path~)
  match find_book_template_descriptor(registry.templates, template_id) {
    Some(template) =>
      match find_book_template_installer(template.template_id) {
        Some(installer) =>
          installer.install_config(
            config_path, book_catalog_path, standing_goal_path,
          )
        None =>
          "Book template `\{template_id}` is registered but has no installer yet."
      }
    None => "Unknown book template: \{template_id}"
  }
}

///|
async fn load_book_template_registry_file(
  registry_path : String,
) -> Array[BookTemplateDescriptor] {
  if !@fs.exists(registry_path) {
    return []
  }
  let text = @fs.read_file(registry_path).text() catch { _ => return [] }
  let parsed = @json.parse(text) catch { _ => return [] }
  let registry : BookTemplateRegistryFile = @json.from_json(parsed) catch {
    _ => return []
  }
  registry.templates
}

///|
fn find_book_template_descriptor(
  templates : Array[BookTemplateDescriptor],
  template_id : String,
) -> BookTemplateDescriptor? {
  for template in templates {
    if template.template_id == template_id {
      return Some(template)
    }
  }
  None
}
