///|
fn civic_service_reconciled_result(
  service : @civic.CivicServiceDefinition,
  health : CivicServiceHealth,
) -> @moonbook.BookResult {
  let plan = civic_service_reconcile_plan(service, health)
  let summary = civic_service_reconciled_summary_with_plan(
    service, health, plan,
  )
  @moonbook.BookResult::new(
    result_id="goal-\{service.book_id}-civic-service",
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
    requires_review=plan.review_items > 0,
    notify_town=true,
  )
}

///|
fn civic_service_reconcile_plan(
  service : @civic.CivicServiceDefinition,
  health : CivicServiceHealth,
) -> @civic.CivicServiceReconcilePlan {
  @civic.civic_service_reconcile_plan(
    service,
    protocol_reduction_count=health.protocol_reduction_count,
    protocol_outbox_count=health.protocol_outbox_count,
    protocol_review_count=health.protocol_review_count,
  )
}

///|
fn civic_service_reconciled_summary_with_plan(
  service : @civic.CivicServiceDefinition,
  health : CivicServiceHealth,
  plan : @civic.CivicServiceReconcilePlan,
) -> String {
  @civic.civic_service_reconciled_summary(
    service,
    latest_protocol_summary=health.latest_protocol_summary,
    protocol_reduction_count=health.protocol_reduction_count,
    protocol_outbox_count=health.protocol_outbox_count,
    plan,
  )
}

///|
fn civic_service_reconciled_decision(health : CivicServiceHealth) -> String {
  @civic.civic_service_reconciled_decision(
    protocol_reduction_count=health.protocol_reduction_count,
    protocol_review_count=health.protocol_review_count,
  )
}
