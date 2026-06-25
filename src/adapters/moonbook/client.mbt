///|
pub async fn accept_goal(
  entry : BookCatalogEntry,
  goal : String,
  goal_id? : String? = None,
) -> BookGoalAcceptance {
  ignore(goal_id)
  let json = run_book_json_command(entry, ["accept", entry.workspace_root, goal])
  @json.from_json(json)
}

///|
pub async fn produce_task_batch(
  entry : BookCatalogEntry,
  goal : String,
  goal_id? : String? = None,
) -> BookTaskBatch {
  ignore(goal_id)
  let json = run_book_json_command(entry, ["tasks", entry.workspace_root, goal])
  let external : ExternalBookTaskBatch = @json.from_json(json)
  {
    goal_id: external.goal_id,
    goal: external.goal,
    summary: external.summary,
    tasks: external.tasks.map(task => {
      external_task_to_book_task(entry, task, external.goal)
    }),
  }
}

///|
pub async fn hydrate_worker_context(
  entry : BookCatalogEntry,
  task : BookTask,
) -> WorkerContextBundle {
  let json = run_book_json_command(entry, [
    "context",
    entry.workspace_root,
    context_goal_for_task(task),
    "--task",
    task.id,
  ]) catch {
    _ =>
      return finalize_worker_context_bundle(
        entry,
        task,
        enrich_worker_context_bundle(
          entry,
          fallback_worker_context_bundle(entry, task),
        ),
      )
  }
  let parsed : WorkerContextBundle = @json.from_json(json) catch {
    _ => fallback_worker_context_bundle(entry, task)
  }
  finalize_worker_context_bundle(
    entry,
    task,
    enrich_worker_context_bundle(entry, parsed),
  )
}

///|
pub async fn persist_result(
  entry : BookCatalogEntry,
  result : BookResult,
  moonbook_root? : String = default_moonbook_root(),
) -> PersistResultOutcome {
  persist_result_payload(entry, result.to_json(), moonbook_root~)
}

///|
pub async fn persist_result_payload(
  entry : BookCatalogEntry,
  payload : Json,
  moonbook_root? : String = default_moonbook_root(),
) -> PersistResultOutcome {
  let result = match decode_book_result_payload(payload) {
    Some(result) => result
    None =>
      fail(
        "MoonBook persist payload must be a BookResult or mooncode-book-result envelope",
      )
  }
  let path = result_temp_path(result.result_id)
  save_result_payload_file(path, payload)
  let json = run_book_json_command(
    entry,
    ["persist", entry.workspace_root, path],
    moonbook_root~,
  )
  @json.from_json(json)
}

///|
pub async fn summarize_state(entry : BookCatalogEntry) -> BookStateSummary {
  let snapshot = book_state_snapshot(entry)
  normalize_book_state_summary(entry, snapshot.summary)
}

///|
pub async fn book_state_snapshot(
  entry : BookCatalogEntry,
  moonbook_root? : String = default_moonbook_root(),
) -> BookStateSnapshot {
  let json = run_book_json_command(
    entry,
    ["state", entry.workspace_root],
    moonbook_root~,
  )
  @json.from_json(json)
}

///|
pub async fn report_health(entry : BookCatalogEntry) -> BookHealthReport {
  let json = run_book_json_command(entry, ["health", entry.workspace_root])
  @json.from_json(json)
}

///|
// Adapter orchestration lives here; normalization, workspace build,
// context enrichment, and research pack installation are split by concern.
