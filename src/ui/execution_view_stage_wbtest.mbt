///|
test "execution view stage groups task execution statuses for UI surfaces" {
  assert_true(
    execution_view_stage_for_status(@core.TaskExecutionStatus::PacketReady)
    is ExecutionViewStage::Packet,
  )
  assert_true(
    execution_view_stage_for_status(@core.TaskExecutionStatus::ProposalImported)
    is ExecutionViewStage::Packet,
  )
  assert_true(
    execution_view_stage_for_status(@core.TaskExecutionStatus::RunConfirmed)
    is ExecutionViewStage::Running,
  )
  assert_true(
    execution_view_stage_for_status(@core.TaskExecutionStatus::Running)
    is ExecutionViewStage::Running,
  )
  assert_true(
    execution_view_stage_for_status(
      @core.TaskExecutionStatus::AwaitingPersistence,
    )
    is ExecutionViewStage::Persisting,
  )
  assert_true(
    execution_view_stage_for_status(@core.TaskExecutionStatus::ReviewQueued)
    is ExecutionViewStage::Review,
  )
  assert_true(
    execution_view_stage_for_status(@core.TaskExecutionStatus::Completed)
    is ExecutionViewStage::Completed,
  )
  assert_true(
    execution_view_stage_for_status(@core.TaskExecutionStatus::Failed)
    is ExecutionViewStage::Recovery,
  )
  assert_true(
    execution_view_stage_for_status(@core.TaskExecutionStatus::Stale)
    is ExecutionViewStage::Recovery,
  )
}
