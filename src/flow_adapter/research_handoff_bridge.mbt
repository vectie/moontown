///|
priv struct ResearchHandoffFlowPlan {
  root : String
  handoff : @civic.CivicCommunicationScenarioHandoff
  request : FlowRequest
  request_ref : String
  result_ref : String
  package_ref : String
}

///|
fn research_handoff_bridge_base(
  handoff : @civic.CivicCommunicationScenarioHandoff,
) -> String raise {
  guard safe_path_segment(handoff.handoff_id) else {
    fail("MoonTown research handoff id must be a safe path segment")
  }
  ".moonsuite/products/moontown/research-handoffs/\{handoff.handoff_id}"
}

///|
fn validate_research_handoff_bridge(
  handoff : @civic.CivicCommunicationScenarioHandoff,
) -> Unit raise {
  let issues = @civic.validate_civic_communication_handoff(handoff)
  if !issues.is_empty() {
    fail("MoonTown rejected the research handoff: \{issues.join("; ")}")
  }
  guard handoff.producer == "moonfind" &&
    safe_path_segment(handoff.producer_run_id) &&
    handoff.scenario.communication_pattern_id == Some("research-salon") &&
    handoff.scenario.review_gate == "named-human" &&
    !handoff.scenario.review_owner.is_blank() &&
    handoff.scenario.participants.length() >= 2 else {
    fail(
      "MoonTown accepts this bridge only for a run-bound MoonFind research salon with named-human review",
    )
  }
}

///|
fn validate_research_handoff_flow_request(
  request : FlowRequest,
  handoff : @civic.CivicCommunicationScenarioHandoff,
  handoff_ref : String,
) -> Unit raise {
  validate_flow_request(request)
  guard request.request_id == "request-\{handoff.handoff_id}" &&
    request.run_id == handoff.producer_run_id &&
    request.work_item_id == "research-salon" &&
    request.attempt_id == "attempt-1" &&
    request.idempotency_key == "\{handoff.handoff_id}/research-salon/attempt-1" &&
    request.input_artifacts == [handoff_ref] else {
    fail("MoonTown research handoff Flow identity has drifted")
  }
}

///|
async fn ensure_research_handoff_flow_plan(
  workspace : String,
  handoff_json : Json,
  created_at : String,
  allow_create : Bool,
) -> ResearchHandoffFlowPlan {
  let root = resolve_workspace(workspace)
  let handoff : @civic.CivicCommunicationScenarioHandoff = @json.from_json(
    handoff_json,
  ) catch {
    _ => fail("MoonTown research handoff does not match the civic contract")
  }
  validate_research_handoff_bridge(handoff)
  let base = research_handoff_bridge_base(handoff)
  let handoff_ref = base + "/handoff.v1.json"
  let request_ref = base + "/flow-request.v1.json"
  let result_ref = base + "/flow-result.v1.json"
  let package_ref = base + "/result-package.v1.json"
  ignore(immutable_json_ref(root, handoff_ref, handoff.to_json()))
  let request = match read_optional_json_ref(root, request_ref) {
    Some(value) => decode_flow_request(value)
    None => {
      guard allow_create else {
        fail("MoonTown has no durable research handoff attempt to reconcile")
      }
      let input_digest = declared_input_digest(root, [handoff_ref])
      let value : Json = {
        "request_id": "request-\{handoff.handoff_id}",
        "run_id": handoff.producer_run_id,
        "work_item_id": "research-salon",
        "attempt_id": "attempt-1",
        "idempotency_key": "\{handoff.handoff_id}/research-salon/attempt-1",
        "product_id": "moontown",
        "operation": operation_ref(),
        "requested_authority": "workspace-mutation",
        "input_contracts": [input_schema_ref()],
        "output_contracts": [output_schema_ref()],
        "required_claim": "execution-result",
        "input_digest": input_digest,
        "input_artifacts": [handoff_ref],
        "timeout_ms": 300000,
        "created_at": created_at,
      }
      ignore(immutable_json_ref(root, request_ref, value))
      decode_flow_request(value)
    }
  }
  validate_research_handoff_flow_request(request, handoff, handoff_ref)
  guard declared_input_digest(root, request.input_artifacts) ==
    request.input_digest else {
    fail("MoonTown research handoff evidence changed after preparation")
  }
  { root, handoff, request, request_ref, result_ref, package_ref }
}

///|
async fn research_handoff_output_json(
  plan : ResearchHandoffFlowPlan,
  receipt : @civic.CivicCommunicationExecutionReceipt,
) -> Json {
  guard receipt.status == "completed" &&
    receipt.review_status == "pending" &&
    !receipt.artifact_refs.is_empty() else {
    return Json::null()
  }
  let output_reference = receipt.artifact_refs[receipt.artifact_refs.length() -
    1]
  let output = read_json_ref(
    plan.root,
    workspace_relative_ref(plan.root, output_reference),
  )
  guard output is Object(fields) &&
    fields.get("ideas") is Some(Array(ideas)) &&
    !ideas.is_empty() else {
    fail("MoonTown completed research salon has no typed reducer ideas")
  }
  {
    "contract_id": @civic.civic_reducer_output_contract_id(),
    "scenario_id": plan.handoff.scenario.id,
    "participant_book_ids": plan.handoff.scenario.participants.map(participant => {
      participant.book_id
    }),
    "ideas": Json::array(ideas),
  }
}

///|
async fn research_handoff_result_package(
  plan : ResearchHandoffFlowPlan,
  adapter_result : Json,
) -> Json {
  let receipt_ref = native_receipt_ref(plan.request)
  let receipt = decode_native_receipt(read_json_ref(plan.root, receipt_ref))
  validate_native_receipt(receipt, plan.handoff)
  let output = research_handoff_output_json(plan, receipt)
  let result_package : Json = {
    "contract_id": "moonfind.moontown-result-ingest.v1",
    "idempotency_key": plan.request.idempotency_key,
    "handoff_id": plan.handoff.handoff_id,
    "producer_run_id": plan.handoff.producer_run_id,
    "receipt": receipt.to_json(),
    "output": output,
    "source": {
      "contract_id": "moontown.research-handoff-result-source.v1",
      "operation_ref": operation_ref(),
      "request_ref": plan.request_ref,
      "result_ref": plan.result_ref,
      "receipt_ref": receipt_ref,
      "adapter_result": adapter_result,
    },
  }
  ignore(immutable_json_ref(plan.root, plan.package_ref, result_package))
  result_package
}

///|
pub async fn execute_research_handoff(
  workspace : String,
  handoff_json : Json,
  created_at : String,
) -> Json {
  let plan = ensure_research_handoff_flow_plan(
    workspace, handoff_json, created_at, true,
  )
  let result = execute(workspace, plan.request_ref, plan.result_ref)
  research_handoff_result_package(plan, result)
}

///|
pub async fn reconcile_research_handoff(
  workspace : String,
  handoff_json : Json,
  created_at : String,
) -> Json {
  let plan = ensure_research_handoff_flow_plan(
    workspace, handoff_json, created_at, false,
  )
  let result = reconcile(workspace, plan.request_ref, plan.result_ref)
  research_handoff_result_package(plan, result)
}
