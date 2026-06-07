///|
async test "live autonomy surfaces transient infrastructure debt separately" {
  let workspace = live_autonomy_test_workspace(
    "/tmp/moontown-live-autonomy-transient-debt",
  )
  let snapshot_path = workspace.snapshot_path
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  state.register_execution(
    live_autonomy_execution_fixture(
      task_id="standing-watch-opc-news-tick-1",
      book_id="research-opc",
      packet_id="packet-transient",
      packet_path="/tmp/packet-transient.json",
      status=@core.TaskExecutionStatus::Completed,
      summary="import timed out",
      output_contract="standing-watch",
      result_decision="deferred-transient-infrastructure",
    ),
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    tick_summary="transient debt check",
  )
  assert_eq(spine.status, "watching")
  assert_eq(spine.failed_count, 0)
  assert_eq(spine.transient_infrastructure_debt_count, 1)
  let live_text = render_live_autonomy_status(snapshot_path~)
  assert_true(live_text.contains("Transient infrastructure debt: `1`"))
  let digest = read_text_or_empty(default_live_digest_path(snapshot_path~))
  assert_true(digest.contains("transient_infrastructure_debt: `1`"))
}
