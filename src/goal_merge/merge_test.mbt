///|
fn goal(
  id? : String = "watch",
  title? : String = "Title",
  prompt? : String = "Source bounded",
  cadence? : Int = 60,
  due? : Int = 240,
  last? : Int? = Some(180),
  book? : String? = None,
  enabled? : Bool = true,
  policy? : String = "local-material:plan.json",
  quality? : Int = 80,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id~,
    title~,
    prompt~,
    cadence_ticks=cadence,
    next_due_tick=due,
    last_run_tick=last,
    target_book_id=book,
    enabled~,
    source_policy=policy,
    quality_threshold=quality,
  )
}

///|
fn bytes(goals : Array[@core.StandingGoal]) -> Bytes {
  @utf8.encode(goals.to_json().stringify())
}

///|
fn success(result : Result[String, String]) -> String raise {
  match result {
    Ok(text) => text
    Err(error) => fail(error)
  }
}

///|
fn merged(
  base : Array[@core.StandingGoal],
  edited : Array[@core.StandingGoal],
  current : Array[@core.StandingGoal],
) -> Array[@core.StandingGoal] raise {
  let text = success(
    @goal_merge.merge_snapshots(bytes(base), bytes(edited), bytes(current)),
  )
  @json.from_json(@json.parse(text))
}

///|
fn field(value : Json, key : String) -> Json raise {
  guard value is Object(fields) && fields.get(key) is Some(found) else {
    fail("Missing field " + key)
  }
  found
}

///|
fn report(
  base : Array[@core.StandingGoal],
  edited : Array[@core.StandingGoal],
  current : Array[@core.StandingGoal],
) -> Json raise {
  @json.parse(
    success(
      @goal_merge.inspect_snapshots(bytes(base), bytes(edited), bytes(current)),
    ),
  )
}

///|
test "edited declaration merges onto advanced run ticks with exact text and disabled state" {
  let base = goal()
  let edited = goal(title="=客户 🌙\n\u0000", cadence=120, enabled=false)
  let current = goal(due=300, last=Some(240), prompt="New current source")
  assert_eq(merged([base], [edited], [current]), [
    goal(
      title="=客户 🌙\n\u0000",
      cadence=120,
      enabled=false,
      due=300,
      last=Some(240),
      prompt="New current source",
    ),
  ])
  assert_eq(
    field(report([base], [edited], [current]), "status"),
    "merged".to_json(),
  )
}

///|
test "every typed field takes only the changed side including absent empty and zero" {
  let base = goal()
  let changed = goal(
    title="Other",
    prompt="",
    cadence=-1,
    due=-2147483648,
    last=None,
    book=Some(""),
    enabled=false,
    policy="",
    quality=2147483647,
  )
  assert_eq(merged([base], [changed], [base]), [changed])
  assert_eq(merged([base], [base], [changed]), [changed])
  assert_eq(merged([base], [changed], [changed]), [changed])
  assert_eq(
    merged([goal(last=None)], [goal(last=Some(0))], [goal(last=None)]),
    [goal(last=Some(0))],
  )
  assert_eq(
    merged([goal(book=Some(""))], [goal(book=None)], [goal(book=Some(""))]),
    [goal(book=None)],
  )
}

///|
test "all diverging fields are visible and no partial merged candidate escapes" {
  let base = goal()
  let edited = goal(
    title="Edited",
    prompt="Edited prompt",
    cadence=20,
    due=260,
    last=Some(200),
    book=Some("a"),
    policy="edited",
    quality=70,
  )
  let current = goal(
    title="Current",
    prompt="Current prompt",
    cadence=30,
    due=270,
    last=Some(210),
    book=Some("b"),
    policy="current",
    quality=90,
  )
  let result = report([base], [edited], [current])
  assert_eq(field(result, "status"), "conflict".to_json())
  assert_eq(field(result, "conflict_count"), (8).to_json())
  assert_true(field(result, "merged_goals") is Null)
  guard field(result, "conflicts") is Array(conflicts) else {
    fail("Expected conflicts")
  }
  assert_eq(field(conflicts[0], "goal_id"), "watch".to_json())
  assert_eq(field(conflicts[0], "field"), "title".to_json())
  assert_eq(field(conflicts[0], "base_value"), "Title".to_json())
  assert_eq(field(conflicts[0], "edited_value"), "Edited".to_json())
  assert_eq(field(conflicts[0], "current_value"), "Current".to_json())
  assert_true(field(conflicts[2], "base_value") is Null)
  assert_eq(field(conflicts[2], "edited_value"), "a".to_json())
  assert_eq(field(conflicts[2], "current_value"), "b".to_json())
  assert_eq(field(conflicts[5], "base_value"), (180).to_json())
  assert_eq(field(conflicts[5], "edited_value"), (200).to_json())
  assert_eq(field(conflicts[5], "current_value"), (210).to_json())
  assert_true(
    @goal_merge.merge_snapshots(
      bytes([base]),
      bytes([edited]),
      bytes([current]),
    )
    is Err(_),
  )
}

