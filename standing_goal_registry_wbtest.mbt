///|
fn test_standing_goal(
  id : String,
  enabled? : Bool = true,
  cadence_ticks? : Int = 60,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id~,
    title="Goal \{id}",
    prompt="Keep \{id} alive.",
    cadence_ticks~,
    enabled~,
  )
}

///|
fn standing_goal_registry_upsert(
  goals : Array[@core.StandingGoal],
  replacement : @core.StandingGoal,
) -> Array[@core.StandingGoal] {
  let updated : Array[@core.StandingGoal] = []
  for goal in goals {
    if goal.id != replacement.id {
      updated.push(goal)
    }
  }
  updated.push(replacement)
  updated
}

///|
fn standing_goal_registry_with_enabled(
  goal : @core.StandingGoal,
  enabled : Bool,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id=goal.id,
    title=goal.title,
    prompt=goal.prompt,
    target_book_id=goal.target_book_id,
    cadence_ticks=goal.cadence_ticks,
    next_due_tick=goal.next_due_tick,
    last_run_tick=goal.last_run_tick,
    enabled~,
    source_policy=goal.source_policy,
    quality_threshold=goal.quality_threshold,
  )
}

///|
fn standing_goal_registry_contains(
  goals : Array[@core.StandingGoal],
  goal_id : String,
) -> Bool {
  standing_goal_registry_find(goals, goal_id) is Some(_)
}

///|
fn standing_goal_registry_enabled(
  goals : Array[@core.StandingGoal],
  goal_id : String,
) -> Bool {
  match standing_goal_registry_find(goals, goal_id) {
    Some(goal) => goal.enabled
    None => false
  }
}

///|
test "standing goal registry upsert replaces matching id" {
  let original = test_standing_goal("same", cadence_ticks=10)
  let other = test_standing_goal("other", cadence_ticks=20)
  let replacement = test_standing_goal("same", cadence_ticks=30)
  let updated = standing_goal_registry_upsert([original, other], replacement)
  assert_eq(updated.length(), 2)
  assert_eq(updated[0].id, "other")
  assert_eq(updated[1].id, "same")
  assert_eq(updated[1].cadence_ticks, 30)
}

///|
test "standing goal registry upsert appends missing id" {
  let updated = standing_goal_registry_upsert(
    [test_standing_goal("existing")],
    test_standing_goal("new"),
  )
  assert_eq(updated.length(), 2)
  assert_eq(updated[0].id, "existing")
  assert_eq(updated[1].id, "new")
}

///|
test "standing goal registry replace or append preserves replacement position" {
  let updated = standing_goal_registry_replace_or_append(
    [
      test_standing_goal("first", cadence_ticks=10),
      test_standing_goal("target", cadence_ticks=20),
      test_standing_goal("last", cadence_ticks=30),
    ],
    test_standing_goal("target", cadence_ticks=99),
  )
  assert_eq(updated.length(), 3)
  assert_eq(updated[0].id, "first")
  assert_eq(updated[1].id, "target")
  assert_eq(updated[1].cadence_ticks, 99)
  assert_eq(updated[2].id, "last")
}

///|
test "standing goal registry replace or append appends missing id" {
  let updated = standing_goal_registry_replace_or_append(
    [test_standing_goal("first")],
    test_standing_goal("new"),
  )
  assert_eq(updated.length(), 2)
  assert_eq(updated[0].id, "first")
  assert_eq(updated[1].id, "new")
}

///|
test "standing goal registry merge updates preserves latest order and appends new updates" {
  let merged = standing_goal_registry_merge_updates(
    [
      test_standing_goal("first", cadence_ticks=10),
      test_standing_goal("stale", cadence_ticks=20),
    ],
    [
      test_standing_goal("stale", cadence_ticks=99),
      test_standing_goal("new", cadence_ticks=30),
    ],
  )
  assert_eq(merged.length(), 3)
  assert_eq(merged[0].id, "first")
  assert_eq(merged[0].cadence_ticks, 10)
  assert_eq(merged[1].id, "stale")
  assert_eq(merged[1].cadence_ticks, 99)
  assert_eq(merged[2].id, "new")
}

///|
test "standing goal registry with enabled preserves scheduling metadata" {
  let original = @core.StandingGoal::new(
    id="goal",
    title="Goal",
    prompt="Prompt",
    target_book_id=Some("book"),
    cadence_ticks=33,
    next_due_tick=44,
    last_run_tick=Some(22),
    enabled=true,
    source_policy="book-first",
    quality_threshold=91,
  )
  let disabled = standing_goal_registry_with_enabled(original, false)
  assert_eq(disabled.id, "goal")
  match disabled.target_book_id {
    Some(book_id) => assert_eq(book_id, "book")
    None => fail("expected target book id")
  }
  assert_eq(disabled.cadence_ticks, 33)
  assert_eq(disabled.next_due_tick, 44)
  match disabled.last_run_tick {
    Some(tick) => assert_eq(tick, 22)
    None => fail("expected last run tick")
  }
  assert_false(disabled.enabled)
  assert_eq(disabled.source_policy, "book-first")
  assert_eq(disabled.quality_threshold, 91)
}

///|
test "standing goal registry checks existence and enabled state" {
  let goals = [
    test_standing_goal("enabled", enabled=true),
    test_standing_goal("disabled", enabled=false),
  ]
  assert_true(standing_goal_registry_contains(goals, "enabled"))
  assert_true(standing_goal_registry_contains(goals, "disabled"))
  assert_false(standing_goal_registry_contains(goals, "missing"))
  assert_eq(
    standing_goal_registry_find(goals, "enabled").unwrap().id,
    "enabled",
  )
  assert_true(standing_goal_registry_find(goals, "missing") is None)
  assert_true(standing_goal_registry_enabled(goals, "enabled"))
  assert_false(standing_goal_registry_enabled(goals, "disabled"))
  assert_false(standing_goal_registry_enabled(goals, "missing"))
}
