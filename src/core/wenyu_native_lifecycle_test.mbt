///|
test "wenyu native execution counts without legacy run and cannot become stale by elapsed ticks" {
  let state = empty_state(TownConfig::new(id="synthetic", name="Synthetic"))
  let record = TaskExecutionRecord::new(
    task_id="wenyu-task",
    book_id="book",
    packet_id="town-work-synthetic",
    packet_path="/synthetic/manifest",
    status=Running,
    summary="Native awaiting approval",
    output_contract="wenyu.build.native-result.v1",
    heartbeat_tick=1,
    stale_after_tick=2,
  )
  state.replace_execution(record)
  assert_eq(live_external_execution_count(state), 1)
  assert_false(no_run_id_live_execution_stale(record, 100000))
}
