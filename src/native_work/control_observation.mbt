///|
async fn observe_with_client(
  work : Work,
  client : @native_code_control.Client,
  now : UInt64,
) -> Work {
  let reservation = work.reservation.unwrap()
  let base = "/v1/code/sessions/" +
    @native_code_control.url_component(reservation.session_id)
  let query = "?book_root=" +
    @native_code_control.url_component(reservation.execution_root)
  let results : Array[Json] = []
  for route in ["/runtime-claim", "/runtime-events", "/runtime-service"] {
    match client.request("GET", base + route + query, "") {
      Ok(value) => results.push(value)
      Err(reason) => {
        let reason = if reason == "native_not_found" {
          if work.observed_instances.contains(client.instance_id) {
            "native_target_unobserved"
          } else {
            "runtime_continuity_unverified"
          }
        } else {
          reason
        }
        return if work.control is Some(_) {
          cancel_waiting(work, reason, now)
        } else {
          waiting(work, "dispatch_uncertain", reason, now)
        }
      }
    }
  }
  let observed = observe(
    work,
    results[0],
    results[1],
    results[2],
    client.instance_id,
    now,
  )
  guard work.control is Some(control) else { return observed }
  if observed.state == "completed" || observed.state == "failed" {
    return {
      ..observed,
      control: Some({
        ..control,
        status: "already_terminal",
        evidence: observed.receipt,
      }),
    }
  }
  // Native completion can precede an owner result that cannot yet be
  // reconciled (for example an unavailable final source). Preserve the owner
  // blocker without attempting to cancel already finished native execution.
  if native_terminal_receipt(results[0], reservation) is Some(receipt) &&
    ["runtime-completed", "runtime-failed", "runtime-rejected"].contains(
      text(receipt, "status"),
    ) {
    return {
      ..observed,
      control: Some({
        ..control,
        status: "already_terminal",
        evidence: receipt,
      }),
    }
  }
  // A terminal cancellation must be pinned to this exact control, and its
  // independently observed delivered receipt must bind the saved body/target.
  if observed.state == "cancelled" {
    if text(observed.receipt, "control_command_id") != control.command_id {
      return cancel_waiting(work, "native_cancel_target_control_mismatch", now)
    }
    let mut selected = Json::null()
    let mut count = 0
    for
      category in [
        "claimable_commands", "claimed_commands", "order_blocked_commands", "delivered_commands",
        "invalid_commands",
      ] {
      for item in rows(results[0], category) {
        if text(item, "command_id") == control.command_id {
          selected = item
          count += 1
        }
      }
    }
    let receipt = field(selected, "receipt")
    let body = @json.parse(control.request_body)
    if count != 1 ||
      field(selected, "command") != body ||
      !same_binding(receipt, reservation) ||
      text(receipt, "command_id") != control.command_id ||
      field(receipt, "command") != body ||
      text(receipt, "status") != "runtime-completed" ||
      text(receipt, "control") != "cancel" ||
      text(receipt, "target_command_id") != reservation.command_id {
      return cancel_waiting(
        work, "native_cancel_control_evidence_unverified", now,
      )
    }
    return {
      ..observed,
      control: Some({ ..control, status: "cancelled", evidence: receipt, }),
    }
  }
  cancel_waiting(
    observed,
    if observed.blocked_reason == "" {
      "cancellation_awaiting_native_evidence"
    } else {
      observed.blocked_reason
    },
    now,
  )
}

///|
fn native_terminal_receipt(claim : Json, reservation : Reservation) -> Json? {
  if !same_binding(claim, reservation) {
    return None
  }
  let body = @json.parse(reservation.request_body) catch { _ => return None }
  let mut selected = Json::null()
  let mut count = 0
  for
    category in [
      "claimable_commands", "claimed_commands", "order_blocked_commands", "delivered_commands",
      "invalid_commands",
    ] {
    for item in rows(claim, category) {
      if text(item, "command_id") == reservation.command_id {
        selected = item
        count += 1
      }
    }
  }
  let receipt = field(selected, "receipt")
  if count == 1 &&
    field(selected, "command") == body &&
    same_binding(receipt, reservation) &&
    text(receipt, "command_id") == reservation.command_id &&
    field(receipt, "command") == body {
    Some(receipt)
  } else {
    None
  }
}
