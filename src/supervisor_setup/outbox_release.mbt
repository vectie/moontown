///|
pub async fn SupervisorSetupApplication::release_runtime_handoff(
  self : SupervisorSetupApplication,
  transport_id : String,
  body : String,
) -> Json {
  supervisor_store_mutex.acquire()
  defer supervisor_store_mutex.release()
  let parsed = @json.parse(body)
  guard parsed is Object(fields) else {
    fail("runtime release body must be an object")
  }
  let kind = json_string(fields, "kind").to_lower()
  let handoff_id = json_string_alias(fields, "handoffId", "handoff_id")
  let expected_cursor = json_int_alias(
    fields, "expectedCursor", "expected_cursor",
  )
  let store = self.load_store()
  if store.cursor != expected_cursor {
    fail("supervisor setup cursor conflict")
  }
  if kind == "activation" {
    let current = latest_activation_handoff(store, handoff_id).unwrap_or_else(() => {
      fail("activation handoff not found")
    })
    if current.claimed_by != Some(transport_id) ||
      current.status != "claimed_for_transport" {
      fail("transport does not own the claimed activation handoff")
    }
    let released = {
      ..current,
      status: "pending_transport",
      revision: current.revision + 1,
      claimed_by: None,
      runtime_command: None,
    }
    let next = {
      ..store,
      cursor: store.cursor + 1,
      activation_handoffs: store.activation_handoffs + [released],
    }
    self.save_store(next)
    return {
      "ok": true,
      "cursor": next.cursor,
      "handoffId": handoff_id,
      "status": released.status,
    }
  }
  if kind == "execution" {
    let current = latest_execution_handoff(store, handoff_id).unwrap_or_else(() => {
      fail("execution handoff not found")
    })
    if current.claimed_by != Some(transport_id) ||
      current.status != "claimed_for_transport" {
      fail("transport does not own the claimed execution handoff")
    }
    let released = {
      ..current,
      status: "pending_transport",
      revision: current.revision + 1,
      claimed_by: None,
    }
    let next = {
      ..store,
      cursor: store.cursor + 1,
      execution_handoffs: store.execution_handoffs + [released],
    }
    self.save_store(next)
    return {
      "ok": true,
      "cursor": next.cursor,
      "handoffId": handoff_id,
      "status": released.status,
    }
  }
  fail("runtime handoff kind must be activation or execution")
}

///|
pub async fn SupervisorSetupApplication::release_bookkeeper_review(
  self : SupervisorSetupApplication,
  transport_id : String,
  body : String,
) -> Json {
  supervisor_store_mutex.acquire()
  defer supervisor_store_mutex.release()
  let parsed = @json.parse(body)
  guard parsed is Object(fields) else {
    fail("Bookkeeper release body must be an object")
  }
  let request_id = json_string_alias(fields, "requestId", "request_id")
  let expected_cursor = json_int_alias(
    fields, "expectedCursor", "expected_cursor",
  )
  let store = self.load_store()
  if store.cursor != expected_cursor {
    fail("supervisor setup cursor conflict")
  }
  let current = latest_review_request(store, request_id).unwrap_or_else(() => {
    fail("Bookkeeper review request not found")
  })
  if current.claimed_by != Some(transport_id) ||
    current.state != "claimed_for_transport" {
    fail("transport does not own the claimed Bookkeeper review request")
  }
  let released = {
    ..current,
    state: current.resume_state.unwrap_or("pending_bookkeeper"),
    revision: current.revision + 1,
    claimed_by: None,
    resume_state: None,
  }
  let next = {
    ..store,
    cursor: store.cursor + 1,
    review_requests: store.review_requests + [released],
  }
  self.save_store(next)
  {
    "ok": true,
    "cursor": next.cursor,
    "requestId": request_id,
    "state": released.state,
    "projectionState": bookkeeper_projection_state(released.state),
    "pendingHumanGate": bookkeeper_human_gate_state(released.state),
  }
}
