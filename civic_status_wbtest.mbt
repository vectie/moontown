///|
async test "civic status marks bootstrapped service operable but unproven" {
  let root = "/tmp/moontown-civic-status-policy"
  ignore_checked_command("rm", ["-rf", root])
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let entry = @moonbook.BookCatalogEntry::new(
    id=service.book_id,
    name="Wenyu Valley / \{service.title}",
    purpose=service.purpose,
    workspace_root=root,
    memory_scope=@core.MemoryScope::BookPrivate,
    tags=["wenyu-valley", "civic-service", service.id],
    skills=["civic-service", service.skill_pack],
  )
  write_wenyu_civic_workspace_seed_for_service(
    entry, service, "test civic status seed",
  )
  let health = inspect_wenyu_civic_service(service, entry)
  assert_eq(health.status, "seeded")
  assert_eq(health.module_mode, "agent-workspace")
  assert_eq(health.skill_mode, "policy-intelligence")
  assert_true(["defined", "reduced", "review"].contains(health.protocol_status))
  assert_eq(health.protocol_ready, health.protocol_status != "defined")
  assert_true(health.operable)
  assert_true(!health.proven_by_result)
  assert_eq(health.missing_required_paths.length(), 0)
  assert_true(health.skill_ready)
  assert_true(health.moonclaw_profile_ready)
}

///|
test "civic status labels latest service result states" {
  assert_eq(
    civic_service_status_label(
      workspace_exists=true,
      missing_required_paths=[],
      skill_ready=true,
      moonclaw_profile_ready=true,
      latest_result_found=false,
      latest_decision="none",
      latest_review_items=0,
    ),
    "seeded",
  )
  assert_eq(
    civic_service_status_label(
      workspace_exists=true,
      missing_required_paths=[],
      skill_ready=true,
      moonclaw_profile_ready=true,
      latest_result_found=true,
      latest_decision="update",
      latest_review_items=0,
    ),
    "changed",
  )
  assert_eq(
    civic_service_status_label(
      workspace_exists=true,
      missing_required_paths=[],
      skill_ready=true,
      moonclaw_profile_ready=true,
      latest_result_found=true,
      latest_decision="update",
      latest_review_items=2,
    ),
    "needs-review",
  )
  assert_eq(
    civic_service_status_label(
      workspace_exists=true,
      missing_required_paths=[],
      skill_ready=true,
      moonclaw_profile_ready=true,
      latest_result_found=true,
      latest_decision="blocked",
      latest_review_items=0,
    ),
    "blocked",
  )
}

