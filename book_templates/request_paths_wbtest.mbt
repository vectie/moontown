///|
test "request paths derive canonical inbox and event files" {
  assert_eq(default_registry_path(), "templates/books/templates.json")
  assert_eq(request_file_name(), "book-template-requests.json")
  assert_eq(request_event_file_name(), "book-template-request-events.jsonl")
  assert_eq(
    request_path_for_snapshot("/tmp/moontown/snapshot.json"),
    "/tmp/moontown/book-template-requests.json",
  )
  assert_eq(
    request_event_path_for_request("/tmp/moontown/book-template-requests.json"),
    "/tmp/moontown/book-template-request-events.jsonl",
  )
}
