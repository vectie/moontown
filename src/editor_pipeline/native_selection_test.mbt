///|
fn native_selection_fixture() -> Json {
  {
    "contract": "moontown.editor_feature_selection.v1",
    "selected_feature": "road-editor-2",
    "title": "Road Editor",
    "implementation_hint": "Add editable roads",
    "acceptance": ["Roads can be edited", "Edits persist"],
    "score": 1,
    "current_gap": "No road editor",
  }
}

///|
test "native selection extracts the owner fields without requiring optional score" {
  let fixture = native_selection_fixture()
  guard fixture is Object(fields) else { fail("expected fixture object") }
  fields.remove("score")
  assert_eq(
    @editor_pipeline.parse_native_selection(fixture.stringify()),
    Some({
      selected_feature: "road-editor-2",
      title: "Road Editor",
      implementation_hint: "Add editable roads",
      acceptance: ["Roads can be edited", "Edits persist"],
    }),
  )
}

///|
test "native selection rejects missing empty and mistyped required fields" {
  for key in ["contract", "selected_feature", "title", "implementation_hint"] {
    let missing = native_selection_fixture()
    guard missing is Object(fields) else { fail("expected fixture object") }
    fields.remove(key)
    assert_true(
      @editor_pipeline.parse_native_selection(missing.stringify()) is None,
    )
    let invalid : Array[Json] = [null, "", " \n\t ", 1, false, [], {}]
    for value in invalid {
      fields[key] = value
      assert_true(
        @editor_pipeline.parse_native_selection(missing.stringify()) is None,
      )
    }
  }
  let wrong_contract = native_selection_fixture()
  guard wrong_contract is Object(fields) else {
    fail("expected fixture object")
  }
  fields["contract"] = "moontown.editor_feature_selection.v2"
  assert_true(
    @editor_pipeline.parse_native_selection(wrong_contract.stringify()) is None,
  )
  for content in ["", "[]", "null", "{", "{}", "{\"contract\":true}"] {
    assert_true(@editor_pipeline.parse_native_selection(content) is None)
  }
}

///|
test "native selection requires nonempty string acceptance criteria" {
  let fixture = native_selection_fixture()
  guard fixture is Object(fields) else { fail("expected fixture object") }
  fields.remove("acceptance")
  assert_true(
    @editor_pipeline.parse_native_selection(fixture.stringify()) is None,
  )
  let invalid : Array[Json] = [
    null,
    "visible",
    [],
    [""],
    [" \n\t "],
    [1],
    [null],
    ["visible", false],
    { "criterion": "visible" },
  ]
  for value in invalid {
    fields["acceptance"] = value
    assert_true(
      @editor_pipeline.parse_native_selection(fixture.stringify()) is None,
    )
  }
}

///|
test "native selection refuses unsafe feature paths and malformed kebab tokens" {
  let fixture = native_selection_fixture()
  guard fixture is Object(fields) else { fail("expected fixture object") }
  for
    feature_id in [
      "../road", "road/../../proof", "road\\proof", ".", "..", "road.json", "road\nimplementation_status: accepted",
      "road\rnext", "road\u{0000}next", " road", "road ", "road editor", "Road",
      "道路", "-road", "road-", "road--editor", "road_editor", "",
    ] {
    fields["selected_feature"] = feature_id.to_json()
    assert_true(
      @editor_pipeline.parse_native_selection(fixture.stringify()) is None,
    )
  }
  for feature_id in ["x", "2", "editor-2", "2d-road-editor"] {
    fields["selected_feature"] = feature_id.to_json()
    assert_true(
      @editor_pipeline.parse_native_selection(fixture.stringify()) is Some(_),
    )
  }
}

///|
test "native selection rejects duplicate root keys including escaped names" {
  let valid = native_selection_fixture().stringify()
  for
    duplicate in [
      "\"contract\":\"wrong\"", "\"selected_feature\":\"other-feature\"", "\"title\":\"Other title\"",
      "\"implementation_hint\":\"Other hint\"", "\"acceptance\":[\"Other acceptance\"]",
      "\"score\":9", "\"\\u0074itle\":\"Escaped title\"", "\"selected_\\u0066eature\":\"escaped-feature\"",
    ] {
    let content = "{" + duplicate + "," + valid[1:].to_owned()
    assert_true(@editor_pipeline.parse_native_selection(content) is None)
  }
}

///|
test "native selection member counting ignores nested and quoted delimiters" {
  let fixture = native_selection_fixture()
  guard fixture is Object(fields) else { fail("expected fixture object") }
  fields["title"] = "A title: {braces} [brackets] and \"quotes\" \\ end"
  fields["extra"] = {
    "selected_feature": "nested-does-not-duplicate-root",
    "records": [{ "title": "Nested: title" }],
  }
  assert_true(
    @editor_pipeline.parse_native_selection(fixture.stringify()) is Some(_),
  )
}
