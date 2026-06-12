///|
test "building protocol snapshot derives status and readiness from observed ledger counts" {
  let protocol = wenyu_building_protocol_for_building_id("policy-hall").unwrap()
  let inbox = building_protocol_snapshot(
    protocol,
    inbox_count=1,
    contribution_count=0,
    reduction_count=0,
    outbox_count=0,
    review_count=0,
    latest_reduction_summary="",
    latest_distribution_summary="",
  )
  assert_eq(inbox.building_id, "policy-hall")
  assert_eq(inbox.status, "inbox")
  assert_true(!inbox.ready)

  let reduced = building_protocol_snapshot(
    protocol,
    inbox_count=1,
    contribution_count=1,
    reduction_count=1,
    outbox_count=1,
    review_count=0,
    latest_reduction_summary="Reduced a policy packet.",
    latest_distribution_summary="Distributed a checklist.",
  )
  assert_eq(reduced.status, "reduced")
  assert_true(reduced.ready)
  assert_eq(reduced.latest_reduction_summary, "Reduced a policy packet.")

  let review = building_protocol_snapshot(
    protocol,
    inbox_count=1,
    contribution_count=1,
    reduction_count=1,
    outbox_count=1,
    review_count=1,
    latest_reduction_summary="Reduced a policy packet.",
    latest_distribution_summary="Distributed a checklist.",
  )
  assert_eq(review.status, "review")
  assert_true(review.ready)
}
