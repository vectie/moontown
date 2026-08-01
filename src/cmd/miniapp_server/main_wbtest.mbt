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
