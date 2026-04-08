///|
fn keep_future_modes_alive() -> Unit {
  ignore(Research)
  ignore(Operations)
  ignore(Custom("custom"))
  ignore(Planner)
  ignore(Watcher)
  ignore(Waiting)
  ignore(WorkerStatus::Blocked)
  ignore(Offline)
  ignore(InProgress)
  ignore(TaskStatus::Blocked)
  ignore(Done)
  ignore(SharedTown)
  ignore(SharedWorkspace)
}

///|
pub fn demo_town() -> Town {
  keep_future_modes_alive()
  let town = new("moonrise")
  town.add_book(
    MoonbookHost::new(
      id="coding",
      name="Moonbook / Coding",
      purpose="Harness engineering for source work, repo memory, and execution policy.",
      workspace_root="/workspace/coding",
      memory_scope=BookPrivate,
      skills=["moonbit", "git", "testing", "review"],
    ),
  )
  town.add_book(
    MoonbookHost::new(
      id="finance",
      name="Moonbook / Finance",
      purpose="Private daily finance operations with isolated memory and task artifacts.",
      workspace_root="/workspace/finance",
      memory_scope=TaskEphemeral,
      skills=["ledgers", "ops", "planning", "reporting"],
    ),
  )
  town.add_worker(
    Worker::new(
      id="claw-harness",
      name="Harness Mayor",
      book_id="coding",
      role=Harness,
      skills=["moonbit", "git", "testing", "planning"],
      preferred_isolation=Worktree,
    ),
  )
  town.add_worker(
    Worker::new(
      id="claw-review",
      name="Review Owl",
      book_id="coding",
      role=Reviewer,
      skills=["review", "testing", "moonbit"],
      preferred_isolation=BookWorkspace,
    ),
  )
  town.add_worker(
    Worker::new(
      id="claw-ledger",
      name="Ledger Fox",
      book_id="finance",
      role=Specialist,
      skills=["ledgers", "planning", "reporting"],
      preferred_isolation=Worktree,
    ),
  )
  town.add_worker(
    Worker::new(
      id="claw-memory",
      name="Archive Cat",
      book_id="finance",
      role=MemoryKeeper,
      skills=["reporting", "ops", "planning"],
      preferred_isolation=BookWorkspace,
    ),
  )
  town.add_task(
    Task::new(
      id="task-town-layer",
      title="Implement town orchestration layer",
      summary="Host multiple moonbooks and route coding work to the right claw worker.",
      book_id="coding",
      domain=Coding,
      required_role=Some(Harness),
      required_skills=["moonbit", "git"],
    ),
  )
  town.add_task(
    Task::new(
      id="task-review-contract",
      title="Review delegation contract",
      summary="Check that the worker protocol is still safe for multi-book orchestration.",
      book_id="coding",
      domain=Coding,
      required_role=Some(Reviewer),
      required_skills=["review", "moonbit"],
    ),
  )
  town.add_task(
    Task::new(
      id="task-ledger-close",
      title="Close daily finance loop",
      summary="Summarize transactions, update balances, and prepare the next-day brief.",
      book_id="finance",
      domain=Finance,
      required_role=Some(Specialist),
      required_skills=["ledgers", "reporting"],
    ),
  )
  town.add_task(
    Task::new(
      id="task-finance-memory",
      title="Capture durable finance memories",
      summary="Store daily finance findings without leaking into the coding moonbook.",
      book_id="finance",
      domain=Finance,
      required_role=Some(MemoryKeeper),
      required_skills=["planning", "reporting"],
    ),
  )
  ignore(town.assign_backlog())
  town
}
