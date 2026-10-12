///|
fn snapshot(goals : Array[@core.StandingGoal]) -> Bytes {
  @utf8.encode(goals.to_json().stringify())
}

///|
fn success(result : Result[String, String]) -> String raise {
  match result {
    Ok(value) => value
    Err(error) => fail(error)
  }
}

///|
fn field(value : Json, key : String) -> Json raise {
  guard value is Object(fields) && fields.get(key) is Some(found) else {
    fail("Missing field " + key)
  }
  found
}

///|
fn item(value : Json, index : Int) -> Json raise {
  guard value is Array(items) && items.get(index) is Some(found) else {
    fail("Missing item")
  }
  found
}

///|
fn fixture() -> Array[@core.StandingGoal] {
  [
    @core.StandingGoal::new(
      id="overdue",
      title="客户 🌙",
      prompt="Review sources",
      next_due_tick=4,
      cadence_ticks=3,
    ),
    @core.StandingGoal::new(
      id="now",
      title="=launch",
      prompt="",
      next_due_tick=10,
      cadence_ticks=2,
      target_book_id=Some(""),
    ),
    @core.StandingGoal::new(
      id="later",
      title="Later",
      prompt="",
      next_due_tick=11,
      cadence_ticks=4,
    ),
    @core.StandingGoal::new(
      id="paused",
      title="Paused",
      prompt="",
      next_due_tick=0,
      enabled=false,
    ),
    @core.StandingGoal::new(
      id="future",
      title="Future",
      prompt="",
      next_due_tick=16,
    ),
  ]
}

///|
test "outlook retains all goals and clusters chronological projected occurrences" {
  let result = @json.parse(
    success(@goal_outlook.report(snapshot(fixture()), 10, 16, format="json")),
  )
  assert_eq(field(result, "occurrence_count"), (7).to_json())
  assert_eq(field(result, "shared_tick_count"), (1).to_json())
  assert_eq(field(result, "peak_goals_at_tick"), (2).to_json())
  assert_eq(field(result, "occupied_tick_count"), (6).to_json())
  let goals = field(result, "goals")
  for i, state in ["overdue", "due_now", "scheduled", "paused", "beyond_window"] {
    assert_eq(field(item(goals, i), "state"), state.to_json())
    assert_eq(field(item(goals, i), "goal"), fixture()[i].to_json())
  }
  assert_eq(field(item(goals, 0), "occurrence_ticks"), [10, 13].to_json())
  assert_eq(field(item(goals, 1), "occurrence_ticks"), [10, 12, 14].to_json())
  assert_eq(field(item(goals, 2), "occurrence_ticks"), [11, 15].to_json())
  assert_eq(
    field(item(goals, 3), "occurrence_ticks"),
    ([] : Array[Int]).to_json(),
  )
  let slots = field(result, "slots")
  assert_eq(field(item(slots, 0), "tick"), (10).to_json())
  assert_eq(field(item(slots, 0), "goal_positions"), [1, 2].to_json())
  assert_eq(field(item(slots, 5), "tick"), (15).to_json())
  assert_eq(field(item(slots, 5), "goal_positions"), [3].to_json())
}

///|
test "projection agrees with repeated core due and dispatch transitions without mutating input" {
  for cadence in [-2147483648, 0, 1, 2, 5, 2147483647] {
    for due in [-2147483648, 0, 9, 10, 11, 25] {
      let goal = @core.StandingGoal::new(
        id="g",
        title="",
        prompt="",
        cadence_ticks=cadence,
        next_due_tick=due,
      )
      let saved = snapshot([goal])
      let report = @json.parse(
        success(@goal_outlook.report(saved, 10, 25, format="json")),
      )
      let ticks : Array[Int] = []
      let mut simulation = goal
      for tick = 10; tick < 25; tick = tick + 1 {
        if simulation.is_due(tick) {
          ticks.push(tick)
          // Avoid overflow in the legacy runtime method for enormous cadences.
          if cadence > 2147483647 - tick {
            break
          }
          simulation = simulation.mark_dispatched(tick)
        }
      }
      assert_eq(
        field(item(field(report, "goals"), 0), "occurrence_ticks"),
        ticks.to_json(),
      )
      assert_eq(snapshot([goal]), saved)
    }
  }
}

