///|
pub fn marketplace_action_request_state_name(
  state : MarketplaceActionRequestState,
) -> String {
  match state {
    ActionRequested => "requested"
    ActionRejected => "rejected"
    ActionAcceptedPendingHandoff => "accepted_pending_handoff"
    ActionHandoffQueued => "handoff_queued"
    ActionRuntimeAcknowledged => "runtime_acknowledged"
    ActionRunning => "running"
    ActionSucceeded => "succeeded"
    ActionFailed => "failed"
  }
}

///|
fn marketplace_action_requires_publisher_decision(action_id : String) -> Bool {
  action_id == "try" ||
  action_id == "install" ||
  action_id == "invite" ||
  action_id == "request_access"
}

///|
fn canonical_marketplace_expiry(value : String) -> Bool {
  value.length() == 20 &&
  value[4] == '-' &&
  value[7] == '-' &&
  value[10] == 'T' &&
  value[13] == ':' &&
  value[16] == ':' &&
  value[19] == 'Z'
}

///|
fn marketplace_action_request_by_id(
  state : MarketplaceState,
  request_id : String,
) -> MarketplaceActionRequest? {
  for request in state.action_requests {
    if request.request_id == request_id {
      return Some(request)
    }
  }
  None
}

///|
fn replace_marketplace_action_request(
  state : MarketplaceState,
  replacement : MarketplaceActionRequest,
) -> MarketplaceState {
  let requests = state.action_requests.filter(request => {
    request.request_id != replacement.request_id
  })
  requests.push(replacement)
  { ..state, action_requests: requests, version: state.version + 1 }
}

///|
fn marketplace_action_request_wire(
  request : MarketplaceActionRequest,
  principal : MarketplacePrincipal,
) -> Json {
  {
    "contract_id": "moontown.marketplace-action-request.v1",
    "request_id": request.request_id,
    "listing_kind": listing_kind_name(request.listing_kind),
    "listing_id": request.listing_id,
    "action_id": request.action_id,
    "requester_principal_id": request.requester_principal_id,
    "publisher_principal_id": request.publisher_principal_id,
    "request_message": request.request_message,
    "state": marketplace_action_request_state_name(request.state),
    "version": request.version,
    "decision_summary": request.decision_summary,
    "instruction": request.instruction,
    "execution_bounds": match request.execution_bounds {
      Some(bounds) => bounds.to_json()
      None => Json::null()
    },
    "execution_handoff_id": optional_string_wire(request.execution_handoff_id),
    "worker_run_id": optional_string_wire(request.worker_run_id),
    "runtime_status": request.runtime_status,
    "result_summary": request.result_summary,
    "result_evidence_refs": request.result_evidence_refs.to_json(),
    "created_at_ms": request.created_at_ms.to_string(),
    "decided_at_ms": match request.decided_at_ms {
      Some(value) => value.to_string().to_json()
      None => Json::null()
    },
    "updated_at_ms": request.updated_at_ms.to_string(),
    "viewer_role": if principal.principal_id == request.publisher_principal_id {
      "publisher"
    } else {
      "requester"
    },
    "can_decide": principal.principal_id == request.publisher_principal_id &&
    request.state == ActionRequested,
    "can_retry_handoff": principal.principal_id ==
    request.publisher_principal_id &&
    request.state == ActionAcceptedPendingHandoff,
  }
}

///|
pub fn marketplace_visible_action_requests(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
) -> Json {
  let requests : Array[Json] = []
  for request in state.action_requests.rev() {
    if request.requester_principal_id == principal.principal_id ||
      request.publisher_principal_id == principal.principal_id {
      requests.push(marketplace_action_request_wire(request, principal))
    }
  }
  {
    "contract_id": "moontown.marketplace-action-requests.v1",
    "requests": requests,
    "request_count": requests.length(),
  }
}

///|
pub fn marketplace_action_request_projection(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  request_id : String,
) -> Json raise {
  let request = marketplace_action_request_by_id(state, request_id).unwrap_or_else(() => {
      fail("marketplace action request not found")
    },
  )
  if request.requester_principal_id != principal.principal_id &&
    request.publisher_principal_id != principal.principal_id {
    fail("marketplace action request is not visible to this principal")
  }
  marketplace_action_request_wire(request, principal)
}

