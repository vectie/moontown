///|
async test "supervision does not keep unpolled running snapshot alive forever" {
  let state = goal_supervision_test_state()
  state.enqueue_task(
    running_standing_watch_task(
      "standing-watch-opc-news-tick-4050", "research-opc",
    ),
  )
  state.register_execution(
    running_snapshot_execution_without_run_id(
      "standing-watch-opc-news-tick-4050", "research-opc", "running snapshot without durable MoonClaw run",
      1, 1,
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [])
  assert_eq(state.executions[0].status, Completed)
  assert_true(state.executions[0].summary.contains("no run id"))
  assert_eq(
    state.executions[0].result_decision,
    "deferred-transient-infrastructure",
  )
}

///|
async test "supervision uses short no-run-id window for restart residue" {
  let state = goal_supervision_test_state()
  state.enqueue_task(
    running_standing_watch_task(
      "standing-watch-opc-news-tick-100", "research-opc",
    ),
  )
  state.register_execution(
    running_snapshot_execution_without_run_id(
      "standing-watch-opc-news-tick-100", "research-opc", "running snapshot written before detached import finished",
      100, 220,
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [], tick=Some(115))
  assert_eq(state.executions[0].status, Completed)
  assert_true(state.executions[0].summary.contains("no run id"))
  assert_eq(
    state.executions[0].result_decision,
    "deferred-transient-infrastructure",
  )
}

///|
async test "no run id live execution closes after stale window" {
  let state = goal_supervision_test_state()
  let execution = standing_watch_execution_fixture(
    task_id="standing-watch-llm-training-tick-10",
    book_id="research-llm",
    packet_path="/tmp/missing-packet.json",
    status=Running,
    summary="old live snapshot",
    heartbeat_tick=10,
    stale_after_tick=12,
  )
  state.register_execution(execution)
  reconcile_no_run_id_live_execution(state, execution, 13)
  assert_eq(state.executions[0].status, Failed)
  assert_true(state.executions[0].summary.contains("no run id"))
  assert_eq(state.executions[0].result_decision, "deferred")
  assert_eq(state.executions[0].requires_review, false)
}

///|
async test "stale detached import failure keeps MoonClaw stderr evidence" {
  let root = cleaned_goal_supervision_test_root(
    "/tmp/moontown-detached-import-stderr-wbtest",
  )
  let packet_path = "\{root}/packets/packet.json"
  let stderr =
    $|RUNTIME ERROR: abort() called
    $|deprecated.mbt:62 at @moonbitlang/core/builtin.StringBuilder::grow_if_necessary
    $|/workspace/external/moonclaw/job/system_storage.mbt:886 by @vectie/moonclaw/job.SystemStore::save_job_proposals

  @support.write_text_file(packet_path + ".import.json.err", stderr)
  let state = goal_supervision_test_state()
  let execution = standing_watch_execution_fixture(
    task_id="standing-watch-llm-training-tick-10",
    book_id="research-llm",
    packet_path~,
    status=ProposalImported,
    summary="old live snapshot",
    heartbeat_tick=10,
    stale_after_tick=12,
  )
  state.register_execution(execution)
  reconcile_no_run_id_live_execution(state, execution, 13)
  assert_eq(state.executions[0].status, Failed)
  assert_true(state.executions[0].summary.contains("Detached import stderr:"))
  assert_true(
    state.executions[0].summary.contains("StringBuilder::grow_if_necessary"),
  )
  assert_true(
    state.executions[0].summary.contains("SystemStore::save_job_proposals"),
  )
}
