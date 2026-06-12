///|
test "worker strategy cycle status names the three runtime cadence policies" {
  assert_eq(
    worker_strategy_cycle_status(Strategy::Balanced, 0),
    @core.WorkerStatus::Running,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Balanced, 1),
    @core.WorkerStatus::Waiting,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Balanced, 8),
    @core.WorkerStatus::Idle,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Throughput, 1),
    @core.WorkerStatus::Running,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Throughput, 2),
    @core.WorkerStatus::Waiting,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Throughput, 7),
    @core.WorkerStatus::Idle,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Recovery, 0),
    @core.WorkerStatus::Idle,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Recovery, 2),
    @core.WorkerStatus::Running,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Recovery, 7),
    @core.WorkerStatus::Waiting,
  )
}

///|
test "worker status for applies mayor recovery and pressure overrides before strategy" {
  let model = init_model()
  assert_eq(
    worker_status_for({ ..model, strategy: Strategy::Throughput, tick: 0 }, 0),
    @core.WorkerStatus::Running,
  )
  assert_eq(
    worker_status_for({ ..model, stability: 20, tick: 0 }, 2),
    @core.WorkerStatus::Idle,
  )
  assert_eq(
    worker_status_for({ ..model, pressure: 90, tick: 0 }, 1),
    @core.WorkerStatus::Waiting,
  )
}
