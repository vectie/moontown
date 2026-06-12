///|
fn test_protocol_snapshot(
  status~ : String,
  ready? : Bool = false,
  inbox_count? : Int = 0,
  contribution_count? : Int = 0,
  reduction_count? : Int = 0,
  outbox_count? : Int = 0,
  review_count? : Int = 0,
  latest_reduction_summary? : String = "",
) -> BuildingProtocolSnapshot {
  {
    building_id: "test-building-\{status}",
    title: "Test Building",
    book_id: "test-book",
    protocol_mode: "exchange-reduce-distribute",
    persistence_mode: "jsonl-ledger",
    social_responsibility: "test",
    status,
    ready,
    inbox_count,
    contribution_count,
    reduction_count,
    outbox_count,
    review_count,
    latest_reduction_summary,
    latest_distribution_summary: "",
    skill_packs: [],
  }
}

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
  assert_true(!building_protocol_is_active(defined))
  assert_true(building_protocol_is_active(active))
  assert_true(building_protocol_is_ready(review))
  assert_true(building_protocol_needs_review(review))
  assert_true(building_protocol_is_blocked(blocked))
  let portfolio = building_protocol_portfolio(
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
  let row = building_protocol_markdown_row(
    test_protocol_snapshot(
      status="review",
      ready=true,
      inbox_count=1,
      contribution_count=2,
      reduction_count=3,
      outbox_count=4,
      review_count=5,
      latest_reduction_summary="A long\nprotocol reduction summary. ",
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
