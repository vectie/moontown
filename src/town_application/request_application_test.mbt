///|
async test "shared application persists a standing watch for both adapters" {
  let root = "/tmp/moontown-town-application-watch-\{@env.now()}"
  let policy_path = root + "/operator-policy.json"
  let policy : Json = { "standing_goal_source_policy": "web-first" }
  @support.write_text_file(policy_path, policy.stringify())
  let app = @town_application.request_application(root, policy_path)
  let request : Json = {
    "title": "Track shared backend architecture",
    "prompt": "Compare the two frontend projections.",
    "target_book_id": "Research Architecture",
    "cadence_ticks": "17",
    "quality_threshold": "91",
  }
  let result = app.submit_standing_watch(request.stringify())
  assert_eq(@support.json_string_field(result, "status"), Some("accepted"))
  let goals = @support.read_optional_json_file(root + "/standing-goals.json")
  guard goals is Some(Array([Object(goal), ..])) else {
    fail("expected a persisted standing goal")
  }
  assert_eq(
    @support.json_object_string(goal, "target_book_id"),
    Some("research-architecture"),
  )
  assert_eq(goal.get("cadence_ticks"), Some((17 : Json)))
  assert_eq(goal.get("quality_threshold"), Some((91 : Json)))
  let ledger = @support.read_text_or_empty(
    root + "/operator-requests/requests.jsonl",
  )
  assert_true(ledger.contains("\"status\":\"accepted\""))
}

///|
async test "shared application queues a comma-delimited evidence book" {
  let root = "/tmp/moontown-town-application-book-\{@env.now()}"
  let app = @town_application.request_application(
    root,
    root + "/unused-policy.json",
  )
  let request : Json = {
    "title": "Backend Architecture PDFs",
    "book_id": "Backend Architecture PDFs",
    "websites": "https://example.org/a, https://example.org/b",
    "cadence_ticks": "23",
  }
  let result = app.queue_evidence_book(request.stringify())
  assert_eq(@support.json_string_field(result, "status"), Some("pending"))
  let config_path = @support.json_string_field(result, "config_path").unwrap()
  let config = @support.read_optional_json_file(root + "/" + config_path)
  guard config is Some(Object(fields)) else {
    fail("expected a persisted evidence-book config")
  }
  assert_eq(
    @support.json_object_string(fields, "book_id"),
    Some("backend-architecture-pdfs"),
  )
  assert_eq(fields.get("cadence_ticks"), Some((23 : Json)))
  guard fields.get("websites") is Some(Array(websites)) else {
    fail("expected normalized websites")
  }
  assert_eq(websites.length(), 2)
}
