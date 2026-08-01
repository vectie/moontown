///|
test "desktop projection resolves runtime books onto Energy Valley buildings" {
  assert_eq(building_module_key("research-opc"), "research-opc")
  assert_eq(
    building_module_key("research-how-llms-are-trained-in-very-detail"),
    "research-llm-training",
  )
  assert_eq(
    building_module_key("research-agent-work-projection"),
    "research-ai-agents",
  )
  assert_eq(building_module_key("coding"), "ai-garden")
  assert_eq(building_module_key("finance"), "valley-market")
  assert_eq(building_module_key("wenyu-policy-hall"), "policy-hall")
  assert_eq(building_module_key("wenyu-broadcast-tower"), "story-radar")
  assert_eq(building_module_key("wenyu-physical-bridge"), "town-shell")
  let catalog_bindings : Map[String, String] = {
    "embodied-robotics-vla": "research-embodied-robotics",
    "wenyu-physical-bridge": "physical-bridge",
    "wenyu-vitality-dashboard": "vitality-dashboard",
  }
  assert_eq(
    building_module_key("embodied-robotics-vla", bindings=catalog_bindings),
    "research-embodied-robotics",
  )
  assert_eq(
    building_module_key("wenyu-physical-bridge", bindings=catalog_bindings),
    "physical-bridge",
  )
  assert_eq(
    building_module_key("wenyu-vitality-dashboard", bindings=catalog_bindings),
    "vitality-tower",
  )
  assert_eq(building_module_key("research-unknown-topic"), "unlocated")
}

///|
test "desktop projection derives visible work vocabulary from evidence" {
  assert_eq(
    projected_task_activity({ "status": "assigned" }),
    ("walking", "前往研究建筑"),
  )
  assert_eq(
    projected_task_activity({ "status": "waiting_review" }),
    ("reviewing", "独立审阅"),
  )
  assert_eq(
    projected_task_activity({
      "status": "running",
      "collaboration": { "participants": [{ "runId": "a" }, { "runId": "b" }] },
    }).0,
    "discussing",
  )
  assert_eq(
    projected_task_activity({
      "status": "running",
      "progress": { "acceptedFacts": 2, "pagesChanged": 1 },
    }).0,
    "synthesizing",
  )
  assert_eq(projected_task_activity({ "status": "running" }).0, "researching")
  assert_eq(projected_task_activity({ "status": "blocked" }).0, "recovering")
  assert_eq(projected_task_activity({ "status": "queued" }).0, "idle")
  assert_eq(projected_task_activity({ "status": "completed" }).0, "idle")
}

///|
test "module projection accepts only the latest explicit MoonBook decision" {
  let accepted_decision : Json = {
    "stage": "deliverable_acceptance",
    "record_id": "decision-7",
    "record_version": "candidate-v3",
    "status": "accepted",
    "owner_route": "bookkeeper://named-reviewer",
    "evidence_count": 4,
    "issue_count": 0,
    "requires_human_review": false,
  }
  let accepted : Json = {
    "contract_version": "moonbook.bookkeeper.v1",
    "projection_version": "moonbook.bookkeeper.ui.v1",
    "loaded": true,
    "deliverable_acceptance": [accepted_decision],
  }
  guard moonbook_acceptance_receipt_projection(Some(accepted))
    is Some(Object(receipt)) else {
    fail("explicit accepted bookkeeper decision was not projected")
  }
  assert_eq(json_string_field(receipt, "decision"), "accepted")
  assert_eq(json_string_field(receipt, "decision_id"), "decision-7")
  assert_eq(
    json_string_field(receipt, "contract_version"),
    "moontown.moonbook.acceptance-receipt-projection.v1",
  )

  let superseded : Json = {
    "contract_version": "moonbook.bookkeeper.v1",
    "projection_version": "moonbook.bookkeeper.ui.v1",
    "loaded": true,
    "deliverable_acceptance": [
      accepted_decision,
      {
        "stage": "deliverable_acceptance",
        "record_id": "decision-8",
        "record_version": "candidate-v4",
        "status": "revision required",
        "owner_route": "bookkeeper://named-reviewer",
        "evidence_count": 4,
        "issue_count": 1,
        "requires_human_review": true,
      },
    ],
  }
  assert_true(moonbook_acceptance_receipt_projection(Some(superseded)) is None)
}

