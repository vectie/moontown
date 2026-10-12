///|
fn rescheduled(goal : @core.StandingGoal, due : Int) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id=goal.id,
    title=goal.title,
    prompt=goal.prompt,
    target_book_id=goal.target_book_id,
    cadence_ticks=goal.cadence_ticks,
    next_due_tick=due,
    last_run_tick=goal.last_run_tick,
    enabled=goal.enabled,
    source_policy=goal.source_policy,
    quality_threshold=goal.quality_threshold,
  )
}

///|
fn decoded_candidate(
  result : Result[String, String],
) -> Array[@core.StandingGoal] raise {
  match @goal_table.decode_snapshot(@utf8.encode(success(result))) {
    Ok(goals) => goals
    Err(error) => fail(error)
  }
}

///|
test "stagger follows selection order while preserving source order and every other field" {
  let goals = fixture()
  let bytes = snapshot(goals)
  let selected = b"[\"later\",\"overdue\"]"
  let candidate = decoded_candidate(
    @goal_outlook.stagger(bytes, selected, 100, 7),
  )
  assert_eq(candidate.length(), goals.length())
  for i, goal in goals {
    assert_eq(
      candidate[i],
      if i == 0 {
        rescheduled(goal, 107)
      } else if i == 2 {
        rescheduled(goal, 100)
      } else {
        goal
      },
    )
  }
  assert_eq(snapshot(goals), bytes)
  let output = success(@goal_outlook.stagger(bytes, selected, 100, 7))
  assert_eq(
    success(@goal_outlook.stagger(@utf8.encode(output), selected, 100, 7)),
    output,
  )
}

///|
test "stagger and compare complete a useful cluster revision without changing cadences" {
  let goals = ["a", "b", "c"].map(id => {
    @core.StandingGoal::new(
      id~,
      title=id,
      prompt="",
      cadence_ticks=30,
      next_due_tick=100,
    )
  })
  let before = snapshot(goals)
  let after = @utf8.encode(
    success(@goal_outlook.stagger(before, b"[\"c\",\"a\",\"b\"]", 100, 5)),
  )
  let comparison = @json.parse(
    success(@goal_outlook.compare(before, after, 100, 130, format="json")),
  )
  assert_eq(field(comparison, "before_shared_ticks"), (1).to_json())
  assert_eq(field(comparison, "after_shared_ticks"), (0).to_json())
  assert_eq(field(comparison, "before_occurrences"), (3).to_json())
  assert_eq(field(comparison, "after_occurrences"), (3).to_json())
  let candidate = decoded_candidate(
    @goal_outlook.stagger(before, b"[\"c\",\"a\",\"b\"]", 100, 5),
  )
  assert_eq(candidate.map(g => g.next_due_tick), [105, 110, 100])
}

///|
test "stagger matches exact IDs and retains optional values and legacy signed fields" {
  let goals = ["g", " G ", "客户 🌙"].mapi((i, id) => {
    @core.StandingGoal::new(
      id~,
      title="=formula",
      prompt="quoted\n\"text\"",
      target_book_id=Some(if i == 0 { "" } else { "null" }),
      cadence_ticks=-2147483648,
      next_due_tick=-2147483648,
      last_run_tick=Some(if i == 0 { 0 } else { -2147483648 }),
      source_policy="unchanged\tpolicy",
      quality_threshold=2147483647,
    )
  })
  let candidate = decoded_candidate(
    @goal_outlook.stagger(
      snapshot(goals),
      @utf8.encode("[\"客户 🌙\",\" G \"]"),
      0,
      10,
    ),
  )
  assert_eq(candidate, [
    goals[0],
    rescheduled(goals[1], 10),
    rescheduled(goals[2], 0),
  ])
  assert_true(
    @goal_outlook.stagger(snapshot(goals), b"[\"G\"]", 0, 1) is Err(_),
  )
}

///|
test "stagger rejects paused unknown and duplicate selected IDs without a candidate" {
  let bytes = snapshot(fixture())
  for
    selection in [
      b"[\"paused\"]", b"[\"overdue\",\"paused\"]", b"[\"missing\"]", b"[\"overdue\",\"missing\"]",
      b"[\"overdue\",\"overdue\"]",
    ] {
    assert_true(@goal_outlook.stagger(bytes, selection, 100, 5) is Err(_))
  }
  assert_true(@goal_outlook.stagger(b"[]", b"[\"g\"]", 0, 1) is Err(_))
}

///|
test "stagger validates every selection item type count and byte bound" {
  let bytes = snapshot(fixture())
  for
    selection in [
      b"[]",
      b"{}",
      b"null",
      b"[1]",
      b"[null]",
      b"[true]",
      b"[\"\"]",
      b"[\" \"]",
      b"[\"overdue\",{}]",
      b"[",
      Bytes::from_array([0xff]),
      @utf8.encode(" ".repeat(1048577)),
      @utf8.encode(Array::make(2001, "overdue").to_json().stringify()),
    ] {
    assert_true(@goal_outlook.stagger(bytes, selection, 100, 5) is Err(_))
  }
}

///|
test "stagger tick arithmetic accepts exact final maximum but never wraps" {
  let bytes = snapshot(fixture())
  let one = b"[\"overdue\"]"
  let two = b"[\"overdue\",\"later\"]"
  let edge = decoded_candidate(@goal_outlook.stagger(bytes, two, 2147483640, 7))
  assert_eq(edge[0].next_due_tick, 2147483640)
  assert_eq(edge[2].next_due_tick, 2147483647)
  assert_eq(
    decoded_candidate(@goal_outlook.stagger(bytes, one, 2147483647, 2147483647))[0].next_due_tick,
    2147483647,
  )
  for
    (start, spacing) in [
      (2147483640, 8),
      (2147483647, 1),
      (-1, 1),
      (0, 0),
      (0, -1),
    ] {
    assert_true(@goal_outlook.stagger(bytes, two, start, spacing) is Err(_))
  }
}

///|
test "stagger retains complete snapshot validation including unselected goals" {
  for
    bytes in [
      b"{}",
      b"[{}]",
      Bytes::from_array([0xff]),
      snapshot([fixture()[0], fixture()[0]]),
      @utf8.encode(" ".repeat(1048577)),
    ] {
    assert_true(@goal_outlook.stagger(bytes, b"[\"overdue\"]", 0, 1) is Err(_))
  }
  let goals = Array::makei(2000, i => {
    @core.StandingGoal::new(id=i.to_string(), title="", prompt="")
  })
  let selection = @utf8.encode(goals.map(g => g.id).to_json().stringify())
  let candidate = decoded_candidate(
    @goal_outlook.stagger(snapshot(goals), selection, 0, 1),
  )
  assert_eq(candidate.length(), 2000)
  assert_eq(candidate[1999].next_due_tick, 1999)
}

///|
test "stagger rejects canonical output growth beyond the snapshot byte bound" {
  let goal = @core.StandingGoal::new(id="g", title="", prompt="")
  let overhead = snapshot([goal]).length()
  let large = @core.StandingGoal::new(
    id="g",
    title="",
    prompt="x".repeat(1048576 - overhead),
  )
  let bytes = snapshot([large])
  assert_eq(bytes.length(), 1048576)
  assert_true(@goal_outlook.stagger(bytes, b"[\"g\"]", 2147483647, 1) is Err(_))
}
