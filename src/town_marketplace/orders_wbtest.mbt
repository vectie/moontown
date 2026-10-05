///|
fn sample_order_draft(order_id : String) -> OrderDraft {
  {
    order_id,
    title: "Prepare a robotics field guide",
    description: "Write a concise guide for new robotics club members.",
    deliverable: "A reviewed MoonBook article",
    acceptance_criteria: "Include setup, safety, and first exercise sections.",
    tags: ["Robotics", "Education"],
  }
}

///|
test "published order can be fulfilled and accepted by distinct principals" {
  let (state, requester, _, fulfiller) = test_state_with_sessions()
  let published = publish_order(
    state,
    requester,
    sample_order_draft("order.robot-guide"),
    now_ms=100UL,
  )
  assert_eq(published.orders[0].state, OrderOpen)
  assert_eq(published.orders[0].tags, ["robotics", "education"])
  let submitted = submit_order_fulfillment(
    published,
    fulfiller,
    {
      order_id: "order.robot-guide",
      expected_version: 1,
      summary: "The article is ready for review.",
      evidence_refs: ["moonbook:robot-guide"],
    },
    now_ms=110UL,
  )
  assert_eq(submitted.orders[0].state, OrderPendingReview)
  assert_eq(submitted.notifications[0].principal_id, requester.principal_id)
  let accepted = decide_order_fulfillment(
    submitted,
    requester,
    {
      order_id: "order.robot-guide",
      expected_version: 2,
      decision: "accept",
      decision_summary: "All requested sections are present.",
    },
    now_ms=120UL,
  )
  assert_eq(accepted.orders[0].state, OrderFulfilled)
  assert_eq(accepted.orders[0].fulfillments[0].decision, "accepted")
  assert_eq(accepted.notifications[1].principal_id, fulfiller.principal_id)
}

///|
test "rejected fulfillment reopens order and keeps the review trail" {
  let (state, requester, _, fulfiller) = test_state_with_sessions()
  let published = publish_order(
    state,
    requester,
    sample_order_draft("order.rework"),
    now_ms=100UL,
  )
  let submitted = submit_order_fulfillment(
    published,
    fulfiller,
    {
      order_id: "order.rework",
      expected_version: 1,
      summary: "A first draft is ready.",
      evidence_refs: [],
    },
    now_ms=110UL,
  )
  let rejected = decide_order_fulfillment(
    submitted,
    requester,
    {
      order_id: "order.rework",
      expected_version: 2,
      decision: "reject",
      decision_summary: "Please add the safety section.",
    },
    now_ms=120UL,
  )
  assert_eq(rejected.orders[0].state, OrderOpen)
  assert_eq(rejected.orders[0].fulfillments[0].decision, "rejected")
  let resubmitted = submit_order_fulfillment(
    rejected,
    fulfiller,
    {
      order_id: "order.rework",
      expected_version: 3,
      summary: "The safety section is included.",
      evidence_refs: [],
    },
    now_ms=130UL,
  )
  assert_eq(resubmitted.orders[0].fulfillments.length(), 2)
}

///|
test "owner cannot fulfill and stale or foreign decisions are denied" {
  let (state, requester, _, fulfiller) = test_state_with_sessions()
  let published = publish_order(
    state,
    requester,
    sample_order_draft("order.policy"),
    now_ms=100UL,
  )
  try
    submit_order_fulfillment(
      published,
      requester,
      {
        order_id: "order.policy",
        expected_version: 1,
        summary: "Self fulfillment",
        evidence_refs: [],
      },
      now_ms=101UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("self fulfillment must be denied")
  }
  let submitted = submit_order_fulfillment(
    published,
    fulfiller,
    {
      order_id: "order.policy",
      expected_version: 1,
      summary: "Submitted for review",
      evidence_refs: [],
    },
    now_ms=110UL,
  )
  try
    decide_order_fulfillment(
      submitted,
      fulfiller,
      {
        order_id: "order.policy",
        expected_version: 2,
        decision: "accept",
        decision_summary: "Approved",
      },
      now_ms=120UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("fulfiller cannot accept own work")
  }
  try
    decide_order_fulfillment(
      submitted,
      requester,
      {
        order_id: "order.policy",
        expected_version: 1,
        decision: "accept",
        decision_summary: "Approved",
      },
      now_ms=120UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("stale version must be denied")
  }
}

