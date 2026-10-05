///|
fn order_by_id(state : MarketplaceState, order_id : String) -> OrderRecord? {
  for order in state.orders {
    if order.order_id == order_id {
      return Some(order)
    }
  }
  None
}

///|
fn order_state_name(state : OrderState) -> String {
  match state {
    OrderOpen => "open"
    OrderPendingReview => "pending_review"
    OrderFulfilled => "fulfilled"
    OrderCancelled => "cancelled"
  }
}

///|
fn order_notification(
  principal_id : String,
  order_id : String,
  kind : String,
  title : String,
  summary : String,
  now_ms : UInt64,
  version : Int,
) -> TownNotification {
  {
    notification_id: "order:{order_id}:{kind}:{principal_id}:{version}",
    principal_id,
    kind,
    title,
    summary,
    object_kind: "order",
    object_id: order_id,
    created_at_ms: now_ms,
    read_at_ms: None,
    version: 1,
  }
}

///|
fn replace_order(
  state : MarketplaceState,
  replacement : OrderRecord,
  notification : TownNotification?,
) -> MarketplaceState {
  let orders = state.orders.filter(order => {
    order.order_id != replacement.order_id
  })
  orders.push(replacement)
  let notifications = state.notifications.copy()
  if notification is Some(value) {
    notifications.push(value)
  }
  { ..state, orders, notifications, version: state.version + 1, }
}

///|
fn publish_order(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  draft : OrderDraft,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  if !principal.active ||
    !valid_symbolic_id(draft.order_id) ||
    order_by_id(state, draft.order_id) is Some(_) {
    fail("invalid or already used order_id")
  }
  let title = validate_public_text("order title", draft.title, 160)
  let description = validate_public_text(
    "order description",
    draft.description,
    2000,
  )
  let deliverable = validate_public_text(
    "order deliverable",
    draft.deliverable,
    1000,
  )
  let acceptance_criteria = validate_public_text(
    "order acceptance criteria",
    draft.acceptance_criteria,
    1000,
  )
  if draft.tags.length() > 12 {
    fail("order accepts at most 12 tags")
  }
  let tags : Array[String] = []
  for raw in draft.tags {
    let tag = validate_public_text("order tag", raw, 40).to_lower()
    if !tags.contains(tag) {
      tags.push(tag)
    }
  }
  let orders = state.orders.copy()
  orders.push({
    order_id: draft.order_id,
    requester_principal_id: principal.principal_id,
    tenant_id: principal.tenant_id,
    title,
    description,
    deliverable,
    acceptance_criteria,
    tags,
    state: OrderOpen,
    fulfillments: [],
    created_at_ms: now_ms,
    updated_at_ms: now_ms,
    version: 1,
  })
  { ..state, orders, version: state.version + 1, }
}

///|
fn submit_order_fulfillment(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  draft : OrderFulfillmentDraft,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  let order = order_by_id(state, draft.order_id).unwrap_or_else(() => {
    fail("order not found")
  })
  if !principal.active ||
    order.requester_principal_id == principal.principal_id ||
    order.state != OrderOpen ||
    order.version != draft.expected_version {
    fail("order is unavailable for fulfillment or version changed")
  }
  let summary = validate_public_text("fulfillment summary", draft.summary, 2000)
  if draft.evidence_refs.length() > 16 {
    fail("fulfillment accepts at most 16 evidence references")
  }
  let evidence_refs : Array[String] = []
  for evidence_ref in draft.evidence_refs {
    if !valid_symbolic_id(evidence_ref) {
      fail("evidence references must be symbolic ids")
    }
    if !evidence_refs.contains(evidence_ref) {
      evidence_refs.push(evidence_ref)
    }
  }
  let fulfillments = order.fulfillments.copy()
  fulfillments.push({
    fulfiller_principal_id: principal.principal_id,
    summary,
    evidence_refs,
    submitted_at_ms: now_ms,
    decision: "pending",
    decision_summary: "",
    decided_at_ms: None,
  })
  replace_order(
    state,
    {
      ..order,
      state: OrderPendingReview,
      fulfillments,
      updated_at_ms: now_ms,
      version: order.version + 1,
    },
    Some(
      order_notification(
        order.requester_principal_id,
        order.order_id,
        "order_fulfillment_submitted",
        "An order fulfillment needs review",
        order.title,
        now_ms,
        order.version + 1,
      ),
    ),
  )
}

