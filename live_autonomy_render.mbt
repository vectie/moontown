///|
pub async fn render_live_autonomy_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  let path = default_live_autonomy_path(snapshot_path~)
  if !@fs.exists(path) {
    ignore(refresh_live_autonomy_spine(snapshot_path~))
    if !@fs.exists(path) {
      return "No live autonomy spine exists at \{path}. Run `moon run cmd/main -- daemon tick` or `moon run cmd/main -- live refresh`."
    }
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ =>
      return "Live autonomy spine exists at \{path}, but it is not valid JSON."
  }
  let decoded = match decode_live_autonomy_spine(parsed) {
    Some(value) => value
    None => {
      ignore(refresh_live_autonomy_spine(snapshot_path~))
      let refreshed = @json.parse(@fs.read_file(path).text()) catch {
        _ =>
          return "Live autonomy spine exists at \{path}, but it is not valid JSON after refresh."
      }
      match decode_live_autonomy_spine(refreshed) {
        Some(value) => value
        None =>
          return "Live autonomy spine exists at \{path}, but it does not match the contract after refresh."
      }
    }
  }
  let current = current_live_autonomy_spine(snapshot_path, decoded)
  let spine = sync_live_autonomy_planbook_counts(current, snapshot_path)
  [
    "# Live Autonomy Spine",
    "",
    "- Status: `\{spine.status}`",
    "- Tick: `\{spine.tick}`",
    "- Stable waiting: `\{spine.stable_waiting}`",
    "- Stable waiting observation streak: `\{spine.stable_waiting_observation_streak}`",
    "- Active workers: `\{spine.active_worker_count}`",
    "- Review: `\{spine.review_count}`",
    "- Blocked: `\{spine.blocked_count}`",
    "- Accepted updates: `\{spine.accepted_update_count}`",
    "- No-change cycles: `\{spine.no_change_count}`",
    "- Unresolved failures: `\{spine.failed_count}`",
    "- Transient infrastructure debt: `\{spine.transient_infrastructure_debt_count}`",
    "- Standing goals: `\{spine.standing_goal_count}`",
    "- Enabled standing goals: `\{spine.enabled_standing_goal_count}`",
    "- Disabled standing goals: `\{spine.disabled_standing_goal_count}`",
    "- Due goals: `\{spine.due_goal_count}`",
    "- PlanBook open gaps: `\{spine.planbook_open_count}`",
    "- PlanBook active repairs: `\{spine.planbook_repair_active_count}`",
    "- Book template requests: `\{spine.book_template_request_count}`",
    "- Pending template requests: `\{spine.pending_book_template_request_count}`",
    "- Failed template requests: `\{spine.failed_book_template_request_count}`",
    "- Latest book-template event: \{spine.book_template_latest_event_summary}",
    "- Visual projection: `\{spine.visual_projection_path}`",
    "- Journal: `\{spine.journal_path}`",
    "- Digest: `\{spine.digest_path}`",
    "- PlanBook change log: `\{spine.planbook_change_log_path}`",
    "- PlanBook engineering digest: `\{spine.planbook_engineering_digest_path}`",
    "",
    "## Stable Waiting Blockers",
    "",
    if spine.stable_waiting_blockers.is_empty() {
      "- none"
    } else {
      markdown_bullets(spine.stable_waiting_blockers)
    },
    "",
    "## Summary",
    "",
    spine.summary,
    "",
    "## Latest Watcher",
    "",
    spine.latest_watcher_summary,
    "",
    "## Latest Change",
    "",
    spine.latest_change_summary,
    "",
    "## Book Template Requests",
    "",
    spine.book_template_request_summary,
    "",
    "Latest event: \{spine.book_template_latest_event_summary}",
    "",
    "## Next Actions",
    "",
    if spine.next_actions.is_empty() {
      "- none"
    } else {
      markdown_bullets(spine.next_actions)
    },
  ].join("\n")
}
