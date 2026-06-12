///|
fn standing_watch_review_predicate_execution(
  task_id? : String = "standing-watch-opc-news-tick-1",
  summary? : String = "standing_goal_decision: needs_review\ndelta_score: 0\nnew_source_count: 0",
  status? : @core.TaskExecutionStatus = @core.TaskExecutionStatus::ReviewQueued,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id="research-opc",
    packet_id="packet",
    packet_path="packet.json",
    status~,
    summary~,
    output_contract="standing-watch-live-snapshot",
  )
}

///|
test "standing watch review predicate detects zero material review" {
  let execution = standing_watch_review_predicate_execution()
  assert_true(
    standing_watch_needs_review_with_zero_material_delta(
      execution,
      @core.WatcherDecisionKind::NeedsReview,
    ),
  )
  assert_true(
    !standing_watch_needs_review_with_zero_material_delta(
      execution,
      @core.WatcherDecisionKind::Update,
    ),
  )
  let changed = standing_watch_review_predicate_execution(
    summary="standing_goal_decision: needs_review\ndelta_score: 2\nnew_source_count: 0",
  )
  assert_true(
    !standing_watch_needs_review_with_zero_material_delta(
      changed,
      @core.WatcherDecisionKind::NeedsReview,
    ),
  )
}

///|
test "standing watch repair predicate keeps generic repair completions open" {
  let repair_goal = @core.StandingGoal::new(
    id="book-quality-repair-research-opc",
    title="Repair OPC",
    prompt="repair",
  )
  let ordinary_goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Watch OPC",
    prompt="watch",
  )
  let execution = standing_watch_review_predicate_execution(
    summary="Workflow completed workspace=/tmp/book",
  )
  assert_true(
    standing_watch_autonomous_repair_still_open(
      repair_goal,
      execution,
      @core.WatcherDecisionKind::NeedsReview,
    ),
  )
  assert_true(
    standing_watch_empty_completion_is_no_change(
      ordinary_goal,
      execution,
      @core.WatcherDecisionKind::NeedsReview,
    ),
  )
}

///|
test "standing watch review predicate detects newer terminal cycles" {
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Watch OPC",
    prompt="watch",
  )
  let old_review = standing_watch_review_predicate_execution(
    task_id="standing-watch-opc-news-tick-1",
    status=@core.TaskExecutionStatus::ReviewQueued,
  )
  let newer_no_change = standing_watch_review_predicate_execution(
    task_id="standing-watch-opc-news-tick-2",
    summary="standing_goal_decision: no_change\ndelta_score: 0\nnew_source_count: 0",
    status=@core.TaskExecutionStatus::Completed,
  )
  assert_true(
    standing_watch_review_superseded_by_newer_review(
      [old_review, newer_no_change],
      [goal],
      goal,
      old_review,
    ),
  )
}
