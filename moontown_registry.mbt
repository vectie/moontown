///|
fn register_demo_books(
  state : @core.TownState,
  books : Array[@core.BookRef],
) -> Unit {
  for book in books {
    register_book_if_missing(state, book)
  }
}

///|
fn register_demo_workers(state : @core.TownState) -> Unit {
  register_worker_if_missing(
    state,
    @core.WorkerRef::new(
      id="claw-harness",
      name="Harness Hound",
      book_id="coding",
      role=@core.WorkerRole::Harness,
      capabilities=["moonbit", "git", "testing"],
    ),
  )
  register_worker_if_missing(
    state,
    @core.WorkerRef::new(
      id="claw-review",
      name="Review Owl",
      book_id="coding",
      role=@core.WorkerRole::Reviewer,
      capabilities=["review", "moonbit"],
    ),
  )
  register_worker_if_missing(
    state,
    @core.WorkerRef::new(
      id="claw-ledger",
      name="Ledger Fox",
      book_id="finance",
      role=@core.WorkerRole::Specialist,
      capabilities=["ledgers", "reporting"],
    ),
  )
  register_worker_if_missing(
    state,
    @core.WorkerRef::new(
      id="claw-memory",
      name="Archive Cat",
      book_id="finance",
      role=@core.WorkerRole::MemoryKeeper,
      capabilities=["reporting", "planning"],
    ),
  )
  for book in state.books {
    register_book_watch_worker(state, book)
    if book.id != "coding" && book.id != "finance" {
      register_book_lane_workers(state, book)
    }
  }
}

///|
fn register_book_watch_worker(
  state : @core.TownState,
  book : @core.BookRef,
) -> Unit {
  register_worker_if_missing(
    state,
    @core.WorkerRef::new(
      id="claw-\{book.id}-watcher",
      name="\{book.name} Watcher",
      book_id=book.id,
      role=@core.WorkerRole::Watcher,
      capabilities=[
        "standing-watch", "web-search", "source-screening", "delta-detection", "digest",
        "memory", "review",
      ],
    ),
  )
}

///|
fn register_book_lane_workers(
  state : @core.TownState,
  book : @core.BookRef,
) -> Unit {
  match @civic.wenyu_civic_service_for_book_id(book.id) {
    Some(service) =>
      register_worker_if_missing(
        state,
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
  register_book_watch_worker(state, book)
  register_worker_if_missing(
    state,
    @core.WorkerRef::new(
      id="claw-\{book.id}-harness",
      name="\{book.name} Harness",
      book_id=book.id,
      role=@core.WorkerRole::Harness,
      capabilities=[
        "research", "analysis", "implementation-planning", "coding", "code-patch",
        "asset-generation", "projection", "testing", "memory", "review",
      ],
    ),
  )
  register_worker_if_missing(
    state,
    @core.WorkerRef::new(
      id="claw-\{book.id}-specialist",
      name="\{book.name} Specialist",
      book_id=book.id,
      role=@core.WorkerRole::Specialist,
      capabilities=["asset-generation", "projection", "design", "research"],
    ),
  )
  register_worker_if_missing(
    state,
    @core.WorkerRef::new(
      id="claw-\{book.id}-review",
      name="\{book.name} Reviewer",
      book_id=book.id,
      role=@core.WorkerRole::Reviewer,
      capabilities=["review", "quality", "evidence"],
    ),
  )
}

///|
fn register_book_if_missing(
  state : @core.TownState,
  book : @core.BookRef,
) -> Unit {
  for existing in state.books {
    if existing.id == book.id {
      return
    }
  }
  state.register_book(book)
}

///|
fn register_worker_if_missing(
  state : @core.TownState,
  worker : @core.WorkerRef,
) -> Unit {
  for existing in state.workers {
    if existing.id == worker.id {
      return
    }
  }
  state.register_worker(worker)
}
