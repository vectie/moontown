///|
pub fn default_town_workers() -> Array[@core.WorkerRef] {
  [
    @core.WorkerRef::new(
      id="claw-harness",
      name="Harness Hound",
      book_id="coding",
      role=Harness,
      capabilities=["moonbit", "git", "testing"],
    ),
    @core.WorkerRef::new(
      id="claw-review",
      name="Review Owl",
      book_id="coding",
      role=Reviewer,
      capabilities=["review", "moonbit"],
    ),
    @core.WorkerRef::new(
      id="claw-ledger",
      name="Ledger Fox",
      book_id="finance",
      role=Specialist,
      capabilities=["ledgers", "reporting"],
    ),
    @core.WorkerRef::new(
      id="claw-memory",
      name="Archive Cat",
      book_id="finance",
      role=MemoryKeeper,
      capabilities=["reporting", "planning"],
    ),
  ]
}

///|
pub fn book_watch_worker(book : @core.BookRef) -> @core.WorkerRef {
  @core.WorkerRef::new(
    id="claw-\{book.id}-watcher",
    name="\{book.name} Watcher",
    book_id=book.id,
    role=Watcher,
    capabilities=[
      "standing-watch", "web-search", "source-screening", "delta-detection", "digest",
      "memory", "review",
    ],
  )
}

///|
pub fn book_lane_workers(book : @core.BookRef) -> Array[@core.WorkerRef] {
  let workers = []
  match @civic.wenyu_civic_service_for_book_id(book.id) {
    Some(service) =>
      workers.push(
        @core.WorkerRef::new(
          id="claw-\{book.id}-civic",
          name="\{service.title} Civic Worker",
          book_id=book.id,
          role=service.worker_role,
          capabilities=[
            "civic-service",
            service.service_kind,
            service.skill_pack,
            "review-gate",
            "projection",
          ],
        ),
      )
    None => ()
  }
  workers.push(book_watch_worker(book))
  workers.push(
    @core.WorkerRef::new(
      id="claw-\{book.id}-harness",
      name="\{book.name} Harness",
      book_id=book.id,
      role=Harness,
      capabilities=[
        "research", "analysis", "implementation-planning", "coding", "code-patch",
        "asset-generation", "projection", "testing", "memory", "review",
      ],
    ),
  )
  workers.push(
    @core.WorkerRef::new(
      id="claw-\{book.id}-specialist",
      name="\{book.name} Specialist",
      book_id=book.id,
      role=Specialist,
      capabilities=["asset-generation", "projection", "design", "research"],
    ),
  )
  workers.push(
    @core.WorkerRef::new(
      id="claw-\{book.id}-review",
      name="\{book.name} Reviewer",
      book_id=book.id,
      role=Reviewer,
      capabilities=["review", "quality", "evidence"],
    ),
  )
  workers
}

///|
pub fn town_workers_for_books(
  books : Array[@core.BookRef],
) -> Array[@core.WorkerRef] {
  let workers = []
  for worker in default_town_workers() {
    workers.push(worker)
  }
  for book in books {
    if book.id != "coding" && book.id != "finance" {
      for worker in book_lane_workers(book) {
        workers.push(worker)
      }
    } else {
      workers.push(book_watch_worker(book))
    }
  }
  workers
}
