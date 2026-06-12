///|
test "building protocol portfolio buckets use named protocol predicates" {
  let defined = test_protocol_snapshot(status="defined")
  let active = test_protocol_snapshot(status="inbox", inbox_count=1)
  let review = test_protocol_snapshot(
    status="review",
    ready=true,
    reduction_count=1,
    outbox_count=1,
    review_count=1,
  )
  let blocked = test_protocol_snapshot(status="blocked")
  assert_true(!@civic.building_protocol_is_active(defined))
  assert_true(@civic.building_protocol_is_active(active))
  assert_true(@civic.building_protocol_is_ready(review))
  assert_true(@civic.building_protocol_needs_review(review))
  assert_true(@civic.building_protocol_is_blocked(blocked))
  let portfolio = @civic.building_protocol_portfolio(
    [defined, active, review, blocked],
    "/tmp/protocol-status.json",
    "/tmp/protocol-registry.json",
  )
  assert_eq(portfolio.total, 4)
  assert_eq(portfolio.active_count, 2)
  assert_eq(portfolio.ready_count, 1)
  assert_eq(portfolio.review_count, 1)
  assert_eq(portfolio.blocked_count, 1)
}

///|
test "building protocol markdown row renders compact protocol evidence" {
  let row = @civic.building_protocol_markdown_row(
    test_protocol_snapshot(
      status="review",
      ready=true,
      inbox_count=1,
      contribution_count=2,
      reduction_count=3,
      outbox_count=4,
      review_count=5,
      latest_reduction_summary="A long protocol reduction summary.",
    ),
  )
  assert_true(
    row.has_prefix(
      "|Test Building|exchange-reduce-distribute|review|1|2|3|4|5|",
    ),
  )
  assert_true(row.has_suffix("|\n"))
  assert_true(row.contains("A long protocol reduction summary."))
}
