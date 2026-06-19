///|
test "worker strategy cycle status names the three runtime cadence policies" {
  assert_eq(
    worker_strategy_cycle_status(Strategy::Balanced, 0),
    Running,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Balanced, 1),
    Waiting,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Balanced, 8),
    Idle,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Throughput, 1),
    Running,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Throughput, 2),
    Waiting,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Throughput, 7),
    Idle,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Recovery, 0),
    Idle,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Recovery, 2),
    Running,
  )
  assert_eq(
    worker_strategy_cycle_status(Strategy::Recovery, 7),
    Waiting,
  )
}

///|
test "worker status for applies mayor recovery and pressure overrides before strategy" {
  let model = init_model()
  assert_eq(
    worker_status_for({ ..model, strategy: Strategy::Throughput, tick: 0 }, 0),
    Running,
  )
  assert_eq(
    worker_status_for({ ..model, stability: 20, tick: 0 }, 2),
    Idle,
  )
  assert_eq(
    worker_status_for({ ..model, pressure: 90, tick: 0 }, 1),
    Waiting,
  )
}
