///|
fn is_civic_service_execution(execution : @core.TaskExecutionRecord) -> Bool {
  execution.task_id.contains("civic-service") ||
  execution.output_contract.contains("civic_service_decision") ||
  execution.output_contract.contains("wenyu.civic.") ||
  execution.context_pages.any(fn(path) {
    path.contains("CIVIC_SERVICE_CONTRACT.md") ||
    path.contains("wenyu-civic-service/SKILL.md")
  })
}

///|
fn civic_persist_summary(
  service : @civic.CivicServiceDefinition,
  execution : @core.TaskExecutionRecord,
) -> String {
  let decision = @civic_runtime.civic_marker_value(
    execution.summary,
    "civic_service_decision",
    fallback="needs_review",
  )
  let book_changed = @civic_runtime.civic_marker_value(
    execution.summary,
    "book_changed",
    fallback="unknown",
  )
  let changed_pages = @civic_runtime.civic_marker_int(
    execution.summary,
    "wiki_pages_changed_count",
    fallback=0,
  )
  let accepted_facts = @civic_runtime.civic_marker_int(
    execution.summary,
    "accepted_facts_count",
    fallback=0,
  )
  let review_items = @civic_runtime.civic_marker_int(
    execution.summary,
    "review_items_created_count",
    fallback=0,
  )
  let projection_updated = @civic_runtime.civic_marker_value(
    execution.summary,
    "projection_updated",
    fallback="unknown",
  )
  let next_check = @civic_runtime.civic_marker_value(
    execution.summary,
    "next_check_hint",
    fallback="review",
  )
  let run_line = match execution.run_id {
    Some(run_id) => " Worker run: `\{run_id}`."
    None => ""
  }
  let evidence = @support.markdown_excerpt(
    compact_markdown_for_candidate(execution.summary),
    900,
  )
  [
    "Civic service result for \{service.title}.",
    "Decision: `\{decision}`.",
    "Book changed: `\{book_changed}`.",
    "Changed pages: \{changed_pages}.",
    "Accepted facts: \{accepted_facts}.",
    "Review items: \{review_items}.",
    "Projection updated: `\{projection_updated}`.",
    "Next check hint: `\{next_check}`.",
    "Contract: `\{service.output_contract}`.",
    "\{run_line}",
    "Service summary: \{evidence}",
  ].join(" ")
}

///|
fn civic_persist_artifacts(
  service : @civic.CivicServiceDefinition,
  execution : @core.TaskExecutionRecord,
) -> Array[String] {
  let artifacts : Array[String] = []
  match execution.run_id {
    Some(run_id) => artifacts.push(run_id)
    None => ()
  }
  for page in service.target_pages {
    artifacts.push(page)
  }
  artifacts
}

///|
fn civic_persist_memory_candidates(
  service : @civic.CivicServiceDefinition,
  execution : @core.TaskExecutionRecord,
) -> Array[@moonbook.MemoryCandidate] {
  let detail = civic_persist_summary(service, execution)
  let candidates : Array[@moonbook.MemoryCandidate] = [
    @moonbook.MemoryCandidate::new(
      kind="civic-service",
      title="\{service.title} service run",
      detail~,
      durable=true,
      target_page=Some(civic_workspace_target_page(service.wiki_pages[0])),
    ),
  ]
  let review_items = @civic_runtime.civic_marker_int(
    execution.summary,
    "review_items_created_count",
    fallback=if execution.requires_review { 1 } else { 0 },
  )
  if review_items > 0 && !service.review_queues.is_empty() {
    candidates.push(
      @moonbook.MemoryCandidate::new(
        kind="review",
        title="\{service.title} review gate",
        detail~,
        durable=true,
        target_page=Some(civic_workspace_target_page(service.review_queues[0])),
      ),
    )
  }
  candidates
}

///|
fn civic_workspace_target_page(path : String) -> String {
  if path.has_prefix("wiki/") {
    path[5:].to_owned()
  } else {
    path
  }
}
