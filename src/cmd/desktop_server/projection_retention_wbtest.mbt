///|
test "operator request projection keeps only the durable tail" {
  let rows : Array[Json] = []
  for index in 0..<(operator_request_projection_limit + 19) {
    let value : Json = { "id": "request-\{index}" }
    push_json_projection_tail(rows, value, operator_request_projection_limit)
  }
  assert_eq(rows.length(), operator_request_projection_limit)
  guard rows[0] is Object(first) else { fail("expected request object") }
  assert_eq(json_string_field(first, "id"), "request-19")
}

///|
test "watcher projection is a deterministic newest-tick top-K" {
  let rows : Array[Json] = []
  let count = watcher_record_projection_limit + 31
  for index in 0..<count {
    let tick = count - 1 - index
    let value : Json = { "goal_id": "goal-\{tick}", "tick": tick }
    push_watcher_record_projection(rows, value)
  }
  assert_eq(rows.length(), watcher_record_projection_limit)
  guard rows[0] is Object(first) else { fail("expected watcher object") }
  guard rows[rows.length() - 1] is Object(last) else {
    fail("expected watcher object")
  }
  assert_eq(
    json_int_field(first, "tick", -1, -1, 2147483647),
    count - watcher_record_projection_limit,
  )
  assert_eq(json_int_field(last, "tick", -1, -1, 2147483647), count - 1)
}

///|
test "runtime terminal history is bounded after deterministic ordering" {
  let source : Array[Json] = []
  let count = energy_valley_runtime_history_projection_limit + 22
  for index in 0..<count {
    let value : Json = {
      "id": "history-\{index}",
      "updatedAt": "\{1000 + index}",
    }
    source.push(value)
  }
  let bounded = bounded_projected_history(source)
  assert_eq(bounded.length(), energy_valley_runtime_history_projection_limit)
  guard bounded[0] is Object(first) else { fail("expected history object") }
  assert_eq(json_string_field(first, "id"), "history-22")
  assert_eq(
    ToJson::to_json(bounded).stringify(),
    ToJson::to_json(bounded_projected_history(bounded)).stringify(),
  )
}
