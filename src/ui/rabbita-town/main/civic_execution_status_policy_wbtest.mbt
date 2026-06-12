///|
test "civic execution stage centralizes task execution status groups" {
  assert_true(
    civic_execution_stage(@core.TaskExecutionStatus::PacketReady)
    is @ui.ExecutionViewStage::Packet,
  )
  assert_true(
    civic_execution_stage(@core.TaskExecutionStatus::ProposalImported)
    is @ui.ExecutionViewStage::Packet,
  )
  assert_true(
    civic_execution_stage(@core.TaskExecutionStatus::RunConfirmed)
    is @ui.ExecutionViewStage::Running,
  )
  assert_true(
    civic_execution_stage(@core.TaskExecutionStatus::Running)
    is @ui.ExecutionViewStage::Running,
  )
  assert_true(
    civic_execution_stage(@core.TaskExecutionStatus::AwaitingPersistence)
    is @ui.ExecutionViewStage::Persisting,
  )
  assert_true(
    civic_execution_stage(@core.TaskExecutionStatus::ReviewQueued)
    is @ui.ExecutionViewStage::Review,
  )
  assert_true(
    civic_execution_stage(@core.TaskExecutionStatus::Completed)
    is @ui.ExecutionViewStage::Completed,
  )
  assert_true(
    civic_execution_stage(@core.TaskExecutionStatus::Failed)
    is @ui.ExecutionViewStage::Recovery,
  )
  assert_true(
    civic_execution_stage(@core.TaskExecutionStatus::Stale)
    is @ui.ExecutionViewStage::Recovery,
  )
}

///|
fn civic_execution_policy_test_execution(
  status : @core.TaskExecutionStatus,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id="task",
    book_id="book",
    packet_id="packet",
    packet_path="packet.json",
    status~,
    summary="test",
    output_contract="contract",
  )
}

///|
fn civic_execution_policy_test_task(prompt : String) -> @core.TownTask {
  @core.TownTask::new(
    id="task",
    book_id="book",
    title="Test task",
    prompt~,
    domain=@core.WorkDomain::SocialExperiment,
  )
}

///|
fn civic_execution_policy_test_phrases() -> CivicExecutionStagePhrases {
  {
    packet: "packet",
    running: "running",
    persisting: "persisting",
    review: "review",
    completed: "completed",
    recovery: "recovery",
  }
}

///|
test "civic execution stage label centralizes status groups" {
  let phrases = civic_execution_policy_test_phrases()
  assert_eq(
    civic_execution_stage_label_for_status(
      @core.TaskExecutionStatus::PacketReady,
      phrases,
    ),
    "packet",
  )
  assert_eq(
    civic_execution_stage_label_for_status(
      @core.TaskExecutionStatus::ProposalImported,
      phrases,
    ),
    "packet",
  )
  assert_eq(
    civic_execution_stage_label_for_status(
      @core.TaskExecutionStatus::RunConfirmed,
      phrases,
    ),
    "running",
  )
  assert_eq(
    civic_execution_stage_label_for_status(
      @core.TaskExecutionStatus::Running,
      phrases,
    ),
    "running",
  )
  assert_eq(
    civic_execution_stage_label_for_status(
      @core.TaskExecutionStatus::AwaitingPersistence,
      phrases,
    ),
    "persisting",
  )
  assert_eq(
    civic_execution_stage_label_for_status(
      @core.TaskExecutionStatus::ReviewQueued,
      phrases,
    ),
    "review",
  )
  assert_eq(
    civic_execution_stage_label_for_status(
      @core.TaskExecutionStatus::Completed,
      phrases,
    ),
    "completed",
  )
  assert_eq(
    civic_execution_stage_label_for_status(
      @core.TaskExecutionStatus::Failed,
      phrases,
    ),
    "recovery",
  )
  assert_eq(
    civic_execution_stage_label_for_status(
      @core.TaskExecutionStatus::Stale,
      phrases,
    ),
    "recovery",
  )
}

///|
test "civic execution stage label preserves fallback when no execution exists" {
  let phrases = civic_execution_policy_test_phrases()
  assert_eq(
    civic_execution_stage_label(None, phrases, fallback="fallback"),
    "fallback",
  )
}

///|
test "civic projected execution stage label centralizes snapshot fallback" {
  let phrases = civic_execution_policy_test_phrases()
  assert_eq(
    civic_projected_execution_stage_label(
      StateSourceKind::SnapshotFile,
      Some(
        civic_execution_policy_test_execution(
          @core.TaskExecutionStatus::Running,
        ),
      ),
      phrases,
      projection_fallback="projection fallback",
      fallback="live fallback",
    ),
    "projection fallback",
  )
  assert_eq(
    civic_projected_execution_stage_label(
      StateSourceKind::DemoSimulation,
      Some(
        civic_execution_policy_test_execution(
          @core.TaskExecutionStatus::Running,
        ),
      ),
      phrases,
      projection_fallback="projection fallback",
      fallback="live fallback",
    ),
    "running",
  )
  assert_eq(
    civic_projected_execution_stage_label(
      StateSourceKind::DemoSimulation,
      None,
      phrases,
      projection_fallback="projection fallback",
      fallback="live fallback",
    ),
    "live fallback",
  )
}

