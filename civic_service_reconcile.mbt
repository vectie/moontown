///|
pub async fn reconcile_wenyu_civic_service_results(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  status_path? : String = default_wenyu_civic_status_path(),
) -> String {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let summaries : Array[String] = []
  let mut reconciled = 0
  let mut skipped = 0
  let mut blocked = 0
  for service in @civic.wenyu_civic_services() {
    let entry = civic_catalog_entry_for_service(service, catalog)
    let health = inspect_wenyu_civic_service(service, entry)
    if !health.operable {
      skipped += 1
      continue
    }
    if !civic_service_has_reconcilable_protocol_work(health) {
      skipped += 1
      continue
    }
    if civic_service_reconciled_result_is_current(service, health) {
      skipped += 1
      continue
    }
    let result = civic_service_reconciled_result(service, health)
    let outcome = @moonbook.persist_result(entry, result) catch {
      error => {
        blocked += 1
        summaries.push(
          "\{service.title}: blocked during MoonBook persist: \{error}",
        )
        continue
      }
    }
    reconciled += 1
    summaries.push(
      "\{service.title}: \{civic_service_reconciled_decision(health)}; pages=\{outcome.updated_pages.length()} review=\{outcome.review_queued}",
    )
  }
  ignore(write_wenyu_civic_status(book_catalog_path~, status_path~))
  let detail = if summaries.is_empty() {
    "No civic service result required reconciliation."
  } else {
    summaries.join("; ")
  }
  "Reconciled \{reconciled} Wenyu civic service result(s); skipped=\{skipped}; blocked=\{blocked}. \{detail}"
}

///|
fn civic_service_has_reconcilable_protocol_work(
  health : CivicServiceHealth,
) -> Bool {
  health.protocol_ready &&
  health.protocol_reduction_count > 0 &&
  health.protocol_outbox_count > 0
}

///|
fn civic_service_reconciled_result_is_current(
  service : @civic.CivicServiceDefinition,
  health : CivicServiceHealth,
) -> Bool {
  if !health.latest_result_found {
    return false
  }
  health.latest_decision == civic_service_reconciled_decision(health) &&
  health.latest_pages_changed ==
  civic_service_reconciled_page_count(service, health) &&
  health.latest_review_items == health.protocol_review_count
}

///|
fn civic_service_reconciled_result(
  service : @civic.CivicServiceDefinition,
  health : CivicServiceHealth,
) -> @moonbook.BookResult {
  let summary = civic_service_reconciled_summary(service, health)
  @moonbook.BookResult::new(
    task_id="goal-\{service.book_id}-civic-service",
    summary~,
    artifacts=[
      "building-protocol:\{service.id}",
      "book:\{service.book_id}",
      "status:\{health.latest_result_path}",
      ..service.target_pages,
    ],
    memory_candidates=[
      @moonbook.MemoryCandidate::new(
        kind="civic-service",
        title="\{service.title} protocol reconciliation",
        detail=summary,
        durable=true,
        target_page=Some(civic_workspace_target_page(service.wiki_pages[0])),
      ),
    ],
    requires_review=health.protocol_review_count > 0,
    notify_town=true,
  )
}

///|
fn civic_service_reconciled_summary(
  service : @civic.CivicServiceDefinition,
  health : CivicServiceHealth,
) -> String {
  let next_check_hint = if health.protocol_review_count > 0 {
    "review"
  } else {
    "normal"
  }
  [
    "civic_service_decision: \{civic_service_reconciled_decision(health)}",
    "book_changed: yes",
    "wiki_pages_changed_count: \{civic_service_reconciled_page_count(service, health)}",
    "accepted_facts_count: 0",
    "review_items_created_count: \{health.protocol_review_count}",
    "projection_updated: yes",
    "next_check_hint: \{next_check_hint}",
    "protocol_reductions_count: \{health.protocol_reduction_count}",
    "protocol_outbox_count: \{health.protocol_outbox_count}",
    "protocol_reviews_count: \{health.protocol_review_count}",
    "",
    "Summary: \{service.title} reconciled the latest building protocol exchange into a MoonBook service-result record. This proves the module moved information through inbox, contribution, reduction, outbox, and return-home/review ledgers; it does not claim the review-gated outputs are accepted facts.",
    "Latest protocol summary: \{health.latest_protocol_summary}",
    "Service mode: \{service.module_mode}; persistence mode: \{service.persistence_mode}; MoonBook role: \{service.book_role}.",
    "Artifacts: \{service.target_pages.join(", ")}",
  ].join("\n")
}

///|
fn civic_service_reconciled_decision(health : CivicServiceHealth) -> String {
  if health.protocol_review_count > 0 {
    "needs_review"
  } else if health.protocol_reduction_count > 0 {
    "update"
  } else {
    "no_change"
  }
}

///|
fn civic_service_reconciled_page_count(
  service : @civic.CivicServiceDefinition,
  health : CivicServiceHealth,
) -> Int {
  if health.protocol_outbox_count == 0 {
    0
  } else {
    service.target_pages.length()
  }
}
