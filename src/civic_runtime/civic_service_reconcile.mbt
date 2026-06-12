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
  @civic.civic_service_has_reconcilable_protocol_work(
    protocol_ready=health.protocol_ready,
    protocol_reduction_count=health.protocol_reduction_count,
    protocol_outbox_count=health.protocol_outbox_count,
  )
}

///|
fn civic_service_reconciled_result_is_current(
  service : @civic.CivicServiceDefinition,
  health : CivicServiceHealth,
) -> Bool {
  let plan = civic_service_reconcile_plan(service, health)
  @civic.civic_service_reconciled_result_is_current(
    latest_result_found=health.latest_result_found,
    latest_decision=health.latest_decision,
    latest_pages_changed=health.latest_pages_changed,
    latest_review_items=health.latest_review_items,
    plan,
  )
}