///|
fn decide_order_fulfillment(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  draft : OrderDecisionDraft,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  let order = order_by_id(state, draft.order_id).unwrap_or_else(() => {
    fail("order not found")
  })
  if !principal.active ||
    order.requester_principal_id != principal.principal_id ||
    order.state != OrderPendingReview ||
    order.version != draft.expected_version {
    fail("order decision is unauthorized or version changed")
  }
  if draft.decision != "accept" && draft.decision != "reject" {
    fail("order decision must be accept or reject")
  }
  let decision_summary = validate_public_text(
    "order decision summary",
    draft.decision_summary,
    1000,
  )
  let last = order.fulfillments
    .last()
    .unwrap_or_else(() => fail("order has no pending fulfillment"))
  if last.decision != "pending" {
    fail("order has no pending fulfillment")
  }
  let fulfillments = order.fulfillments.copy()
  fulfillments[fulfillments.length() - 1] = {
    ..last,
    decision: if draft.decision == "accept" {
      "accepted"
    } else {
      "rejected"
    },
    decision_summary,
    decided_at_ms: Some(now_ms),
  }
  replace_order(
    state,
    {
      ..order,
      state: if draft.decision == "accept" {
        OrderFulfilled
      } else {
        OrderOpen
      },
      fulfillments,
      updated_at_ms: now_ms,
      version: order.version + 1,
    },
    Some(
      order_notification(
        last.fulfiller_principal_id,
        order.order_id,
        "order_fulfillment_{draft.decision}",
        if draft.decision == "accept" {
          "Your fulfillment was accepted"
        } else {
          "Your fulfillment needs changes"
        },
        order.title,
        now_ms,
        order.version + 1,
      ),
    ),
  )
}

///|
fn cancel_order(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  draft : OrderCancelDraft,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  let order = order_by_id(state, draft.order_id).unwrap_or_else(() => {
    fail("order not found")
  })
  if !principal.active ||
    order.requester_principal_id != principal.principal_id ||
    order.state != OrderOpen ||
    order.version != draft.expected_version {
    fail("order cannot be cancelled or version changed")
  }
  replace_order(
    state,
    {
      ..order,
      state: OrderCancelled,
      updated_at_ms: now_ms,
      version: order.version + 1,
    },
    None,
  )
}

///|
fn order_card(order : OrderRecord, principal : MarketplacePrincipal) -> Json {
  let owner = order.requester_principal_id == principal.principal_id
  let visible_fulfillments : Array[Json] = []
  for fulfillment in order.fulfillments {
    if owner || fulfillment.fulfiller_principal_id == principal.principal_id {
      visible_fulfillments.push({
        "fulfiller_principal_id": fulfillment.fulfiller_principal_id,
        "summary": fulfillment.summary,
        "evidence_refs": fulfillment.evidence_refs.to_json(),
        "submitted_at_ms": fulfillment.submitted_at_ms.to_string(),
        "decision": fulfillment.decision,
        "decision_summary": fulfillment.decision_summary,
        "decided_at_ms": match fulfillment.decided_at_ms {
          Some(value) => value.to_string().to_json()
          None => Json::null()
        },
      })
    }
  }
  {
    "contract_id": "moontown.order.v1",
    "order_id": order.order_id,
    "requester_principal_id": order.requester_principal_id,
    "title": order.title,
    "description": order.description,
    "deliverable": order.deliverable,
    "acceptance_criteria": order.acceptance_criteria,
    "tags": order.tags.to_json(),
    "state": order_state_name(order.state),
    "version": order.version,
    "created_at_ms": order.created_at_ms.to_string(),
    "updated_at_ms": order.updated_at_ms.to_string(),
    "fulfillments": visible_fulfillments.to_json(),
    "can_fulfill": order.state == OrderOpen && !owner,
    "can_cancel": order.state == OrderOpen && owner,
    "can_decide": order.state == OrderPendingReview && owner,
  }
}

///|
fn visible_orders(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  query : String,
) -> Json {
  let terms = query_terms(query)
  let orders : Array[Json] = []
  for order in state.orders.rev() {
    let participant = order.requester_principal_id == principal.principal_id ||
      order.fulfillments.any(fulfillment => {
        fulfillment.fulfiller_principal_id == principal.principal_id
      })
    if order.state != OrderOpen && !participant {
      continue
    }
    let searchable = (order.title +
    " " +
    order.description +
    " " +
    order.tags.join(" ")).to_lower()
    if terms.all(term => searchable.contains(term)) {
      orders.push(order_card(order, principal))
    }
  }
  {
    "contract_id": "moontown.orderlist.v1",
    "orders": orders,
    "result_count": orders.length(),
  }
}