///|
test "orderlist connects accounts while hiding other fulfillers' submissions" {
  let (state, requester, _, fulfiller) = test_state_with_sessions()
  let other_tenant = {
    ..fulfiller,
    principal_id: "outside-town",
    tenant_id: "town-b",
  }
  let published = publish_order(
    state,
    requester,
    sample_order_draft("order.private-attempt"),
    now_ms=100UL,
  )
  assert_eq(
    json_card_int(visible_orders(published, other_tenant, ""), "result_count"),
    1,
  )
  let submitted = submit_order_fulfillment(
    published,
    other_tenant,
    {
      order_id: "order.private-attempt",
      expected_version: 1,
      summary: "A draft is ready.",
      evidence_refs: [],
    },
    now_ms=110UL,
  )
  let rejected = decide_order_fulfillment(
    submitted,
    requester,
    {
      order_id: "order.private-attempt",
      expected_version: 2,
      decision: "reject",
      decision_summary: "Needs more detail.",
    },
    now_ms=120UL,
  )
  let new_fulfiller = { ..fulfiller, principal_id: "another-worker", }
  let cards = visible_orders(rejected, new_fulfiller, "robotics")
  assert_eq(json_card_int(cards, "result_count"), 1)
  guard cards is Object(fields) && fields["orders"] is Array([Object(card)]) else {
    fail("expected one order card")
  }
  assert_true(card["fulfillments"] is Array([]))
}

///|
test "older marketplace store loads with an empty orderlist" {
  let old = empty_marketplace_state().to_json()
  guard old is Object(fields) else { fail("expected marketplace object") }
  fields["schema"] = "moontown.marketplace-store.v2".to_json()
  fields.remove("orders")
  let migrated = migrate_marketplace_state_json(old)
  let state : MarketplaceState = @json.from_json(migrated)
  assert_eq(state.schema, marketplace_schema())
  assert_eq(state.orders.length(), 0)
}

///|
async test "order API persists a cross-account fulfillment and decision" {
  let path = "/tmp/moontown-orderlist-wbtest/state.json"
  if @fs.exists(path) {
    @fs.remove(path)
  }
  let requester = test_principal("order-owner", [])
  let fulfiller = {
    ..test_principal("order-worker", []),
    tenant_id: "personal:order-worker",
  }
  let app = marketplace_application(
    path, requester, "session-order-owner", "opaque-order-owner-token",
  )
  let published = app.execute(
    "opaque-order-owner-token",
    "publish-order",
    sample_order_draft("order.api-flow").to_json().stringify(),
    "",
    now_ms=100UL,
  )
  assert_true(published.stringify().contains("order.api-flow"))
  app.synchronize_account_session(
    fulfiller,
    "opaque-order-worker-token",
    now_ms=101UL,
    expires_at_ms=1000UL,
  )
  let fulfillment : OrderFulfillmentDraft = {
    order_id: "order.api-flow",
    expected_version: 1,
    summary: "A complete field guide is ready.",
    evidence_refs: ["moonbook:field-guide"],
  }
  let submitted = app.execute(
    "opaque-order-worker-token",
    "fulfill-order",
    fulfillment.to_json().stringify(),
    "",
    now_ms=110UL,
  )
  assert_true(submitted.stringify().contains("pending_review"))
  let decision : OrderDecisionDraft = {
    order_id: "order.api-flow",
    expected_version: 2,
    decision: "accept",
    decision_summary: "Meets the acceptance criteria.",
  }
  let decided = app.execute(
    "opaque-order-owner-token",
    "decide-order",
    decision.to_json().stringify(),
    "",
    now_ms=120UL,
  )
  assert_true(decided.stringify().contains("fulfilled"))
  let restarted = marketplace_application(
    path, requester, "session-order-owner", "opaque-order-owner-token",
  )
  let listed = restarted.execute(
    "opaque-order-owner-token",
    "orders",
    "",
    "field guide",
    now_ms=130UL,
  )
  assert_true(listed.stringify().contains("order.api-flow"))
}

///|
async test "account session using bootstrap token survives marketplace reload" {
  let path = "/tmp/moontown-orderlist-bootstrap-session-wbtest/state.json"
  if @fs.exists(path) {
    @fs.remove(path)
  }
  let requester = test_principal("order-bootstrap-owner", [])
  let token = "opaque-order-bootstrap-token"
  let app = marketplace_application(
    path, requester, "bootstrap:order-bootstrap-owner", token,
  )
  app.synchronize_account_session(
    requester,
    token,
    now_ms=100UL,
    expires_at_ms=200UL,
  )
  let response = app.execute(token, "orders", "", "", now_ms=150UL)
  assert_true(response.stringify().contains("orders"))
  try app.execute(token, "orders", "", "", now_ms=201UL) catch {
    error => assert_true("\{error}".contains("expired"))
  } noraise {
    _ => fail("expired account session must not authorize marketplace access")
  }
}