///|
pub fn marketplace_prepare_action_handoff(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  draft : ActionRequestResumeDraft,
) -> Json raise {
  let request = marketplace_action_request_by_id(state, draft.request_id).unwrap_or_else(() => {
      fail("marketplace action request not found")
    },
  )
  if request.publisher_principal_id != principal.principal_id ||
    request.state != ActionAcceptedPendingHandoff ||
    request.version != draft.expected_version {
    fail("marketplace action handoff retry is unauthorized or stale")
  }
  marketplace_action_request_wire(request, principal)
}

///|
fn validate_marketplace_execution_bounds(
  draft : ActionRequestDecisionDraft,
) -> MarketplaceExecutionBounds raise {
  if !(draft.claim_ceiling == "evidence-only" ||
    draft.claim_ceiling == "draft" ||
    draft.claim_ceiling == "reviewable") ||
    draft.max_cost_micro_usd <= 0L ||
    draft.max_cost_micro_usd > 2000000L ||
    draft.max_runtime_ms <= 0L ||
    draft.max_runtime_ms > 300000L ||
    draft.max_tokens <= 0L ||
    draft.max_tokens > 12000L ||
    draft.max_artifacts <= 0 ||
    draft.max_artifacts > 3 ||
    !canonical_marketplace_expiry(draft.expires_at) {
    fail("marketplace execution must stay within the visible v1 ceilings")
  }
  {
    claim_ceiling: draft.claim_ceiling,
    max_cost_micro_usd: draft.max_cost_micro_usd,
    max_runtime_ms: draft.max_runtime_ms,
    max_tokens: draft.max_tokens,
    max_artifacts: draft.max_artifacts,
    web_search: draft.web_search,
    expires_at: draft.expires_at,
  }
}

///|
pub fn marketplace_decide_action_request(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  draft : ActionRequestDecisionDraft,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  let current = marketplace_action_request_by_id(state, draft.request_id).unwrap_or_else(() => {
      fail("marketplace action request not found")
    },
  )
  if current.publisher_principal_id != principal.principal_id ||
    current.expected_version != draft.expected_version ||
    current.version != draft.expected_version {
    fail("marketplace action request decision is unauthorized or stale")
  }
  let decision = draft.decision.trim().to_owned().to_lower()
  let summary = validate_public_text(
    "action request decision summary",
    draft.decision_summary,
    1000,
  )
  if decision == "reject" {
    if current.state != ActionRequested {
      fail("only a requested marketplace action can be rejected")
    }
    let rejected = {
      ..current,
      state: ActionRejected,
      expected_version: current.version + 1,
      decision_summary: summary,
      decided_at_ms: Some(now_ms),
      updated_at_ms: now_ms,
      version: current.version + 1,
    }
    return marketplace_action_request_notification(
      replace_marketplace_action_request(state, rejected),
      rejected,
      "Marketplace request declined",
      summary,
      now_ms~,
    )
  }
  if decision != "accept" || current.state != ActionRequested {
    fail("only a requested marketplace action can be accepted")
  }
  let instruction = validate_public_text(
    "marketplace execution instruction",
    draft.instruction,
    2000,
  )
  let accepted = {
    ..current,
    state: ActionAcceptedPendingHandoff,
    expected_version: current.version + 1,
    decision_summary: summary,
    instruction,
    execution_bounds: Some(validate_marketplace_execution_bounds(draft)),
    runtime_status: "pending_handoff",
    decided_at_ms: Some(now_ms),
    updated_at_ms: now_ms,
    version: current.version + 1,
  }
  marketplace_action_request_notification(
    replace_marketplace_action_request(state, accepted),
    accepted,
    "Marketplace request approved",
    "The publisher approved bounded execution. MoonTown is preparing a MoonClaw handoff.",
    now_ms~,
  )
}

///|
fn marketplace_action_request_notification(
  state : MarketplaceState,
  request : MarketplaceActionRequest,
  title : String,
  summary : String,
  now_ms~ : UInt64,
) -> MarketplaceState {
  let notification : TownNotification = {
    notification_id: "action-state:\{request.request_id}:\{request.version}",
    principal_id: request.requester_principal_id,
    kind: "marketplace_action_status",
    title,
    summary,
    object_kind: "marketplace_action_request",
    object_id: request.request_id,
    created_at_ms: now_ms,
    read_at_ms: None,
    version: 1,
  }
  {
    ..state,
    notifications: state.notifications + [notification],
    version: state.version + 1,
  }
}

