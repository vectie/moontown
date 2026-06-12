///|
fn worker_visibility_test_worker(
  status? : @core.WorkerStatus = @core.WorkerStatus::Idle,
  role? : String = "worker",
  book_id? : String = "research",
  zone_key? : String = "book-research",
) -> WorkerSim {
  {
    id: "worker-\{status.to_string()}-\{role}",
    title: "Runtime Worker",
    role,
    book_id,
    status,
    zone_key,
    energy: 80,
    load: 20,
    summary: "test worker",
  }
}

///|
test "worker visibility separates working workers from idle workers" {
  assert_true(
    is_working_worker(
      worker_visibility_test_worker(status=@core.WorkerStatus::Running),
    ),
  )
  assert_true(
    is_working_worker(
      worker_visibility_test_worker(status=@core.WorkerStatus::Blocked),
    ),
  )
  assert_true(
    !is_working_worker(
      worker_visibility_test_worker(status=@core.WorkerStatus::Idle),
    ),
  )
}

///|
test "visible overworld workers keeps active workers and on-duty watchers" {
  let workers = [
    worker_visibility_test_worker(status=@core.WorkerStatus::Running),
    worker_visibility_test_worker(status=@core.WorkerStatus::Idle),
    worker_visibility_test_worker(
      status=@core.WorkerStatus::Idle,
      role="Standing Watcher",
    ),
  ]
  let visible = visible_overworld_workers(workers)
  assert_eq(visible.length(), 2)
  assert_eq(visible[0].status, @core.WorkerStatus::Running)
  assert_eq(visible[1].role, "Standing Watcher")
}

///|
test "worker node ownership explains every ownership route" {
  let direct = worker_visibility_test_worker(
    book_id="research",
    zone_key="city-hall",
  )
  assert_true(worker_node_ownership_for_key("city-hall", direct) is DirectZone)
  let book = worker_visibility_test_worker(
    book_id="research",
    zone_key="elsewhere",
  )
  assert_true(worker_node_ownership_for_key("book-research", book) is BookNode)
  assert_true(
    worker_node_ownership_for_key("lab-research-wing", book) is BookKeyMention,
  )
  assert_true(
    worker_node_ownership_for_key("worker-yard", book) is WorkerYardIdle,
  )
  let running = worker_visibility_test_worker(
    status=@core.WorkerStatus::Running,
    book_id="research",
    zone_key="elsewhere",
  )
  assert_true(worker_node_ownership_for_key("worker-yard", running) is NotOwned)
}
