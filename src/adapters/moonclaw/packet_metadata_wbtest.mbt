///|
test "proposal packet pins provider task spec for bootstrap ingest" {
  let task = moonclaw_adapter_bootstrap_ingest_task()
  let metadata = packet_step_metadata(Some(task)).stringify()
  assert_true(metadata.contains("\"extension_task_id\":\"task-bootstrap\""))
  assert_true(metadata.contains("\"bookapi_task_id\":\"task-bootstrap\""))
  assert_true(metadata.contains("\"kind\":\"bootstrap_gather\""))
  assert_true(metadata.contains("\"extension_task_kind\":\"bootstrap_gather\""))
}

///|
test "proposal packet applies no-input policy consistently" {
  let bundle : @moonbook.WorkerContextBundle = @json.from_json({
    "book_id": "research-opc",
    "workspace_root": "/tmp/research-opc",
    "task_id": "task-opc",
    "prompt": "Research OPC.",
    "policy": [],
    "routines": [],
    "skill_paths": [],
    "context_pages": [],
    "active_memory": [],
    "user_memory": [],
    "working_memory": [],
    "memory_summary": "No prior memory.",
    "output_contract": ["Return Markdown."],
  }) catch {
    _ => fail("expected worker context bundle")
  }
  let packet = proposal_packet_from_bundle(
    bundle, "Research OPC", "Run research task", "research-worker",
  )
  let metadata = packet.metadata.stringify()
  assert_true(metadata.contains("\"disable_waiting_for_input\":true"))
  assert_true(metadata.contains("\"best_effort_on_missing_input\":true"))
  assert_true(metadata.contains("\"profile_metadata\":{"))
  assert_true(metadata.contains("\"step_metadata\":{"))
}

///|
test "proposal packet carries catalog policy loop metadata" {
  let bundle : @moonbook.WorkerContextBundle = @json.from_json({
    "book_id": "research-opc",
    "workspace_root": "/tmp/research-opc",
    "task_id": "task-opc",
    "prompt": "Research OPC.",
    "policy": [],
    "routines": [],
    "skill_paths": [],
    "context_pages": [],
    "active_memory": [],
    "user_memory": [],
    "working_memory": [],
    "memory_summary": "No prior memory.",
    "output_contract": ["Return Markdown."],
  }) catch {
    _ => fail("expected worker context bundle")
  }
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-opc",
    name="OPC Research",
    purpose="Watch one-person company research.",
    workspace_root="/tmp/research-opc",
    tags=["research"],
  )
  let packet = proposal_packet_from_bundle(
    bundle,
    "Research OPC",
    "Run research task",
    "research-worker",
    entry=Some(entry),
  )
  let metadata = packet.metadata.stringify()
  assert_true(metadata.contains("\"book_type\":\"research-book\""))
  assert_true(metadata.contains("\"book_policy\":{"))
  assert_true(metadata.contains("\"book_loop_plan\":{"))
  assert_true(metadata.contains("\"book_internal_distance_plan\":["))
  assert_true(metadata.contains("\"phase\":\"read-policy\""))
  assert_true(metadata.contains("\"layer\":\"information\""))
  assert_true(metadata.contains("\"layer\":\"decisiveness\""))
}

///|
test "proposal packet mirrors extension and bookapi task specs" {
  let task = moonclaw_adapter_book_task(
    id="task-mirror",
    title="Mirror task metadata",
    kind="standing-watch",
    prompt="Run a normal task without route rewrite.",
    priority=42,
    requires_review=false,
    target_pages=["wiki/synthesis/overview.md"],
  )
  let metadata = match packet_step_metadata(Some(task)) {
    Object(fields) => fields
    _ => fail("expected metadata object")
  }
  assert_eq(
    metadata.get("extension_task_spec").unwrap().stringify(),
    metadata.get("bookapi_task_spec").unwrap().stringify(),
  )
  assert_eq(
    metadata.get("extension_target_pages").unwrap().stringify(),
    metadata.get("bookapi_target_pages").unwrap().stringify(),
  )
  assert_eq(
    metadata.get("extension_task_kind").unwrap().stringify(),
    "\"standing-watch\"",
  )
}

///|
test "research bootstrap packet leaves web tools to the selected profile" {
  let task = moonclaw_adapter_bootstrap_ingest_task(
    id="goal-research-opc-research-bootstrap-ingest",
  )
  let metadata = packet_step_metadata(Some(task)).stringify()
  assert_true(metadata.contains("MoonClaw raw research bootstrap artifacts"))
  assert_true(metadata.contains("raw/bootstrap/deep-report.md"))
  assert_true(!metadata.contains("\"tool_contract\""))
  assert_true(!metadata.contains("\"web_search\":false"))
  assert_true(!metadata.contains("wiki/sources"))
}
