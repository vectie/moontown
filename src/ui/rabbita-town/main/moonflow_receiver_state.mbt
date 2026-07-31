///|
fn safe_moonflow_run_id(value : String) -> Bool {
  !value.is_empty() &&
  value.all(ch => {
    (ch >= 'a' && ch <= 'z') ||
    (ch >= 'A' && ch <= 'Z') ||
    (ch >= '0' && ch <= '9') ||
    ch == '-' ||
    ch == '_' ||
    ch == '.'
  })
}

///|
fn safe_moonflow_token(value : String) -> Bool {
  value.length() == 64 &&
  value.all(ch => (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f'))
}

///|
fn moonflow_receiver_endpoint(request : MoonFlowReceiverRequest) -> String {
  "/api/moonflow/runs/\{request.run_id}/handoffs/\{request.handoff_token}"
}

///|
fn initial_moonflow_receiver_state() -> MoonFlowReceiverState {
  let request = {
    run_id: current_browser_query_param("moonflow_run").trim().to_owned(),
    handoff_token: current_browser_query_param("moonflow_handoff")
    .trim()
    .to_owned(),
  }
  if request.run_id.is_empty() && request.handoff_token.is_empty() {
    NoMoonFlowReceiver
  } else if !safe_moonflow_run_id(request.run_id) ||
    !safe_moonflow_token(request.handoff_token) {
    BlockedMoonFlowReceiver(
      "The MoonFlow launch is incomplete or unsafe. It requires one safe run id and one 64-character lowercase handoff token.",
    )
  } else {
    LoadingMoonFlowReceiver(request)
  }
}

///|
fn moonflow_receiver_validation_issues(
  request : MoonFlowReceiverRequest,
  intake : MoonFlowReceiverIntake,
  status : MoonFlowReceiverStatus,
) -> Array[String] {
  let issues : Array[String] = []
  let endpoint = moonflow_receiver_endpoint(request)
  if intake.contract_id != "moonflow.operator-handoff.v2" ||
    intake.contract_version != "2.0.0" {
    issues.push("unsupported operator-handoff contract")
  }
  if intake.binding.handoff_token != request.handoff_token ||
    intake.binding.handoff_digest != "sha256:\{request.handoff_token}" ||
    intake.binding.intake_path != endpoint ||
    intake.binding.status_path != endpoint + "/status" ||
    intake.binding.receipt_path != endpoint + "/receipt" ||
    intake.binding.return_path != "/?activity=flow" {
    issues.push(
      "receiver binding does not match the exact launch token and paths",
    )
  }
  if intake.payload.action_kind != "open-product" ||
    intake.payload.run.run_id != request.run_id ||
    intake.payload.run.product_id != "moontown" ||
    intake.payload.run.operation !=
    "moontown/civic.communication.synthesize@0.1.0" ||
    intake.payload.run.issued_work_item_status != "ready" {
    issues.push("the run item is not a ready MoonTown civic synthesis")
  }
  if intake.payload.authority.requested_authority != "workspace-mutation" ||
    intake.payload.authority.status != "requested" ||
    intake.payload.authority.granted {
    issues.push("authority request is not an ungranted workspace mutation")
  }
  if intake.payload.contracts.capability_status != "catalog-bound" ||
    intake.payload.contracts.input_contracts !=
    ["moontown/civic-communication-handoff@1.0.0"] ||
    intake.payload.contracts.output_contracts !=
    ["moontown/civic-synthesis-result@1.0.0"] ||
    intake.payload.contracts.required_claim != "execution-result" ||
    intake.payload.contracts.claim_ceiling != "execution-result" {
    issues.push("declared contracts exceed the MoonTown capability")
  }
  if !intake.payload.review.required ||
    intake.payload.review.status != "required" ||
    intake.payload.review.acceptance_criteria.is_empty() {
    issues.push("the declared review boundary is missing")
  }
  if intake.payload.app_entrypoint.kind != "pack-manifest" ||
    intake.payload.app_entrypoint.pack_id != "moontown" ||
    intake.payload.app_entrypoint.path != "/pack-apps/moontown/" {
    issues.push("the handoff targets a different pack entrypoint")
  }
  if status.contract_id != "moonflow.receiver-status.v1" ||
    status.contract_version != "1.0.0" ||
    status.run_id != request.run_id ||
    status.handoff_token != request.handoff_token ||
    status.handoff_digest != intake.binding.handoff_digest ||
    status.intake_path != endpoint ||
    status.status_path != endpoint + "/status" ||
    status.receipt_path != endpoint + "/receipt" ||
    status.return_path != intake.binding.return_path {
    issues.push("MoonFlow status does not match the inspected handoff")
  }
  issues
}

///|
fn resolve_moonflow_receiver_inspection(
  request : MoonFlowReceiverRequest,
  raw : String,
) -> MoonFlowReceiverState {
  let reply : MoonFlowReceiverInspectionReply = @json.from_json(
    @json.parse(raw),
  ) catch {
    _ =>
      return BlockedMoonFlowReceiver(
        "MoonFlow receiver inspection returned an invalid typed response.",
      )
  }
  if reply.contract_version != "moontown.moonflow-receiver-inspection.reply.v1" ||
    reply.requested_run_id != request.run_id ||
    reply.requested_handoff_token != request.handoff_token {
    return BlockedMoonFlowReceiver(
      "MoonFlow receiver inspection identity drifted from the launch URL.",
    )
  }
  if !reply.ok {
    return BlockedMoonFlowReceiver(
      if reply.error.is_empty() {
        "MoonFlow intake is unavailable."
      } else {
        reply.error
      },
    )
  }
  guard reply.intake is Some(intake_json) && reply.status is Some(status_json) else {
    return BlockedMoonFlowReceiver(
      "MoonFlow returned no intake or receiver status.",
    )
  }
  let intake : MoonFlowReceiverIntake = @json.from_json(intake_json) catch {
    _ =>
      return BlockedMoonFlowReceiver(
        "MoonFlow intake did not match the operator-handoff contract.",
      )
  }
  let status : MoonFlowReceiverStatus = @json.from_json(status_json) catch {
    _ =>
      return BlockedMoonFlowReceiver(
        "MoonFlow status did not match the receiver-status contract.",
      )
  }
  let issues = moonflow_receiver_validation_issues(request, intake, status)
  if !issues.is_empty() {
    BlockedMoonFlowReceiver(
      "MoonFlow validation failed: " + issues.join("; ") + ".",
    )
  } else if status.status == "accepted" && status.stage == "applied" {
    SettledMoonFlowReceiver(request, intake, status, None)
  } else if status.status == "pending" && status.work_item_status == "ready" {
    ReadyMoonFlowReceiver(request, intake, status)
  } else {
    BlockedMoonFlowReceiver(
      "MoonFlow receiver is in unsupported state \{status.status}/\{status.work_item_status}.",
    )
  }
}

///|
fn resolve_moonflow_receiver_settlement(
  request : MoonFlowReceiverRequest,
  intake : MoonFlowReceiverIntake,
  previous_status : MoonFlowReceiverStatus,
  expected_action : String,
  raw : String,
) -> MoonFlowReceiverState {
  let reply : MoonFlowReceiverSettlementReply = @json.from_json(
    @json.parse(raw),
  ) catch {
    _ =>
      return BlockedMoonFlowReceiver(
        "MoonTown settlement returned invalid JSON. The durable product attempt may still be reconciled from the same launch.",
      )
  }
  if reply.contract_version != "moontown.moonflow-receiver-settlement.reply.v1" ||
    reply.action != expected_action {
    return BlockedMoonFlowReceiver(
      "MoonTown blocked a receiver settlement whose action identity drifted.",
    )
  }
  let status = match reply.receiver_status {
    Some(value) => @json.from_json(value) catch { _ => previous_status }
    None => previous_status
  }
  SettledMoonFlowReceiver(request, intake, status, Some(reply))
}
