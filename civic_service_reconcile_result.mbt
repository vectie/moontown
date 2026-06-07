///|
priv struct CivicServiceReconcilePlan {
  decision : String
  page_count : Int
  review_items : Int
  next_check_hint : String
}

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
    requires_review=plan.review_items > 0,
    notify_town=true,
  )
}

///|
fn civic_service_reconcile_plan(
  service : @civic.CivicServiceDefinition,
  health : CivicServiceHealth,
) -> CivicServiceReconcilePlan {
  let review_items = health.protocol_review_count
  {
    decision: civic_service_reconciled_decision(health),
    page_count: civic_service_reconciled_page_count(service, health),
    review_items,
    next_check_hint: if review_items > 0 {
      "review"
    } else {
      "normal"
    },
  }
}

///|
fn civic_service_reconciled_summary_with_plan(
  service : @civic.CivicServiceDefinition,
  health : CivicServiceHealth,
  plan : CivicServiceReconcilePlan,
) -> String {
  [
    civic_service_reconciled_contract_block(health, plan),
    "",
    civic_service_reconciled_narrative(service),
    civic_service_reconciled_protocol_summary(health),
    civic_service_reconciled_mode_line(service),
    civic_service_reconciled_artifacts_line(service),
  ].join("\n")
}

///|
fn civic_service_reconciled_contract_block(
  health : CivicServiceHealth,
  plan : CivicServiceReconcilePlan,
) -> String {
  [
    "civic_service_decision: \{plan.decision}",
    "book_changed: yes",
    "wiki_pages_changed_count: \{plan.page_count}",
    "accepted_facts_count: 0",
    "review_items_created_count: \{plan.review_items}",
    "projection_updated: yes",
    "next_check_hint: \{plan.next_check_hint}",
    "protocol_reductions_count: \{health.protocol_reduction_count}",
    "protocol_outbox_count: \{health.protocol_outbox_count}",
    "protocol_reviews_count: \{plan.review_items}",
  ].join("\n")
}

///|
fn civic_service_reconciled_narrative(
  service : @civic.CivicServiceDefinition,
) -> String {
  [
    "Summary: \{service.title} reconciled the latest building protocol exchange into a MoonBook service-result record.",
    "This proves the module moved information through inbox, contribution, reduction, outbox, and return-home/review ledgers;",
    "it does not claim the review-gated outputs are accepted facts.",
  ].join(" ")
}

///|
fn civic_service_reconciled_protocol_summary(
  health : CivicServiceHealth,
) -> String {
  "Latest protocol summary: \{health.latest_protocol_summary}"
}

///|
fn civic_service_reconciled_mode_line(
  service : @civic.CivicServiceDefinition,
) -> String {
  "Service mode: \{service.module_mode}; persistence mode: \{service.persistence_mode}; MoonBook role: \{service.book_role}."
}

///|
fn civic_service_reconciled_artifacts_line(
  service : @civic.CivicServiceDefinition,
) -> String {
  "Artifacts: \{service.target_pages.join(", ")}"
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
