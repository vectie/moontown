///|
fn mailbox_key(value : String) -> String {
  @crypto.bytes_to_hex_string(@crypto.sha256(@encoding/utf8.encode(value)))[0:32].to_owned()
}

///|
fn pack_bridge_product_ref(product_id : String) -> String {
  ".moonsuite/products/\{product_id}/pack-bridge"
}

///|
fn pack_bridge_product_path(workspace : String, product_id : String) -> String {
  workspace + "/" + pack_bridge_product_ref(product_id)
}

///|
pub fn candidate_inbox_ref(
  product_id : String,
  candidate_ref : String,
) -> String {
  pack_bridge_product_ref(product_id) +
  "/inbox/candidates/\{mailbox_key(candidate_ref)}.json"
}

///|
pub fn candidate_acknowledgement_ref(
  product_id : String,
  candidate_ref : String,
) -> String {
  pack_bridge_product_ref(product_id) +
  "/outbox/candidate-receipts/\{mailbox_key(candidate_ref)}.json"
}

///|
pub fn projection_outbox_ref(product_id : String) -> String {
  pack_bridge_product_ref(product_id) + "/outbox/projection.json"
}

///|
async fn write_mailbox_json(path : String, value : Json) -> Unit {
  ensure_parent_directory(path)
  let content = value.stringify(indent=2) + "\n"
  if @fs.exists(path) {
    guard @fs.read_file(path).text() == content else {
      fail("pack bridge mailbox identity is already bound to another payload")
    }
    return
  }
  let temporary = path + ".next"
  @fs.write_file(
    temporary,
    @encoding/utf8.encode(content),
    create_mode=CreateNew,
    permission=0o644,
    sync=Full,
  )
  @fs.rename(temporary, path, replace=false)
}

///|
async fn deliver_candidate_to_pack(
  workspace : String,
  product_id : String,
  candidate : @pack_town_bridge.TownPackCandidate,
) -> String {
  let reference = candidate_inbox_ref(product_id, candidate.candidate_ref)
  write_mailbox_json(workspace + "/" + reference, candidate.to_json())
  reference
}

///|
fn projection_for_pack(
  state : PackBridgeRuntimeState,
  pack_id : String,
) -> @pack_town_bridge.PackTownProjection? {
  for projection in state.projections.projections {
    if projection.pack_id == pack_id {
      return Some(projection)
    }
  }
  None
}

///|
fn projection_issue_text(
  issues : Array[@pack_town_bridge.PackTownBridgeIssue],
) -> String {
  issues.map(issue => "\{issue.path}: \{issue.message}").join("; ")
}

///|
fn apply_published_projection(
  state : PackBridgeRuntimeState,
  activation : @host.HostActivationProjection,
  manifest_ref : String,
  projection : @pack_town_bridge.PackTownProjection,
  occurred_at : String,
) -> Unit {
  guard lifecycle_index(state, activation.pack_id) is Some(index) else {
    return
  }
  let lifecycle = activated_lifecycle(
    Some(state.lifecycles[index]),
    activation.pack_id,
    activation.version,
    occurred_at,
    manifest_ref,
  )
  match
    @pack_town_bridge.reconcile_projection(
      state.projections,
      activation,
      projection,
    ) {
    Ok(registry) => {
      if projection_for_pack(state, activation.pack_id) == Some(projection) &&
        lifecycle.stage == "projecting" {
        return
      }
      state.projections = registry
      replace_lifecycle(
        state,
        @pack_town_bridge.reduce_pack_lifecycle(
          lifecycle,
          lifecycle_event(lifecycle, "projection-accepted", occurred_at, [
            projection_outbox_ref(activation.product_id),
          ]),
        ).unwrap(),
      )
    }
    Err(issues) => {
      let detail = projection_issue_text(issues)
      if lifecycle.stage == "degraded" && lifecycle.issue == Some(detail) {
        return
      }
      replace_lifecycle(
        state,
        @pack_town_bridge.reduce_pack_lifecycle(
          lifecycle,
          lifecycle_event(
            lifecycle,
            "projection-rejected",
            occurred_at,
            [projection_outbox_ref(activation.product_id)],
            issue=Some(detail),
          ),
        ).unwrap(),
      )
    }
  }
}

