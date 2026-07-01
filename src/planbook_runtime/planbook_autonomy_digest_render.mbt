///|
fn planbook_daily_engineering_digest_markdown(
  status : PlanbookAutonomyStatus,
  workspace_root : String,
) -> String {
  let open_items : Array[String] = []
  let satisfied_items : Array[String] = []
  for item in status.criteria {
    if item.satisfied {
      satisfied_items.push("- `\{item.id}`: \{item.evidence}")
    } else {
      open_items.push(
        "- `\{item.id}`: \{item.evidence}. Next: \{item.next_action}",
      )
    }
  }
  [
    "# Daily Engineering Digest",
    "",
    "- generated_at_ms: `\{status.generated_at_ms}`",
    "- status: `\{status.status}`",
    "- open_gaps: `\{status.open_count}`",
    "- satisfied_criteria: `\{status.satisfied_count}`",
    "- active_review: `wiki/reviews/active-plan-review.md`",
    "- change_log: `wiki/history/change-log.md`",
    "- backlog_progress: `wiki/planning/backlog-progress.md`",
    "- latest_validation: `.moonsuite/products/moontown/planbook/latest-validation.md`",
    "",
    "## Current Open Work",
    "",
    if open_items.is_empty() {
      "- none; the town is in stable watch mode until operator input, web/search evidence, or a new backlog item creates a gap"
    } else {
      open_items.join("\n")
    },
    "",
    "## Satisfied Work",
    "",
    if satisfied_items.is_empty() {
      "- none"
    } else {
      satisfied_items.join("\n")
    },
    "",
    "## Source-Control Policy",
    "",
    "- Repair packets require validation commands, `git diff --check`, `git status --short`, focused diff summary, `commit_status`, `commit_message`, and `push_status`.",
    "- Local commit readiness is allowed after validation. Push remains disabled unless a future explicit policy changes it.",
    "",
    "## Workspace",
    "",
    "- `\{workspace_root}`",
  ].join("\n")
}
