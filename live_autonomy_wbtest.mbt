///|
async test "live autonomy spine persists current state and journal" {
  let root = "/tmp/moontown-live-autonomy-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::ReviewQueued,
  )
  let goal = @core.StandingGoal::new(
    id="watch-opc",
    title="Watch OPC",
    prompt="Track OPC updates",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
    next_due_tick=0,
  )
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-opc",
    tick=42,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::Update,
    delta_score=7,
    new_source_count=2,
    detail="accepted two useful sources",
    next_due_tick=102,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    standing_goals=[goal],
    watcher_records=[record],
    tick_summary="test live tick",
  )
  assert_eq(spine.status, "watching")
  assert_false(spine.stable_waiting)
  assert_eq(spine.stable_waiting_observation_streak, 0)
  assert_eq(spine.review_count, 1)
  assert_eq(spine.accepted_update_count, 1)
  assert_eq(spine.blocked_count, 0)
  assert_true(
    spine.stable_waiting_blockers.any(fn(blocker) {
      blocker.contains("review queue")
    }),
  )
  let live_text = read_text_or_empty(default_live_autonomy_path(snapshot_path~))
  let journal_text = read_text_or_empty(
    default_town_journal_path(snapshot_path~),
  )
  let digest_text = read_text_or_empty(default_live_digest_path(snapshot_path~))
  assert_true(live_text.contains("\"status\": \"watching\""))
  assert_true(live_text.contains("\"stable_waiting\": false"))
  assert_true(live_text.contains("\"digest_path\""))
  assert_true(live_text.contains("\"planbook_change_log_path\""))
  assert_true(live_text.contains("\"planbook_engineering_digest_path\""))
  assert_true(live_text.contains("\"latest_change_summary\""))
  assert_true(journal_text.contains("\"accepted_update_count\":1"))
  assert_true(digest_text.contains("# Moontown Live Digest"))
  assert_true(digest_text.contains("stable_waiting: `false`"))
  assert_true(digest_text.contains("Stable Waiting Blockers"))
  assert_true(digest_text.contains("Latest PlanBook Change"))
  assert_true(digest_text.contains("|watch-opc|research-opc|"))
}

///|
async test "live autonomy stable waiting streak increments across journal probes" {
  let root = "/tmp/moontown-live-autonomy-stable-streak-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  write_text_file(
    default_town_journal_path(snapshot_path~),
    [
      "{\"tick\":10,\"active_worker_count\":0,\"review_count\":0,\"blocked_count\":0,\"failed_count\":0,\"due_goal_count\":0,\"planbook_open_count\":0,\"planbook_repair_active_count\":0,\"pending_book_template_request_count\":0,\"failed_book_template_request_count\":0}",
      "{\"tick\":11,\"active_worker_count\":0,\"review_count\":0,\"blocked_count\":0,\"failed_count\":0,\"due_goal_count\":0,\"planbook_open_count\":0,\"planbook_repair_active_count\":0,\"pending_book_template_request_count\":0,\"failed_book_template_request_count\":0}",
    ].join("\n") +
    "\n",
  )
  assert_eq(
    prior_live_autonomy_stable_waiting_observation_streak(snapshot_path, 12),
    2,
  )
}

///|
async test "live autonomy stable waiting streak resets on due journal work" {
  let root = "/tmp/moontown-live-autonomy-stable-reset-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  write_text_file(
    default_town_journal_path(snapshot_path~),
    [
      "{\"tick\":10,\"active_worker_count\":0,\"review_count\":0,\"blocked_count\":0,\"failed_count\":0,\"due_goal_count\":0,\"planbook_open_count\":0,\"planbook_repair_active_count\":0,\"pending_book_template_request_count\":0,\"failed_book_template_request_count\":0}",
      "{\"tick\":11,\"active_worker_count\":0,\"review_count\":0,\"blocked_count\":0,\"failed_count\":0,\"due_goal_count\":1,\"planbook_open_count\":0,\"planbook_repair_active_count\":0,\"pending_book_template_request_count\":0,\"failed_book_template_request_count\":0}",
      "{\"tick\":12,\"active_worker_count\":0,\"review_count\":0,\"blocked_count\":0,\"failed_count\":0,\"due_goal_count\":0,\"planbook_open_count\":0,\"planbook_repair_active_count\":0,\"pending_book_template_request_count\":0,\"failed_book_template_request_count\":0}",
    ].join("\n") +
    "\n",
  )
  assert_eq(
    prior_live_autonomy_stable_waiting_observation_streak(snapshot_path, 13),
    1,
  )
  let due_probe = LiveAutonomyStabilityProbe::{
    tick: 99,
    active_worker_count: 0,
    review_count: 0,
    blocked_count: 0,
    failed_count: 0,
    due_goal_count: 1,
    planbook_open_count: 0,
    planbook_repair_active_count: 0,
    pending_book_template_request_count: 0,
    failed_book_template_request_count: 0,
  }
  assert_false(live_autonomy_stability_probe_is_stable(due_probe))
  assert_true(
    live_autonomy_stable_waiting_blockers(0, 0, 0, 0, 1, 0, 0, 0, 0).any(fn(
      blocker,
    ) {
      blocker.contains("due standing goals")
    }),
  )
}

