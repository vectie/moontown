///|
async fn result_from_durable_receipt(
  root : String,
  request : FlowRequest,
  handoff : @civic.CivicCommunicationScenarioHandoff,
  result_ref : String,
) -> Json {
  let receipt_ref = native_receipt_ref(request)
  let receipt = decode_native_receipt(read_json_ref(root, receipt_ref))
  validate_native_receipt(receipt, handoff)
  let output_ref = synthesis_result_ref(request)
  let output : Json = {
    "contract_id": "moontown.civic-synthesis-result.v1",
    "operation_ref": operation_ref(),
    "request_id": request.request_id,
    "attempt_id": request.attempt_id,
    "idempotency_key": request.idempotency_key,
    "handoff_id": handoff.handoff_id,
    "producer": handoff.producer,
    "producer_run_id": handoff.producer_run_id,
    "scenario_id": receipt.scenario_id,
    "round_id": receipt.round_id,
    "round_number": receipt.round_number,
    "execution_status": receipt.status,
    "review_status": receipt.review_status,
    "accepted": false,
    "claim_ceiling": "execution-result",
    "reducer_kind": receipt.reducer_kind,
    "participant_count": receipt.participant_count,
    "reviewable_output_count": receipt.reviewable_output_count,
    "receipt_ref": receipt_ref,
    "evidence": Json::array(evidence_json(root, receipt_ref, receipt)),
    "summary": receipt.summary,
  }
  let output_text = immutable_json_ref(root, output_ref, output)
  validate_result_evidence(root, output)
  let succeeded = receipt.status == "completed"
  let result : Json = {
    "result_id": "result-\{request.attempt_id}-\{if succeeded { "succeeded" } else { "failed" }}",
    "request_id": request.request_id,
    "attempt_id": request.attempt_id,
    "idempotency_key": request.idempotency_key,
    "product_id": "moontown",
    "external_job_id": "moontown-\{request.attempt_id}",
    "status": if succeeded {
      "succeeded"
    } else {
      "failed"
    },
    "output_digest": sha256_text(output_text),
    "output_artifacts": [output_ref],
    "error_kind": if succeeded {
      ""
    } else {
      "civic-synthesis-\{receipt.status}"
    },
    "compensable": false,
    "recorded_at": request.created_at,
  }
  ignore(immutable_json_ref(root, result_ref, result))
  result
}

///|
async fn validate_existing_result(
  root : String,
  request : FlowRequest,
  result : Json,
) -> Unit {
  let fields = json_object(result, "adapter result")
  if json_string_field(fields, "request_id") != request.request_id ||
    json_string_field(fields, "attempt_id") != request.attempt_id ||
    json_string_field(fields, "idempotency_key") != request.idempotency_key ||
    json_string_field(fields, "product_id") != "moontown" {
    fail("MoonTown adapter result belongs to a different request")
  }
  guard fields.get("output_artifacts") is Some(Array([String(output_ref)])) else {
    fail("MoonTown adapter result must name exactly one synthesis result")
  }
  let output_text = @fs.read_file(scoped_path(root, output_ref)).text()
  if json_string_field(fields, "output_digest") != sha256_text(output_text) {
    fail("MoonTown adapter result output digest does not match")
  }
  validate_result_evidence(root, @json.parse(output_text))
}

///|
async fn execute_with_mode(
  workspace : String,
  request_ref : String,
  result_ref : String,
  reducer_mode : @civic.CivicCommunicationReductionMode,
) -> Json {
  let root = resolve_workspace(workspace)
  let request = decode_flow_request(read_json_ref(root, request_ref))
  if declared_input_digest(root, request.input_artifacts) !=
    request.input_digest {
    fail("MoonTown Flow request input digest does not match its artifacts")
  }
  let (handoff_ref, handoff) = find_handoff(root, request)
  match read_optional_json_ref(root, result_ref) {
    Some(result) => {
      validate_existing_result(root, request, result)
      return result
    }
    None => ()
  }
  if @fs.exists(scoped_path(root, native_receipt_ref(request))) {
    return result_from_durable_receipt(root, request, handoff, result_ref)
  }
  ignore(
    @civic_runtime.bootstrap_civic_communication_handoff_file(
      scoped_path(root, handoff_ref),
      scoped_path(root, native_receipt_ref(request)),
      book_catalog_path=scoped_path(
        root, ".moonsuite/products/moontown/book-catalog.json",
      ),
      workspace_base=root,
      reducer_mode~,
      run_inline=reducer_mode is @civic.MoonClawReducer,
    ),
  )
  result_from_durable_receipt(root, request, handoff, result_ref)
}

///|
pub async fn execute(
  workspace : String,
  request_ref : String,
  result_ref : String,
) -> Json {
  execute_with_mode(workspace, request_ref, result_ref, @civic.MoonClawReducer)
}

///|
pub async fn reconcile(
  workspace : String,
  request_ref : String,
  result_ref : String,
) -> Json {
  let root = resolve_workspace(workspace)
  let request = decode_flow_request(read_json_ref(root, request_ref))
  if declared_input_digest(root, request.input_artifacts) !=
    request.input_digest {
    fail("MoonTown Flow reconciliation found changed input artifacts")
  }
  let (_, handoff) = find_handoff(root, request)
  match read_optional_json_ref(root, result_ref) {
    Some(result) => {
      validate_existing_result(root, request, result)
      result
    }
    None =>
      if @fs.exists(scoped_path(root, native_receipt_ref(request))) {
        result_from_durable_receipt(root, request, handoff, result_ref)
      } else {
        fail(
          "MoonTown Flow outcome is unknown: no durable civic receipt exists; do not retry automatically",
        )
      }
  }
}