///|
pub fn marketplace_bind_action_handoff(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  draft : ActionRequestHandoffDraft,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  let current = marketplace_action_request_by_id(state, draft.request_id).unwrap_or_else(() => {
      fail("marketplace action request not found")
    },
  )
  if current.publisher_principal_id != principal.principal_id ||
    current.state != ActionAcceptedPendingHandoff ||
    current.version != draft.expected_version ||
    !valid_symbolic_id(draft.handoff_id) ||
    !draft.handoff_id.has_prefix("supervisor-execution-") {
    fail("marketplace handoff binding is unauthorized, stale, or invalid")
  }
  let queued = {
    ..current,
    state: ActionHandoffQueued,
    expected_version: current.version + 1,
    execution_handoff_id: Some(draft.handoff_id),
    runtime_status: "pending_transport",
    updated_at_ms: now_ms,
    version: current.version + 1,
  }
  marketplace_action_request_notification(
    replace_marketplace_action_request(state, queued),
    queued,
    "Marketplace work queued",
    "The approved request is now in the governed MoonClaw handoff queue.",
    now_ms~,
  )
}

///|
fn marketplace_state_for_runtime_status(
  status : String,
) -> MarketplaceActionRequestState raise {
  match status {
    "pending_transport" | "claimed_for_transport" => ActionHandoffQueued
    "runtime_acknowledged" | "pending_provider" => ActionRuntimeAcknowledged
    "running" | "waiting_for_input" => ActionRunning
    "succeeded" => ActionSucceeded
    "runtime_failed" | "failed" | "cancelled" => ActionFailed
    _ => fail("unsupported marketplace runtime status")
  }
}

///| Trusted local reconciliation from the existing supervisor/MoonClaw

///| receipt chain. This function is not exposed as a public HTTP operation.
pub fn marketplace_reconcile_action_request_runtime(
  state : MarketplaceState,
  draft : ActionRequestRuntimeDraft,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  let mut found : MarketplaceActionRequest? = None
  for request in state.action_requests {
    if request.execution_handoff_id == Some(draft.handoff_id) {
      found = Some(request)
    }
  }
  let current = found.unwrap_or_else(() => {
    fail("marketplace action request handoff not found")
  })
  let next_state = marketplace_state_for_runtime_status(draft.runtime_status)
  if current.state == ActionSucceeded || current.state == ActionFailed {
    if current.state == next_state {
      return state
    }
    fail("terminal marketplace action state cannot be rewritten")
  }
  let draft_worker_run_id = if draft.worker_run_id.is_empty() {
    None
  } else {
    Some(draft.worker_run_id)
  }
  if current.runtime_status == draft.runtime_status &&
    current.worker_run_id == draft_worker_run_id {
    return state
  }
  let result_summary = if draft.result_summary.is_empty() {
    current.result_summary
  } else {
    validate_public_text(
      "marketplace runtime result summary", draft.result_summary, 2000,
    )
  }
  let evidence = normalized_terms(draft.result_evidence_refs)
  let reconciled = {
    ..current,
    state: next_state,
    expected_version: current.version + 1,
    worker_run_id: if draft.worker_run_id.is_empty() {
      current.worker_run_id
    } else {
      Some(draft.worker_run_id)
    },
    runtime_status: draft.runtime_status,
    result_summary,
    result_evidence_refs: if evidence.is_empty() {
      current.result_evidence_refs
    } else {
      evidence
    },
    updated_at_ms: now_ms,
    version: current.version + 1,
  }
  let title = match next_state {
    ActionRuntimeAcknowledged => "Marketplace worker accepted"
    ActionRunning => "Marketplace work is running"
    ActionSucceeded => "Marketplace work completed"
    ActionFailed => "Marketplace work needs attention"
    _ => "Marketplace work updated"
  }
  marketplace_action_request_notification(
    replace_marketplace_action_request(state, reconciled),
    reconciled,
    title,
    if result_summary.is_empty() { draft.runtime_status } else { result_summary },
    now_ms~,
  )
}
