///|
fn civic_catalog_entry_for_service(
  service : @civic.CivicServiceDefinition,
  catalog : Array[@moonbook.BookCatalogEntry],
) -> @moonbook.BookCatalogEntry {
  for entry in catalog {
    match @civic.wenyu_civic_service_for_book_id(entry.id) {
      Some(found) if found.id == service.id => return entry
      _ => ()
    }
  }
  @civic.wenyu_civic_book_entry(service)
}

///|
async fn inspect_wenyu_civic_service(
  service : @civic.CivicServiceDefinition,
  entry : @moonbook.BookCatalogEntry,
) -> CivicServiceHealth {
  let readiness = inspect_civic_service_workspace_readiness(service, entry)
  let latest = inspect_civic_service_latest_result(service, readiness.root)
  let protocol = inspect_civic_service_protocol(service)
  let status = civic_service_status_label(
    workspace_exists=readiness.workspace_exists,
    missing_required_paths=readiness.missing_required_paths,
    skill_ready=readiness.skill_ready,
    moonclaw_profile_ready=readiness.moonclaw_profile_ready,
    latest_result_found=latest.found,
    latest_decision=latest.decision,
    latest_review_items=latest.review_items,
  )
  {
    service_id: service.id,
    title: service.title,
    book_id: service.book_id,
    service_kind: service.service_kind,
    module_mode: service.module_mode,
    book_role: service.book_role,
    skill_mode: service.skill_mode,
    protocol_status: protocol.status,
    protocol_ready: protocol.ready,
    protocol_inbox_count: protocol.inbox_count,
    protocol_contribution_count: protocol.contribution_count,
    protocol_reduction_count: protocol.reduction_count,
    protocol_outbox_count: protocol.outbox_count,
    protocol_review_count: protocol.review_count,
    latest_protocol_summary: protocol.latest_summary,
    protocol_history: protocol.history,
    protocol_history_state: protocol.history_state,
    workspace_root: readiness.root,
    status,
    operable: readiness.operable,
    proven_by_result: civic_service_result_is_proven(latest.decision),
    workspace_exists: readiness.workspace_exists,
    schema_ready: readiness.schema_ready,
    wiki_ready: readiness.wiki_ready,
    review_ready: readiness.review_ready,
    projection_ready: readiness.projection_ready,
    skill_ready: readiness.skill_ready,
    moonclaw_profile_ready: readiness.moonclaw_profile_ready,
    latest_result_path: latest.path,
    latest_result_found: latest.found,
    latest_decision: latest.decision,
    latest_book_changed: latest.book_changed,
    latest_pages_changed: latest.pages_changed,
    latest_accepted_facts: latest.accepted_facts,
    latest_review_items: latest.review_items,
    next_check_hint: latest.next_check_hint,
    missing_required_paths: readiness.missing_required_paths,
    notes: civic_health_notes(
      operable=readiness.operable,
      status~,
      missing_required_paths=readiness.missing_required_paths,
      latest_decision=latest.decision,
      latest_review_items=latest.review_items,
    ),
  }
}

///|
fn civic_service_portfolio(
  services : Array[CivicServiceHealth],
  status_path : String,
) -> CivicServicePortfolio {
  {
    total: services.length(),
    operable_count: count_civic_services_by(services, fn(item) { item.operable }),
    proven_count: count_civic_services_by(services, fn(item) {
      item.proven_by_result
    }),
    seeded_count: count_civic_services_by(services, fn(item) {
      civic_service_status_is_seeded(item.status)
    }),
    missing_count: count_civic_services_by(services, fn(item) {
      civic_service_status_is_missing_or_incomplete(item.status)
    }),
    review_count: count_civic_services_by(services, fn(item) {
      civic_service_status_is_review(item.status)
    }),
    blocked_count: count_civic_services_by(services, fn(item) {
      civic_service_status_is_blocked(item.status)
    }),
    changed_count: count_civic_services_by(services, fn(item) {
      civic_service_status_is_changed(item.status)
    }),
    no_change_count: count_civic_services_by(services, fn(item) {
      civic_service_status_is_no_change(item.status)
    }),
    status_path,
    markdown_path: civic_markdown_status_path(status_path),
    services,
  }
}

///|
fn count_civic_services_by(
  services : Array[CivicServiceHealth],
  predicate : (CivicServiceHealth) -> Bool,
) -> Int {
  services.filter(predicate).length()
}

///|
fn civic_markdown_status_path(status_path : String) -> String {
  if status_path.has_suffix(".json") {
    "\{status_path[:status_path.length() - 5]}.md"
  } else {
    "\{status_path}.md"
  }
}
