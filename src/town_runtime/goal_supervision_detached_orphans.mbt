///|
async fn rehydrate_orphaned_deferred_watcher_records(
  state : @core.TownState,
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
  tick : Int,
) -> Unit {
  let ledger_dir = watcher_ledger_dir_for_snapshot(snapshot_path)
  for goal in standing_goals {
    if @core.live_external_execution_count(state) >=
      @core.max_live_external_executions() {
      return
    }
    let records = @storage.load_watcher_run_records(goal.id, dir=ledger_dir)
    match latest_orphaned_deferred_watcher_record(state, records) {
      Some(record) =>
        match deferred_watcher_packet_path(record) {
          Some(packet_path) => {
            let task_id = record.task_id.unwrap_or("")
            let book_id = record.target_book_id
            let packet_id = packet_id_from_packet_path(packet_path)
            let task = @core.TownTask::new(
              id=task_id,
              book_id~,
              title="Standing watch recovery: \{goal.title}",
              prompt=goal.prompt,
              domain=@core.WorkDomain::Research,
              required_role=Some(@core.WorkerRole::Watcher),
              status=@core.TownTaskStatus::Assigned,
            )
            let execution = @core.TaskExecutionRecord::new(
              task_id~,
              book_id~,
              packet_id~,
              packet_path~,
              status=@core.TaskExecutionStatus::ProposalImported,
              summary="Mayor rehydrated orphaned deferred watcher record for `\{goal.id}` from persisted ledger receipt path. Original detail: \{record.detail}",
              output_contract="standing-watch",
              heartbeat_tick=tick,
              stale_after_tick=tick + 15,
              result_decision="deferred",
              requires_review=false,
              notify_town=true,
            )
            state.replace_task(task)
            state.replace_execution(execution)
            ignore(
              reconcile_detached_import_receipt_if_available(
                state, execution, tick,
              ),
            )
            state.record_event(
              @core.TownEvent::new(
                id="event-watch-rehydrate-\{state.events.length()}-\{task_id}",
                kind="recovery",
                detail="Mayor rehydrated orphaned deferred watcher `\{task_id}` for `\{goal.id}` so the detached MoonClaw import can be supervised again.",
                related_task_id=Some(task_id),
                related_book_id=Some(book_id),
              ),
            )
          }
          None => ()
        }
      None => ()
    }
  }
}

///|
fn latest_orphaned_deferred_watcher_record(
  state : @core.TownState,
  records : Array[@core.WatcherRunRecord],
) -> @core.WatcherRunRecord? {
  let mut latest : @core.WatcherRunRecord? = None
  for record in records {
    if !orphaned_deferred_watcher_record_candidate(state, records, record) {
      continue
    }
    match latest {
      Some(current) => if record.tick >= current.tick { latest = Some(record) }
      None => latest = Some(record)
    }
  }
  latest
}

///|
fn orphaned_deferred_watcher_record_candidate(
  state : @core.TownState,
  records : Array[@core.WatcherRunRecord],
  record : @core.WatcherRunRecord,
) -> Bool {
  if record.decision != @core.WatcherDecisionKind::Deferred {
    return false
  }
  let task_id = match record.task_id {
    Some(task_id) => task_id
    None => return false
  }
  if @core.find_execution(state, task_id) is Some(_) {
    return false
  }
  if deferred_watcher_record_has_terminal_successor(records, record) {
    return false
  }
  deferred_watcher_packet_path(record) is Some(_)
}

///|
fn deferred_watcher_record_has_terminal_successor(
  records : Array[@core.WatcherRunRecord],
  record : @core.WatcherRunRecord,
) -> Bool {
  for other in records {
    if other.task_id == record.task_id &&
      other.tick >= record.tick &&
      other.decision != @core.WatcherDecisionKind::Deferred {
      return true
    }
  }
  false
}

///|
fn deferred_watcher_packet_path(record : @core.WatcherRunRecord) -> String? {
  let receipt_path = match deferred_watcher_receipt_path(record.detail) {
    Some(path) => path
    None => return None
  }
  if receipt_path.has_suffix(".import.json") {
    Some(
      receipt_path[:receipt_path.length() - ".import.json".length()].to_owned(),
    )
  } else {
    None
  }
}

///|
fn deferred_watcher_receipt_path(detail : String) -> String? {
  let needle = "waiting for receipt "
  for line in detail.split("\n") {
    let parts = line.split(needle).to_array()
    if parts.length() < 2 {
      continue
    }
    let candidate = parts[1].trim(chars=" .").to_owned()
    if candidate.has_suffix(".import.json") {
      return Some(candidate)
    }
  }
  None
}

///|
fn packet_id_from_packet_path(packet_path : String) -> String {
  let basename = @support.path_basename(packet_path)
  if basename.has_suffix(".json") {
    basename[:basename.length() - ".json".length()].to_owned()
  } else {
    basename
  }
}