///|
async test "live autonomy can use daemon tick instead of event-derived tick" {
  let root = "/tmp/moontown-live-autonomy-daemon-tick-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  let goal = @core.StandingGoal::new(
    id="watch-opc",
    title="Watch OPC",
    prompt="Track OPC updates",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
    next_due_tick=120,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    standing_goals=[goal],
    tick_summary="daemon tick alignment",
    daemon_tick=Some(119),
  )
  assert_eq(spine.tick, 119)
  assert_eq(spine.due_goal_count, 1)
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(status.contains("Tick: `119`"))
  assert_true(status.contains("Due goals: `1`"))
  assert_true(status.contains("PlanBook change log:"))
  assert_true(status.contains("PlanBook engineering digest:"))
}

///|
async test "live autonomy surfaces book template request inbox" {
  let root = "/tmp/moontown-live-autonomy-template-request-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  ignore(
    save_book_template_request_ledger(
      default_book_template_request_path(snapshot_path~),
      {
        requests: [
          {
            id: "request-pdf-watch",
            template_id: "pdf-evidence-watch",
            config_path: "requests/pdf-watch.json",
            status: "pending",
            summary: "waiting for daemon",
            last_processed_tick: 0,
          },
          {
            id: "request-bad-config",
            template_id: "pdf-evidence-watch",
            config_path: "requests/missing.json",
            status: "failed",
            summary: "missing config",
            last_processed_tick: 4,
          },
        ],
      },
    ),
  )
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    tick_summary="template inbox tick",
  )
  assert_eq(spine.book_template_request_count, 2)
  assert_eq(spine.pending_book_template_request_count, 1)
  assert_eq(spine.failed_book_template_request_count, 1)
  assert_eq(spine.enabled_standing_goal_count, 0)
  assert_eq(spine.disabled_standing_goal_count, 0)
  assert_eq(spine.book_template_latest_event_summary, "none")
  assert_true(spine.summary.contains("template_requests=2"))
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(status.contains("Book template requests: `2`"))
  assert_true(status.contains("Pending template requests: `1`"))
  assert_true(status.contains("Failed template requests: `1`"))
  assert_true(status.contains("Enabled standing goals: `0`"))
  assert_true(status.contains("Disabled standing goals: `0`"))
  assert_true(status.contains("Latest book-template event: none"))
  assert_true(status.contains("Inspect failed book-template request configs"))
  let digest_text = read_text_or_empty(default_live_digest_path(snapshot_path~))
  assert_true(digest_text.contains("book_template_requests: `2`"))
  assert_true(digest_text.contains("enabled_standing_goals: `0`"))
  assert_true(digest_text.contains("disabled_standing_goals: `0`"))
  assert_true(digest_text.contains("failed_book_template_requests: `1`"))
  assert_true(digest_text.contains("book_template_latest_event: none"))
}

///|
test "live autonomy hides historical repair entries when planbook is stable" {
  let latest = normalized_planbook_latest_change_summary(
    "1780258564852 - repair task running\n\nRepair `planbook-repair-live-runtime-recovery` is `running`.",
    0, 0,
  )
  assert_true(latest.contains("PlanBook is stable"))
  let still_active = normalized_planbook_latest_change_summary(
    "1780258564852 - repair task running", 1, 1,
  )
  assert_true(still_active.contains("repair task running"))
}

