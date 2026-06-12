///|
test "civic service reconciliation policy plans review update and no-change" {
  let service = wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let review = civic_service_reconcile_plan(
    service,
    protocol_reduction_count=2,
    protocol_outbox_count=2,
    protocol_review_count=1,
  )
  assert_eq(review.decision, "needs_review")
  assert_eq(review.page_count, service.target_pages.length())
  assert_eq(review.review_items, 1)
  assert_eq(review.next_check_hint, "review")

  let update = civic_service_reconcile_plan(
    service,
    protocol_reduction_count=1,
    protocol_outbox_count=1,
    protocol_review_count=0,
  )
  assert_eq(update.decision, "update")
  assert_eq(update.page_count, service.target_pages.length())
  assert_eq(update.review_items, 0)
  assert_eq(update.next_check_hint, "normal")

  let no_change = civic_service_reconcile_plan(
    service,
    protocol_reduction_count=0,
    protocol_outbox_count=0,
    protocol_review_count=0,
  )
  assert_eq(no_change.decision, "no_change")
  assert_eq(no_change.page_count, 0)
}

///|
test "civic service reconciliation policy renders result contract" {
  let service = wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let plan = civic_service_reconcile_plan(
    service,
    protocol_reduction_count=2,
    protocol_outbox_count=2,
    protocol_review_count=1,
  )
  let contract = civic_service_reconciled_contract_block(
    plan,
    protocol_reduction_count=2,
    protocol_outbox_count=2,
  )
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

  let summary = civic_service_reconciled_summary(
    service,
    latest_protocol_summary="Policy Hall reduced source packets.",
    protocol_reduction_count=2,
    protocol_outbox_count=2,
    plan,
  )
  assert_true(summary.contains("civic_service_decision: needs_review"))
  assert_true(summary.contains("accepted_facts_count: 0"))
  assert_true(summary.contains("review_items_created_count: 1"))
  assert_true(
    summary.contains(
      "does not claim the review-gated outputs are accepted facts",
    ),
  )
  assert_true(summary.contains(service.module_mode))
}

///|
test "civic service reconciliation policy gates work and current results" {
  let service = wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let plan = civic_service_reconcile_plan(
    service,
    protocol_reduction_count=2,
    protocol_outbox_count=2,
    protocol_review_count=1,
  )
  assert_true(
    civic_service_has_reconcilable_protocol_work(
      protocol_ready=true,
      protocol_reduction_count=2,
      protocol_outbox_count=2,
    ),
  )
  assert_true(
    !civic_service_has_reconcilable_protocol_work(
      protocol_ready=false,
      protocol_reduction_count=2,
      protocol_outbox_count=2,
    ),
  )
  assert_true(
    !civic_service_has_reconcilable_protocol_work(
      protocol_ready=true,
      protocol_reduction_count=0,
      protocol_outbox_count=2,
    ),
  )
  assert_true(
    civic_service_reconciled_result_is_current(
      latest_result_found=true,
      latest_decision="needs_review",
      latest_pages_changed=service.target_pages.length(),
      latest_review_items=1,
      plan,
    ),
  )
  assert_true(
    !civic_service_reconciled_result_is_current(
      latest_result_found=true,
      latest_decision="needs_review",
      latest_pages_changed=0,
      latest_review_items=1,
      plan,
    ),
  )
  assert_true(
    !civic_service_reconciled_result_is_current(
      latest_result_found=false,
      latest_decision="needs_review",
      latest_pages_changed=service.target_pages.length(),
      latest_review_items=1,
      plan,
    ),
  )
}
