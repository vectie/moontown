///|
fn worker_count_test_worker(status : @core.WorkerStatus) -> WorkerSim {
  {
    id: "worker-\{status.to_string()}",
    title: "Runtime Worker",
    role: "test",
    book_id: "book",
    status,
    zone_key: "book-test",
    energy: 80,
    load: 20,
    summary: "test worker",
  }
}

///|
test "worker count summary empty has stable derived counts" {
  let summary = worker_count_summary_empty()
  assert_eq(summary.total, 0)
  assert_eq(summary.online(), 0)
  assert_eq(summary.idle, 0)
  assert_eq(summary.waiting, 0)
}

///|
test "worker count summary add increments exactly one status bucket" {
  let summary = worker_count_summary_empty()
    .add(worker_count_test_worker(Waiting))
    .add(worker_count_test_worker(Blocked))
  assert_eq(summary.total, 2)
  assert_eq(summary.waiting, 1)
  assert_eq(summary.blocked, 1)
  assert_eq(summary.running, 0)
  assert_eq(summary.online(), 2)
  assert_eq(summary.idle, 0)
  assert_eq(summary.waiting, 1)
}

///|
test "worker count summary covers every worker status" {
  let summary = worker_count_summary([
    worker_count_test_worker(Running),
    worker_count_test_worker(Running),
    worker_count_test_worker(Waiting),
    worker_count_test_worker(Idle),
    worker_count_test_worker(Blocked),
    worker_count_test_worker(Offline),
  ])
  assert_eq(summary.total, 6)
  assert_eq(summary.running, 2)
  assert_eq(summary.waiting, 1)
  assert_eq(summary.idle, 1)
  assert_eq(summary.blocked, 1)
  assert_eq(summary.offline, 1)
  assert_eq(summary.online(), 5)
  assert_eq(summary.idle, 1)
  assert_eq(summary.waiting, 1)
}
