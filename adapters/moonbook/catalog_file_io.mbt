///|
pub async fn save_catalog_file(
  path : String,
  catalog : Array[BookCatalogEntry],
) -> Unit {
  write_workspace_text(path, catalog.to_json().stringify())
}

///|
pub async fn load_catalog_file(path : String) -> Array[BookCatalogEntry]? {
  let parsed = match moonbook_read_optional_json_file(path) {
    Some(json) => json
    None => return None
  }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
pub async fn load_or_create_catalog(
  path? : String = default_catalog_path(),
) -> Array[BookCatalogEntry] {
  match load_catalog_file(path) {
    Some(catalog) => {
      let normalized = normalize_catalog(catalog)
      if normalized != catalog {
        save_catalog_file(path, normalized)
      }
      normalized
    }
    None => {
      let catalog = default_catalog()
      save_catalog_file(path, catalog)
      catalog
    }
  }
}

///|
pub async fn load_or_create_provider(
  path? : String = default_catalog_path(),
) -> MoonbookCatalogProvider {
  MoonbookCatalogProvider::new(load_or_create_catalog(path~))
}
