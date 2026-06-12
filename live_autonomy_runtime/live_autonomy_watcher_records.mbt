///|
fn count_watcher_decisions(
  records : Array[@core.WatcherRunRecord],
  decision : @core.WatcherDecisionKind,
) -> Int {
  let mut count = 0
  for record in records {
    if @standing_watch_policy.watcher_record_effective_decision(record) ==
      decision {
      count += 1
    }
  }
  count
}

///|
fn latest_watcher_record(
  records : Array[@core.WatcherRunRecord],
) -> @core.WatcherRunRecord? {
  if records.is_empty() {
    None
  } else {
    let mut latest = records[0]
    for record in records {
      if @standing_watch_policy.watcher_record_prefer_candidate(latest, record) {
        latest = record
      }
    }
    Some(latest)
  }
}

///|
fn latest_record_for_goal(
  records : Array[@core.WatcherRunRecord],
  goal_id : String,
) -> @core.WatcherRunRecord? {
  let mut latest : @core.WatcherRunRecord? = None
  for record in records {
    if record.goal_id != goal_id {
      continue
    }
    match latest {
      Some(current) =>
        if @standing_watch_policy.watcher_record_prefer_candidate(
            current, record,
          ) {
          latest = Some(record)
        }
      None => latest = Some(record)
    }
  }
  latest
}

///|
fn latest_watcher_record_summary(
  records : Array[@core.WatcherRunRecord],
  standing_goals : Array[@core.StandingGoal],
) -> String {
  match latest_watcher_record(records) {
    Some(record) => {
      let next_due = latest_watcher_summary_next_due(record, standing_goals)
      let decision = @standing_watch_policy.watcher_record_effective_decision(
        record,
      ).to_string()
      "\{record.goal_id} -> \{decision} sources=\{record.new_source_count} delta=\{record.delta_score} next_due=\{next_due}"
    }
    None => "No watcher records yet."
  }
}

///|
fn latest_watcher_summary_next_due(
  record : @core.WatcherRunRecord,
  standing_goals : Array[@core.StandingGoal],
) -> Int {
  for goal in standing_goals {
    if goal.id == record.goal_id {
      return goal.next_due_tick
    }
  }
  record.next_due_tick
}
