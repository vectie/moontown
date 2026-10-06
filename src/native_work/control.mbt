///|
fn cancel_body(work : Work, reservation : Reservation) -> String {
  (
    {
      "protocol": "mooncode.v1",
      "session_id": reservation.session_id,
      "book_root": reservation.execution_root,
      "model_workspace": reservation.model_workspace,
      "model": reservation.model,
      "command": "cancel",
      "packet": { "command_id": work.id + "-cancel" },
      "payload": { "target_command_id": reservation.command_id },
    } : Json).stringify()
}

///|
fn cancel_waiting(work : Work, reason : String, now : UInt64) -> Work {
  waiting(work, "cancel_pending", reason, now)
}

///|
fn selected_work(
  state : State,
  id : String,
  expected_revision : Int,
) -> Work raise {
  if state.revision != expected_revision {
    fail("native_work_revision_conflict")
  }
  match state.work.iter().find_first(work => work.id == id) {
    Some(work) => work
    None => fail("native_work_not_found")
  }
}

///|
async fn saved_client(
  work : Work,
  injected : @native_code_control.Client?,
) -> Result[@native_code_control.Client, String] {
  let reservation = work.reservation.unwrap()
  let loaded = match injected {
    Some(client) => Ok(client)
    None =>
      @native_code_control.load(
        path=reservation.config_path,
        owner_workspace=work.request.owner_workspace,
      )
  }
  match loaded {
    Err(reason) => Err(reason)
    Ok(client) =>
      if client.owner_workspace != work.request.owner_workspace {
        Err("control_owner_mismatch")
      } else if client.config_path != reservation.config_path {
        Err("control_reference_changed")
      } else {
        Ok(client)
      }
  }
}

///|
/// Persist intent before transmission. A reserved but absent native target is
/// uncertain: cancellation must never resubmit the original to make it appear.
pub async fn cancel(
  id : String,
  expected_revision : Int,
  now : UInt64,
  path? : String = default_path(),
  client? : @native_code_control.Client,
) -> Work {
  let lock = lock_state(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_unlocked(path)
  let original = selected_work(state, id, expected_revision)
  if terminal(original.state) {
    return original
  }
  guard original.reservation is Some(reservation) else {
    let cancelled = {
      ..original,
      state: "cancelled",
      blocked_reason: "cancelled_before_reservation",
      receipt: if original.request.kind == "wenyu_build" {
        wenyu_unreserved_receipt(original, "cancelled_before_reservation")
      } else {
        original.receipt
      },
      last_attempt_at_ms: now,
      retry_after_ms: 0UL,
    }
    save_unlocked(path, replace_work(state, cancelled))
    return cancelled
  }
  let mut work = original
  if work.control is None {
    let body = cancel_body(work, reservation)
    work = {
      ..cancel_waiting(work, "cancellation_requested", now),
      control: Some({
        command_id: work.id + "-cancel",
        target_command_id: reservation.command_id,
        request_body: body,
        body_digest: digest(body),
        status: "pending",
        last_attempt_at_ms: 0UL,
        evidence: Json::null(),
      }),
    }
    save_unlocked(path, replace_work(state, work))
  }
  work = cancel_with_saved_client(work, client, now, path)
  save_unlocked(path, replace_work(load_unlocked(path), work))
  work
}

///|
async fn cancel_with_saved_client(
  work : Work,
  injected : @native_code_control.Client?,
  now : UInt64,
  path : String,
) -> Work {
  let client = match saved_client(work, injected) {
    Ok(client) => client
    Err(reason) => return cancel_waiting(work, reason, now)
  }
  // Observe first so an already finished task remains its true outcome.
  let observed = observe_with_client(work, client, now)
  if terminal(observed.state) ||
    observed.control.unwrap().status == "already_terminal" {
    return observed
  }
  // A replacement authority is usable only after the saved original command
  // has been observed there. Contradictory identity must never authorize POST.
  if !observed.observed_instances.contains(client.instance_id) ||
    [
      "native_observation_identity_mismatch", "native_command_identity_conflict",
      "native_command_body_mismatch", "native_receipt_identity_mismatch", "native_receipt_command_binding_mismatch",
    ].contains(observed.blocked_reason) {
    return observed
  }
  let control = work.control.unwrap()
  let reservation = work.reservation.unwrap()
  let base = "/v1/code/sessions/" +
    @native_code_control.url_component(reservation.session_id)
  let work = {
    ..observed,
    control: Some({ ..control, last_attempt_at_ms: now, }),
  }
  // The attempt is durable too; a lost response or process restart retains
  // this same control and never substitutes an original prompt submission.
  save_unlocked(path, replace_work(load_unlocked(path), work))
  let reply = client.request("POST", base + "/turns", control.request_body)
  let reason = match reply {
    Ok(value) if same_binding(value, reservation) &&
      field(value, "accepted") == true.to_json() &&
      text(value, "command_id") == control.command_id =>
      "cancellation_awaiting_native_evidence"
    Ok(_) => "native_cancel_acceptance_identity_mismatch"
    Err(reason) => reason
  }
  // Even a conflict/lost response can race with completion. Never infer the
  // original outcome from HTTP acceptance or a control service projection.
  let observed = observe_with_client(work, client, now)
  if terminal(observed.state) ||
    observed.control.unwrap().status == "already_terminal" {
    observed
  } else {
    cancel_waiting(observed, reason, now)
  }
}

///|
/// Observe saved native work only. No prompt/control POST, reservation, model
/// lookup, Book result application, or source edit occurs on this path.
pub async fn refresh(
  id : String,
  expected_revision : Int,
  now : UInt64,
  path? : String = default_path(),
  client? : @native_code_control.Client,
) -> Work {
  let lock = lock_state(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_unlocked(path)
  let original = selected_work(state, id, expected_revision)
  if terminal(original.state) || original.reservation is None {
    return original
  }
  let observed = match saved_client(original, client) {
    Ok(client) => observe_with_client(original, client, now)
    Err(reason) =>
      if original.control is Some(_) {
        cancel_waiting(original, reason, now)
      } else {
        waiting(original, "waiting_control", reason, now)
      }
  }
  if observed.to_json() != original.to_json() {
    save_unlocked(path, replace_work(state, observed))
  }
  observed
}
