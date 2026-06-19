///|
fn default_role_for_book(entry : BookCatalogEntry) -> @core.WorkerRole {
  if entry.id == "finance" {
    MemoryKeeper
  } else {
    Harness
  }
}

///|
fn normalize_target_page(path : String) -> String {
  if path.contains("/") {
    path
  } else {
    "wiki/\{path}"
  }
}

///|
fn external_task_to_book_task(
  entry : BookCatalogEntry,
  task : ExternalBookTask,
  goal : String,
) -> BookTask {
  {
    id: task.id,
    goal: Some(goal),
    title: task.title,
    kind: task.kind,
    prompt: task.prompt,
    priority: task.priority,
    requires_review: task.requires_review,
    target_pages: task.target_pages.map(path => normalize_target_page(path)),
    required_role: Some(infer_role_for_kind(entry, task.kind)),
  }
}

///|
fn infer_role_for_kind(
  entry : BookCatalogEntry,
  kind : String,
) -> @core.WorkerRole {
  match kind {
    "review" => Reviewer
    "planning" => Planner
    "ingest" => Harness
    "ingest-followup" => Harness
    "implementation-backlog" => Planner
    "code-patch" => Harness
    "test-fix" => Harness
    "projection-schema" => Harness
    "image-asset" => Specialist
    _ => default_role_for_book(entry)
  }
}
