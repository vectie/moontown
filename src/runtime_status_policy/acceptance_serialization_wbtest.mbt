///|
test "runtime acceptance count dedupes approved review and stale live snapshots" {
  let state = runtime_status_policy_test_state()
  state.register_execution(
    runtime_status_policy_test_execution(
      "task-approved",
      ReviewQueued,
      packet_id="review",
    ),
  )
  state.register_execution(
    runtime_status_policy_test_execution(
      "task-approved",
      AwaitingAcceptance,
      packet_id="approved",
    ),
  )
  state.register_execution(
    runtime_status_policy_test_execution(
      "task-approved",
      AwaitingAcceptance,
      packet_id="approved-latest",
    ),
  )
  state.register_execution(
    runtime_status_policy_test_execution(
      "task-approved",
      Running,
      packet_id="old-running",
    ),
  )
  let indexes = effective_execution_indexes(state)
  assert_eq(indexes.length(), 1)
  assert_eq(indexes[0], 2)
  let counts = runtime_status_execution_counts(
    state,
    @health.inspect_town(state),
  )
  assert_eq(counts.awaiting_acceptance, 1)
  assert_eq(counts.running, 0)
  assert_eq(counts.review, 0)
  assert_eq(counts.completed, 0)
  assert_true(
    runtime_status_execution_summary(counts).contains("awaiting_acceptance=1"),
  )
}

///|
test "legacy runtime status JSON omits acceptance count and still decodes as zero" {
  let empty = empty_runtime_status("/tmp/legacy-town.json")
  assert_eq(empty.awaiting_acceptance_count, Some(0))
  let encoded = empty.to_json()
  guard encoded is Object(fields) else { fail("expected status object") }
  assert_eq(fields.get("awaiting_acceptance_count"), Some((0 : Int).to_json()))
  ignore(fields.remove("awaiting_acceptance_count"))
  let legacy : TownRuntimeStatus = @json.from_json(encoded)
  assert_eq(legacy.awaiting_acceptance_count, None)
  assert_eq(legacy.awaiting_acceptance_count.unwrap_or(0), 0)
  assert_eq(legacy.snapshot_path, empty.snapshot_path)
  assert_eq(legacy.running_count, empty.running_count)
  assert_eq(legacy.review_count, empty.review_count)
  assert_eq(legacy.completed_count, empty.completed_count)
  let report = render_runtime_status_report(
    legacy,
    daemon_id="legacy",
    saved_tick=0,
    lease_owner="mayor",
    daemon_job_count=0,
    runtime_health_summary="healthy",
  )
  assert_true(report.contains("awaiting_acceptance=0"))
}

///|
test "new runtime status JSON explicitly roundtrips acceptance count" {
  let status = {
    ..empty_runtime_status("/tmp/town.json"),
    awaiting_acceptance_count: Some(2),
  }
  let encoded = status.to_json()
  guard encoded is Object(fields) else { fail("expected status object") }
  assert_eq(fields.get("awaiting_acceptance_count"), Some((2 : Int).to_json()))
  let decoded : TownRuntimeStatus = @json.from_json(encoded)
  assert_eq(decoded, status)
  let report = render_runtime_status_report(
    decoded,
    daemon_id="acceptance",
    saved_tick=0,
    lease_owner="mayor",
    daemon_job_count=0,
    runtime_health_summary="healthy",
  )
  assert_true(report.contains("awaiting_acceptance=2"))
}
