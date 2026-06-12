///|
fn write_live_autonomy_digest_header(
  builder : StringBuilder,
  spine : LiveAutonomySpine,
) -> Unit {
  builder.write_string("# Moontown Live Digest\n\n")
  builder.write_string("- status: `\{spine.status}`\n")
  builder.write_string("- tick: `\{spine.tick}`\n")
  builder.write_string("- stable_waiting: `\{spine.stable_waiting}`\n")
  builder.write_string(
    "- stable_waiting_observation_streak: `\{spine.stable_waiting_observation_streak}`\n",
  )
  builder.write_string(
    "- stable_waiting_blockers: `\{spine.stable_waiting_blockers.length()}`\n",
  )
  builder.write_string("- active_workers: `\{spine.active_worker_count}`\n")
  builder.write_string("- review_queue: `\{spine.review_count}`\n")
  builder.write_string("- blocked_or_unhealthy: `\{spine.blocked_count}`\n")
  builder.write_string("- unresolved_failures: `\{spine.failed_count}`\n")
  builder.write_string(
    "- transient_infrastructure_debt: `\{spine.transient_infrastructure_debt_count}`\n",
  )
  builder.write_string("- accepted_updates: `\{spine.accepted_update_count}`\n")
  builder.write_string("- no_change_cycles: `\{spine.no_change_count}`\n")
  builder.write_string("- standing_goals: `\{spine.standing_goal_count}`\n")
  builder.write_string(
    "- enabled_standing_goals: `\{spine.enabled_standing_goal_count}`\n",
  )
  builder.write_string(
    "- disabled_standing_goals: `\{spine.disabled_standing_goal_count}`\n",
  )
  builder.write_string(
    "- planbook_open_gaps: `\{spine.planbook_open_count}`\n\n",
  )
  builder.write_string(
    "- planbook_active_repairs: `\{spine.planbook_repair_active_count}`\n\n",
  )
  builder.write_string(
    "- book_template_requests: `\{spine.book_template_request_count}`\n",
  )
  builder.write_string(
    "- pending_book_template_requests: `\{spine.pending_book_template_request_count}`\n",
  )
  builder.write_string(
    "- failed_book_template_requests: `\{spine.failed_book_template_request_count}`\n",
  )
  builder.write_string(
    "- book_template_request_summary: \{spine.book_template_request_summary}\n\n",
  )
  builder.write_string(
    "- book_template_latest_event: \{spine.book_template_latest_event_summary}\n\n",
  )
  builder.write_string(
    "- planbook_change_log: `\{spine.planbook_change_log_path}`\n",
  )
  builder.write_string(
    "- planbook_engineering_digest: `\{spine.planbook_engineering_digest_path}`\n",
  )
  builder.write_string("- latest_change: \{spine.latest_change_summary}\n\n")
  builder.write_string("## Current Interpretation\n\n")
  builder.write_string(live_autonomy_digest_interpretation(spine))
  builder.write_string("\n\n")
}

///|
fn write_live_autonomy_digest_stable_blockers(
  builder : StringBuilder,
  spine : LiveAutonomySpine,
) -> Unit {
  builder.write_string("## Stable Waiting Blockers\n\n")
  if spine.stable_waiting_blockers.is_empty() {
    builder.write_string("- none\n\n")
  } else {
    for blocker in spine.stable_waiting_blockers {
      builder.write_string("- \{blocker}\n")
    }
    builder.write_string("\n")
  }
}