///|
test "civic execution action label reuses execution status grouping" {
  let phrases : CivicExecutionActionPhrases = {
    packet: "packet action",
    running: "running action",
    persisting: "persisting action",
    review: "review action",
    completed: "completed action",
    recovery: "recovery action",
  }
  assert_eq(
    civic_execution_action_label(
      Some(
        civic_execution_policy_test_execution(
          @core.TaskExecutionStatus::ProposalImported,
        ),
      ),
      phrases,
      fallback="fallback",
    ),
    "packet action",
  )
  assert_eq(
    civic_execution_action_label(
      Some(
        civic_execution_policy_test_execution(
          @core.TaskExecutionStatus::ReviewQueued,
        ),
      ),
      phrases,
      fallback="fallback",
    ),
    "review action",
  )
  assert_eq(
    civic_execution_action_label(None, phrases, fallback="fallback"),
    "fallback",
  )
}

///|
test "civic execution signal label reuses execution status grouping" {
  let phrases : CivicExecutionSignalPhrases = {
    packet: "packet signal",
    running: "running signal",
    persisting: "persisting signal",
    review: "review signal",
    completed: "completed signal",
    recovery: "recovery signal",
  }
  assert_eq(
    civic_execution_signal_label(
      Some(
        civic_execution_policy_test_execution(
          @core.TaskExecutionStatus::PacketReady,
        ),
      ),
      phrases,
      fallback="fallback",
    ),
    "packet signal",
  )
  assert_eq(
    civic_execution_signal_label(
      Some(
        civic_execution_policy_test_execution(@core.TaskExecutionStatus::Failed),
      ),
      phrases,
      fallback="fallback",
    ),
    "recovery signal",
  )
  assert_eq(
    civic_execution_signal_label(None, phrases, fallback="fallback"),
    "fallback",
  )
}

///|
test "civic signal phrases centralizes common module defaults" {
  let phrases = civic_signal_phrases(
    running="running signal",
    persisting="persisting signal",
    review="review signal",
    completed="completed signal",
  )
  assert_eq(
    civic_execution_stage_label_for_status(
      @core.TaskExecutionStatus::PacketReady,
      phrases,
    ),
    "Dispatching",
  )
  assert_eq(
    civic_execution_stage_label_for_status(
      @core.TaskExecutionStatus::Failed,
      phrases,
    ),
    "Needs recovery",
  )
}

///|
test "civic signal phrases allows module-specific dispatch labels" {
  let phrases = civic_signal_phrases(
    packet="Build dispatch",
    running="Build live",
    persisting="Patch awaiting persistence",
    review="Patch review queued",
    completed="Patch landed",
  )
  assert_eq(
    civic_execution_stage_label_for_status(
      @core.TaskExecutionStatus::ProposalImported,
      phrases,
    ),
    "Build dispatch",
  )
}

///|
test "civic projected execution signal label centralizes snapshot bridge fallback" {
  let phrases : CivicExecutionSignalPhrases = {
    packet: "packet signal",
    running: "running signal",
    persisting: "persisting signal",
    review: "review signal",
    completed: "completed signal",
    recovery: "recovery signal",
  }
  assert_eq(
    civic_projected_execution_signal_label(
      StateSourceKind::SnapshotFile,
      Some(
        civic_execution_policy_test_execution(
          @core.TaskExecutionStatus::Running,
        ),
      ),
      phrases,
      fallback="fallback",
    ),
    "Projection bridge",
  )
  assert_eq(
    civic_projected_execution_signal_label(
      StateSourceKind::DemoSimulation,
      Some(
        civic_execution_policy_test_execution(
          @core.TaskExecutionStatus::Running,
        ),
      ),
      phrases,
      fallback="fallback",
    ),
    "running signal",
  )
  assert_eq(
    civic_projected_execution_signal_label(
      StateSourceKind::DemoSimulation,
      None,
      phrases,
      fallback="fallback",
    ),
    "fallback",
  )
}

///|
test "civic task prompt fallback centralizes task override behavior" {
  assert_eq(
    civic_task_prompt_or_fallback(
      Some(civic_execution_policy_test_task("operator requested action")),
      fallback="module fallback",
    ),
    "operator requested action",
  )
  assert_eq(
    civic_task_prompt_or_fallback(None, fallback="module fallback"),
    "module fallback",
  )
}

///|
test "civic projected task fallback centralizes source-aware no-task copy" {
  assert_eq(
    civic_task_prompt_or_projected_fallback(
      StateSourceKind::SnapshotFile,
      None,
      projection_fallback="projection copy",
      fallback="live copy",
    ),
    "projection copy",
  )
  assert_eq(
    civic_task_prompt_or_projected_fallback(
      StateSourceKind::DemoSimulation,
      None,
      projection_fallback="projection copy",
      fallback="live copy",
    ),
    "live copy",
  )
  assert_eq(
    civic_task_prompt_or_projected_fallback(
      StateSourceKind::SnapshotFile,
      Some(civic_execution_policy_test_task("task copy wins")),
      projection_fallback="projection copy",
      fallback="live copy",
    ),
    "task copy wins",
  )
}

///|
test "civic execution score reuses execution status grouping" {
  let policy : CivicExecutionScorePolicy = {
    packet: 10,
    running: 20,
    persisting: 30,
    review: 40,
    completed: 50,
    recovery: 60,
  }
  assert_eq(
    civic_execution_score(
      Some(
        civic_execution_policy_test_execution(
          @core.TaskExecutionStatus::ProposalImported,
        ),
      ),
      policy,
      fallback=0,
    ),
    10,
  )
  assert_eq(
    civic_execution_score(
      Some(
        civic_execution_policy_test_execution(
          @core.TaskExecutionStatus::Running,
        ),
      ),
      policy,
      fallback=0,
    ),
    20,
  )
  assert_eq(
    civic_execution_score(
      Some(
        civic_execution_policy_test_execution(@core.TaskExecutionStatus::Stale),
      ),
      policy,
      fallback=0,
    ),
    60,
  )
  assert_eq(civic_execution_score(None, policy, fallback=7), 7)
}
