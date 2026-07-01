///|
pub fn default_catalog() -> Array[BookCatalogEntry] {
  [
    BookCatalogEntry::new(
      id="coding",
      name="Moonbook / Coding",
      purpose="Harness engineering for source work, repo memory, and execution policy.",
      workspace_root=default_workspace_root("coding"),
      memory_scope=BookPrivate,
      tags=["moonbit", "git", "review"],
      skills=["analysis", "memory", "review"],
    ),
    BookCatalogEntry::new(
      id="finance",
      name="Moonbook / Finance",
      purpose="Private daily finance operations with isolated memory and task artifacts.",
      workspace_root=default_workspace_root("finance"),
      memory_scope=TaskEphemeral,
      tags=["ledger", "planning", "ops"],
      skills=["planning", "memory", "reporting"],
    ),
  ]
}

///|
pub fn default_workspace_root(book_id : String) -> String {
  @moonsuite.book_root("", book_id)
}

///|
pub fn default_catalog_path() -> String {
  @storage.moontown_product_artifact("moonbooks.json")
}

///|
pub fn default_moonbook_root() -> String {
  match @sys.get_env_var("MOONTOWN_MOONBOOK_ROOT") {
    Some(root) if !root.is_empty() => root
    _ =>
      match @sys.get_env_var("MOONBOOK_ROOT") {
        Some(root) if !root.is_empty() => root
        _ => default_moonbook_external_root()
      }
  }
}

///|
fn default_moonbook_external_root() -> String {
  @storage.moontown_product_artifact("external/moonbook")
}
