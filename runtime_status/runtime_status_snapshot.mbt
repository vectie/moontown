///|
pub async fn inspect_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> TownRuntimeStatus {
  match @storage.load_snapshot_file(snapshot_path) {
    Some(snapshot) => {
      let daemon = @daemon_runtime.load_daemon_state(
        @daemon_runtime.default_daemon_state_path(snapshot_path),
      )
      let goals = @storage.load_or_create_standing_goals(
        path=@daemon_runtime.default_standing_goal_state_path(snapshot_path),
      )
      let watcher_records = load_watcher_records_for_goals(snapshot_path, goals)
      let template_request_status = @book_templates.inspect_book_template_request_status(
        request_path=@book_templates.request_path_for_snapshot(snapshot_path),
      )
      let daemon_tick = effective_daemon_tick(
        snapshot_path,
        daemon,
        snapshot.town,
        goals,
        watcher_records,
      )
      runtime_status_from_state(
        snapshot.town,
        snapshot_path,
        standing_goals=goals,
        daemon_tick~,
        watcher_records~,
        book_template_request_status=Some(template_request_status),
      )
    }
    None => empty_runtime_status(snapshot_path)
  }
}

///|
pub fn runtime_status_from_state(
  state : @core.TownState,
  snapshot_path : String,
  standing_goals? : Array[@core.StandingGoal] = [],
  daemon_tick? : Int = 0,
  watcher_records? : Array[@core.WatcherRunRecord] = [],
  book_template_request_status? : @book_templates.BookTemplateRequestStatus? = None,
) -> TownRuntimeStatus {
  let report = @health.inspect_town(state)
  let actions = @scheduler.plan_tick(state, report)
  let next_tick = daemon_tick + 1
  let standing_goal_counts = @runtime_status_policy.runtime_status_standing_goal_counts(
    standing_goals, next_tick,
  )
  for action in @scheduler.plan_standing_goal_actions(standing_goals, next_tick) {
    actions.push(action)
  }
  let execution_counts = @runtime_status_policy.runtime_status_execution_counts(
    state, report,
  )
  let template_request_status = book_template_request_status.unwrap_or(
    empty_book_template_request_status(snapshot_path),
  )
  let template_request_counts = @book_templates.request_runtime_counts(
    template_request_status,
  )
  {
    snapshot_path,
    has_snapshot: true,
    book_count: state.books.length(),
    worker_count: state.workers.length(),
    task_count: state.tasks.length(),
    execution_count: state.executions.length(),
    event_count: state.events.length(),
    running_count: execution_counts.running,
    review_count: execution_counts.review,
    failed_count: execution_counts.failed,
    stale_count: execution_counts.stale,
    completed_count: execution_counts.completed,
    standing_goal_count: standing_goal_counts.total,
    enabled_standing_goal_count: standing_goal_counts.enabled,
    disabled_standing_goal_count: standing_goal_counts.disabled,
    due_standing_goal_count: standing_goal_counts.due,
    watcher_record_count: watcher_records.length(),
    watcher_summary: watcher_status_summary(watcher_records, standing_goals),
    book_template_request_count: template_request_counts.total,
    pending_book_template_request_count: template_request_counts.pending,
    failed_book_template_request_count: template_request_counts.failed,
    book_template_request_summary: template_request_status.summary,
    book_template_latest_event_summary: template_request_status.latest_event_summary,
    daemon_tick,
    daemon_actions: actions,
    summary: @runtime_status_policy.runtime_status_summary(
      state,
      execution_counts,
      standing_goal_counts,
      watcher_records.length(),
      template_request_counts,
      actions.length(),
    ),
  }
}
