///|
test "unconfirmed watch dispatch is explicit and ends when a run is known" {
  let legacy = TaskExecutionRecord::new(
    task_id="standing-watch-demo-tick-1",
    book_id="demo",
    packet_id="packet",
    packet_path="packet.json",
    status=Running,
    summary="Pending dispatch",
    output_contract="standing-watch-live-snapshot",
  )
  assert_false(unconfirmed_standing_watch_dispatch(legacy))
  let pending = TaskExecutionRecord::new(
    task_id=legacy.task_id,
    book_id=legacy.book_id,
    packet_id=legacy.packet_id,
    packet_path=legacy.packet_path,
    status=Stale,
    summary=legacy.summary,
    output_contract=legacy.output_contract,
    result_decision=unconfirmed_standing_watch_decision(),
  )
  assert_true(unconfirmed_standing_watch_dispatch(pending))
  let known = TaskExecutionRecord::new(
    task_id=pending.task_id,
    book_id=pending.book_id,
    packet_id=pending.packet_id,
    packet_path=pending.packet_path,
    status=Running,
    summary=pending.summary,
    output_contract=pending.output_contract,
    run_id=Some("original-run"),
    result_decision=pending.result_decision,
  )
  assert_false(unconfirmed_standing_watch_dispatch(known))
}
