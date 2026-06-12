///|
test "snapshot worker profile centralizes persisted worker load and energy" {
  let running = snapshot_worker_profile(@core.WorkerStatus::Running)
  assert_eq(running.load, 74)
  assert_eq(running.energy, 64)
  let waiting = snapshot_worker_profile(@core.WorkerStatus::Waiting)
  assert_eq(waiting.load, 28)
  assert_eq(waiting.energy, 79)
  let idle = snapshot_worker_profile(@core.WorkerStatus::Idle)
  assert_eq(idle.load, 16)
  assert_eq(idle.energy, 88)
  let blocked = snapshot_worker_profile(@core.WorkerStatus::Blocked)
  assert_eq(blocked.load, 91)
  assert_eq(blocked.energy, 38)
  let offline = snapshot_worker_profile(@core.WorkerStatus::Offline)
  assert_eq(offline.load, 0)
  assert_eq(offline.energy, 0)
}
