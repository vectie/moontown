///|
priv struct LiveAutonomyStatusView {
  tick_label : String
  outcome_label : String
  standing_goal_label : String
  planbook_label : String
  latest_watcher_label : String
  latest_book_event_label : String
  artifact_label : String
  latest_change_label : String
}

///|
fn live_autonomy_status_view(
  spine : LiveAutonomySnapshot,
) -> LiveAutonomyStatusView {
  {
    tick_label: "tick \{spine.tick} generated at \{spine.generated_at_ms}",
    outcome_label: "accepted \{spine.accepted_update_count}, no-change \{spine.no_change_count}, review \{spine.review_count}, blocked \{spine.blocked_count}, failed \{spine.failed_count}",
    standing_goal_label: "goals \{spine.enabled_standing_goal_count} active / \{spine.disabled_standing_goal_count} archived, due goals \{spine.due_goal_count}",
    planbook_label: "plan gaps \{spine.planbook_open_count}, template inbox \{spine.pending_book_template_request_count}/\{spine.failed_book_template_request_count}",
    latest_watcher_label: "Latest watcher: \{spine.latest_watcher_summary}",
    latest_book_event_label: "Latest book event: \{spine.book_template_latest_event_summary}",
    artifact_label: "Digest: \{spine.digest_path}. Visual: \{spine.visual_projection_path}. Journal: \{spine.journal_path}. Engineering: \{spine.planbook_engineering_digest_path}. Change log: \{spine.planbook_change_log_path}",
    latest_change_label: "Latest: \{compact_single_line(spine.latest_change_summary, limit=180)}",
  }
}

///|
fn LiveAutonomyStatusView::detail_label(
  self : LiveAutonomyStatusView,
) -> String {
  [
    self.tick_label,
    self.outcome_label,
    self.standing_goal_label,
    self.planbook_label,
  ].join("; ") +
  ". " +
  [
    self.latest_watcher_label,
    self.latest_book_event_label,
    self.artifact_label,
    self.latest_change_label,
  ].join(". ")
}

///|
fn compact_single_line(summary : String, limit~ : Int) -> String {
  let normalized = StringBuilder::new()
  for char in summary {
    if char == '\n' || char == '\r' || char == '\t' {
      normalized.write_char(' ')
    } else {
      normalized.write_char(char)
    }
  }
  let one_line = normalized.to_string().trim().to_owned()
  if one_line.length() <= limit {
    one_line
  } else {
    let builder = StringBuilder::new()
    let mut emitted = 0
    for char in one_line {
      if emitted >= limit {
        break
      }
      builder.write_char(char)
      emitted += 1
    }
    "\{builder.to_string()}..."
  }
}