///|
fn acknowledgement_event(decision : String) -> String? {
  match decision {
    "received" => Some("receive")
    "accepted" => Some("accept")
    "rejected" => Some("reject")
    "blocked" => Some("block")
    _ => None
  }
}

///|
fn apply_candidate_acknowledgement(
  state : PackBridgeRuntimeState,
  activation : @host.HostActivationProjection,
  acknowledgement : @pack_town_bridge.PackCandidateAcknowledgement,
  acknowledgement_ref : String,
) -> Unit raise {
  guard acknowledgement.contract_id ==
    @pack_town_bridge.candidate_acknowledgement_contract_id() &&
    acknowledgement.pack_id == activation.pack_id &&
    acknowledgement.occurred_at.trim() != "" &&
    candidate_index(state, acknowledgement.candidate_ref) is Some(index) &&
    candidate_envelope_index(state, acknowledgement.candidate_ref) is Some(_) else {
    fail("pack candidate acknowledgement identity is invalid")
  }
  let current = state.candidates[index]
  guard current.pack_id == acknowledgement.pack_id &&
    current.operation_id == acknowledgement.operation_id else {
    fail("pack candidate acknowledgement route does not match delivery")
  }
  if acknowledgement.decision == "received" &&
    current.status == "review-pending" &&
    current.evidence_refs.contains(acknowledgement_ref) {
    return
  }
  if ["accepted", "rejected", "blocked"].contains(current.status) {
    guard current.status == acknowledgement.decision else {
      fail("pack candidate acknowledgement conflicts with settled receipt")
    }
    return
  }
  guard acknowledgement_event(acknowledgement.decision) is Some(event) else {
    fail("pack candidate acknowledgement decision is unsupported")
  }
  let evidence_refs = acknowledgement.evidence_refs.copy()
  if !evidence_refs.contains(acknowledgement_ref) {
    evidence_refs.push(acknowledgement_ref)
  }
  let issue = if event == "accept" { None } else { acknowledgement.issue }
  guard @pack_town_bridge.transition_candidate_receipt(
      current,
      event,
      acknowledgement.occurred_at,
      evidence_refs,
      issue~,
    )
    is Ok(settled) else {
    fail("pack candidate acknowledgement cannot settle receipt")
  }
  replace_candidate(state, settled)
}

///|
fn record_mailbox_failure(
  state : PackBridgeRuntimeState,
  activation : @host.HostActivationProjection,
  occurred_at : String,
  issue : String,
) -> Unit {
  guard lifecycle_index(state, activation.pack_id) is Some(index) else {
    return
  }
  let lifecycle = state.lifecycles[index]
  if lifecycle.stage == "degraded" && lifecycle.issue == Some(issue) {
    return
  }
  replace_lifecycle(
    state,
    @pack_town_bridge.reduce_pack_lifecycle(
      lifecycle,
      lifecycle_event(
        lifecycle,
        "verification-failed",
        occurred_at,
        [pack_bridge_product_ref(activation.product_id) + "/outbox"],
        issue=Some(issue),
      ),
    ).unwrap(),
  )
}

///|
async fn reconcile_pack_mailbox(
  workspace : String,
  state : PackBridgeRuntimeState,
  activation : @host.HostActivationProjection,
  manifest_ref : String,
  occurred_at : String,
) -> Unit {
  let root = pack_bridge_product_path(workspace, activation.product_id)
  let projection_path = root + "/outbox/projection.json"
  if @fs.exists(projection_path) {
    let projection : @pack_town_bridge.PackTownProjection = @json.from_json(
      @json.parse(@fs.read_file(projection_path).text()),
    )
    apply_published_projection(
      state, activation, manifest_ref, projection, occurred_at,
    )
  }
  let receipts_path = root + "/outbox/candidate-receipts"
  if !@fs.exists(receipts_path) {
    return
  }
  for name in @sync_fs.read_dir(receipts_path) {
    if !name.has_suffix(".json") {
      continue
    }
    let acknowledgement_path = receipts_path + "/" + name
    let acknowledgement : @pack_town_bridge.PackCandidateAcknowledgement = @json.from_json(
      @json.parse(@fs.read_file(acknowledgement_path).text()),
    )
    apply_candidate_acknowledgement(
      state,
      activation,
      acknowledgement,
      pack_bridge_product_ref(activation.product_id) +
      "/outbox/candidate-receipts/" +
      name,
    )
  }
}
