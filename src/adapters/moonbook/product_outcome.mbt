///|
/// The existing product-outcome CLI owns all Book records and review authority.
/// The host resolves the catalog entry; packages cannot nominate a Book root.
pub async fn product_outcome_operation(
  entry : BookCatalogEntry,
  operation : String,
  request_path : String,
) -> Json {
  guard ["product-import", "product-read"].contains(operation) else {
    fail("Unsupported product outcome operation")
  }
  let executable = @sys.get_env_var("MOONTOWN_BOOK_OUTCOME_BIN").unwrap_or("")
  guard !executable.trim().is_empty() else {
    fail(
      "Configure MOONTOWN_BOOK_OUTCOME_BIN with the existing MoonBook outcome_lessons executable",
    )
  }
  @integration.run_json(executable, [
    operation,
    entry.workspace_root,
    request_path,
  ])
}
