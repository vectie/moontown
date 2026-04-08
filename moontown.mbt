///|
fn planned_event(
  decision : @dispatch.RouteDecision,
  index : Int,
) -> @core.TownEvent {
  match decision {
    Assigned(plan) =>
      @core.TownEvent::new(
        id="event-\{index}",
        kind="assignment",
        detail="\{plan.task_id} -> \{plan.worker_id} (\{plan.reason})",
        related_task_id=Some(plan.task_id),
        related_book_id=Some(plan.book_id),
      )
    Escalated(reason) =>
      @core.TownEvent::new(
        id="event-\{index}",
        kind="escalation",
        detail=reason,
      )
    Deferred(reason) =>
      @core.TownEvent::new(id="event-\{index}", kind="deferred", detail=reason)
  }
}

///|
fn seed_dispatch_events(state : @core.TownState) -> Unit {
  for i in 0..<state.tasks.length() {
    let task = state.tasks[i]
    let decision = @dispatch.route_task(
      state,
      @dispatch.RouteRequest::new(task~),
    )
    state.record_event(planned_event(decision, i))
  }
}

///|
pub fn demo_state() -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  state.register_book(
    @core.BookRef::new(
      id="coding",
      name="Moonbook / Coding",
      purpose="Harness engineering for source work, repo memory, and execution policy.",
      workspace_root="/workspace/coding",
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["moonbit", "git", "review"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="finance",
      name="Moonbook / Finance",
      purpose="Private daily finance operations with isolated memory and task artifacts.",
      workspace_root="/workspace/finance",
      memory_scope=@core.MemoryScope::TaskEphemeral,
      tags=["ledger", "planning", "ops"],
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-harness",
      name="Harness Mayor",
      book_id="coding",
      role=@core.WorkerRole::Harness,
      capabilities=["moonbit", "git", "testing"],
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-review",
      name="Review Owl",
      book_id="coding",
      role=@core.WorkerRole::Reviewer,
      capabilities=["review", "moonbit"],
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-ledger",
      name="Ledger Fox",
      book_id="finance",
      role=@core.WorkerRole::Specialist,
      capabilities=["ledgers", "reporting"],
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="claw-memory",
      name="Archive Cat",
      book_id="finance",
      role=@core.WorkerRole::MemoryKeeper,
      capabilities=["reporting", "planning"],
    ),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="task-town-layer",
      book_id="coding",
      title="Implement town orchestration layer",
      prompt="Host multiple moonbooks and route coding work to the right claw worker.",
      domain=@core.WorkDomain::Coding,
      required_role=Some(@core.WorkerRole::Harness),
      required_capabilities=["moonbit", "git"],
    ),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="task-review-contract",
      book_id="coding",
      title="Review delegation contract",
      prompt="Check that the worker protocol is still safe for multi-book orchestration.",
      domain=@core.WorkDomain::Coding,
      required_role=Some(@core.WorkerRole::Reviewer),
      required_capabilities=["review", "moonbit"],
    ),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="task-ledger-close",
      book_id="finance",
      title="Close daily finance loop",
      prompt="Summarize transactions, update balances, and prepare the next-day brief.",
      domain=@core.WorkDomain::Finance,
      required_role=Some(@core.WorkerRole::Specialist),
      required_capabilities=["ledgers", "reporting"],
    ),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="task-finance-memory",
      book_id="finance",
      title="Capture durable finance memories",
      prompt="Store daily finance findings without leaking into the coding moonbook.",
      domain=@core.WorkDomain::Finance,
      required_role=Some(@core.WorkerRole::MemoryKeeper),
      required_capabilities=["planning", "reporting"],
    ),
  )
  seed_dispatch_events(state)
  state
}

///|
pub fn demo_dashboard() -> String {
  let state = demo_state()
  let report = @health.inspect_town(state)
  let model = @ui.build_dashboard(state, report)
  let tick = @scheduler.next_tick(1, @scheduler.plan_tick(state, report))
  let snapshot = @storage.snapshot_of(state)
  @ui.render_dashboard(model) +
  "\nTown Tick\n- \{tick.summary}\n\nSnapshot\n- \{@storage.describe_snapshot(snapshot)}\n"
}

///|
pub async fn load_or_create_demo_state(
  path? : String = @storage.default_snapshot_path(),
) -> @core.TownState {
  let snapshot = @storage.load_or_create_snapshot(path, demo_state)
  snapshot.town
}

///|
pub async fn load_or_create_demo_dashboard(
  path? : String = @storage.default_snapshot_path(),
) -> String {
  let state = load_or_create_demo_state(path~)
  let report = @health.inspect_town(state)
  let model = @ui.build_dashboard(state, report)
  let tick = @scheduler.next_tick(1, @scheduler.plan_tick(state, report))
  let snapshot = @storage.snapshot_of(state)
  @ui.render_dashboard(model) +
  "\nTown Tick\n- \{tick.summary}\n\nSnapshot\n- \{@storage.describe_snapshot(snapshot)}\n"
}