///|
async test "live autonomy journal tick floor is monotonic" {
  let root = "/tmp/moontown-live-autonomy-tick-floor"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  ignore(
    write_live_autonomy_spine(
      state,
      snapshot_path~,
      tick_summary="older live file",
      daemon_tick=Some(12),
    ),
  )
  write_text_file(
    default_town_journal_path(snapshot_path~),
    "{\"generated_at_ms\":\"1\",\"tick\":40,\"status\":\"watching\",\"summary\":\"old\",\"active_worker_count\":0,\"review_count\":0,\"blocked_count\":0,\"accepted_update_count\":0,\"no_change_count\":0,\"failed_count\":0,\"transient_infrastructure_debt_count\":0,\"due_goal_count\":0,\"standing_goal_count\":0,\"enabled_standing_goal_count\":0,\"disabled_standing_goal_count\":0,\"planbook_open_count\":0,\"planbook_repair_active_count\":0,\"book_template_request_count\":0,\"pending_book_template_request_count\":0,\"failed_book_template_request_count\":0,\"book_template_request_summary\":\"none\",\"book_template_latest_event_summary\":\"none\",\"latest_watcher_summary\":\"none\",\"visual_projection_path\":\"\",\"journal_path\":\"\",\"digest_path\":\"\",\"planbook_change_log_path\":\"\",\"planbook_engineering_digest_path\":\"\",\"latest_change_summary\":\"none\",\"next_actions\":[]}\n",
  )
  assert_eq(latest_live_autonomy_journal_tick(snapshot_path), 40)
}

///|
async test "live autonomy surfaces transient infrastructure debt separately" {
  let root = "/tmp/moontown-live-autonomy-transient-debt"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-1",
      book_id="research-opc",
      packet_id="packet-transient",
      packet_path="/tmp/packet-transient.json",
      status=@core.TaskExecutionStatus::Completed,
      summary="import timed out",
      output_contract="standing-watch",
      result_decision="deferred-transient-infrastructure",
    ),
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    tick_summary="transient debt check",
  )
  assert_eq(spine.status, "watching")
  assert_eq(spine.failed_count, 0)
  assert_eq(spine.transient_infrastructure_debt_count, 1)
  let live_text = render_live_autonomy_status(snapshot_path~)
  assert_true(live_text.contains("Transient infrastructure debt: `1`"))
  let digest = read_text_or_empty(default_live_digest_path(snapshot_path~))
  assert_true(digest.contains("transient_infrastructure_debt: `1`"))
}

///|
async test "live autonomy distinguishes historical watcher failures from current blockers" {
  let root = "/tmp/moontown-live-autonomy-failure-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-opc",
    tick=41,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::Failed,
    delta_score=0,
    new_source_count=0,
    detail="historical network issue already recovered",
    next_due_tick=101,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    watcher_records=[record],
    tick_summary="test recovered failure",
  )
  assert_eq(spine.status, "watching")
  assert_eq(spine.failed_count, 0)
  let live_text = render_live_autonomy_status(snapshot_path~)
  assert_true(live_text.contains("Unresolved failures: `0`"))
}

///|
async test "live status reconciles stale planbook counts from authoritative state" {
  let root = "/tmp/moontown-live-autonomy-planbook-reconcile-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  ignore(
    write_moontown_planbook_autonomy(
      snapshot_path~,
      workspace_root~,
      book_catalog_path="\{root}/catalog.json",
    ),
  )
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    tick_summary="stale planbook count setup",
  )
  let stale_spine = {
    ..spine,
    planbook_open_count: 99,
    planbook_repair_active_count: 99,
  }
  let goal = @core.StandingGoal::new(
    id="watch-sync-deferred",
    title="Watch deferred sync",
    prompt="watch sync",
    target_book_id=Some("research-sync"),
    cadence_ticks=60,
    next_due_tick=16000,
  )
  @storage.save_standing_goals_file("\{root}/standing-goals.json", [goal])
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-sync-deferred",
    tick=15877,
    target_book_id="research-sync",
    decision=@core.WatcherDecisionKind::Deferred,
    delta_score=0,
    new_source_count=0,
    detail="Mayor deferred standing goal because no watcher was currently eligible.",
    next_due_tick=16000,
  )
  write_text_file(
    "\{root}/watchers/watch-sync-deferred.jsonl",
    record.to_json().stringify() + "\n",
  )
  write_text_file(
    default_live_autonomy_path(snapshot_path~),
    stale_spine.to_json().stringify(indent=2),
  )
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(!status.contains("PlanBook open gaps: `99`"))
  assert_true(!status.contains("PlanBook active repairs: `99`"))
  assert_true(status.contains("planbook counts reconciled"))
  assert_true(status.contains("watch-sync-deferred -> Deferred"))
  assert_true(status.contains("Latest watcher is deferred"))
}

