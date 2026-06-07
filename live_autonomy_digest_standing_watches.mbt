///|
fn write_live_autonomy_digest_standing_watches(
  builder : StringBuilder,
  spine : LiveAutonomySpine,
  standing_goals : Array[@core.StandingGoal],
  watcher_records : Array[@core.WatcherRunRecord],
) -> Unit {
  builder.write_string("## Standing Watches\n\n")
  if standing_goals.is_empty() {
    builder.write_string("No standing watches are configured.\n\n")
    return
  }
  builder.write_string(
    "| Goal | Book | Next Due | Due In | Approx Time | Latest Decision | Evidence |\n",
  )
  builder.write_string("|---|---|---:|---:|---|---|---:|\n")
  for goal in standing_goals {
    write_live_autonomy_digest_standing_watch_row(
      builder, spine, watcher_records, goal,
    )
  }
  builder.write_string("\n")
}

///|
fn write_live_autonomy_digest_standing_watch_row(
  builder : StringBuilder,
  spine : LiveAutonomySpine,
  watcher_records : Array[@core.WatcherRunRecord],
  goal : @core.StandingGoal,
) -> Unit {
  let latest = latest_record_for_goal(watcher_records, goal.id)
  let decision = match latest {
    Some(record) => record.decision.to_string()
    None => "not-run"
  }
  let evidence = match latest {
    Some(record) => record.new_source_count.to_string()
    None => "0"
  }
  let book = goal.target_book_id.unwrap_or("mayor-selected-book")
  let due_in_ticks = if goal.next_due_tick > spine.tick {
    goal.next_due_tick - spine.tick
  } else {
    0
  }
  builder.write_string(
    "|\{goal.id}|\{book}|\{goal.next_due_tick}|\{due_in_ticks}|\{live_autonomy_due_in_label(due_in_ticks)}|\{decision}|\{evidence}|\n",
  )
}
