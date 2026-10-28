///|
test "semantic interior reuses full furniture and keeps entity identity" {
  let input =
    #|{"title":"政策大厅","slots":[{"id":"desk-a","name":"工作桌","kind":"workstation","x":0.2,"z":0.6},{"id":"meeting-a","name":"议事桌","kind":"meeting","x":0.6,"z":0.5}]}
  guard @models.town_interior_study(input)
    is {
      "study": { "id": "room", "parts": Array(parts), .. },
      "entities": Array(entities),
      ..
    } else {
    fail("missing semantic room")
  }
  assert_eq(entities.length(), 2)
  assert_true(entities[0] is { "id": "desk-a", "name": "工作桌", .. })
  assert_true(
    parts.any(p => p is { "layer": "desk-a", "caption": "desk-a", .. }),
  )
  assert_true(
    parts.any(p => p is { "layer": "meeting-a", "caption": "meeting-a", .. }),
  )
  assert_true(parts.any(p => p is { "layer": "walls", .. }))
  assert_true(parts.length() > 50)
  assert_eq(
    @models.town_interior_study(input),
    @models.town_interior_study(input),
  )
}

///|
test "semantic room input cannot replace the G3 reference model" {
  for input in ["", "{}", "[]", "{\"title\":\"test\",\"slots\":[{}]}"] {
    assert_true(@models.town_interior_study(input) is Null)
  }
  assert_true(
    @models.interior_study()
    is { "study": { "id": "interior-g3", .. }, "zones": [_, ..], .. },
  )
}
