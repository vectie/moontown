///|
fn decode_handoff(value : Json) -> @civic.CivicCommunicationScenarioHandoff? {
  Some(@json.from_json(value)) catch {
    _ => None
  }
}

///|
async fn find_handoff(
  root : String,
  request : FlowRequest,
) -> (String, @civic.CivicCommunicationScenarioHandoff) {
  for reference in request.input_artifacts {
    let parsed = read_json_ref(root, reference) catch { _ => continue }
    match decode_handoff(parsed) {
      Some(handoff) =>
        if @civic.validate_civic_communication_handoff(handoff).is_empty() {
          return (reference, handoff)
        }
      None => ()
    }
  }
  fail(
    "MoonTown Flow request has no valid moontown.civic.communication.handoff.v1 input",
  )
}

///|
fn decode_native_receipt(
  value : Json,
) -> @civic.CivicCommunicationExecutionReceipt raise {
  @json.from_json(value) catch {
    _ => fail("MoonTown native civic receipt is malformed")
  }
}

///|
fn validate_native_receipt(
  receipt : @civic.CivicCommunicationExecutionReceipt,
  handoff : @civic.CivicCommunicationScenarioHandoff,
) -> Unit raise {
  if receipt.contract_version !=
    @civic.civic_communication_receipt_contract_version() ||
    receipt.handoff_id != handoff.handoff_id ||
    receipt.producer != handoff.producer ||
    receipt.producer_run_id != handoff.producer_run_id ||
    receipt.consumer != "moontown" ||
    receipt.scenario_id != handoff.scenario.id {
    fail("MoonTown native civic receipt identity does not match the handoff")
  }
  if !["completed", "blocked", "rejected"].contains(receipt.status) {
    fail("MoonTown native civic receipt has an unsupported status")
  }
  if receipt.status == "completed" {
    if receipt.review_status != "pending" ||
      receipt.participant_count < 2 ||
      receipt.reviewable_output_count < 1 ||
      receipt.artifact_refs.is_empty() {
      fail("MoonTown completed civic receipt is not review-ready")
    }
  } else if receipt.review_status != "blocked" ||
    receipt.reviewable_output_count != 0 {
    fail("MoonTown non-completed civic receipt must remain blocked")
  }
}

///|
async fn evidence_json(
  root : String,
  receipt_ref : String,
  receipt : @civic.CivicCommunicationExecutionReceipt,
) -> Array[Json] {
  let references : Array[String] = [receipt_ref]
  for artifact in receipt.artifact_refs {
    let reference = workspace_relative_ref(root, artifact)
    if !references.contains(reference) {
      references.push(reference)
    }
  }
  let evidence : Array[Json] = []
  for reference in references {
    if !@fs.exists(scoped_path(root, reference)) {
      fail("MoonTown declared evidence is missing: \{reference}")
    }
    evidence.push({ "ref": reference, "digest": digest_ref(root, reference) })
  }
  evidence
}

///|
async fn validate_result_evidence(root : String, result : Json) -> Unit {
  let fields = json_object(result, "civic synthesis result")
  if json_string_field(fields, "contract_id") !=
    "moontown.civic-synthesis-result.v1" ||
    json_string_field(fields, "operation_ref") != operation_ref() {
    fail("MoonTown civic synthesis result has the wrong contract identity")
  }
  guard fields.get("accepted") is Some(False) else {
    fail("MoonTown civic synthesis result cannot self-accept")
  }
  guard fields.get("evidence") is Some(Array(evidence)) else {
    fail("MoonTown civic synthesis result requires evidence")
  }
  for item in evidence {
    let identity = json_object(item, "evidence identity")
    let reference = json_string_field(identity, "ref")
    let digest = json_string_field(identity, "digest")
    if digest_ref(root, reference) != digest {
      fail("MoonTown civic synthesis evidence digest changed: \{reference}")
    }
  }
}