///|
test "current order and additions survive while candidate-only additions append in candidate order" {
  let a = goal(id="a")
  let b = goal(id="b")
  let c = goal(id=" c ")
  let d = goal(id="D")
  let e = goal(id="e")
  assert_eq(merged([a, b], [b, a, d, e], [c, b, a]), [c, b, a, d, e])
  assert_eq(merged([], [a], [a]), [a])
  assert_eq(merged([], [], [a]), [a])
  assert_eq(merged([], [a], []), [a])
  assert_eq(merged([], [], []), [])
}

///|
test "independent deletions are retained but delete modify and independent add conflicts are explicit" {
  let before = goal()
  let after = goal(due=300)
  assert_eq(merged([before], [], [before]), [])
  assert_eq(merged([before], [before], []), [])
  assert_eq(merged([before], [], []), [])
  for
    (base, edited, current, kind) in [
      ([before], [], [after], "deleted_modified"),
      ([before], [after], [], "modified_deleted"),
      ([], [before], [after], "added_differently"),
    ] {
    let result = report(base, edited, current)
    guard field(result, "conflicts") is Array(conflicts) else {
      fail("Expected conflicts")
    }
    assert_eq(conflicts.length(), 1)
    assert_eq(field(conflicts[0], "field"), "$goal".to_json())
    assert_eq(field(conflicts[0], "kind"), kind.to_json())
    assert_true(field(result, "merged_goals") is Null)
  }
}

///|
test "each full snapshot is strictly validated with a named input diagnostic" {
  let valid = bytes([goal()])
  for
    (base, edited, current, label) in [
      (b"[", valid, valid, "BASE"),
      (valid, b"\xff", valid, "EDITED"),
      (valid, valid, bytes([goal(), goal()]), "CURRENT"),
    ] {
    guard @goal_merge.merge_snapshots(base, edited, current) is Err(error) else {
      fail("Expected error")
    }
    assert_true(error.contains(label))
  }
}

///|
test "merging individually bounded arrays cannot exceed the 2000 goal result limit" {
  let edited = Array::makei(1001, i => goal(id="edited-" + i.to_string()))
  let current = Array::makei(1000, i => goal(id="current-" + i.to_string()))
  guard @goal_merge.merge_snapshots(b"[]", bytes(edited), bytes(current))
    is Err(error) else {
    fail("Expected merged count bound")
  }
  assert_true(error.contains("2,000"))
}

///|
test "combined output and conflict inspection fail explicitly instead of truncating" {
  let text = Array::make(700000, "x").join("")
  let a = goal(id="a")
  let b = goal(id="b")
  let large_a = goal(id="a", prompt=text)
  let large_b = goal(id="b", prompt=text)
  guard @goal_merge.merge_snapshots(
      bytes([a, b]),
      bytes([large_a, b]),
      bytes([a, large_b]),
    )
    is Err(error) else {
    fail("Expected output byte bound")
  }
  assert_true(error.contains("1048576"))
  guard @goal_merge.inspect_snapshots(
      bytes([goal(prompt=text)]),
      bytes([goal(prompt=text + "e")]),
      bytes([goal(prompt=text + "c")]),
    )
    is Err(error) else {
    fail("Expected conflict byte bound")
  }
  assert_true(error.contains("2097152"))
}

///|
test "optional conflicts expose exact scalar or null values on every side" {
  for
    (base, edited, current, books, ticks) in [
      (
        goal(book=Some("base"), last=Some(40)),
        goal(book=None, last=Some(0)),
        goal(book=Some(""), last=None),
        ["base".to_json(), Json::null(), "".to_json()],
        [(40).to_json(), (0).to_json(), Json::null()],
      ),
      (
        goal(book=None, last=None),
        goal(book=Some(""), last=Some(-2147483648)),
        goal(book=Some("null"), last=Some(2147483647)),
        [Json::null(), "".to_json(), "null".to_json()],
        [Json::null(), (-2147483648).to_json(), (2147483647).to_json()],
      ),
      (
        goal(book=Some(""), last=Some(0)),
        goal(book=Some("null"), last=None),
        goal(book=None, last=Some(40)),
        ["".to_json(), "null".to_json(), Json::null()],
        [(0).to_json(), Json::null(), (40).to_json()],
      ),
    ] {
    let result = report([base], [edited], [current])
    assert_true(field(result, "merged_goals") is Null)
    let expected : Json = [
      {
        "goal_id": "watch",
        "field": "target_book_id",
        "kind": "different_edits",
        "base_value": books[0],
        "edited_value": books[1],
        "current_value": books[2],
      },
      {
        "goal_id": "watch",
        "field": "last_run_tick",
        "kind": "different_edits",
        "base_value": ticks[0],
        "edited_value": ticks[1],
        "current_value": ticks[2],
      },
    ]
    assert_eq(field(result, "conflicts"), expected)
    assert_true(
      @goal_merge.merge_snapshots(
        bytes([base]),
        bytes([edited]),
        bytes([current]),
      )
      is Err(_),
    )
  }
}
