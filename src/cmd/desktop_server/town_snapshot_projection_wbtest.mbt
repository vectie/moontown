///|
test "town snapshot serve helper projects a bounded event tail" {
  let events : Array[Json] = []
  for index in 0..<133 {
    events.push({
      "id": "event-\{index}",
      "kind": "test",
      "detail": "event \{index}",
    })
  }
  let source : Json = {
    "town": {
      "config": {
        "id": "town",
        "name": "Town",
        "heartbeat_seconds": 30,
        "max_concurrent_tasks": 12,
      },
      "books": [],
      "workers": [],
      "tasks": [],
      "executions": [],
      "events": events,
    },
    "event_count": 133,
  }
  guard bounded_town_snapshot_text(source.stringify()) is Some(text) else {
    fail("valid durable snapshot did not produce a browser projection")
  }
  let projected = @json.parse(text) catch {
    error => fail("projected snapshot was not JSON: \{error}")
  }
  guard projected is Object(root) else { fail("expected projected object") }
  let town = object_fields(root.get("town"))
  let retained_events = array_field(town, "events")
  assert_eq(retained_events.length(), 128)
  guard retained_events[0] is Object(first) else {
    fail("expected retained event object")
  }
  assert_eq(json_string_field(first, "id"), "event-5")
  assert_eq(json_int_field(root, "event_count", -1, -1, 1000), 133)
  let retention = object_fields(root.get("retention"))
  assert_eq(json_int_field(retention, "total_events", -1, -1, 1000), 133)
  assert_eq(json_int_field(retention, "retained_events", -1, -1, 1000), 128)
  assert_eq(json_int_field(retention, "omitted_events", -1, -1, 1000), 5)
}

///|
test "town snapshot serve helper leaves malformed input to existing fallback" {
  assert_true(bounded_town_snapshot_text("") is None)
  assert_true(bounded_town_snapshot_text("not-json") is None)
}
