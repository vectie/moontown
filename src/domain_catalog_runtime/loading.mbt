///|
async fn load_knowledge_domain_catalog_with_errors(
  catalog_path : String,
) -> (@domain_catalog.KnowledgeDomainCatalog?, Array[String]) {
  if !@fs.exists(catalog_path) {
    return (None, ["catalog file does not exist: \{catalog_path}"])
  }
  let text = @fs.read_file(catalog_path).text() catch {
    _ => return (None, ["catalog file could not be read: \{catalog_path}"])
  }
  let parsed = @json.parse(text) catch {
    _ => return (None, ["catalog JSON could not be parsed: \{catalog_path}"])
  }
  let catalog : @domain_catalog.KnowledgeDomainCatalog = @json.from_json(parsed) catch {
    _ =>
      return (
        None,
        ["catalog JSON did not match the typed schema: \{catalog_path}"],
      )
  }
  let errors = @domain_catalog.validate_knowledge_domain_catalog(catalog)
  if errors.is_empty() {
    (Some(catalog), [])
  } else {
    (None, errors)
  }
}

///|
fn render_catalog_load_failure(
  title : String,
  catalog_path : String,
  errors : Array[String],
) -> String {
  let rows : Array[String] = []
  for error in errors {
    rows.push("- \{error}")
  }
  [
    "# \{title}",
    "",
    "- Catalog: `\{catalog_path}`",
    "- Valid: `false`",
    "",
    "## Validation errors",
    "",
    if rows.is_empty() {
      "- unknown catalog error"
    } else {
      rows.join("\n")
    },
  ].join("\n")
}
