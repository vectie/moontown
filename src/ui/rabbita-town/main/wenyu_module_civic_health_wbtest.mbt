///|
test "civic health status kind owns class and blocked policy" {
  assert_true(civic_health_status_kind("changed") is Complete)
  assert_true(civic_health_status_kind("no-change") is Complete)
  assert_true(civic_health_status_kind("needs-review") is Review)
  assert_true(civic_health_status_kind("seeded") is Waiting)
  assert_true(civic_health_status_kind("blocked") is Alert)
  assert_true(civic_health_status_kind("missing-workspace") is Alert)
  assert_true(civic_health_status_kind("incomplete") is Alert)
  assert_true(civic_health_status_kind("misconfigured") is Alert)
  assert_true(civic_health_status_kind("result-unknown") is Projected)
  assert_eq(civic_health_status_class("changed"), "module-status-complete")
  assert_eq(civic_health_status_class("needs-review"), "module-status-review")
  assert_eq(civic_health_status_class("seeded"), "module-status-waiting")
  assert_eq(civic_health_status_class("blocked"), "module-status-alert")
  assert_eq(civic_health_status_class("unknown"), "module-status-projected")
  assert_true(civic_health_status_kind_is_blocked(Alert))
  assert_true(!civic_health_status_kind_is_blocked(Complete))
}

///|
test "civic health status label keeps operator-facing text separate from state" {
  assert_eq(civic_health_status_label("missing-workspace"), "Missing workspace")
  assert_eq(civic_health_status_label("needs-review"), "Needs review")
  assert_eq(civic_health_status_label("no-change"), "No change")
  assert_eq(civic_health_status_label("result-unknown"), "Result unknown")
  assert_eq(civic_health_status_label("misconfigured"), "Misconfigured")
  assert_eq(civic_health_status_label("seeded"), "seeded")
}

///|
test "civic health detail uses readable fallback sections" {
  let detail = civic_health_detail(civic_health_snapshot_fixture())
  assert_true(detail.contains("Policy Hall (`wenyu-policy-hall`)"))
  assert_true(detail.contains("Protocol flow: in 1, contributions 2"))
  assert_true(
    detail.contains("Latest protocol summary: no protocol summary yet."),
  )
  assert_true(detail.contains("no detailed notes"))
}

///|
test "civic protocol summary counts ready services and review gates" {
  let ready = civic_health_snapshot_fixture()
  let reviewing = {
    ..ready,
    service_id: "wenyu-review-service",
    protocol_ready: false,
    protocol_review_count: 3,
  }
  let counts = civic_protocol_summary_counts([ready, reviewing])
  assert_eq(counts.ready_count, 1)
  assert_eq(counts.review_count, 3)
}

///|
test "civic status summary separates operability from portfolio state" {
  let service = civic_health_snapshot_fixture()
  let summary = civic_status_summary_from_portfolio(7, {
    total: 2,
    operable_count: 1,
    proven_count: 1,
    seeded_count: 1,
    missing_count: 0,
    review_count: 1,
    blocked_count: 0,
    changed_count: 1,
    no_change_count: 0,
    services: [
      service,
      {
        ..service,
        service_id: "wenyu-review-service",
        protocol_review_count: 2,
      },
    ],
  })
  assert_true(summary.contains("v7: 1/2 operable"))
  assert_true(summary.contains("1 service-result proof"))
  assert_true(summary.contains("2 protocol-active"))
  assert_true(summary.contains("2 review gates"))
  assert_true(summary.contains("Portfolio: seeded 1, missing 0, review 1"))
}

///|
fn civic_health_snapshot_fixture() -> CivicServiceHealthSnapshot {
  {
    service_id: "wenyu-policy-hall",
    title: "Policy Hall",
    book_id: "wenyu-policy-hall",
    service_kind: "policy",
    module_mode: "gateway",
    book_role: "civic-service",
    skill_mode: "policy-triage",
    protocol_status: "ready",
    protocol_ready: true,
    protocol_inbox_count: 1,
    protocol_contribution_count: 2,
    protocol_reduction_count: 3,
    protocol_outbox_count: 4,
    protocol_review_count: 0,
    latest_protocol_summary: "",
    protocol_history: None,
    protocol_history_state: None,
    status: "seeded",
    operable: true,
    proven_by_result: false,
    latest_decision: "none",
    latest_pages_changed: 0,
    latest_accepted_facts: 0,
    latest_review_items: 0,
    missing_required_paths: [],
    notes: [],
  }
}
