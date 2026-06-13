///|
pub async fn inspect_registry(
  registry_path? : String = @book_templates.default_registry_path(),
) -> @book_templates.BookTemplateRegistry {
  let templates = load_registry_file(registry_path)
  @book_templates.registry_from_observed(
    registry_path~,
    templates~,
    missing_paths=observed_registry_missing_paths(registry_path, templates),
  )
}

///|
async fn load_registry_file(
  registry_path : String,
) -> Array[@book_templates.BookTemplateDescriptor] {
  if !@fs.exists(registry_path) {
    return []
  }
  let text = @fs.read_file(registry_path).text() catch { _ => return [] }
  let parsed = @json.parse(text) catch { _ => return [] }
  let registry : @book_templates.BookTemplateRegistryFile = @json.from_json(
    parsed,
  ) catch {
    _ => return []
  }
  registry.templates
}

///|
async fn observed_registry_missing_paths(
  registry_path : String,
  templates : Array[@book_templates.BookTemplateDescriptor],
) -> Array[String] {
  let missing : Array[String] = []
  if !@fs.exists(registry_path) {
    missing.push(registry_path)
  }
  for template in templates {
    for path in @book_templates.descriptor_check_paths(template) {
      if !@fs.exists(path) {
        missing.push(path)
      }
    }
  }
  missing
}
