///|
fn demo_state(model : Model) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(
      id="wenyu-valley",
      name="Wenyu Valley / AI Innovation Town",
      heartbeat_seconds=30,
      max_concurrent_tasks=24,
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="wenyu-town-shell",
      name="Town Shell",
      purpose="Owns the live district shell, runtime projection contract, and operator-facing Wenyu map.",
      workspace_root="/town/wenyu-town-shell",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["projection", "ui", "shell"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="wenyu-resident-twins",
      name="Resident Twins",
      purpose="Projects resident identity, memory summaries, reflection loops, privacy scope, and next actions into the town view.",
      workspace_root="/town/wenyu-resident-twins",
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["resident-twins", "memory", "projection"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="policy-hall",
      name="Policy Release Hall",
      purpose="Turns policy documents into quest lines, advisor answers, and application checklists.",
      workspace_root="/town/policy-hall",
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["policy", "quest", "advisor"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="wenyu-contest-express",
      name="Contest Express",
      purpose="Turns contest participation into a nurturing lane with countdowns, readiness reviews, mock judging, and champion replay hooks.",
      workspace_root="/town/wenyu-contest-express",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["contest", "roadshow", "readiness"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="social-square",
      name="Social Square",
      purpose="Maintains weak-tie matching, activity initiation, and collaboration loops.",
      workspace_root="/town/social-square",
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["matching", "events", "community"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="talent-avenue",
      name="Talent Star Avenue",
      purpose="Projects resident talent cards, skills heatmaps, and reception tours.",
      workspace_root="/town/talent-avenue",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["talent", "graph", "showcase"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="ai-garden",
      name="AI Science Garden",
      purpose="Runs AI learning tips, tool trials, creator workshops, and tutorial quests.",
      workspace_root="/town/ai-garden",
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["learning", "tools", "workshop"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="wenyu-physical-bridge",
      name="Physical Bridge",
      purpose="Bridges virtual requests into venue booking, proxy attendance, robot dispatch, and live district telemetry.",
      workspace_root="/town/wenyu-physical-bridge",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["physical-bridge", "robot", "telemetry"],
    ),
  )
  for worker in worker_sims(model) {
    state.register_worker(
      @core.WorkerRef::new(
        id=worker.id,
        name=worker.title,
        book_id=worker.book_id,
        role=worker_role_from_id(worker.id),
        capabilities=worker_capabilities(worker.id),
        status=worker.status,
      ),
    )
  }
  for task in task_specs(model) {
    state.enqueue_task(task)
  }
  for execution in execution_specs(model) {
    state.register_execution(execution)
  }
  state
}

///|
fn snapshot_placeholder_state(model : Model) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  state.register_book(
    @core.BookRef::new(
      id="wenyu-town-shell",
      name="Town Shell",
      purpose="Town Shell stays visible here while the browser bridge waits for a persisted projection feed.",
      workspace_root="/town/wenyu-town-shell",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["projection", "ui", "shell"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="snapshot",
      name="Persisted Town Snapshot",
      purpose="Browser snapshot bridge placeholder for `.moontown/town.json`.",
      workspace_root=".moontown",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["snapshot", "pending-bridge"],
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="snapshot-bridge",
      name="Snapshot Bridge",
      book_id="snapshot",
      role=@core.WorkerRole::Watcher,
      capabilities=["state-source", "projection"],
      status=@core.WorkerStatus::Waiting,
    ),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="connect-snapshot-source",
      book_id="snapshot",
      title="Connect persisted town state",
      prompt="Load `.moontown/town.json` through a local endpoint or generated static JSON artifact.",
      domain=@core.WorkDomain::Operations,
      required_role=Some(@core.WorkerRole::Watcher),
      required_capabilities=["state-source"],
      status=@core.TownTaskStatus::Planned,
    ),
  )
  state.record_event(
    @core.TownEvent::new(
      id="snapshot-source-\{model.tick}",
      kind="state-source",
      detail="Snapshot source selected; Rabbita browser bundle needs a state bridge before this reflects live town data.",
    ),
  )
  state
}
