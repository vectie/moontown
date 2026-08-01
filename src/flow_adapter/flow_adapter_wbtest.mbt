///|
async fn write_test_json(
  root : String,
  reference : String,
  value : Json,
) -> Unit {
  let path = scoped_path(root, reference)
  @fsx.make_directory(@pathx.dirname(path), recursive=true, exists_ok=true)
  @fsx.write_to_file(path, value.stringify(indent=2) + "\n", create=0o644)
}

///|
async fn flow_adapter_fixture() -> (String, String, String) {
  let root = @fs.tmpdir(prefix="moontown-flow-adapter")
  let input_ref = "inputs/handoff.json"
  let request_ref = "runtime/request.json"
  let result_ref = "runtime/result.json"
  let scenario = @json.parse(
    @fs.read_file("assets/templates/civic-salons/robotics-mini-salon.json").text(),
  )
  write_test_json(root, input_ref, {
    "contract_version": "moontown.civic.communication.handoff.v1",
    "handoff_id": "moonfind-flow-adapter-test",
    "producer": "moonfind",
    "producer_run_id": "flow-adapter-test",
    "scenario": scenario,
  })
  let input_digest = declared_input_digest(root, [input_ref])
  write_test_json(root, request_ref, {
    "request_id": "request-flow-adapter-test",
    "run_id": "flow-adapter-test",
    "book_id": "research-robotics",
    "work_item_id": "synthesize",
    "declaration_id": "synthesize",
    "attempt_id": "attempt-synthesize-1",
    "idempotency_key": "flow-adapter-test/synthesize/1",
    "product_id": "moontown",
    "operation": operation_ref(),
    "requested_authority": "workspace-mutation",
    "acceptance_criteria": ["reviewable civic synthesis exists"],
    "input_contracts": [input_schema_ref()],
    "output_contracts": [output_schema_ref()],
    "required_claim": "execution-result",
    "input_digest": input_digest,
    "input_artifacts": [input_ref],
    "timeout_ms": 60000,
    "created_at": "2026-07-31T00:00:00Z",
  })
  (root, request_ref, result_ref)
}

///|
async test "versioned civic synthesis executes once and reconciles evidence" {
  let (root, request_ref, result_ref) = flow_adapter_fixture()
  let first = execute_with_mode(
    root,
    request_ref,
    result_ref,
    @civic.FixtureReducer,
  )
  let replay = execute_with_mode(
    root,
    request_ref,
    result_ref,
    @civic.FixtureReducer,
  )
  assert_eq(first, replay)
  let fields = json_object(first, "adapter result")
  assert_eq(json_string_field(fields, "status"), "succeeded")
  guard fields["output_artifacts"] is Array([String(output_ref)]) else {
    fail("expected one versioned synthesis result")
  }
  let output = read_json_ref(root, output_ref)
  let output_fields = json_object(output, "synthesis result")
  assert_eq(json_string_field(output_fields, "operation_ref"), operation_ref())
  assert_eq(json_string_field(output_fields, "review_status"), "pending")
  assert_true(output_fields["accepted"] is False)
  assert_eq(
    json_string_field(output_fields, "claim_ceiling"),
    "execution-result",
  )
  guard output_fields["evidence"] is Array(evidence) else {
    fail("expected bound evidence")
  }
  assert_true(evidence.length() >= 2)
  let reconciled = reconcile(root, request_ref, result_ref)
  assert_eq(reconciled, first)
}

///|
async test "health attestation binds exact versioned operation and evidence" {
  let root = @fs.tmpdir(prefix="moontown-flow-health")
  let attestation = publish_health(
    root, "2026-07-31T00:00:00Z", "2026-07-31T01:00:00Z", "health/moontown-civic-synthesis-v1.json",
    "health/moontown-civic-synthesis-v1.attestation.json",
  )
  let fields = json_object(attestation, "health attestation")
  assert_eq(
    json_string_field(fields, "contract_id"),
    "moonflow.adapter-health.v1",
  )
  assert_eq(json_string_field(fields, "protocol"), "moonflow.adapter.v2")
  assert_eq(json_string_field(fields, "status"), "healthy")
  guard fields["operation_refs"] is Array([String(operation)]) else {
    fail("expected one health-bound operation")
  }
  assert_eq(operation, operation_ref())
  let evidence_ref = json_string_field(fields, "evidence_ref")
  assert_eq(
    json_string_field(fields, "evidence_digest"),
    digest_ref(root, evidence_ref),
  )
}

///|
async test "pack and host declaration publish the same capability truth" {
  let pack = json_object(
    @json.parse(@fs.read_file("pack.json").text()),
    "pack manifest",
  )
  assert_eq(json_string_field(pack, "id"), "moontown")
  assert_eq(json_string_field(pack, "version"), pack_version())
  guard pack["tools"] is Array(tools) else {
    fail("expected MoonTown pack tools")
  }
  assert_true(tools.length() >= 1)
  let tool = json_object(tools[0], "civic synthesis pack tool")
  assert_eq(json_string_field(tool, "id"), operation_id())
  assert_eq(json_string_field(tool, "owner_product"), "moontown")
  guard tool["review_required"] is True else {
    fail("civic synthesis must require review")
  }
  let declaration = json_object(
    @json.parse(
      @fs.read_file("adapters/moonflow/adapter-declaration.v1.json").text(),
    ),
    "adapter declaration",
  )
  assert_eq(json_string_field(declaration, "adapter_id"), adapter_id())
  assert_eq(json_string_field(declaration, "protocol"), "moonflow.adapter.v2")
  guard declaration["operations"] is Array([Object(operation)]) else {
    fail("expected one declared operation")
  }
  assert_eq(json_string_field(operation, "operation_id"), operation_id())
  assert_true(operation["supports_reconcile"] is True)
}
