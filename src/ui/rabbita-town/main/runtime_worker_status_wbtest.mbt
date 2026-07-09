///|
test "worker operating cycle keeps running waiting and idle coverage" {
  assert_eq(worker_operating_cycle_status(0), Running)
  assert_eq(worker_operating_cycle_status(1), Waiting)
  assert_eq(worker_operating_cycle_status(8), Idle)
}

///|
test "worker status for applies mayor recovery and pressure overrides before operating cycle" {
  let model = init_model()
  assert_eq(worker_status_for({ ..model, tick: 0 }, 0), Running)
  assert_eq(
    worker_status_for({ ..model, stability: 20, tick: 0 }, 2),
    Idle,
  )
  assert_eq(
    worker_status_for({ ..model, pressure: 90, tick: 0 }, 1),
    Waiting,
  )
}
