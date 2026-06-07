///|
test "book quality repair standing goal constructors preserve scheduling rules" {
  let item = book_quality_repair_bridge_item_fixture(
    "research-robotics",
    book_quality_research_type(),
    "/tmp/research-robotics",
  )
  let created = new_book_quality_repair_standing_goal(item, 41)
  assert_eq(created.id, item.standing_goal_id)
  assert_eq(created.title, "Repair book quality: research-robotics")
  assert_true(created.target_book_id is Some("research-robotics"))
  assert_eq(created.cadence_ticks, book_quality_repair_goal_cadence_ticks())
  assert_eq(created.next_due_tick, 42)
  assert_true(created.last_run_tick is None)
  assert_true(created.enabled)
  assert_eq(created.source_policy, book_quality_web_first_policy())
  assert_eq(created.quality_threshold, semantic_quality_ready_threshold())
  assert_true(created.prompt.contains("Repair the book."))
  let existing = @core.StandingGoal::new(
    id=item.standing_goal_id,
    title="Old title",
    prompt="Old prompt",
    target_book_id=Some(item.book_id),
    cadence_ticks=5,
    next_due_tick=99,
    last_run_tick=Some(88),
    enabled=false,
    source_policy=book_quality_book_first_policy(),
    quality_threshold=12,
  )
  let refreshed = refreshed_book_quality_repair_standing_goal(existing, item)
  assert_eq(refreshed.id, item.standing_goal_id)
  assert_eq(refreshed.next_due_tick, 99)
  assert_true(refreshed.last_run_tick is Some(88))
  assert_true(refreshed.enabled)
  assert_eq(refreshed.cadence_ticks, book_quality_repair_goal_cadence_ticks())
  assert_eq(refreshed.quality_threshold, semantic_quality_ready_threshold())
  assert_true(refreshed.prompt.contains("Repair the book."))
}

///|
test "book quality repair standing goal upsert appends or refreshes in place" {
  let item = book_quality_repair_bridge_item_fixture(
    "research-robotics",
    book_quality_research_type(),
    "/tmp/research-robotics",
  )
  let goals : Array[@core.StandingGoal] = []
  upsert_book_quality_repair_standing_goal(goals, item, 10)
  assert_eq(goals.length(), 1)
  assert_eq(goals[0].next_due_tick, 11)
  let existing = @core.StandingGoal::new(
    id=item.standing_goal_id,
    title="Old title",
    prompt="Old prompt",
    target_book_id=Some(item.book_id),
    cadence_ticks=5,
    next_due_tick=31,
    last_run_tick=Some(30),
    enabled=false,
  )
  let other = @core.StandingGoal::new(
    id="other-goal",
    title="Other",
    prompt="Other",
  )
  let existing_goals = [other, existing]
  upsert_book_quality_repair_standing_goal(existing_goals, item, 100)
  assert_eq(existing_goals.length(), 2)
  assert_eq(existing_goals[0].id, "other-goal")
  assert_eq(existing_goals[1].id, item.standing_goal_id)
  assert_eq(existing_goals[1].next_due_tick, 31)
  assert_true(existing_goals[1].last_run_tick is Some(30))
  assert_true(existing_goals[1].enabled)
}

///|
async test "book quality repair goal retirement decision names each policy reason" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-retirement-decision-wbtest",
  )
  let result_dir = "\{root}/results"
  let book_id = "research-robotics"
  let score = book_quality_score_fixture(
    book_id,
    book_quality_research_type(),
    "\{root}/books/\{book_id}",
  )
  let repair_goal = @core.StandingGoal::new(
    id=book_quality_repair_goal_id(book_id),
    title="Repair book quality",
    prompt="Repair.",
    target_book_id=Some(book_id),
    enabled=true,
  )
  let unrelated = @core.StandingGoal::new(
    id="ordinary-watch",
    title="Ordinary Watch",
    prompt="Watch.",
    target_book_id=Some(book_id),
    enabled=true,
  )
  assert_true(
    book_quality_repair_goal_retirement_decision(
      unrelated,
      [score],
      [book_id],
      result_dir,
    )
    is NotRepairGoal,
  )
  let no_target = @core.StandingGoal::new(
    id=book_quality_repair_goal_id("missing-target"),
    title="Repair book quality",
    prompt="Repair.",
    enabled=true,
  )
  assert_true(
    book_quality_repair_goal_retirement_decision(
      no_target,
      [score],
      [book_id],
      result_dir,
    )
    is MissingTargetBook,
  )
  assert_true(
    book_quality_repair_goal_retirement_decision(
      repair_goal,
      [],
      [book_id],
      result_dir,
    )
    is MissingBookScore,
  )
  assert_true(
    book_quality_repair_goal_retirement_decision(
      repair_goal,
      [score],
      [],
      result_dir,
    )
    is NoLongerRepairableBook,
  )
  assert_true(
    book_quality_repair_goal_retirement_decision(
      repair_goal,
      [score],
      [book_id],
      result_dir,
    )
    is StillNeedsRepair,
  )
  write_text_file(
    book_quality_ai_review_result_path(result_dir, book_id),
    "ai_quality_score: 44\n",
  )
  assert_true(
    book_quality_repair_goal_retirement_decision(
      repair_goal,
      [score],
      [book_id],
      result_dir,
    )
    is StillNeedsRepair,
  )
  write_text_file(
    book_quality_ai_review_result_path(result_dir, book_id),
    "ai_quality_score: \{semantic_quality_ready_threshold()}\n",
  )
  assert_true(
    book_quality_repair_goal_retirement_decision(
      repair_goal,
      [score],
      [book_id],
      result_dir,
    )
    is ReadySemanticReview,
  )
  assert_true(
    book_quality_should_retire_repair_goal(
      repair_goal,
      [score],
      [book_id],
      result_dir,
    ),
  )
}
