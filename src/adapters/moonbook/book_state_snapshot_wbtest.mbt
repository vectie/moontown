///|
test "book state snapshot contract decodes MoonBook read model" {
  let snapshot : BookStateSnapshot = @json.from_json({
    "contract": "moonbook.book_state.v1",
    "book_id": "research-demo",
    "root": "/tmp/research-demo",
    "generated_at": 1,
    "catalog": {
      "id": "research-demo",
      "name": "Research Demo",
      "purpose": "Demo book",
      "workspace_root": "/tmp/research-demo",
      "memory_scope": "BookPrivate",
      "tags": ["research"],
      "skills": ["wiki-review"],
    },
    "summary": book_state_summary_contract_fixture().to_json(),
    "health": book_health_contract_fixture().to_json(),
    "knowledge": {
      "contract": "moonbook.knowledge_bundle.v1",
      "book_id": "research-demo",
      "root": "/tmp/research-demo",
      "generated_at": 1,
      "summary": book_state_summary_contract_fixture().to_json(),
      "health": book_health_contract_fixture().to_json(),
      "pages": [],
      "graph": { "nodes": [], "edges": [] },
      "review_queue_path": "wiki/reviews/pending.md",
      "event_protocol": "moonbook.executable_event.v1",
    },
    "paths": {
      "knowledge_manifest": "book/knowledge/manifest.json",
      "generated_knowledge_bundle": "book/site/generated/knowledge-bundle.json",
      "generated_graph": "book/site/generated/graph.json",
      "latest_event": "events/latest.json",
      "review_queue": "wiki/reviews/pending.md",
    },
  })
  assert_eq(snapshot.contract, "moonbook.book_state.v1")
  assert_eq(snapshot.summary.total_evidence_count, 2)
  assert_eq(snapshot.knowledge.event_protocol, "moonbook.executable_event.v1")
  assert_eq(snapshot.paths.latest_event, "events/latest.json")
  assert_true(snapshot.latest_event is None)
}

///|
fn book_state_summary_contract_fixture() -> BookStateSummary {
  BookStateSummary::new(
    book_id="research-demo",
    root="/tmp/research-demo",
    page_count=8,
    source_count=2,
    entity_count=1,
    concept_count=1,
    pending_review_count=0,
    keeper_memory_count=0,
    keeper_working_count=0,
    evidence_count=2,
    total_evidence_count=2,
    operational_evidence_count=0,
    substantive_coverage_ready=true,
    summary="pages=8 evidence=2",
  )
}

///|
fn book_health_contract_fixture() -> BookHealthReport {
  {
    level: "ok",
    summary: "ready",
    pending_review_count: 0,
    low_confidence_claim_count: 0,
    maintenance_entry_count: 0,
    keeper_working_count: 0,
    evidence_count: 2,
    issues: [],
  }
}
