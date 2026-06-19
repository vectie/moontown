///|
test "execution view stage groups task execution statuses for UI surfaces" {
  assert_true(execution_view_stage_for_status(PacketReady) is Packet)
  assert_true(execution_view_stage_for_status(ProposalImported) is Packet)
  assert_true(execution_view_stage_for_status(RunConfirmed) is Running)
  assert_true(execution_view_stage_for_status(Running) is Running)
  assert_true(
    execution_view_stage_for_status(AwaitingPersistence) is Persisting,
  )
  assert_true(execution_view_stage_for_status(ReviewQueued) is Review)
  assert_true(execution_view_stage_for_status(Completed) is Completed)
  assert_true(execution_view_stage_for_status(Failed) is Recovery)
  assert_true(execution_view_stage_for_status(Stale) is Recovery)
}
