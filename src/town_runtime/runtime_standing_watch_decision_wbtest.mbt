///|
test "standing watch decision reads MoonBook no-change marker" {
  let execution = standing_watch_decision_execution(
    summary="standing_goal_decision: no_change\ndelta_score: 0\nnew_source_count: 0",
  )
  assert_eq(
    @standing_watch_policy.standing_watch_decision_from_execution(execution),
    @core.WatcherDecisionKind::NoChange,
  )
  assert_eq(@standing_watch_policy.standing_watch_delta_score(execution), 0)
  assert_eq(
    @standing_watch_policy.standing_watch_new_source_count(execution),
    0,
  )
  assert_true(
    @standing_watch_policy.standing_watch_execution_has_zero_material_delta(
      execution,
    ),
  )
}

///|
test "standing watch material delta helpers centralize zero-delta checks" {
  assert_true(
    @standing_watch_policy.standing_watch_summary_has_zero_material_delta(
      "standing_goal_decision: no_change\ndelta_score: 0\nnew_source_count: 0",
    ),
  )
  assert_true(
    !@standing_watch_policy.standing_watch_summary_has_zero_material_delta(
      "standing_goal_decision: update\ndelta_score: 5\nnew_source_count: 0",
    ),
  )
  let record = @core.WatcherRunRecord::new(
    goal_id="research-opc",
    tick=1,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::NoChange,
    delta_score=0,
    new_source_count=0,
  )
  assert_true(
    @standing_watch_policy.watcher_record_has_zero_material_delta(record),
  )
  let changed = @core.WatcherRunRecord::new(
    goal_id="research-opc",
    tick=1,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::Update,
    delta_score=0,
    new_source_count=1,
  )
  assert_true(
    !@standing_watch_policy.watcher_record_has_zero_material_delta(changed),
  )
}

///|
test "standing watch decision text classifies book-changing outcomes" {
  assert_true(
    @standing_watch_policy.standing_watch_decision_text_marks_update("update"),
  )
  assert_true(
    !@standing_watch_policy.standing_watch_decision_text_marks_update(
      "needs_review",
    ),
  )
  assert_true(
    @standing_watch_policy.standing_watch_decision_text_marks_book_changed(
      "update",
    ),
  )
  assert_true(
    @standing_watch_policy.standing_watch_decision_text_marks_book_changed(
      "needs_review",
    ),
  )
  assert_true(
    !@standing_watch_policy.standing_watch_decision_text_marks_book_changed(
      "no_change",
    ),
  )
  assert_true(
    !@standing_watch_policy.standing_watch_decision_text_marks_book_changed(
      "deferred",
    ),
  )
}

///|
test "standing watch marker decision rules parse known decision markers in order" {
  assert_true(
    @standing_watch_policy.standing_watch_marker_decision(
      "standing_goal_decision: failed",
    ) ==
    Some(@core.WatcherDecisionKind::Failed),
  )
  assert_true(
    @standing_watch_policy.standing_watch_marker_decision(
      "standing_goal_decision=deferred",
    ) ==
    Some(@core.WatcherDecisionKind::Deferred),
  )
  assert_true(
    @standing_watch_policy.standing_watch_marker_decision("decision: no_change") ==
    Some(@core.WatcherDecisionKind::NoChange),
  )
  assert_true(
    @standing_watch_policy.standing_watch_marker_decision(
      "decision=needs_review",
    ) ==
    Some(@core.WatcherDecisionKind::NeedsReview),
  )
  assert_true(
    @standing_watch_policy.standing_watch_marker_decision(
      "standing_goal_decision: update",
    ) ==
    Some(@core.WatcherDecisionKind::Update),
  )
  assert_true(
    @standing_watch_policy.standing_watch_marker_decision(
      "standing_goal_decision: failed\nstanding_goal_decision: update",
    ) ==
    Some(@core.WatcherDecisionKind::Failed),
  )
}

///|
test "standing watch reconcile helper detects review with zero material delta" {
  let execution = standing_watch_decision_execution(
    summary="standing_goal_decision: needs_review\ndelta_score: 0\nnew_source_count: 0",
  )
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
  let changed = copy_execution_with(
    execution,
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
test "standing watch decision treats missing marker as review instead of update" {
  let execution = standing_watch_decision_execution(
    summary="Workflow completed workspace=/tmp/book",
  )
  assert_eq(
    @standing_watch_policy.standing_watch_decision_from_execution(execution),
    @core.WatcherDecisionKind::NeedsReview,
  )
  assert_eq(@standing_watch_policy.standing_watch_delta_score(execution), 0)
  assert_eq(
    @standing_watch_policy.standing_watch_new_source_count(execution),
    0,
  )
}

///|
test "standing watch decision honors marker even when execution is review queued" {
  let execution = standing_watch_decision_execution(
    status=@core.TaskExecutionStatus::ReviewQueued,
    summary="standing_goal_decision: no_change\ndelta_score: 9\nnew_source_count: 0\nnext_check_hint: slower",
  )
  assert_eq(
    @standing_watch_policy.standing_watch_decision_from_execution(execution),
    @core.WatcherDecisionKind::NoChange,
  )
  assert_eq(@standing_watch_policy.standing_watch_delta_score(execution), 9)
  assert_false(
    @standing_watch_policy.standing_watch_execution_has_zero_material_delta(
      execution,
    ),
  )
}

///|
test "standing watch transient dispatch marker defers immediate retry" {
  let execution = standing_watch_decision_execution(
    summary="Resource temporarily unavailable\nstanding_goal_decision: deferred\nstanding_watch_transient_retry: true",
  )
  assert_eq(
    @standing_watch_policy.standing_watch_decision_from_execution(execution),
    @core.WatcherDecisionKind::Deferred,
  )
}

///|
test "standing watch classifies MoonClaw proposal store abort as transient" {
  let detail = "Standing watch execution failed. RUNTIME ERROR: abort() called\nStringBuilder::grow_if_necessary\n/vectie/moonclaw/job/system_storage.mbt:886 by SystemStore::save_job_proposals"
  assert_eq(
    @standing_watch_policy.standing_watch_transient_dispatch_error(detail),
    true,
  )
}

///|
test "standing watch transient infrastructure review is stabilized as deferred accounting" {
  let execution = standing_watch_decision_execution(
    task_id="standing-watch-opc-news-tick-15951",
    status=@core.TaskExecutionStatus::ReviewQueued,
    summary="Standing watch execution failed for research-opc. RUNTIME ERROR: abort() called. StringBuilder::grow_if_necessary. SystemStore::save_job_proposals.\nstanding_goal_decision: deferred\nstanding_watch_transient_retry: true",
    output_contract="standing-watch-live-snapshot",
    requires_review=true,
    notify_town=true,
  )
  let stabilized = stabilize_deferred_standing_watch_execution(execution, 15951)
  assert_eq(stabilized.status, @core.TaskExecutionStatus::Completed)
  assert_eq(stabilized.result_decision, "deferred")
  assert_eq(stabilized.requires_review, false)
  assert_eq(stabilized.notify_town, false)
}