///|
test "knowledge catalog override is the exclusive desktop source" {
  assert_eq(
    knowledge_domain_catalog_paths(
      Some("/tmp/operator-catalog.json"),
      "/static",
      "/resources",
    ),
    ["/tmp/operator-catalog.json"],
  )
  assert_eq(knowledge_domain_catalog_paths(None, "/static", "/resources"), [
    "/static/knowledge-domain-catalog.json", "/resources/domains/catalog.v1.json",
    "assets/templates/domains/catalog.v1.json",
  ])
}

///|
async test "resolved knowledge catalog body has a stable SHA-256 identity" {
  guard resolved_knowledge_domain_catalog() is Some(catalog) else {
    fail("the checked-in knowledge catalog must resolve")
  }
  let body = knowledge_domain_catalog_body(catalog)
  let digest = knowledge_domain_catalog_digest(catalog)
  assert_true(body.contains("moontown.knowledge-domain-catalog.v1"))
  assert_true(digest.has_prefix("sha256:"))
  assert_eq(digest.length(), 71)
  assert_eq(knowledge_domain_catalog_digest(catalog), digest)
}

///|
test "desktop projection treats uncertain watcher outcomes conservatively" {
  assert_eq(
    watcher_task_status({ "decision": "NeedsReview" }),
    Some("waiting_review"),
  )
  assert_eq(watcher_task_status({ "decision": "Deferred" }), Some("blocked"))
  assert_eq(
    watcher_task_status({ "decision": "unexpected-value" }),
    Some("blocked"),
  )
  assert_eq(watcher_task_status(Map([])), None)
}

///|
test "desktop projection reads detailed watcher progress markers" {
  let watcher : Map[String, Json] = {
    "new_source_count": 8,
    "detail": "checked_sources_count: 9\naccepted_facts_count: 4\nrejected_facts_count: 2\nwiki_pages_changed_count: 7\nbook_changed: yes",
  }
  assert_eq(watcher_non_negative_int(watcher, "new_source_count"), Some(8))
  assert_eq(watcher_non_negative_int(watcher, "checked_sources_count"), Some(9))
  assert_eq(watcher_non_negative_int(watcher, "accepted_facts_count"), Some(4))
  assert_eq(watcher_non_negative_int(watcher, "rejected_facts_count"), Some(2))
  assert_eq(
    watcher_non_negative_int(watcher, "wiki_pages_changed_count"),
    Some(7),
  )
  assert_eq(watcher_detail_value(watcher, "book_changed"), Some("yes"))
}

///|
test "desktop collaboration does not mislabel pending work as running" {
  assert_eq(collaboration_participant_status("Running"), "running")
  assert_eq(collaboration_participant_status("Queued"), "queued")
  assert_eq(collaboration_participant_status("Pending"), "assigned")
  assert_eq(collaboration_participant_status("Succeeded"), "completed")
  assert_eq(collaboration_participant_status("unrecognized"), "unknown")
}

///|
test "desktop server exposes every Rabbita runtime snapshot path" {
  for
    path in [
      "/town.json", "/visual-projection.json", "/module-projections.json", "/moondesk-bridge.json",
      "/civic-status.json", "/daemon.json", "/live-autonomy.json", "/editor-pipeline.json",
      "/standing-goals.json", "/book-template-requests.json",
    ] {
    assert_true(runtime_snapshot_source(path) is Some(_), msg=path)
  }
  assert_true(runtime_snapshot_source("/not-a-runtime-file.json") is None)
}

///|
test "desktop server publishes its canonical adapter contract" {
  let contract = @town_contract.desktop_contract().stringify()
  assert_true(contract.contains(@town_contract.desktop_standing_watch_path()))
  assert_true(contract.contains(@town_contract.desktop_evidence_book_path()))
}
