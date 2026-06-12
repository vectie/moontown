///|
pub(all) struct CivicServiceReconcilePlan {
  decision : String
  page_count : Int
  review_items : Int
  next_check_hint : String
}

///|
pub fn civic_service_reconcile_plan(
  service : CivicServiceDefinition,
  protocol_reduction_count~ : Int,
  protocol_outbox_count~ : Int,
  protocol_review_count~ : Int,
) -> CivicServiceReconcilePlan {
  let review_items = protocol_review_count
  {
    decision: civic_service_reconciled_decision(
      protocol_reduction_count~,
      protocol_review_count~,
    ),
    page_count: civic_service_reconciled_page_count(
      service,
      protocol_outbox_count~,
    ),
    review_items,
    next_check_hint: if review_items > 0 {
      "review"
    } else {
      "normal"
    },
  }
}

///|
pub fn civic_service_has_reconcilable_protocol_work(
  protocol_ready~ : Bool,
  protocol_reduction_count~ : Int,
  protocol_outbox_count~ : Int,
) -> Bool {
  protocol_ready && protocol_reduction_count > 0 && protocol_outbox_count > 0
}

///|
pub fn civic_service_reconciled_result_is_current(
  latest_result_found~ : Bool,
  latest_decision~ : String,
  latest_pages_changed~ : Int,
  latest_review_items~ : Int,
  plan : CivicServiceReconcilePlan,
) -> Bool {
  latest_result_found &&
  latest_decision == plan.decision &&
  latest_pages_changed == plan.page_count &&
  latest_review_items == plan.review_items
}

///|
pub fn civic_service_reconciled_summary(
  service : CivicServiceDefinition,
  latest_protocol_summary~ : String,
  protocol_reduction_count~ : Int,
  protocol_outbox_count~ : Int,
  plan : CivicServiceReconcilePlan,
) -> String {
  [
    civic_service_reconciled_contract_block(
      plan,
      protocol_reduction_count~,
      protocol_outbox_count~,
    ),
    "",
    civic_service_reconciled_narrative(service),
    civic_service_reconciled_protocol_summary(latest_protocol_summary),
    civic_service_reconciled_mode_line(service),
    civic_service_reconciled_artifacts_line(service),
  ].join("\n")
}

///|
pub fn civic_service_reconciled_contract_block(
  plan : CivicServiceReconcilePlan,
  protocol_reduction_count~ : Int,
  protocol_outbox_count~ : Int,
) -> String {
  [
    "civic_service_decision: \{plan.decision}",
    "book_changed: yes",
    "wiki_pages_changed_count: \{plan.page_count}",
    "accepted_facts_count: 0",
    "review_items_created_count: \{plan.review_items}",
    "projection_updated: yes",
    "next_check_hint: \{plan.next_check_hint}",
    "protocol_reductions_count: \{protocol_reduction_count}",
    "protocol_outbox_count: \{protocol_outbox_count}",
    "protocol_reviews_count: \{plan.review_items}",
  ].join("\n")
}

///|
pub fn civic_service_reconciled_narrative(
  service : CivicServiceDefinition,
) -> String {
  [
    "Summary: \{service.title} reconciled the latest building protocol exchange into a MoonBook service-result record.",
    "This proves the module moved information through inbox, contribution, reduction, outbox, and return-home/review ledgers;",
    "it does not claim the review-gated outputs are accepted facts.",
  ].join(" ")
}

///|
pub fn civic_service_reconciled_protocol_summary(
  latest_protocol_summary : String,
) -> String {
  "Latest protocol summary: \{latest_protocol_summary}"
}

///|
pub fn civic_service_reconciled_mode_line(
  service : CivicServiceDefinition,
) -> String {
  "Service mode: \{service.module_mode}; persistence mode: \{service.persistence_mode}; MoonBook role: \{service.book_role}."
}

///|
pub fn civic_service_reconciled_artifacts_line(
  service : CivicServiceDefinition,
) -> String {
  "Artifacts: \{service.target_pages.join(", ")}"
}

///|
pub fn civic_service_reconciled_decision(
  protocol_reduction_count~ : Int,
  protocol_review_count~ : Int,
) -> String {
  if protocol_review_count > 0 {
    "needs_review"
  } else if protocol_reduction_count > 0 {
    "update"
  } else {
    "no_change"
  }
}

///|
pub fn civic_service_reconciled_page_count(
  service : CivicServiceDefinition,
  protocol_outbox_count~ : Int,
) -> Int {
  if protocol_outbox_count == 0 {
    0
  } else {
    service.target_pages.length()
  }
}
