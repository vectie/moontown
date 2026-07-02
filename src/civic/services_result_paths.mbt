///|
pub fn civic_service_result_path(
  service : CivicServiceDefinition,
  root? : String = "",
) -> String {
  if civic_service_uses_town_result_root(root) {
    @storage.moontown_product_artifact(
      "book-results/goal-\{service.book_id}-civic-service.json",
    )
  } else {
    "\{root}/book-results/goal-\{service.book_id}-civic-service.json"
  }
}

///|
fn civic_service_uses_town_result_root(root : String) -> Bool {
  root.trim().is_empty() || @storage.moontown_workspace_root_is_suite_book(root)
}
