///|
async fn sync_live_autonomy_planbook_counts(
  spine : LiveAutonomySpine,
  snapshot_path : String,
) -> LiveAutonomySpine {
  let planbook = live_autonomy_planbook_metadata(snapshot_path)
  let planbook_open = planbook.planbook_open
  let planbook_repair_active = planbook.planbook_repair_active
  if planbook_open == spine.planbook_open_count &&
    planbook_repair_active == spine.planbook_repair_active_count {
    spine
  } else {
    let summary = synced_live_autonomy_summary(
      spine.summary,
      spine.tick,
      spine.active_worker_count,
      spine.review_count,
      spine.blocked_count,
      spine.accepted_update_count,
      spine.no_change_count,
      planbook_open,
    )
    let waiting = synced_live_autonomy_waiting_state(
      spine, snapshot_path, planbook_open, planbook_repair_active,
    )
    let goals = @storage.load_or_create_standing_goals(
      path=live_autonomy_standing_goal_path(snapshot_path),
    )
    let records = load_live_autonomy_watcher_records(snapshot_path, goals)
    let synced = {
      ..spine,
      generated_at_ms: @env.now(),
      planbook_open_count: planbook_open,
      planbook_repair_active_count: planbook_repair_active,
      stable_waiting: waiting.stable_waiting,
      stable_waiting_observation_streak: waiting.stable_waiting_observation_streak,
      stable_waiting_blockers: waiting.stable_waiting_blockers,
      planbook_change_log_path: planbook.planbook_change_log_path,
      planbook_engineering_digest_path: planbook.planbook_engineering_digest_path,
      latest_change_summary: planbook.latest_change_summary,
      latest_watcher_summary: latest_watcher_record_summary(records, goals),
      summary,
      next_actions: synced_live_autonomy_next_actions(
        spine, records, planbook_open, planbook_repair_active,
      ),
    }
    write_text_file(
      default_live_autonomy_path(snapshot_path~),
      synced.to_json().stringify(indent=2),
    )
    synced
  }
}

///|
priv struct LiveAutonomySyncedWaitingState {
  stable_waiting : Bool
  stable_waiting_observation_streak : Int
  stable_waiting_blockers : Array[String]
}

///|
async fn synced_live_autonomy_waiting_state(
  spine : LiveAutonomySpine,
  snapshot_path : String,
  planbook_open : Int,
  planbook_repair_active : Int,
) -> LiveAutonomySyncedWaitingState {
  let stable_waiting_blockers = live_autonomy_stable_waiting_blockers_for({
    active_workers: spine.active_worker_count,
    review: spine.review_count,
    blocked: spine.blocked_count,
    failed: spine.failed_count,
    due_goals: spine.due_goal_count,
    planbook_open,
    planbook_repair_active,
    pending_book_template_requests: spine.pending_book_template_request_count,
    failed_book_template_requests: spine.failed_book_template_request_count,
  })
  let stable_waiting = stable_waiting_blockers.is_empty()
  {
    stable_waiting,
    stable_waiting_observation_streak: synced_live_autonomy_waiting_streak(
      spine, snapshot_path, stable_waiting,
    ),
    stable_waiting_blockers,
  }
}

///|
async fn synced_live_autonomy_waiting_streak(
  spine : LiveAutonomySpine,
  snapshot_path : String,
  stable_waiting : Bool,
) -> Int {
  if stable_waiting {
    max_int(
      spine.stable_waiting_observation_streak,
      prior_live_autonomy_stable_waiting_observation_streak(
        snapshot_path,
        spine.tick,
      ) +
      1,
    )
  } else {
    0
  }
}

///|
fn synced_live_autonomy_next_actions(
  spine : LiveAutonomySpine,
  watcher_records : Array[@core.WatcherRunRecord],
  planbook_open : Int,
  planbook_repair_active : Int,
) -> Array[String] {
  live_autonomy_next_actions_for({
    blockers: {
      active_workers: spine.active_worker_count,
      review: spine.review_count,
      blocked: spine.blocked_count,
      failed: spine.failed_count,
      due_goals: spine.due_goal_count,
      planbook_open,
      planbook_repair_active,
      pending_book_template_requests: spine.pending_book_template_request_count,
      failed_book_template_requests: spine.failed_book_template_request_count,
    },
    watcher_records,
    transient_infrastructure_debt: spine.transient_infrastructure_debt_count,
  })
}

///|
fn synced_live_autonomy_summary(
  previous : String,
  tick : Int,
  active_workers : Int,
  review : Int,
  blocked : Int,
  accepted_updates : Int,
  no_change : Int,
  planbook_open : Int,
) -> String {
  let mut prefix = ""
  for part in previous.split(";") {
    prefix = part.trim().to_owned()
    break
  }
  let metrics = "tick=\{tick} active=\{active_workers} review=\{review} blocked=\{blocked} accepted_updates=\{accepted_updates} no_change=\{no_change} planbook_open=\{planbook_open}"
  if prefix.is_blank() || prefix.has_prefix("tick=") {
    "\{metrics}; planbook counts reconciled from authoritative state"
  } else {
    "\{prefix}; \{metrics}; planbook counts reconciled from authoritative state"
  }
}
