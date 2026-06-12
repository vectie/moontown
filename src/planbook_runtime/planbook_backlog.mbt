///|
fn planbook_backlog_target_files_for_criterion(
  criterion_id : String,
  source_root : String,
) -> Array[String] {
  if !criterion_id.contains("backlog-") {
    return []
  }
  [
    "\{source_root}/src/planbook_runtime/planbook_backlog.mbt",
    "\{source_root}/src/planbook_runtime/planbook_autonomy.mbt",
    "\{source_root}/src/planbook_runtime/planbook_repair.mbt",
    "\{source_root}/src/planbook_runtime/planbook.mbt",
    "\{source_root}/src/runtime_status/runtime_status_snapshot.mbt",
    "\{source_root}/docs/PLANBOOK.md",
    "\{source_root}/docs/USAGE.md",
    "\{source_root}/.moontown/books/plan-moontown-quality/raw/backlog/implementation-backlog.json",
  ]
}

///|
fn planbook_backlog_criterion_for_item(
  item : PlanbookImplementationBacklogItem,
  workspace_root : String,
) -> PlanbookCriterionStatus {
  ignore(workspace_root)
  planbook_criterion(
    "backlog-\{item.id}",
    item.source_plan,
    "Backlog: \{item.title}",
    item.owner,
    false,
    "\{item.rationale} Priority: \{item.priority}. Target files: \{item.target_files.join(", ")}",
    "implement backlog item `\{item.id}` using its acceptance criteria: \{item.acceptance.join("; ")}. Validate with: \{item.validation.join("; ")}. Write completion evidence to `raw/backlog/completed/\{item.id}.md` after validation.",
  )
}
