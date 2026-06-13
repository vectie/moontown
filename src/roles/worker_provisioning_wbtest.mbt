///|
test "default town workers include coding and finance personas" {
  let workers = default_town_workers()
  assert_true(
    workers.any(fn(worker) {
      worker.id == "claw-harness" &&
      worker.book_id == "coding" &&
      worker.role == @core.WorkerRole::Harness &&
      worker.capabilities.contains("moonbit")
    }),
  )
  assert_true(
    workers.any(fn(worker) {
      worker.id == "claw-memory" &&
      worker.book_id == "finance" &&
      worker.role == @core.WorkerRole::MemoryKeeper &&
      worker.capabilities.contains("planning")
    }),
  )
}

///|
test "every book gets a standing watch worker" {
  let book = @core.BookRef::new(
    id="research-opc",
    name="OPC Research",
    purpose="research",
    workspace_root="/books/research-opc",
  )
  let worker = book_watch_worker(book)
  assert_eq(worker.id, "claw-research-opc-watcher")
  assert_eq(worker.book_id, "research-opc")
  assert_eq(worker.role, @core.WorkerRole::Watcher)
  assert_true(worker.capabilities.contains("standing-watch"))
  assert_true(worker.capabilities.contains("delta-detection"))
}

///|
test "civic books receive service-specific worker lane" {
  let book = @core.BookRef::new(
    id="wenyu-policy-hall",
    name="Policy Hall",
    purpose="civic",
    workspace_root="/books/wenyu-policy-hall",
  )
  let workers = book_lane_workers(book)
  assert_true(
    workers.any(fn(worker) {
      worker.id == "claw-wenyu-policy-hall-civic" &&
      worker.capabilities.contains("civic-service") &&
      worker.capabilities.contains("policy-service") &&
      worker.capabilities.contains("civic-policy-researcher")
    }),
  )
  assert_true(
    workers.any(fn(worker) {
      worker.id == "claw-wenyu-policy-hall-review" &&
      worker.role == @core.WorkerRole::Reviewer
    }),
  )
}

///|
test "town worker provisioning emits unique worker ids" {
  let books = [
    @core.BookRef::new(
      id="coding",
      name="Coding",
      purpose="coding",
      workspace_root="/books/coding",
    ),
    @core.BookRef::new(
      id="wenyu-policy-hall",
      name="Policy Hall",
      purpose="civic",
      workspace_root="/books/wenyu-policy-hall",
    ),
  ]
  let workers = town_workers_for_books(books)
  for index = 0; index < workers.length(); index = index + 1 {
    for other = index + 1; other < workers.length(); other = other + 1 {
      assert_true(workers[index].id != workers[other].id)
    }
  }
}
