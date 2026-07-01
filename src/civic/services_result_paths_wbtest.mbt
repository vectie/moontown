///|
test "civic service result path uses town root for town-managed workspaces" {
  let service = wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  assert_eq(
    civic_service_result_path(service),
    ".moonsuite/products/moontown/book-results/goal-wenyu-policy-hall-civic-service.json",
  )
  assert_eq(
    civic_service_result_path(service, root=".moontown/books/wenyu-policy-hall"),
    ".moonsuite/products/moontown/book-results/goal-wenyu-policy-hall-civic-service.json",
  )
  assert_eq(
    civic_service_result_path(
      service,
      root="/tmp/town/.moontown/books/wenyu-policy-hall",
    ),
    ".moonsuite/products/moontown/book-results/goal-wenyu-policy-hall-civic-service.json",
  )
  assert_eq(
    civic_service_result_path(service, root="/tmp/town/books/wenyu-policy-hall"),
    ".moonsuite/products/moontown/book-results/goal-wenyu-policy-hall-civic-service.json",
  )
}

///|
test "civic service result path uses local root outside town workspace" {
  let service = wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  assert_eq(
    civic_service_result_path(service, root="/tmp/policy-hall"),
    "/tmp/policy-hall/book-results/goal-wenyu-policy-hall-civic-service.json",
  )
}
