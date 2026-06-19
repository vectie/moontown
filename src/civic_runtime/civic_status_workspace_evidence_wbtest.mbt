///|
async test "civic status marks bootstrapped service operable but unproven" {
  let root = "/tmp/moontown-civic-status-policy"
  @support.ignore_checked_command("rm", ["-rf", root])
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let entry = @moonbook.BookCatalogEntry::new(
    id=service.book_id,
    name="Wenyu Valley / \{service.title}",
    purpose=service.purpose,
    workspace_root=root,
    memory_scope=BookPrivate,
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
async test "civic workspace readiness separates structural gates" {
  let root = "/tmp/moontown-civic-readiness"
  @support.ignore_checked_command("rm", ["-rf", root])
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let entry = @moonbook.BookCatalogEntry::new(
    id=service.book_id,
    name="Wenyu Valley / \{service.title}",
    purpose=service.purpose,
    workspace_root=root,
    memory_scope=BookPrivate,
    tags=["wenyu-valley", "civic-service", service.id],
    skills=["civic-service", service.skill_pack],
  )
  let missing = inspect_civic_service_workspace_readiness(service, entry)
  assert_true(!missing.workspace_exists)
  assert_true(!missing.operable)
  write_wenyu_civic_workspace_seed_for_service(
    entry, service, "test civic readiness seed",
  )
  let ready = inspect_civic_service_workspace_readiness(service, entry)
  assert_true(ready.workspace_exists)
  assert_eq(ready.missing_required_paths.length(), 0)
  assert_true(ready.schema_ready)
  assert_true(ready.wiki_ready)
  assert_true(ready.review_ready)
  assert_true(ready.projection_ready)
  assert_true(ready.skill_ready)
  assert_true(ready.moonclaw_profile_ready)
  assert_true(ready.operable)
}

///|
async test "civic latest result evidence parses contract markers" {
  let root = "/tmp/moontown-civic-latest-result"
  @support.ignore_checked_command("rm", ["-rf", root])
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let missing = inspect_civic_service_latest_result(service, root)
  assert_true(!missing.found)
  assert_eq(missing.decision, "none")
  let path = @civic.civic_service_result_path(service, root~)
  @support.write_text_file(
    path,
    @moonbook.BookResult::new(
      task_id="policy-service",
      summary=[
        "civic_service_decision: update", "book_changed: yes", "wiki_pages_changed_count: 3",
        "accepted_facts_count: 5", "review_items_created_count: 2", "next_check_hint: follow_up",
      ].join("\n"),
    )
    .to_json()
    .stringify(indent=2),
  )
  let parsed = inspect_civic_service_latest_result(service, root)
  assert_true(parsed.found)
  assert_eq(parsed.path, path)
  assert_eq(parsed.decision, "update")
  assert_eq(parsed.book_changed, "yes")
  assert_eq(parsed.pages_changed, 3)
  assert_eq(parsed.accepted_facts, 5)
  assert_eq(parsed.review_items, 2)
  assert_eq(parsed.next_check_hint, "follow_up")
}
