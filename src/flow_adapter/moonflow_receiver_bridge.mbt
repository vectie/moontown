///|
priv struct MoonFlowResearchReceiver {
  intake : Json
  root : String
  run_id : String
  work_item_id : String
  declaration_id : String
  token : String
  digest : String
  request_id : String
  attempt_id : String
  idempotency_key : String
  requested_authority : String
  output_contracts : Array[String]
  acceptance_criteria : Array[String]
  input_artifacts : Array[String]
  handoff : Json
}

///|
fn receiver_strict_fields(
  value : Json,
  label : String,
  allowed : Array[String],
) -> Map[String, Json] raise {
  let fields = json_object(value, label)
  for key, _ in fields {
    if !allowed.contains(key) {
      fail(
        "MoonTown MoonFlow receiver rejects unsupported \{label} field: \{key}",
      )
    }
  }
  fields
}

///|
fn receiver_bool_field(fields : Map[String, Json], name : String) -> Bool raise {
  match fields.get(name) {
    Some(True) => true
    Some(False) => false
    _ => fail("MoonTown MoonFlow receiver requires boolean \{name}")
  }
}

///|
fn receiver_safe_token(token : String) -> Bool {
  if token.length() != 64 {
    return false
  }
  token.all(ch => (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f'))
}

///|
fn receiver_safe_ref(reference : String) -> Bool {
  safe_artifact_ref(reference) &&
  !reference.contains("%") &&
  !reference.contains("\u0000")
}

///|
fn receiver_base(run_id : String, token : String) -> String {
  ".moonsuite/products/moontown/moonflow-receivers/\{run_id}/\{token}"
}

///|
fn receiver_expected_endpoint(run_id : String, token : String) -> String {
  "/api/moonflow/runs/\{run_id}/handoffs/\{token}"
}

///|
fn receiver_supported_criterion(criterion : String) -> Bool {
  criterion ==
  "independent participant books and one pending-review synthesis exist; the synthesis is not accepted knowledge"
}

///|
async fn decode_moonflow_research_receiver(
  workspace : String,
  intake : Json,
) -> MoonFlowResearchReceiver {
  let root = resolve_workspace(workspace)
  let top = receiver_strict_fields(intake, "handoff", [
    "contract_id", "contract_version", "handoff_id", "handoff_ref", "binding", "payload",
  ])
  guard json_string_field(top, "contract_id") == "moonflow.operator-handoff.v2" &&
    json_string_field(top, "contract_version") == "2.0.0" &&
    top.get("binding") is Some(binding_json) &&
    top.get("payload") is Some(payload_json) else {
    fail("MoonTown received an unsupported MoonFlow operator handoff")
  }
  let published_handoff_id = json_string_field(top, "handoff_id")
  let published_handoff_ref = json_string_field(top, "handoff_ref")
  guard safe_path_segment(published_handoff_id) &&
    receiver_safe_ref(published_handoff_ref) &&
    published_handoff_ref.has_prefix("operator-handoffs/") else {
    fail("MoonTown MoonFlow handoff publication identity is unsafe")
  }
  let binding = receiver_strict_fields(binding_json, "binding", [
    "handoff_token", "handoff_digest", "request_id", "attempt_id", "idempotency_key",
    "intake_path", "status_path", "receipt_path", "return_path",
  ])
  let payload = receiver_strict_fields(payload_json, "payload", [
    "action_kind", "run", "authority", "contracts", "inputs", "evidence", "review",
    "app_entrypoint",
  ])
  guard json_string_field(payload, "action_kind") == "open-product" &&
    payload.get("run") is Some(run_json) &&
    payload.get("authority") is Some(authority_json) &&
    payload.get("contracts") is Some(contracts_json) &&
    payload.get("inputs") is Some(inputs_json) &&
    payload.get("evidence") is Some(evidence_json) &&
    payload.get("review") is Some(review_json) &&
    payload.get("app_entrypoint") is Some(entrypoint_json) else {
    fail("MoonTown MoonFlow payload is incomplete")
  }
  let run = receiver_strict_fields(run_json, "run", [
    "run_id", "book_id", "work_item_id", "declaration_id", "product_id", "operation",
    "issued_projection_sequence", "issued_work_item_status", "issued_run_outcome",
  ])
  let run_id = json_string_field(run, "run_id")
  let work_item_id = json_string_field(run, "work_item_id")
  let declaration_id = json_string_field(run, "declaration_id")
  guard safe_path_segment(run_id) &&
    safe_path_segment(work_item_id) &&
    safe_path_segment(declaration_id) &&
    json_string_field(run, "product_id") == "moontown" &&
    json_string_field(run, "operation") == operation_ref() &&
    json_string_field(run, "issued_work_item_status") == "ready" else {
    fail(
      "MoonTown MoonFlow run identity or issued state does not match this pack",
    )
  }
  let token = json_string_field(binding, "handoff_token")
  let digest = json_string_field(binding, "handoff_digest")
  let endpoint = receiver_expected_endpoint(run_id, token)
  guard receiver_safe_token(token) &&
    digest == "sha256:\{token}" &&
    digest == sha256_text(payload_json.stringify()) &&
    json_string_field(binding, "request_id") ==
    "receiver-request-\{token[0:24]}" &&
    json_string_field(binding, "attempt_id") ==
    "receiver-attempt-\{token[0:24]}" &&
    json_string_field(binding, "idempotency_key") == "receiver-\{token}" &&
    json_string_field(binding, "intake_path") == endpoint &&
    json_string_field(binding, "status_path") == endpoint + "/status" &&
    json_string_field(binding, "receipt_path") == endpoint + "/receipt" &&
    json_string_field(binding, "return_path") == "/?activity=flow" else {
    fail("MoonTown rejected a MoonFlow receiver binding whose identity drifted")
  }
  let authority = receiver_strict_fields(authority_json, "authority", [
    "requested_authority", "status", "granted",
  ])
  let requested_authority = json_string_field(authority, "requested_authority")
  guard requested_authority == "workspace-mutation" &&
    json_string_field(authority, "status") == "requested" &&
    !receiver_bool_field(authority, "granted") else {
    fail("MoonTown requires an ungranted workspace-mutation authority request")
  }
  let contracts = receiver_strict_fields(contracts_json, "contracts", [
    "capability_status", "input_contracts", "output_contracts", "required_claim",
    "claim_ceiling",
  ])
  let input_contracts = json_strings_field(contracts, "input_contracts")
  let output_contracts = json_strings_field(contracts, "output_contracts")
  guard json_string_field(contracts, "capability_status") == "catalog-bound" &&
    input_contracts == [input_schema_ref()] &&
    output_contracts == [output_schema_ref()] &&
    json_string_field(contracts, "required_claim") == "execution-result" &&
    json_string_field(contracts, "claim_ceiling") == "execution-result" else {
    fail("MoonTown MoonFlow contracts exceed the civic synthesis capability")
  }
  let inputs = receiver_strict_fields(inputs_json, "inputs", [
    "digest", "artifacts",
  ])
  let input_artifacts = json_strings_field(inputs, "artifacts")
  guard input_artifacts.length() == 1 &&
    input_artifacts.all(receiver_safe_ref) &&
    declared_input_digest(root, input_artifacts) ==
    json_string_field(inputs, "digest") else {
    fail("MoonTown MoonFlow input evidence is missing, unsafe, or changed")
  }
  let evidence = receiver_strict_fields(evidence_json, "evidence", [
    "source_digest", "refs",
  ])
  ignore(json_string_field(evidence, "source_digest"))
  guard evidence.get("refs") is Some(Array(evidence_refs)) &&
    !evidence_refs.is_empty() else {
    fail("MoonTown MoonFlow handoff has no evidence references")
  }
  let mut matched_input_evidence = false
  for evidence_ref in evidence_refs {
    let fields = receiver_strict_fields(evidence_ref, "evidence reference", [
      "kind", "reference", "digest",
    ])
    let kind = json_string_field(fields, "kind")
    let reference = json_string_field(fields, "reference")
    let reference_digest = json_string_field(fields, "digest")
    if kind == "input-artifact" {
      guard input_artifacts.contains(reference) &&
        digest_ref(root, reference) == reference_digest else {
        fail("MoonTown MoonFlow input evidence reference changed")
      }
      matched_input_evidence = true
    }
  }
  guard matched_input_evidence else {
    fail("MoonTown MoonFlow handoff did not bind its input artifact evidence")
  }
  let review = receiver_strict_fields(review_json, "review", [
    "required", "status", "acceptance_criteria",
  ])
  let acceptance_criteria = json_strings_field(review, "acceptance_criteria")
  guard receiver_bool_field(review, "required") &&
    json_string_field(review, "status") == "required" &&
    !acceptance_criteria.is_empty() &&
    acceptance_criteria.all(receiver_supported_criterion) else {
    fail(
      "MoonTown cannot truthfully satisfy the declared MoonFlow review criteria",
    )
  }
  let entrypoint = receiver_strict_fields(entrypoint_json, "app entrypoint", [
    "kind", "pack_id", "entrypoint_id", "path", "fallback_path",
  ])
  guard json_string_field(entrypoint, "kind") == "pack-manifest" &&
    json_string_field(entrypoint, "pack_id") == "moontown" &&
    json_string_field(entrypoint, "path") == "/pack-apps/moontown/" else {
    fail("MoonTown MoonFlow handoff targets a different pack entrypoint")
  }
  let handoff = read_json_ref(root, input_artifacts[0])
  let typed : @civic.CivicCommunicationScenarioHandoff = @json.from_json(
    handoff,
  ) catch {
    _ => fail("MoonTown MoonFlow input is not a civic communication handoff")
  }
  validate_research_handoff_bridge(typed)
  let intake_ref = receiver_base(run_id, token) + "/intake.v2.json"
  ignore(immutable_json_ref(root, intake_ref, intake))
  {
    intake,
    root,
    run_id,
    work_item_id,
    declaration_id,
    token,
    digest,
    request_id: json_string_field(binding, "request_id"),
    attempt_id: json_string_field(binding, "attempt_id"),
    idempotency_key: json_string_field(binding, "idempotency_key"),
    requested_authority,
    output_contracts,
    acceptance_criteria,
    input_artifacts,
    handoff,
  }
}

///|
fn receiver_add_unique_ref(
  refs : Array[String],
  reference : String,
) -> Unit raise {
  guard receiver_safe_ref(reference) else {
    fail("MoonTown receiver output reference is not workspace-confined")
  }
  if !refs.contains(reference) {
    refs.push(reference)
  }
}

///|
async fn receiver_result_refs(
  receiver : MoonFlowResearchReceiver,
  plan : ResearchHandoffFlowPlan,
  result_package : Json,
) -> Array[String] {
  guard read_json_ref(receiver.root, plan.package_ref) == result_package &&
    result_package is Object(package_fields) &&
    package_fields.get("receipt") is Some(Object(native_receipt)) &&
    package_fields.get("source") is Some(Object(source)) else {
    fail(
      "MoonTown receiver result package is not the persisted synthesis result",
    )
  }
  let refs : Array[String] = []
  receiver_add_unique_ref(refs, plan.package_ref)
  receiver_add_unique_ref(refs, json_string_field(source, "request_ref"))
  receiver_add_unique_ref(refs, json_string_field(source, "result_ref"))
  receiver_add_unique_ref(refs, json_string_field(source, "receipt_ref"))
  guard native_receipt.get("artifact_refs") is Some(Array(artifacts)) else {
    fail("MoonTown receiver native receipt has no artifact references")
  }
  for artifact in artifacts {
    guard artifact is String(reference) else {
      fail(
        "MoonTown receiver native receipt contains a malformed artifact reference",
      )
    }
    receiver_add_unique_ref(
      refs,
      workspace_relative_ref(receiver.root, reference),
    )
  }
  for reference in refs {
    ignore(digest_ref(receiver.root, reference))
  }
  refs
}

///|
async fn validate_existing_receiver_receipt(
  receiver : MoonFlowResearchReceiver,
  receipt : Json,
) -> Unit {
  let fields = receiver_strict_fields(receipt, "receiver receipt", [
    "contract_id", "contract_version", "receipt_id", "handoff_token", "handoff_digest",
    "run_id", "work_item_id", "declaration_id", "product_id", "operation", "request_id",
    "attempt_id", "idempotency_key", "decision", "output_contracts", "output_artifacts",
    "output_digest", "authority", "review", "owner_id", "recorded_at",
  ])
  let artifacts = json_strings_field(fields, "output_artifacts")
  guard json_string_field(fields, "contract_id") ==
    "moonflow.receiver-receipt.v1" &&
    json_string_field(fields, "contract_version") == "1.0.0" &&
    json_string_field(fields, "handoff_token") == receiver.token &&
    json_string_field(fields, "handoff_digest") == receiver.digest &&
    json_string_field(fields, "run_id") == receiver.run_id &&
    json_string_field(fields, "work_item_id") == receiver.work_item_id &&
    json_string_field(fields, "declaration_id") == receiver.declaration_id &&
    json_string_field(fields, "product_id") == "moontown" &&
    json_string_field(fields, "operation") == operation_ref() &&
    json_string_field(fields, "request_id") == receiver.request_id &&
    json_string_field(fields, "attempt_id") == receiver.attempt_id &&
    json_string_field(fields, "idempotency_key") == receiver.idempotency_key &&
    json_string_field(fields, "decision") == "accepted" &&
    json_strings_field(fields, "output_contracts") == receiver.output_contracts &&
    declared_input_digest(receiver.root, artifacts) ==
    json_string_field(fields, "output_digest") else {
    fail("MoonTown persisted receiver receipt no longer matches its handoff")
  }
}

///|
pub async fn moonflow_research_handoff(
  workspace : String,
  intake : Json,
) -> Json {
  decode_moonflow_research_receiver(workspace, intake).handoff
}

///|
pub async fn prepare_moonflow_research_receipt(
  workspace : String,
  intake : Json,
  result_package : Json,
  callback_http_status : Int,
  recorded_at : String,
) -> Json {
  guard callback_http_status >= 200 && callback_http_status < 300 else {
    fail("MoonTown cannot settle MoonFlow before MoonFind accepts the result")
  }
  let receiver = decode_moonflow_research_receiver(workspace, intake)
  let plan = ensure_research_handoff_flow_plan(
    workspace,
    receiver.handoff,
    recorded_at,
    false,
  )
  let base = receiver_base(receiver.run_id, receiver.token)
  let receiver_receipt_ref = base + "/receiver-receipt.v1.json"
  match read_optional_json_ref(receiver.root, receiver_receipt_ref) {
    Some(existing) => {
      validate_existing_receiver_receipt(receiver, existing)
      return existing
    }
    None => ()
  }
  let refs = receiver_result_refs(receiver, plan, result_package)
  let authority_ref = base + "/authority-receipt.v1.json"
  let review_ref = base + "/review-receipt.v1.json"
  let authority : Json = {
    "contract_id": "moontown.moonflow-authority-receipt.v1",
    "contract_version": "1.0.0",
    "run_id": receiver.run_id,
    "work_item_id": receiver.work_item_id,
    "handoff_token": receiver.token,
    "handoff_digest": receiver.digest,
    "requested_authority": receiver.requested_authority,
    "decision": "granted",
    "scope": "persist the declared civic synthesis result and return its correlated MoonFind callback",
    "result_package_ref": plan.package_ref,
    "callback_transport": "moonfind.moontown-result-ingest.v1",
    "callback_http_status": callback_http_status,
    "recorded_at": recorded_at,
  }
  ignore(immutable_json_ref(receiver.root, authority_ref, authority))
  receiver_add_unique_ref(refs, authority_ref)
  let criteria_json : Array[Json] = receiver.acceptance_criteria.map(criterion => {
    "criterion": criterion,
    "satisfied": true,
    "evidence_refs": refs.copy(),
    "note": "MoonTown persisted independent participant artifacts and a completed synthesis that remains explicitly pending named-human review; no knowledge acceptance is claimed.",
  })
  let review : Json = {
    "contract_id": "moontown.moonflow-output-review.v1",
    "contract_version": "1.0.0",
    "review_id": "review-\{receiver.token[0:24]}",
    "decision": "accepted",
    "scope": "operational output acceptance only; synthesis knowledge remains pending named-human review",
    "criteria": Json::array(criteria_json),
    "recorded_at": recorded_at,
  }
  ignore(immutable_json_ref(receiver.root, review_ref, review))
  receiver_add_unique_ref(refs, review_ref)
  let receipt : Json = {
    "contract_id": "moonflow.receiver-receipt.v1",
    "contract_version": "1.0.0",
    "receipt_id": "receipt-\{receiver.token[0:24]}",
    "handoff_token": receiver.token,
    "handoff_digest": receiver.digest,
    "run_id": receiver.run_id,
    "work_item_id": receiver.work_item_id,
    "declaration_id": receiver.declaration_id,
    "product_id": "moontown",
    "operation": operation_ref(),
    "request_id": receiver.request_id,
    "attempt_id": receiver.attempt_id,
    "idempotency_key": receiver.idempotency_key,
    "decision": "accepted",
    "output_contracts": receiver.output_contracts,
    "output_artifacts": refs,
    "output_digest": declared_input_digest(receiver.root, refs),
    "authority": {
      "requested_authority": receiver.requested_authority,
      "decision": "granted",
      "receipt_ref": authority_ref,
    },
    "review": {
      "review_id": "review-\{receiver.token[0:24]}",
      "decision": "accepted",
      "reviewer_id": "moontown-receiver-verifier",
      "review_authority_id": "moontown-declared-output-policy",
      "criteria": Json::array(criteria_json),
    },
    "owner_id": "moontown-local-operator",
    "recorded_at": recorded_at,
  }
  ignore(immutable_json_ref(receiver.root, receiver_receipt_ref, receipt))
  validate_existing_receiver_receipt(receiver, receipt)
  receipt
}
