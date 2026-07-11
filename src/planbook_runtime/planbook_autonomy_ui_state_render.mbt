///|
fn planbook_autonomy_ui_state_json(status : PlanbookAutonomyStatus) -> String {
  let summary = @support.json_string(
    "Self-build, self-healing, execution evidence, and review state for MoonTown quality work.",
  )
  let chip_tone = if status.open_count == 0 { "healthy" } else { "review" }
  let gap_tone = if status.open_count == 0 { "healthy" } else { "warning" }
  let review_meta = if status.open_count == 0 { "Accepted" } else { "Open" }
  let journey_status = if status.open_count == 0 {
    "accepted"
  } else {
    "review"
  }
  let journey_summary = @support.json_string(
    "Inspected self-build criteria and produced repair evidence.",
  )
  [
    "{",
    "  \"book_id\": \{@support.json_string(status.book_id)},",
    "  \"title\": \"MoonTown Quality Planbook\",",
    "  \"summary\": \{summary},",
    "  \"status_chips\": [",
    "    {\"label\":\"\{status.status}\",\"tone\":\"\{chip_tone}\"},",
    "    {\"label\":\"open gaps \{status.open_count}\",\"tone\":\"\{gap_tone}\"}",
    "  ],",
    "  \"metrics\": [",
    "    {\"label\":\"Satisfied\",\"value\":\"\{status.satisfied_count}\",\"note\":\"self-build criteria\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Open\",\"value\":\"\{status.open_count}\",\"note\":\"repair backlog\",\"tone\":\"review\"}",
    "  ],",
    "  \"readiness\": [",
    "    {\"title\":\"Self-healing status\",\"detail\":\"wiki/planning/self-healing.md\",\"meta\":\"Generated\"},",
    "    {\"title\":\"Execution evidence\",\"detail\":\"wiki/planning/execution-evidence.md\",\"meta\":\"Generated\"},",
    "    {\"title\":\"Implementation backlog\",\"detail\":\"wiki/planning/implementation-backlog.md\",\"meta\":\"Document-controlled\"},",
    "    {\"title\":\"Backlog progress\",\"detail\":\"wiki/planning/backlog-progress.md\",\"meta\":\"Cadence\"},",
    "    {\"title\":\"Stop policy\",\"detail\":\"wiki/planning/stop-policy.md\",\"meta\":\"Safety\"},",
    "    {\"title\":\"Change log\",\"detail\":\"wiki/history/change-log.md\",\"meta\":\"Live history\"},",
    "    {\"title\":\"Daily engineering digest\",\"detail\":\"wiki/history/daily-engineering-digest.md\",\"meta\":\"Overnight review\"}",
    "  ],",
    "  \"review_queue\": [",
    "    {\"title\":\"PlanBook repair backlog\",\"detail\":\"wiki/reviews/active-plan-review.md\",\"meta\":\"\{review_meta}\"}",
    "  ],",
    "  \"page_families\": [",
    "    {\"title\":\"Self-Healing\",\"detail\":\"wiki/planning/self-healing.md\",\"meta\":\"PlanBook\"}",
    "  ],",
    "  \"journey\": [",
    "    {\"title\":\"PlanBook autonomy doctor\",\"stage\":\"inspect\",\"status\":\"\{journey_status}\",\"summary\":\{journey_summary},\"highlights\":[]}",
    "  ]",
    "}",
  ].join("\n")
}
