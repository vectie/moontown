///|
test "book quality repair standing goal constructors preserve scheduling rules" {
  let item = book_quality_repair_bridge_item_fixture(
    "research-robotics",
    @book_quality.research_type(),
    "/tmp/research-robotics",
  )
  let created = @book_quality.new_repair_standing_goal(item, 41)
  assert_eq(created.id, item.standing_goal_id)
  assert_eq(created.title, "Repair book quality: research-robotics")
  assert_true(created.target_book_id is Some("research-robotics"))
  assert_eq(created.cadence_ticks, @book_quality.repair_goal_cadence_ticks())
  assert_eq(created.next_due_tick, 42)
  assert_true(created.last_run_tick is None)
  assert_true(created.enabled)
  assert_eq(created.source_policy, @book_quality.web_first_policy())
  assert_eq(created.quality_threshold, @book_quality.semantic_ready_threshold())
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
    source_policy=@book_quality.book_first_policy(),
    quality_threshold=12,
  )
  let refreshed = @book_quality.refreshed_repair_standing_goal(existing, item)
  assert_eq(refreshed.id, item.standing_goal_id)
  assert_eq(refreshed.next_due_tick, 99)
  assert_true(refreshed.last_run_tick is Some(88))
  assert_true(refreshed.enabled)
  assert_eq(refreshed.cadence_ticks, @book_quality.repair_goal_cadence_ticks())
  assert_eq(
    refreshed.quality_threshold,
    @book_quality.semantic_ready_threshold(),
  )
  assert_true(refreshed.prompt.contains("Repair the book."))
}

///|
async fn book_quality_repair_retirement_label_for_test(
  goal : @core.StandingGoal,
  scores : Array[@book_quality.BookQualityScore],
  repairable_book_ids : Array[String],
  result_dir : String,
) -> String {
  @book_quality.repair_goal_retirement_decision_label(
    book_quality_repair_goal_retirement_decision(
      goal, scores, repairable_book_ids, result_dir,
    ),
  )
}

///|
test "book quality repair standing goal upsert appends or refreshes in place" {
  let item = book_quality_repair_bridge_item_fixture(
    "research-robotics",
    @book_quality.research_type(),
    "/tmp/research-robotics",
  )
  let goals : Array[@core.StandingGoal] = []
  @book_quality.upsert_repair_standing_goal(goals, item, 10)
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
  @book_quality.upsert_repair_standing_goal(existing_goals, item, 100)
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
    @book_quality.research_type(),
    "\{root}/books/\{book_id}",
  )
  let repair_goal = @core.StandingGoal::new(
    id=@book_quality.repair_goal_id(book_id),
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
  assert_eq(
    book_quality_repair_retirement_label_for_test(
      unrelated,
      [score],
      [book_id],
      result_dir,
    ),
    "not-repair-goal",
  )
  let no_target = @core.StandingGoal::new(
    id=@book_quality.repair_goal_id("missing-target"),
    title="Repair book quality",
    prompt="Repair.",
    enabled=true,
  )
  assert_eq(
    book_quality_repair_retirement_label_for_test(
      no_target,
      [score],
      [book_id],
      result_dir,
    ),
    "missing-target-book",
  )
  assert_eq(
    book_quality_repair_retirement_label_for_test(
      repair_goal,
      [],
      [book_id],
      result_dir,
    ),
    "missing-book-score",
  )
  assert_eq(
    book_quality_repair_retirement_label_for_test(
      repair_goal,
      [score],
      [],
      result_dir,
    ),
    "no-longer-repairable-book",
  )
  assert_eq(
    book_quality_repair_retirement_label_for_test(
      repair_goal,
      [score],
      [book_id],
      result_dir,
    ),
    "still-needs-repair",
  )
  write_text_file(
    @book_quality.review_result_path(result_dir, book_id),
    "ai_quality_score: 44\n",
  )
  assert_eq(
    book_quality_repair_retirement_label_for_test(
      repair_goal,
      [score],
      [book_id],
      result_dir,
    ),
    "still-needs-repair",
  )
  write_text_file(
    @book_quality.review_result_path(result_dir, book_id),
    "ai_quality_score: \{@book_quality.semantic_ready_threshold()}\n",
  )
  assert_eq(
    book_quality_repair_retirement_label_for_test(
      repair_goal,
      [score],
      [book_id],
      result_dir,
    ),
    "ready-semantic-review",
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