///|
test "maximum tick arithmetic stays exact and nonpositive cadences are visibly normalized" {
  let goals = [
    @core.StandingGoal::new(
      id="g",
      title="",
      prompt="",
      next_due_tick=-2147483648,
      cadence_ticks=0,
    ),
    @core.StandingGoal::new(
      id="h",
      title="",
      prompt="",
      next_due_tick=2147483645,
      cadence_ticks=2147483647,
    ),
  ]
  let result = @json.parse(
    success(
      @goal_outlook.report(
        snapshot(goals),
        2147483644,
        2147483647,
        format="json",
      ),
    ),
  )
  let views = field(result, "goals")
  assert_eq(field(item(views, 0), "effective_cadence_ticks"), (1).to_json())
  assert_eq(
    field(item(views, 0), "occurrence_ticks"),
    [2147483644, 2147483645, 2147483646].to_json(),
  )
  assert_eq(field(item(views, 1), "occurrence_ticks"), [2147483645].to_json())
}

///|
test "compare matches exact IDs exposes additions removals edits and unchanged positions" {
  let before = fixture()
  let after = [
    with_changes(before[1], cadence=3),
    with_changes(before[0], title="Edited title"),
    before[3],
    before[4],
    @core.StandingGoal::new(
      id=" Overdue ",
      title="New",
      prompt="",
      next_due_tick=10,
      cadence_ticks=20,
    ),
  ]
  let result = @json.parse(
    success(
      @goal_outlook.compare(
        snapshot(before),
        snapshot(after),
        10,
        16,
        format="json",
      ),
    ),
  )
  assert_eq(field(result, "before_occurrences"), (7).to_json())
  assert_eq(field(result, "after_occurrences"), (5).to_json())
  assert_eq(field(result, "occurrence_delta"), (-2).to_json())
  let changes = field(result, "changes")
  for
    i, state in [
      "changed", "changed", "removed", "unchanged", "unchanged", "added",
    ] {
    assert_eq(field(item(changes, i), "state"), state.to_json())
  }
  assert_eq(field(item(changes, 0), "outlook_changed"), false.to_json())
  assert_eq(field(item(changes, 0), "settings_changed"), true.to_json())
  assert_eq(field(item(changes, 1), "outlook_changed"), true.to_json())
  assert_eq(field(item(changes, 2), "occurrence_delta"), (-2).to_json())
  assert_eq(field(item(changes, 5), "goal_id"), " Overdue ".to_json())
  assert_eq(
    field(field(item(changes, 0), "after"), "source_position"),
    (2).to_json(),
  )
}

///|
test "reorder and raw-byte differences do not invent settings changes" {
  let goals = fixture()
  let before = snapshot(goals)
  let after = @utf8.encode(
    "\n" +
    [goals[4], goals[3], goals[2], goals[1], goals[0]].to_json().stringify() +
    "\n",
  )
  let report = @json.parse(
    success(@goal_outlook.compare(before, after, 10, 16, format="json")),
  )
  assert_true(field(report, "before_digest") != field(report, "after_digest"))
  assert_eq(field(report, "occurrence_delta"), (0).to_json())
  guard field(report, "changes") is Array(changes) else { fail("changes") }
  for change in changes {
    assert_eq(field(change, "state"), "unchanged".to_json())
    assert_eq(field(change, "outlook_changed"), false.to_json())
  }
}

///|
test "empty snapshots and all paused windows remain useful zero reports" {
  let result = @json.parse(
    success(@goal_outlook.report(b"[]", 0, 1000000, format="json")),
  )
  assert_eq(field(result, "occurrence_count"), (0).to_json())
  assert_eq(field(result, "peak_goals_at_tick"), (0).to_json())
  assert_eq(field(result, "slots"), ([] : Array[Int]).to_json())
  let paused = snapshot([fixture()[3]])
  let result = @json.parse(
    success(@goal_outlook.report(paused, 0, 20, format="json")),
  )
  assert_eq(field(item(field(result, "goals"), 0), "state"), "paused".to_json())
  let comparison = @json.parse(
    success(@goal_outlook.compare(paused, b"[]", 0, 20, format="json")),
  )
  assert_eq(
    field(item(field(comparison, "changes"), 0), "state"),
    "removed".to_json(),
  )
  assert_eq(field(comparison, "occurrence_delta"), (0).to_json())
}

