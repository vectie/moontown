///|
priv struct GoalBookLaunch {
  entry : @moonbook.BookCatalogEntry
  tasks : Array[@moonbook.BookTask]
  pending_review_baseline : Int
}

///|
async fn prepare_goal_book_launch(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  task_limit : Int,
) -> GoalBookLaunch? {
  let acceptance = @moonbook.accept_goal(entry, objective) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-accept-\{entry.id}",
          kind="error",
          detail="MoonBook accept failed for \{entry.id}: \{error}",
          related_book_id=Some(entry.id),
        ),
      )
      return None
    }
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-accept-\{entry.id}",
      kind="accept",
      detail="MoonBook accepted \{entry.id}: \{acceptance.summary}",
      related_book_id=Some(entry.id),
    ),
  )
  preseed_goal_bootstrap_inputs(entry, objective) catch {
    error =>
      state.record_event(
        @core.TownEvent::new(
          id="event-preseed-\{entry.id}",
          kind="error",
          detail="Moontown failed to preseed bootstrap inputs for \{entry.id}: \{error}",
          related_book_id=Some(entry.id),
        ),
      )
  }
  let initial_summary = @moonbook.summarize_state(entry) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-preflight-\{entry.id}",
          kind="error",
          detail="MoonBook preflight summary failed for \{entry.id}: \{error}",
          related_book_id=Some(entry.id),
        ),
      )
      return None
    }
  }
  let batch = @moonbook.produce_task_batch(entry, objective) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-plan-\{entry.id}",
          kind="error",
          detail="MoonBook planning failed for \{entry.id}: \{error}",
          related_book_id=Some(entry.id),
        ),
      )
      return None
    }
  }
  let plan = goal_book_task_plan(
    state,
    entry,
    objective,
    initial_summary,
    batch.tasks,
    task_limit,
  )
  if plan.bootstrap_active {
    state.record_event(
      @core.TownEvent::new(
        id="event-bootstrap-\{entry.id}",
        kind="planning",
        detail="Bootstrap ingest-first plan for \{entry.id}: evidence=\{initial_summary.evidence_count} verified_sources=\{initial_summary.verified_source_count} candidate_sources=\{initial_summary.candidate_source_count} tasks=\{plan.tasks.length()} limit=\{plan.task_limit}",
        related_book_id=Some(entry.id),
      ),
    )
  }
  Some({
    entry,
    tasks: select_goal_book_tasks(plan.tasks, plan.task_limit),
    pending_review_baseline: initial_summary.pending_review_count,
  })
}

///|
async fn goal_book_task_plan(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  initial_summary : @moonbook.BookStateSummary,
  batch_tasks : Array[@moonbook.BookTask],
  task_limit : Int,
) -> ResearchBootstrapPlan {
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) => {
      state.record_event(
        @core.TownEvent::new(
          id="event-civic-plan-\{entry.id}",
          kind="planning",
          detail="Wenyu civic service plan for \{entry.id}: dispatching \{service.title} service workflow before any product-build or research-bootstrap tasks.",
          related_book_id=Some(entry.id),
        ),
      )
      goal_book_wenyu_civic_service_plan(
        entry, objective, batch_tasks, task_limit,
      )
    }
    None =>
      goal_book_research_or_build_plan(
        state, entry, objective, initial_summary, batch_tasks, task_limit,
      )
  }
}

///|
async fn goal_book_research_or_build_plan(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  initial_summary : @moonbook.BookStateSummary,
  batch_tasks : Array[@moonbook.BookTask],
  task_limit : Int,
) -> ResearchBootstrapPlan {
  let bootstrap = research_bootstrap_plan(
    entry, objective, initial_summary, batch_tasks, task_limit,
  )
  if @build_pipeline.is_wenyu_book(entry) &&
    @build_pipeline.wenyu_book_ready_for_build(entry) {
    state.record_event(
      @core.TownEvent::new(
        id="event-build-plan-\{entry.id}",
        kind="planning",
        detail="Wenyu build-stage plan for \{entry.id}: research quality passed; dispatching implementation, code, and asset tasks.",
        related_book_id=Some(entry.id),
      ),
    )
    goal_book_wenyu_build_plan(entry, objective, task_limit)
  } else {
    bootstrap
  }
}

///|
fn goal_book_wenyu_build_plan(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  task_limit : Int,
) -> ResearchBootstrapPlan {
  {
    tasks: @build_pipeline.wenyu_build_tasks(
      entry,
      objective,
      current_repo_root(),
    ),
    task_limit: @build_pipeline.wenyu_build_task_limit(task_limit),
    bootstrap_active: false,
  }
}

///|
fn goal_book_wenyu_civic_service_plan(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  tasks : Array[@moonbook.BookTask],
  task_limit : Int,
) -> ResearchBootstrapPlan {
  {
    tasks: @build_pipeline.wenyu_civic_service_plan_tasks(
      entry,
      objective,
      @dispatch.prioritized_book_tasks(tasks, objective),
    ),
    task_limit: @build_pipeline.positive_wenyu_task_limit(task_limit),
    bootstrap_active: false,
  }
}

///|
fn select_goal_book_tasks(
  tasks : Array[@moonbook.BookTask],
  task_limit : Int,
) -> Array[@moonbook.BookTask] {
  let selected : Array[@moonbook.BookTask] = []
  let mut emitted = 0
  for task in tasks {
    if emitted >= task_limit {
      break
    }
    selected.push(task)
    emitted += 1
  }
  selected
}
