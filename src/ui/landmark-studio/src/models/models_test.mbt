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

///|
test "map volumes retain both towers and their elevated links" {
  for number in 1..<=7 {
    guard @models.future_center_map_parts(number) is Array(parts) else {
      fail("expected parts")
    }
    assert_true(parts.length() > 100)
    if number == 7 {
      for height in [27.0, 51.0, 73.0] {
        assert_true(
          parts.any(p => {
            p
            is {
              "kind": String("box"),
              "material": String("glass"),
              "position": [Number(x, ..), Number(y, ..), Number(z, ..)],
              ..
            } &&
            x == 0 &&
            y == height &&
            z == 0
          }),
        )
      }
    }
  }
}
