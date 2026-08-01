///|
test "miniapp dev mode is allowed only on loopback" {
  assert_true(session_authorized("127.0.0.1:18191", "", ""))
  assert_true(session_authorized("localhost:18191", "", "anything"))
  assert_true(!session_authorized("0.0.0.0:18191", "", "anything"))
}

///|
test "configured miniapp session token must match" {
  assert_true(session_authorized("0.0.0.0:18191", "secret", "secret"))
  assert_true(!session_authorized("0.0.0.0:18191", "secret", "wrong"))
  assert_true(!session_authorized("127.0.0.1:18191", "secret", ""))
}

///|
test "miniapp contract advertises the shared snapshot and write routes" {
  let contract = @town_contract.miniapp_contract().stringify()
  assert_true(contract.contains(@town_contract.miniapp_snapshot_path()))
  assert_true(contract.contains(@town_contract.miniapp_standing_watch_path()))
  assert_true(contract.contains(@town_contract.miniapp_evidence_book_path()))
  let desktop = @town_contract.desktop_contract().stringify()
  assert_true(desktop.contains(@town_contract.miniapp_supervisor_wake_path()))
  assert_true(desktop.contains(@town_contract.miniapp_supervisor_stop_path()))
  assert_true(desktop.contains(@town_contract.miniapp_supervisor_resume_path()))
}

///|
test "marketplace routing keeps caller session separate from fixed bootstrap" {
  assert_eq(
    select_marketplace_opaque_session("user-session-token", "bootstrap-token"),
    "user-session-token",
  )
  assert_eq(
    select_marketplace_opaque_session("", "bootstrap-token"),
    "bootstrap-token",
  )
  assert_true(
    marketplace_operation(
      @town_contract.miniapp_marketplace_search_path(),
      true,
      false,
    ) ==
    Some("search"),
  )
  assert_true(
    marketplace_operation(
      @town_contract.miniapp_marketplace_agent_listing_path(),
      false,
      true,
    ) ==
    Some("upsert-agent"),
  )
  assert_true(
    marketplace_operation(
      @town_contract.miniapp_marketplace_review_queue_path(),
      true,
      false,
    ) ==
    Some("review-queue"),
  )
  assert_true(
    marketplace_operation(
      @town_contract.miniapp_marketplace_shared_listings_path(),
      true,
      false,
    ) ==
    Some("shared-listings"),
  )
  assert_true(
    marketplace_operation(
      @town_contract.miniapp_marketplace_share_grants_revoke_path(),
      false,
      true,
    ) ==
    Some("revoke-share-grant"),
  )
}

///|
test "marketplace HTTP method classification keeps reads and writes separate" {
  assert_true(http_method_is_get(@http.Get))
  assert_false(http_method_is_get(@http.Post))
  assert_true(http_method_is_post(@http.Post))
  assert_false(http_method_is_post(@http.Get))
}

///|
test "marketplace query decoder preserves UTF-8 search terms" {
  assert_eq(
    request_query_parameter(
      "/miniapp/marketplace/discovery/search?q=%E6%9C%BA%E5%99%A8%E4%BA%BA+agent",
      "q",
    ),
    "机器人 agent",
  )
  assert_eq(request_query_parameter("/search?q=C%2B%2B", "q"), "C++")
}

///|
test "marketplace action request routes keep read decision and recovery separate" {
  assert_eq(
    marketplace_operation(
      @town_contract.miniapp_marketplace_action_requests_path(),
      true,
      false,
    ),
    Some("action-requests"),
  )
  assert_eq(
    marketplace_operation(
      @town_contract.miniapp_marketplace_action_decision_path(),
      false,
      true,
    ),
    Some("decide-action-request"),
  )
  assert_eq(
    marketplace_operation(
      @town_contract.miniapp_marketplace_action_retry_path(),
      false,
      true,
    ),
    Some("prepare-action-handoff"),
  )
}

///|
test "marketplace bridge derives the existing bounded supervisor delegate payload" {
  let request : Json = {
    "request_id": "action:agent.robot-guide:reader-a:7",
    "listing_id": "agent.robot-guide",
    "action_id": "try",
    "instruction": "Prepare a reviewable robotics reading plan.",
    "execution_bounds": {
      "claim_ceiling": "reviewable",
      "max_cost_micro_usd": "2000000",
      "max_runtime_ms": "300000",
      "max_tokens": "12000",
      "max_artifacts": 3,
      "web_search": false,
      "expires_at": "2026-08-01T00:05:00Z",
    },
  }
  let snapshot : Json = {
    "cursor": 9,
    "readiness": { "ready": true },
    "profile": {
      "revision": 2,
      "activeRunId": "supervisor-run-1",
      "runtimeCursor": 18,
      "bindings": {
        "workspaceId": "robotics-book",
        "buildingId": "robotics-book",
        "bookIds": ["robotics-book"],
      },
    },
  }
  let payload = marketplace_delegate_payload(bridge_object(request), snapshot).stringify()
  assert_true(
    payload.contains("marketplace-action:agent.robot-guide:reader-a:7"),
  )
  assert_true(payload.contains("\"model\":\"gpt-5.6-sol\""))
  assert_true(payload.contains("\"webSearch\":false"))
  assert_true(payload.contains("\"maxCostMicroUsd\":\"2000000\""))
  assert_true(payload.contains("\"maxRuntimeMs\":\"300000\""))
  assert_true(payload.contains("\"maxTokens\":\"12000\""))
  assert_true(payload.contains("books/robotics-book/artifacts"))
  assert_true(payload.contains("marketplace_request_id"))
  assert_false(payload.contains("/Users/"))
  assert_false(payload.contains("authority"))
}

///|
test "marketplace pending handoff preserves the accepted decision for retry" {
  let result = marketplace_pending_handoff_result(
    "decide-action-request",
    {
      "ok": true,
      "payload": {
        "action_request": {
          "request_id": "action:agent.robot-guide:reader-a:7",
          "state": "accepted_pending_handoff",
          "version": 2,
          "can_decide": false,
          "can_retry_handoff": true,
        },
      },
    },
  ).stringify()
  assert_true(result.contains("\"ok\":true"))
  assert_true(result.contains("accepted_pending_handoff"))
  assert_true(result.contains("supervisor_activation_required"))
  assert_true(result.contains("\"can_retry_handoff\":true"))
  assert_false(result.contains("marketplace_handoff_not_ready"))
}