///|
test "civic portfolio counts operable and review services" {
  let services = [
    CivicServiceHealth::{
      service_id: "policy-hall",
      title: "Policy Hall",
      book_id: "wenyu-policy-hall",
      service_kind: "policy-service",
      module_mode: "agent-workspace",
      book_role: "source-backed-service-workspace",
      skill_mode: "policy-intelligence",
      protocol_status: "review",
      protocol_ready: true,
      protocol_inbox_count: 1,
      protocol_contribution_count: 1,
      protocol_reduction_count: 1,
      protocol_outbox_count: 1,
      protocol_review_count: 1,
      latest_protocol_summary: "Policy Hall reduced one source into a review item.",
      protocol_history: [],
      protocol_history_state: "ready",
      workspace_root: "/tmp/policy",
      status: "needs-review",
      operable: true,
      proven_by_result: true,
      workspace_exists: true,
      schema_ready: true,
      wiki_ready: true,
      review_ready: true,
      projection_ready: true,
      skill_ready: true,
      moonclaw_profile_ready: true,
      latest_result_path: ".moontown/book-results/goal-wenyu-policy-hall-civic-service.json",
      latest_result_found: true,
      latest_decision: "needs_review",
      latest_book_changed: "yes",
      latest_pages_changed: 2,
      latest_accepted_facts: 3,
      latest_review_items: 1,
      next_check_hint: "review",
      missing_required_paths: [],
      notes: ["workspace is operable"],
    },
    CivicServiceHealth::{
      service_id: "contest-express",
      title: "Contest Express",
      book_id: "wenyu-contest-express",
      service_kind: "contest-service",
      module_mode: "agent-workspace",
      book_role: "coaching-workspace",
      skill_mode: "contest-coaching",
      protocol_status: "defined",
      protocol_ready: false,
      protocol_inbox_count: 0,
      protocol_contribution_count: 0,
      protocol_reduction_count: 0,
      protocol_outbox_count: 0,
      protocol_review_count: 0,
      latest_protocol_summary: "",
      protocol_history: [],
      protocol_history_state: "no-events-yet",
      workspace_root: "/tmp/contest",
      status: "missing-workspace",
      operable: false,
      proven_by_result: false,
      workspace_exists: false,
      schema_ready: false,
      wiki_ready: false,
      review_ready: false,
      projection_ready: false,
      skill_ready: false,
      moonclaw_profile_ready: false,
      latest_result_path: ".moontown/book-results/goal-wenyu-contest-express-civic-service.json",
      latest_result_found: false,
      latest_decision: "none",
      latest_book_changed: "unknown",
      latest_pages_changed: 0,
      latest_accepted_facts: 0,
      latest_review_items: 0,
      next_check_hint: "unknown",
      missing_required_paths: ["wiki/index.md"],
      notes: ["workspace is not yet fully operable"],
    },
  ]
  let portfolio = civic_service_portfolio(
    services, ".moontown/civic/status.json",
  )
  assert_eq(portfolio.total, 2)
  assert_eq(portfolio.operable_count, 1)
  assert_eq(portfolio.proven_count, 1)
  assert_eq(portfolio.review_count, 1)
  assert_eq(portfolio.missing_count, 1)
  assert_eq(portfolio.markdown_path, ".moontown/civic/status.md")
  let json_text = portfolio.to_json().stringify()
  assert_true(json_text.contains("protocol_history"))
  assert_true(json_text.contains("protocol_history_state"))
}

///|
test "civic service reconciliation uses protocol work without accepting facts" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let health = CivicServiceHealth::{
    service_id: "policy-hall",
    title: "Policy Hall",
    book_id: "wenyu-policy-hall",
    service_kind: "policy-service",
    module_mode: "agent-workspace",
    book_role: "source-backed-service-workspace",
    skill_mode: "policy-intelligence",
    protocol_status: "review",
    protocol_ready: true,
    protocol_inbox_count: 3,
    protocol_contribution_count: 3,
    protocol_reduction_count: 3,
    protocol_outbox_count: 3,
    protocol_review_count: 1,
    latest_protocol_summary: "Policy Hall reduced source packets into a pending checklist review.",
    protocol_history: [],
    protocol_history_state: "ready",
    workspace_root: "/tmp/policy",
    status: "seeded",
    operable: true,
    proven_by_result: false,
    workspace_exists: true,
    schema_ready: true,
    wiki_ready: true,
    review_ready: true,
    projection_ready: true,
    skill_ready: true,
    moonclaw_profile_ready: true,
    latest_result_path: ".moontown/book-results/goal-wenyu-policy-hall-civic-service.json",
    latest_result_found: false,
    latest_decision: "none",
    latest_book_changed: "unknown",
    latest_pages_changed: 0,
    latest_accepted_facts: 0,
    latest_review_items: 0,
    next_check_hint: "unknown",
    missing_required_paths: [],
    notes: [],
  }
  assert_true(civic_service_has_reconcilable_protocol_work(health))
  assert_eq(civic_service_reconciled_decision(health), "needs_review")
  let summary = civic_service_reconciled_summary(service, health)
  assert_true(summary.contains("civic_service_decision: needs_review"))
  assert_true(summary.contains("accepted_facts_count: 0"))
  assert_true(summary.contains("review_items_created_count: 1"))
  assert_true(
    summary.contains(
      "does not claim the review-gated outputs are accepted facts",
    ),
  )
}
