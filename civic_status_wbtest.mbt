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
}