///|
async test "live status recomputes watcher summary from current ledger" {
  let root = "/tmp/moontown-live-autonomy-current-watcher-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Watch OPC",
    prompt="watch opc",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
    next_due_tick=16000,
  )
  @storage.save_standing_goals_file("\{root}/standing-goals.json", [goal])
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-opc-news",
    tick=15877,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::NeedsReview,
    delta_score=0,
    new_source_count=0,
    detail="Standing watch execution failed for research-opc. RUNTIME ERROR: abort() called. StringBuilder::grow_if_necessary. SystemStore::save_job_proposals.",
    next_due_tick=15907,
  )
  write_text_file(
    "\{root}/watchers/watch-opc-news.jsonl",
    record.to_json().stringify() + "\n",
  )
  ignore(
    write_live_autonomy_spine(
      state,
      snapshot_path~,
      tick_summary="stale cached live watcher",
    ),
  )
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(status.contains("watch-opc-news -> Failed"))
  assert_true(!status.contains("watch-opc-news -> NeedsReview"))
}

///|
async test "live autonomy does not count orphaned worker loss as no-change" {
  let root = "/tmp/moontown-live-autonomy-orphaned-worker-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  let record = @core.WatcherRunRecord::new(
    goal_id="book-quality-repair-research-ai-agents",
    tick=17782,
    target_book_id="research-ai-agents",
    decision=@core.WatcherDecisionKind::NoChange,
    delta_score=0,
    new_source_count=0,
    detail="MoonClaw run run-1 is indexed as Running, but no live proposal process was found; treating it as failed for mayor recovery.\nkeeper_auto_triage: persisted_terminal_result\npersisted_result_review: false",
    next_due_tick=17842,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    watcher_records=[record],
    tick_summary="orphaned worker accounting",
  )
  assert_eq(spine.no_change_count, 0)
  assert_eq(
    spine.latest_watcher_summary,
    "book-quality-repair-research-ai-agents -> Deferred sources=0 delta=0 next_due=17842",
  )
  assert_true(
    spine.next_actions.any(fn(action) {
      action.contains("Latest watcher is deferred")
    }),
  )
  assert_false(
    spine.next_actions.any(fn(action) {
      action.contains("Town is watching; wait")
    }),
  )
}

///|
async test "live autonomy latest watcher prefers parsed terminal duplicate" {
  let root = "/tmp/moontown-live-autonomy-canonical-watcher-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  let parsed = @core.WatcherRunRecord::new(
    goal_id="watch-opc-news",
    tick=17972,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::NoChange,
    delta_score=8,
    new_source_count=0,
    detail="standing_goal_decision: no_change\ndelta_score: 8\nnew_source_count: 0\nbook_changed: no",
    task_id=Some("standing-watch-opc-news-tick-17972"),
    run_id=Some("run-opc"),
    next_due_tick=18032,
  )
  let generic = @core.WatcherRunRecord::new(
    goal_id="watch-opc-news",
    tick=17972,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::NeedsReview,
    delta_score=0,
    new_source_count=0,
    detail="MoonClaw run run-opc completed: Workflow completed",
    task_id=Some("standing-watch-opc-news-tick-17972"),
    run_id=Some("run-opc"),
    next_due_tick=18002,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    watcher_records=[parsed, generic],
    tick_summary="canonical watcher check",
  )
  assert_eq(
    spine.latest_watcher_summary,
    "watch-opc-news -> NoChange sources=0 delta=8 next_due=18032",
  )
}

///|
async test "live status counts active executions when worker state is idle" {
  let root = "/tmp/moontown-live-autonomy-active-execution-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Running,
  )
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  ignore(
    write_live_autonomy_spine(
      state,
      snapshot_path~,
      tick_summary="active execution snapshot",
    ),
  )
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(status.contains("Active workers: `1`"))
}

///|
async test "live status uses effective tick from active execution task id" {
  let root = "/tmp/moontown-live-autonomy-effective-tick-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-16012",
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      status=@core.TaskExecutionStatus::Running,
      summary="running",
      output_contract="standing-watch",
    ),
  )
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  ignore(
    write_live_autonomy_spine(
      state,
      snapshot_path~,
      tick_summary="stale cached live tick",
      daemon_tick=Some(15907),
    ),
  )
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(status.contains("Tick: `16012`"))
}

///|
async test "live refresh works without saved town snapshot" {
  let root = "/tmp/moontown-live-autonomy-no-snapshot-refresh-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let message = refresh_live_autonomy_spine(snapshot_path~)
  assert_true(message.contains("without saved town snapshot"))
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(status.contains("# Live Autonomy Spine"))
  assert_true(status.contains("Active workers: `0`"))
}
