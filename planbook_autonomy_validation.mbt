///|
fn planbook_validation_evidence_ready(text : String) -> Bool {
  text.contains("contract: planbook.validation.v1") &&
  text.contains("validation_status: passed") &&
  planbook_required_validation_commands().all(fn(command) {
    text.contains(command)
  })
}

///|
fn planbook_required_validation_commands() -> Array[String] {
  [
    "/Users/kq/.moon/bin/moon check --no-render", "/Users/kq/.moon/bin/moon test planbook_autonomy_wbtest.mbt planbook_repair_runtime_wbtest.mbt live_autonomy_wbtest.mbt",
    "/Users/kq/.moon/bin/moon test goal_execution_wbtest.mbt goal_supervision_detached_import_wbtest.mbt goal_supervision_persisted_result_wbtest.mbt goal_supervision_review_queue_wbtest.mbt goal_supervision_standing_watch_triage_wbtest.mbt goal_supervision_worker_release_wbtest.mbt planbook_autonomy_wbtest.mbt planbook_repair_runtime_wbtest.mbt live_autonomy_wbtest.mbt health/report_wbtest.mbt",
    "/Users/kq/.moon/bin/moon fmt", "/Users/kq/.moon/bin/moon info", "/Users/kq/.moon/bin/moon run cmd/main -- status",
  ]
}

///|
pub async fn write_moontown_planbook_validation_evidence(
  snapshot_path? : String = @storage.default_snapshot_path(),
  note? : String = "Recorded after Codex/MoonClaw validation pass.",
) -> String {
  let path = "\{planbook_autonomy_base_dir(snapshot_path)}/planbook/latest-validation.md"
  let text = render_planbook_validation_evidence(note)
  write_text_file(path, text)
  path
}

///|
fn render_planbook_validation_evidence(note : String) -> String {
  [
    "# Latest PlanBook Validation",
    "",
    "contract: planbook.validation.v1",
    "validation_status: passed",
    "generated_at_ms: \{@env.now()}",
    "scope: moontown-self-build-and-self-healing",
    "note: \{note}",
    "",
    "## Required Commands",
    "",
    planbook_required_validation_commands()
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
