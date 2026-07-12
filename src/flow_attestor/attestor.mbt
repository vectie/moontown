///|
fn object(value : Json, label : String) -> Map[String, Json] raise {
  match value {
    Object(fields) => fields
    _ => fail("MoonTown Flow attestor requires \{label} to be an object")
  }
}

///|
fn string_field(fields : Map[String, Json], name : String) -> String raise {
  match fields.get(name) {
    Some(String(value)) if !value.trim().is_empty() => value
    _ => fail("MoonTown Flow attestor requires \{name}")
  }
}

///|
fn safe_ref(reference : String) -> Bool {
  let value = reference.trim().replace(old="\\", new="/")
  !value.is_empty() &&
  !value.has_prefix("/") &&
  !value.split("/").any(part => part.is_empty() || part == "..")
}

///|
fn scoped_path(workspace : String, reference : String) -> String raise {
  if !safe_ref(reference) {
    fail("MoonTown Flow artifact must be workspace-relative")
  }
  @pathx.join(@pathx.normalize(workspace), reference)
}

///|
async fn read_json(path : String) -> Json {
  @json.parse(@fsx.read_file(path))
}

///|
async fn write_json(path : String, value : Json) -> Unit {
  @fsx.make_directory(@pathx.dirname(path), recursive=true, exists_ok=true)
  @fsx.write_to_file(path, value.stringify(indent=2) + "\n", create=0o644)
}

///|
pub async fn attest(
  workspace : String,
  request_ref : String,
  result_ref : String,
  attestation_ref : String,
  attestor_id : String,
  draft_ref : String,
  final_ref : String,
) -> Unit {
  let request = read_json(scoped_path(workspace, request_ref))
  let request_fields = object(request, "request")
  let operation = string_field(request_fields, "operation")
  if ![
      "deliberate-concept", "deliberate-evidence", "deliberate-design", "deliberate-outcome",
    ].contains(operation) {
    fail("MoonTown does not own the requested Flow operation")
  }
  let result = read_json(scoped_path(workspace, result_ref))
  let result_fields = object(result, "draft result")
  let draft = read_json(scoped_path(workspace, draft_ref))
  let draft_fields = object(draft, "deliberation draft")
  if string_field(draft_fields, "contract_id") != "moontown.deliberation.v1" ||
    string_field(draft_fields, "product_id") != "moontown" {
    fail("MoonTown deliberation draft has the wrong identity")
  }
  let round_json = match draft_fields.get("civic_round") {
    Some(value) => value
    None => fail("MoonTown deliberation draft requires civic_round")
  }
  let round : @emergence.AutonomousCivicRound = @json.from_json(round_json)
  let evaluated = match @emergence.evaluate_autonomous_civic_round(round) {
    Ok(value) => value
    Err(reason) =>
      fail("MoonTown civic evaluation rejected the draft: \{reason}")
  }
  if !evaluated.accepted || !evaluated.autonomous_round_qualified {
    fail("MoonTown requires accepted autonomous emergence with dissent")
  }
  let final_artifact : Json = {
    "contract_id": "moontown.deliberation.v1",
    "product_id": "moontown",
    "operation": operation,
    "selected_contribution_id": evaluated.winner_id,
    "selected_outcome": evaluated.proposal,
    "comparison_criteria": evaluated.comparison_criteria.to_json(),
    "unseeded_idea_ids": evaluated.unseeded_idea_ids.to_json(),
    "dissent_ids": evaluated.dissent_ids.to_json(),
    "minority_ids": evaluated.minority_ids.to_json(),
    "evaluations": evaluated.evaluations.to_json(),
    "coalition_graph": evaluated.coalition_graph.to_json(),
    "stage_receipts": evaluated.stage_receipts.to_json(),
    "review": evaluated.review.to_json(),
    "deliveries": evaluated.deliveries.to_json(),
    "requested_authority": evaluated.requested_authority,
    "emergence_qualified": true,
    "claim_ceiling": "accepted-knowledge",
    "physical_readiness": false,
  }
  write_json(scoped_path(workspace, final_ref), final_artifact)
  write_json(scoped_path(workspace, attestation_ref), {
    "contract_id": "moonflow.product-attestation.v1",
    "attestor_id": attestor_id,
    "product_id": "moontown",
    "request_id": string_field(request_fields, "request_id"),
    "result_id": string_field(result_fields, "result_id"),
    "output_digest": string_field(result_fields, "output_digest"),
    "accepted": true,
    "native_final_artifact": final_ref,
    "operation": operation,
  })
}
