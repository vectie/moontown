///|
test "civic service reconciliation uses protocol work without accepting facts" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let health = test_civic_service_health(
    protocol_status="review",
    protocol_inbox_count=3,
    protocol_contribution_count=3,
    protocol_reduction_count=3,
    protocol_outbox_count=3,
    protocol_review_count=1,
    latest_protocol_summary="Policy Hall reduced source packets into a pending checklist review.",
    status="seeded",
    notes=[],
  )
  assert_true(civic_service_has_reconcilable_protocol_work(health))
  assert_eq(civic_service_reconciled_decision(health), "needs_review")
  let plan = civic_service_reconcile_plan(service, health)
  let summary = civic_service_reconciled_summary_with_plan(
    service, health, plan,
  )
  assert_true(summary.contains("civic_service_decision: needs_review"))
  assert_true(summary.contains("accepted_facts_count: 0"))
  assert_true(summary.contains("review_items_created_count: 1"))
  assert_true(
    summary.contains(
      "does not claim the review-gated outputs are accepted facts",
    ),
  )
}

///|
test "civic service reconciliation plan centralizes review outcome markers" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let health = test_civic_service_health(
    protocol_status="review",
    protocol_reduction_count=2,
    protocol_outbox_count=2,
    protocol_review_count=1,
  )
  let plan = civic_service_reconcile_plan(service, health)
  assert_eq(plan.decision, "needs_review")
  assert_eq(plan.page_count, service.target_pages.length())
  assert_eq(plan.review_items, 1)
  assert_eq(plan.next_check_hint, "review")
  let summary = civic_service_reconciled_summary_with_plan(
    service, health, plan,
  )
  assert_true(summary.contains("civic_service_decision: needs_review"))
  assert_true(
    summary.contains(
      "wiki_pages_changed_count: \{service.target_pages.length()}",
    ),
  )
  assert_true(summary.contains("review_items_created_count: 1"))
  assert_true(summary.contains("next_check_hint: review"))
  let contract = civic_service_reconciled_contract_block(health, plan)
  assert_true(contract.has_prefix("civic_service_decision: needs_review\n"))
  assert_true(contract.contains("accepted_facts_count: 0"))
  assert_true(contract.contains("protocol_reductions_count: 2"))
  assert_true(contract.contains("protocol_outbox_count: 2"))
  assert_true(contract.contains("protocol_reviews_count: 1"))
  assert_true(
    !contract.contains(
      "does not claim the review-gated outputs are accepted facts",
    ),
  )
  assert_true(
    civic_service_reconciled_narrative(service).contains(service.title),
  )
  assert_true(
    civic_service_reconciled_mode_line(service).contains(service.module_mode),
  )
}

///|
test "civic service reconciliation plan distinguishes update and no-change outcomes" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let update_health = test_civic_service_health(
    protocol_status="reduced",
    protocol_reduction_count=1,
    protocol_outbox_count=1,
  )
  let update_plan = civic_service_reconcile_plan(service, update_health)
  assert_eq(update_plan.decision, "update")
  assert_eq(update_plan.page_count, service.target_pages.length())
  assert_eq(update_plan.review_items, 0)
  assert_eq(update_plan.next_check_hint, "normal")
  let no_change_health = test_civic_service_health(
    protocol_status="reduced",
    protocol_reduction_count=0,
    protocol_outbox_count=0,
  )
  let no_change_plan = civic_service_reconcile_plan(service, no_change_health)
  assert_eq(no_change_plan.decision, "no_change")
  assert_eq(no_change_plan.page_count, 0)
  assert_eq(no_change_plan.review_items, 0)
  assert_eq(no_change_plan.next_check_hint, "normal")
}

///|
test "civic service current check compares latest result to reconcile plan" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let matching = test_civic_service_health(
    protocol_status="review",
    protocol_reduction_count=2,
    protocol_outbox_count=2,
    protocol_review_count=1,
    latest_decision="needs_review",
    latest_pages_changed=service.target_pages.length(),
    latest_review_items=1,
  )
  assert_true(civic_service_reconciled_result_is_current(service, matching))
  let stale = test_civic_service_health(
    protocol_status="review",
    protocol_reduction_count=2,
    protocol_outbox_count=2,
    protocol_review_count=1,
    latest_decision="needs_review",
    latest_pages_changed=0,
    latest_review_items=1,
  )
  assert_true(!civic_service_reconciled_result_is_current(service, stale))
  let missing = test_civic_service_health(
    protocol_status="review",
    protocol_reduction_count=2,
    protocol_outbox_count=2,
    protocol_review_count=1,
  )
  assert_true(!civic_service_reconciled_result_is_current(service, missing))
}
