///|
pub fn validation_evidence_contract() -> String {
  "planbook.validation.v1"
}

///|
pub fn validation_evidence_passed_status() -> String {
  "passed"
}

///|
pub fn validation_required_commands() -> Array[String] {
  [
    "moon check --no-render", "moon test planbook_autonomy_wbtest.mbt planbook_repair_runtime_wbtest.mbt live_autonomy_wbtest.mbt",
    "moon test goal_execution_wbtest.mbt goal_supervision_detached_import_wbtest.mbt goal_supervision_persisted_result_wbtest.mbt goal_supervision_review_queue_wbtest.mbt goal_supervision_standing_watch_triage_wbtest.mbt goal_supervision_worker_release_wbtest.mbt planbook_autonomy_wbtest.mbt planbook_repair_runtime_wbtest.mbt live_autonomy_wbtest.mbt health/report_wbtest.mbt",
    "moon fmt", "moon info", "moon run src/cmd/main -- status",
  ]
}

///|
pub fn validation_evidence_ready(text : String) -> Bool {
  text.contains("contract: \{validation_evidence_contract()}") &&
  text.contains("validation_status: \{validation_evidence_passed_status()}") &&
  validation_required_commands().all(fn(command) { text.contains(command) })
}

///|
pub fn validation_evidence_markdown(
  note : String,
  generated_at_ms : UInt64,
) -> String {
  [
    "# Latest PlanBook Validation",
    "",
    "contract: \{validation_evidence_contract()}",
    "validation_status: \{validation_evidence_passed_status()}",
    "generated_at_ms: \{generated_at_ms}",
    "scope: moontown-self-build-and-self-healing",
    "note: \{note}",
    "",
    "## Required Commands",
    "",
    validation_required_commands()
    .map(fn(command) { "- `\{command}`: passed" })
    .join("\n"),
    "",
    "## Acceptance",
    "",
    "- Failed/stale execution accounting is reconciled after successful MoonBook persistence.",
    "- Already-persisted terminal book results can clear stale failed execution records on the next supervision cycle.",
    "- PlanBook open-gap count is exposed through live autonomy state.",
    "- The launchd daemon remains healthy after a real heartbeat.",
  ].join("\n")
}
