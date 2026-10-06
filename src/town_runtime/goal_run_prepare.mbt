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
  wenyu_execution? : String = "native",
  wenyu_model? : String = "",
  wenyu_allow_no_change? : Bool = false,
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
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
  if !acceptance.accepted {
    state.record_event(
      @core.TownEvent::new(
        id="event-reject-\{entry.id}",
        kind="planning",
        detail="MoonBook declined planning for \{entry.id}: \{acceptance.reason}",
        related_book_id=Some(entry.id),
      ),
    )
    return None
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-accept-\{entry.id}",
      kind="accept",
      detail="MoonBook accepted \{entry.id}: \{acceptance.summary}",
      related_book_id=Some(entry.id),
    ),
  )
  preseed_goal_bootstrap_inputs(entry, objective, wenyu_execution~) catch {
    error =>
      state.record_event(
        @core.TownEvent::new(
          id="event-preseed-\{entry.id}",
          kind="error",
          detail="MoonTown failed to preseed bootstrap inputs for \{entry.id}: \{error}",
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
  let tasks = select_goal_book_tasks(plan.tasks, plan.task_limit)
  let selected : Array[@moonbook.BookTask] = []
  for task in tasks {
    if @build_pipeline.is_wenyu_book(entry) &&
      [
        "implementation-backlog", "code-patch", "image-asset", "projection-schema",
        "test-fix",
      ].contains(task.kind) {
      let scoped = @build_pipeline_runtime.wenyu_task_after_explicit_supersession(
        @build_pipeline_runtime.wenyu_objective_task(task, objective),
        @native_work.path_for_snapshot(snapshot_path),
      )
      if @build_pipeline_runtime.wenyu_native_task_kind(scoped.kind) {
        ignore(
          @build_pipeline_runtime.freeze_wenyu_launch(
            entry,
            scoped,
            acceptance.goal_id,
            objective,
            execution=wenyu_execution,
            model=wenyu_model,
            allow_no_change=wenyu_allow_no_change,
            native_path=@native_work.path_for_snapshot(snapshot_path),
            catalog_path=book_catalog_path,
          ) catch {
            error => {
              state.record_event(
                @core.TownEvent::new(
                  id="event-wenyu-prepare-\{entry.id}",
                  kind="error",
                  detail="Wenyu launch preparation needs attention for \{entry.id}: \{error}",
                  related_book_id=Some(entry.id),
                  related_task_id=Some(scoped.id),
                ),
              )
              return None
            }
          },
        )
      }
      selected.push(scoped)
    } else {
      selected.push(task)
    }
  }
  Some({
    entry,
    tasks: selected,
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
    @build_pipeline_runtime.wenyu_book_ready_for_build(entry) {
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
      @env.get_env_var("MOONTOWN_WORKSPACE_ROOT").unwrap_or(
        "<MOONTOWN_WORKSPACE_ROOT required>",
      ),
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
