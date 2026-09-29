///|
test "four stable independently selectable studies" {
  guard @models.studies() is Array(items) else {
    fail("expected studies array")
  }
  assert_eq(items.length(), 4)
  let ids : Array[String] = []
  for item in items {
    guard item
      is { "id": String(id), "parts": Array(parts), "note": String(note), .. } else {
      fail("missing model metadata")
    }
    ids.push(id)
    assert_true(parts.length() > 500)
    assert_true(note.length() > 20)
  }
  assert_eq(ids, ["center", "vision", "east-bridge", "arch-bridge"])
}
