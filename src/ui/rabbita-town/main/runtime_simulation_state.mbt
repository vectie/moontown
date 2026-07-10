///|
fn simulation_state(model : Model) -> @core.TownState {
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
      memory_scope=SharedTown,
      tags=["projection", "ui", "shell"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="wenyu-resident-twins",
      name="Resident Twins",
      purpose="Projects resident identity, memory summaries, reflection loops, privacy scope, and next actions into the town view.",
      workspace_root="/town/wenyu-resident-twins",
      memory_scope=BookPrivate,
      tags=["resident-twins", "memory", "projection"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="policy-hall",
      name="Policy Release Hall",
      purpose="Turns policy documents into quest lines, advisor answers, and application checklists.",
      workspace_root="/town/policy-hall",
      memory_scope=BookPrivate,
      tags=["policy", "quest", "advisor"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="wenyu-contest-express",
      name="Contest Express",
      purpose="Turns contest participation into a nurturing lane with countdowns, readiness reviews, mock judging, and champion replay hooks.",
      workspace_root="/town/wenyu-contest-express",
      memory_scope=SharedTown,
      tags=["contest", "roadshow", "readiness"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="social-square",
      name="Social Square",
      purpose="Maintains weak-tie matching, activity initiation, and collaboration loops.",
      workspace_root="/town/social-square",
      memory_scope=BookPrivate,
      tags=["matching", "events", "community"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="talent-avenue",
      name="Talent Star Avenue",
      purpose="Projects resident talent cards, skills heatmaps, and reception tours.",
      workspace_root="/town/talent-avenue",
      memory_scope=SharedTown,
      tags=["talent", "graph", "showcase"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="ai-garden",
      name="AI Science Garden",
      purpose="Runs AI learning tips, tool trials, creator workshops, and tutorial quests.",
      workspace_root="/town/ai-garden",
      memory_scope=BookPrivate,
      tags=["learning", "tools", "workshop"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="wenyu-physical-bridge",
      name="Physical Bridge",
      purpose="Bridges virtual requests into venue booking, proxy attendance, robot dispatch, and live district telemetry.",
      workspace_root="/town/wenyu-physical-bridge",
      memory_scope=SharedTown,
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
fn snapshot_placeholder_state() -> @core.TownState {
  @core.empty_state(
    @core.TownConfig::new(
      id="wenyu-valley",
      name="Wenyu Valley / AI Innovation Town",
      heartbeat_seconds=30,
      max_concurrent_tasks=24,
    ),
  )
}
