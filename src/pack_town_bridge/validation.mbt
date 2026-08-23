///|
fn add_issue(
  issues : Array[PackTownBridgeIssue],
  path : String,
  message : String,
) -> Unit {
  issues.push({ path, message })
}

///|
fn require_text(
  issues : Array[PackTownBridgeIssue],
  path : String,
  value : String,
) -> Unit {
  if value.trim().is_empty() {
    add_issue(issues, path, "must not be blank")
  }
}

///|
fn require_identifier(
  issues : Array[PackTownBridgeIssue],
  path : String,
  value : String,
) -> Unit {
  if !@pack.safe_identifier(value) {
    add_issue(issues, path, "must be a safe identifier")
  }
}

///|
fn require_ref(
  issues : Array[PackTownBridgeIssue],
  path : String,
  value : String,
) -> Unit {
  if !@pack.safe_artifact_path(value) {
    add_issue(issues, path, "must be a safe relative reference")
  }
}

///|
fn require_unique(
  issues : Array[PackTownBridgeIssue],
  path : String,
  values : Array[String],
) -> Unit {
  let seen : Map[String, Bool] = Map([])
  for index, value in values {
    if seen.contains(value) {
      add_issue(issues, "\{path}[\{index}]", "must be unique")
    } else {
      seen[value] = true
    }
  }
}

///|
fn validate_refs(
  issues : Array[PackTownBridgeIssue],
  path : String,
  values : Array[String],
) -> Unit {
  for index, value in values {
    require_ref(issues, "\{path}[\{index}]", value)
  }
  require_unique(issues, path, values)
}

///|
fn validate_identifiers(
  issues : Array[PackTownBridgeIssue],
  path : String,
  values : Array[String],
) -> Unit {
  for index, value in values {
    require_identifier(issues, "\{path}[\{index}]", value)
  }
  require_unique(issues, path, values)
}

///|
fn declared_operation(
  activation : @host.HostActivationProjection,
  operation_id : String,
) -> @pack.ToolDeclaration? {
  for tool in activation.tools {
    if tool.id == operation_id {
      return Some(tool)
    }
  }
  None
}

///|
fn declares_projection_provider(
  activation : @host.HostActivationProjection,
) -> Bool {
  activation.provider_ports.any(port => {
    port.id == projection_provider_port_id() &&
    port.version == projection_provider_port_version()
  })
}

///|
fn validate_activation(
  activation : @host.HostActivationProjection,
  issues : Array[PackTownBridgeIssue],
) -> Unit {
  if activation.contract != "moonsuite.pack-host-activation.v1" {
    add_issue(
      issues, "activation.contract", "must be moonsuite.pack-host-activation.v1",
    )
  }
  require_identifier(issues, "activation.pack_id", activation.pack_id)
  require_identifier(issues, "activation.product_id", activation.product_id)
  require_text(issues, "activation.version", activation.version)
}

///|
fn validate_subject(
  activation : @host.HostActivationProjection,
  subject : PackTownSubject,
  index : Int,
  issues : Array[PackTownBridgeIssue],
) -> Unit {
  let base = "subjects[\{index}]"
  require_ref(issues, base + ".subject_ref", subject.subject_ref)
  require_identifier(issues, base + ".schema_id", subject.schema_id)
  require_text(issues, base + ".title", subject.title)
  require_text(issues, base + ".summary", subject.summary)
  require_identifier(issues, base + ".lifecycle_state", subject.lifecycle_state)
  require_identifier(issues, base + ".attention", subject.attention)
  validate_refs(issues, base + ".place_refs", subject.place_refs)
  validate_refs(issues, base + ".related_refs", subject.related_refs)
  validate_refs(issues, base + ".workflow_refs", subject.workflow_refs)
  validate_refs(issues, base + ".run_refs", subject.run_refs)
  validate_refs(issues, base + ".evidence_refs", subject.evidence_refs)
  validate_identifiers(issues, base + ".operation_ids", subject.operation_ids)
  for operation_index, operation_id in subject.operation_ids {
    if declared_operation(activation, operation_id) is None {
      add_issue(
        issues,
        "\{base}.operation_ids[\{operation_index}]",
        "must name an operation declared by the activated pack",
      )
    }
  }
  if !(subject.domain_payload is Object(_)) {
    add_issue(issues, base + ".domain_payload", "must be an object")
  }
}

