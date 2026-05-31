///|
async test "research persistence handoff uses topic artifacts instead of runtime plumbing" {
  let root = "/tmp/moontown-research-persist-handoff"
  ignore_checked_command("rm", ["-rf", root])
  write_text_file(
    root + "/raw/bootstrap/synthesis-brief.md",
    "# Synthesis Brief\n\nOne Person Company (OPC) is an evidence-limited solo-founder operating model.\n",
  )
  write_text_file(
    root + "/raw/bootstrap/source-screen.md",
    "# Source Screen\n\n| Source ID | Decision |\n| --- | --- |\n| W1 | include |\n",
  )
  write_text_file(
    root + "/raw/bootstrap/evidence-matrix.md",
    "# Evidence Matrix\n\n| Claim ID | Claim |\n| --- | --- |\n| C1 | OPC uses leverage. |\n",
  )
  write_text_file(
    root + "/raw/bootstrap/deep-report.md",
    "# One Person Company (OPC): Deep Research Analysis\n\n## Executive Summary\n\nOPC research summary.\n",
  )
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-opc",
    name="One Person Company",
    purpose="Track OPC",
    workspace_root=root,
  )
  let execution = @core.TaskExecutionRecord::new(
    task_id="goal-research-opc-research-bootstrap-ingest",
    book_id="research-opc",
    packet_id="packet-opc",
    packet_path="packet-opc.json",
    run_id=Some("run-opc"),
    status=@core.TaskExecutionStatus::Completed,
    summary="MoonClaw run run-opc completed: Workflow completed",
    output_contract="moontown.research.raw.v1",
  )
  let summary = research_persist_summary(entry, execution)
  assert_true(summary.contains("One Person Company (OPC)"))
  assert_true(!summary.contains("MoonClaw run"))
  let artifacts = research_persist_artifacts(entry, execution)
  assert_true(artifacts.contains("raw/bootstrap/deep-report.md"))
  let candidates = research_persist_memory_candidates(entry, execution)
  assert_eq(candidates.length(), 4)
  assert_true(
    candidates[0].target_page == Some("sources/opc-screened-sources.md"),
  )
  assert_true(candidates[1].target_page == Some("entities/opc.md"))
  assert_true(
    candidates[2].target_page == Some("concepts/opc-research-thesis.md"),
  )
  assert_true(
    candidates[3].target_page == Some("synthesis/opc-research-thesis.md"),
  )
}

///|
test "moonclaw supervision seconds parser accepts zero for nonblocking mode" {
  assert_eq(parse_non_negative_seconds("900", fallback=0), 900)
  assert_eq(parse_non_negative_seconds(" 1800 ", fallback=0), 1800)
  assert_eq(parse_non_negative_seconds("0", fallback=3600), 0)
  assert_eq(parse_non_negative_seconds("", fallback=3600), 3600)
  assert_eq(parse_non_negative_seconds("10m", fallback=3600), 3600)
}

///|
test "successful book persistence reconciles failed execution into review queue" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="goal-synthesis",
    book_id="coding",
    packet_id="packet",
    packet_path="packet.json",
    status=@core.TaskExecutionStatus::Failed,
    summary="ExternalProposalPacket: context_pages must not be empty",
    output_contract="wiki.update",
    requires_review=true,
  )
  let outcome : @moonbook.PersistResultOutcome = @json.from_json(
    @json.parse(
      "{\"log_path\":\"/tmp/book/result.json\",\"updated_pages\":[\"wiki/index.md\"],\"review_queued\":true,\"notify_town\":false,\"evidence_id\":\"EV-goal-synthesis\"}",
    ),
  )
  let reconciled = execution_after_successful_book_persist(
    execution, outcome, 42,
  )
  assert_eq(reconciled.status, @core.TaskExecutionStatus::ReviewQueued)
  assert_true(reconciled.next_retry_tick == None)
  assert_eq(reconciled.result_decision, "persisted-review")
  assert_true(
    reconciled.summary.contains("keeper_auto_triage: persisted_terminal_result"),
  )
}

///|
test "successful non-review book persistence closes stale execution" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="goal-course",
    book_id="course",
    packet_id="packet",
    packet_path="packet.json",
    status=@core.TaskExecutionStatus::Stale,
    summary="missed heartbeat",
    output_contract="course.update",
  )
  let outcome : @moonbook.PersistResultOutcome = @json.from_json(
    @json.parse(
      "{\"log_path\":\"/tmp/book/result.json\",\"updated_pages\":[\"wiki/index.md\"],\"review_queued\":false,\"notify_town\":false,\"evidence_id\":\"EV-goal-course\"}",
    ),
  )
  let reconciled = execution_after_successful_book_persist(
    execution, outcome, 43,
  )
  assert_eq(reconciled.status, @core.TaskExecutionStatus::Completed)
  assert_eq(reconciled.result_decision, "persisted")
  assert_true(reconciled.summary.contains("persisted_evidence_id"))
}
