///|
test "moonclaw supervision seconds parser accepts zero for nonblocking mode" {
  assert_eq(parse_non_negative_seconds("900", fallback=0), 900)
  assert_eq(parse_non_negative_seconds(" 1800 ", fallback=0), 1800)
  assert_eq(parse_non_negative_seconds("0", fallback=3600), 0)
  assert_eq(parse_non_negative_seconds("", fallback=3600), 3600)
  assert_eq(parse_non_negative_seconds("10m", fallback=3600), 3600)
}

///|
test "moonclaw import timeout defaults to bounded daemon work" {
  assert_eq(moontown_moonclaw_import_timeout_ms(), 20_000)
  assert_eq(
    @runtime_error_policy.transient_external_dependency_error(
      "Moontown external import timed out while importing MoonClaw proposal.",
    ),
    true,
  )
}

///|
test "successful book persistence reconciles failed execution into review queue" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="goal-synthesis",
    book_id="coding",
    packet_id="packet",
    packet_path="packet.json",
    status=Failed,
    summary="ExternalProposalPacket: context_pages must not be empty",
    output_contract="wiki.update",
    requires_review=true,
  )
  let outcome = recovered_persist_result_outcome(
    "coding",
    @moonbook.BookResult::new(
      result_id="goal-synthesis",
      summary="Synthesis persisted but requires keeper review.",
      artifacts=["wiki/index.md"],
      requires_review=true,
    ),
    evidence_id="EV-goal-synthesis",
  )
  let reconciled = execution_after_successful_book_persist(
    execution, outcome, 42,
  )
  assert_eq(reconciled.status, ReviewQueued)
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
    status=Stale,
    summary="missed heartbeat",
    output_contract="course.update",
  )
  let outcome = recovered_persist_result_outcome(
    "course",
    @moonbook.BookResult::new(
      result_id="goal-course",
      summary="Course bootstrap persisted with durable artifacts.",
      artifacts=["wiki/index.md"],
      requires_review=false,
    ),
    evidence_id="EV-goal-course",
  )
  let reconciled = execution_after_successful_book_persist(
    execution, outcome, 43,
  )
  assert_eq(reconciled.status, Completed)
  assert_eq(reconciled.result_decision, "persisted")
  assert_true(reconciled.summary.contains("persisted_evidence_id"))
}