///|
pub fn projection_conformance_issues(
  activation : @host.HostActivationProjection,
  projection : PackTownProjection,
) -> Array[PackTownBridgeIssue] {
  let issues : Array[PackTownBridgeIssue] = []
  validate_activation(activation, issues)
  if projection.contract_id != projection_contract_id() {
    add_issue(issues, "contract_id", "must be \{projection_contract_id()}")
  }
  if projection.pack_id != activation.pack_id {
    add_issue(issues, "pack_id", "must match the activated pack")
  }
  if projection.product_id != activation.product_id {
    add_issue(issues, "product_id", "must match the activated product")
  }
  if projection.version != activation.version {
    add_issue(issues, "version", "must match the activated pack version")
  }
  if !declares_projection_provider(activation) {
    add_issue(
      issues,
      "activation.provider_ports",
      "must declare \{projection_provider_port_id()}@\{projection_provider_port_version()}",
    )
  }
  require_text(issues, "generated_at", projection.generated_at)
  let subject_refs = projection.subjects.map(subject => subject.subject_ref)
  require_unique(issues, "subjects.subject_ref", subject_refs)
  for index, subject in projection.subjects {
    validate_subject(activation, subject, index, issues)
  }
  issues
}

///|
fn safe_claim_ceiling(value : String) -> Bool {
  ["observation", "research-evidence", "execution-result", "accepted-knowledge"].contains(
    value,
  )
}

///|
pub fn candidate_conformance_issues(
  activation : @host.HostActivationProjection,
  candidate : TownPackCandidate,
) -> Array[PackTownBridgeIssue] {
  let issues : Array[PackTownBridgeIssue] = []
  validate_activation(activation, issues)
  if candidate.contract_id != candidate_contract_id() {
    add_issue(issues, "contract_id", "must be \{candidate_contract_id()}")
  }
  require_ref(issues, "candidate_ref", candidate.candidate_ref)
  require_ref(issues, "origin_ref", candidate.origin_ref)
  if candidate.target_pack_id != activation.pack_id {
    add_issue(issues, "target_pack_id", "must match the activated pack")
  }
  require_identifier(
    issues,
    "intake_operation_id",
    candidate.intake_operation_id,
  )
  match declared_operation(activation, candidate.intake_operation_id) {
    None =>
      add_issue(
        issues, "intake_operation_id", "must name an operation declared by the activated pack",
      )
    Some(operation) => {
      if operation.input_schema_id != candidate_input_schema_id() {
        add_issue(
          issues,
          "intake_operation_id",
          "declared operation must accept \{candidate_input_schema_id()}",
        )
      }
      if operation.authority is (ExternalEffect | PhysicalEffect) {
        add_issue(
          issues, "intake_operation_id", "candidate intake cannot directly request external or physical effect",
        )
      }
    }
  }
  require_identifier(issues, "submitted_by", candidate.submitted_by)
  require_text(issues, "submitted_at", candidate.submitted_at)
  require_text(issues, "title", candidate.title)
  require_text(issues, "rationale", candidate.rationale)
  if !safe_claim_ceiling(candidate.claim_ceiling) {
    add_issue(
      issues, "claim_ceiling", "must remain within MoonTown knowledge authority",
    )
  }
  validate_refs(issues, "evidence_refs", candidate.evidence_refs)
  if !(candidate.domain_payload is Object(_)) {
    add_issue(issues, "domain_payload", "must be an object")
  }
  issues
}

///|
pub fn resolve_candidate_route(
  activation : @host.HostActivationProjection,
  candidate : TownPackCandidate,
) -> Result[CandidateRoute, Array[PackTownBridgeIssue]] {
  let issues = candidate_conformance_issues(activation, candidate)
  if !issues.is_empty() {
    return Err(issues)
  }
  guard declared_operation(activation, candidate.intake_operation_id)
    is Some(operation) else {
    return Err([
      {
        path: "intake_operation_id",
        message: "declared operation disappeared during route resolution",
      },
    ])
  }
  Ok({
    pack_id: activation.pack_id,
    product_id: activation.product_id,
    version: activation.version,
    operation_id: operation.id,
    authority: operation.authority,
    review_required: operation.review_required,
  })
}