///|
test "CSV quotes JSON text cells and retains zero-count goals plus comparison absence" {
  let csv = success(
    @goal_outlook.report(snapshot(fixture()), 10, 16, format="csv"),
  )
  assert_true(csv.contains("\"\"\"=launch\"\"\""))
  assert_true(csv.contains("\"paused\""))
  assert_true(csv.contains("\"[]\""))
  assert_true(csv.has_suffix("\r\n"))
  let comparison = success(
    @goal_outlook.compare(snapshot(fixture()), b"[]", 10, 16, format="csv"),
  )
  assert_true(comparison.contains("\"removed\""))
  assert_true(comparison.contains("\"2\",\"null\",\"-2\""))
}

///|
test "window and occurrence bounds fail without partial projection" {
  for (start, end) in [(-1, 1), (0, 0), (2, 1), (0, 1000001)] {
    assert_true(
      @goal_outlook.report(b"[]", start, end, format="json") is Err(_),
    )
  }
  let one = snapshot([
    @core.StandingGoal::new(id="g", title="", prompt="", cadence_ticks=1),
  ])
  let boundary = @json.parse(
    success(@goal_outlook.report(one, 0, 10000, format="json")),
  )
  assert_eq(field(boundary, "occurrence_count"), (10000).to_json())
  assert_true(@goal_outlook.report(one, 0, 10001, format="json") is Err(_))
  assert_true(
    @goal_outlook.compare(b"[]", one, 0, 10001, format="json") is Err(_),
  )
  assert_true(@goal_outlook.report(b"[]", 0, 1, format="html") is Err(_))
  assert_true(
    @goal_outlook.compare(b"[]", b"[]", 0, 1, format="html") is Err(_),
  )
}

///|
test "shared exact decoder rejects malformed snapshots unknown fields identity and integer loss" {
  let goal = fixture()[0]
  let text = goal.to_json().stringify()
  for
    bytes in [
      b"{}",
      b"[{}]",
      b"[1]",
      Bytes::from_array([0xff]),
      snapshot([goal, goal]),
      snapshot([with_changes(goal, id=" ")]),
      @utf8.encode(
        "[" +
        text.replace_all(old="\"cadence_ticks\":3", new="\"cadence_ticks\":3.5") +
        "]",
      ),
      @utf8.encode(
        "[" +
        text.replace_all(
          old="\"next_due_tick\":4",
          new="\"next_due_tick\":2147483648",
        ) +
        "]",
      ),
      @utf8.encode(
        "[" +
        text.replace_all(old="\"id\":", new="\"unknown\":true,\"id\":") +
        "]",
      ),
      @utf8.encode(" ".repeat(1048577)),
    ] {
    assert_true(@goal_outlook.report(bytes, 10, 16, format="json") is Err(_))
    assert_true(
      @goal_outlook.compare(snapshot([goal]), bytes, 10, 16, format="json")
      is Err(_),
    )
  }
  assert_true(@goal_table.decode_snapshot(snapshot([goal])) is Ok([_]))
  let too_many = snapshot(
    Array::makei(2001, i => {
      @core.StandingGoal::new(
        id=i.to_string(),
        title="",
        prompt="",
        enabled=false,
      )
    }),
  )
  assert_true(@goal_outlook.report(too_many, 0, 1, format="json") is Err(_))
}

///|
test "digests bind original bytes rather than canonical serialization" {
  let bytes = snapshot(fixture())
  let result = @json.parse(
    success(@goal_outlook.report(bytes, 10, 16, format="json")),
  )
  assert_eq(
    field(result, "source_digest"),
    ("sha256:" + @crypto.bytes_to_hex_string(@crypto.sha256(bytes))).to_json(),
  )
  assert_eq(field(result, "source_size_bytes"), bytes.length().to_json())
  let changed = @json.parse(
    success(
      @goal_outlook.report(
        @utf8.encode("\n" + @utf8.decode(bytes)),
        10,
        16,
        format="json",
      ),
    ),
  )
  assert_true(field(result, "source_digest") != field(changed, "source_digest"))
  assert_eq(field(result, "slots"), field(changed, "slots"))
}

///|
fn with_changes(
  goal : @core.StandingGoal,
  id? : String,
  title? : String,
  cadence? : Int,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id=id.unwrap_or(goal.id),
    title=title.unwrap_or(goal.title),
    prompt=goal.prompt,
    target_book_id=goal.target_book_id,
    cadence_ticks=cadence.unwrap_or(goal.cadence_ticks),
    next_due_tick=goal.next_due_tick,
    last_run_tick=goal.last_run_tick,
    enabled=goal.enabled,
    source_policy=goal.source_policy,
    quality_threshold=goal.quality_threshold,
  )
}
