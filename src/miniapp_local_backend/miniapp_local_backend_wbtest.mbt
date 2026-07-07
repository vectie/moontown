///|
test "local backend exposes route catalog for miniapp wrappers" {
  let routes = miniapp_local_backend_routes()
  assert_eq(routes.length(), 12)
  assert_true(miniapp_local_backend_test_has_route(routes, "dev-login"))
  assert_true(miniapp_local_backend_test_has_route(routes, "snapshot"))
  assert_true(miniapp_local_backend_test_has_route(routes, "share-building"))
  assert_true(miniapp_local_backend_test_has_route(routes, "publish-building"))
  assert_true(miniapp_local_backend_test_has_route(routes, "chat-send"))
  assert_true(miniapp_local_backend_test_has_route(routes, "accept-run"))
}

///|
test "local backend dev login snapshot and search are session scoped" {
  let state = miniapp_local_backend_fixture_state()
  let login = miniapp_local_backend_dev_login(state, "user-a", now_ms=5000UL)
  assert_eq(login.ok, true)
  assert_true(login.session_id == Some("dev-session-user-a-5000"))
  assert_true(login.body.contains("kind=dev-login ok=true"))
  let session = login.session_id.unwrap()
  let snapshot = miniapp_local_backend_snapshot(
    login.state,
    session,
    now_ms=5100UL,
  )
  assert_eq(snapshot.ok, true)
  assert_true(snapshot.body.contains("kind=snapshot ok=true"))
  assert_true(snapshot.body.contains("messages="))
  assert_true(snapshot.body.contains("audit="))
  let search = miniapp_local_backend_search_buildings(
    login.state,
    session,
    "policy",
    now_ms=5200UL,
  )
  assert_eq(search.ok, true)
  assert_true(search.body.contains("results=1"))
  assert_true(search.body.contains("first=policy-hall"))
}

///|
test "local backend can create agent chat and update run lifecycle" {
  let login = miniapp_local_backend_dev_login(
    miniapp_local_backend_fixture_state(),
    "user-a",
    now_ms=6000UL,
  )
  let session = login.session_id.unwrap()
  let created = miniapp_local_backend_create_agent(
    login.state,
    session,
    {
      id: "agent-local",
      display_name: "Local Agent",
      owner_kind: @miniapp_contracts.UserOwner,
      owner_id: "user-a",
      building_id: Some("private-lab"),
      capabilities: ["answer"],
    },
    now_ms=6100UL,
  )
  assert_eq(created.ok, true)
  assert_true(created.body.contains("kind=create-agent ok=true"))
  let chat = miniapp_local_backend_chat_send(
    created.state,
    session,
    {
      message_id: "msg-local-chat",
      run_id: "run-local-chat",
      thread_id: "thread-private-lab",
      building_id: "private-lab",
      agent_id: Some("agent-local"),
      body: "Ask local agent.",
      answer_summary: "Local answer waiting for review.",
    },
    now_ms=6200UL,
  )
  assert_eq(chat.ok, true)
  assert_true(chat.body.contains("kind=chat-send ok=true"))
  let cancelled = miniapp_local_backend_cancel_run(
    chat.state,
    session,
    { run_id: "run-local-chat", summary: "Cancelled locally." },
    now_ms=6300UL,
  )
  assert_eq(cancelled.ok, true)
  let retried = miniapp_local_backend_retry_run(
    cancelled.state,
    session,
    { run_id: "run-local-chat", summary: "Retried locally." },
    now_ms=6400UL,
  )
  assert_eq(retried.ok, true)
  let accepted = miniapp_local_backend_accept_run(
    retried.state,
    session,
    { run_id: "run-local-chat", summary: "Accepted locally." },
    now_ms=6500UL,
  )
  assert_eq(accepted.ok, true)
  assert_true(accepted.body.contains("kind=accept-run ok=true"))
  assert_eq(
    accepted.state.snapshot.runs.length(),
    login.state.snapshot.runs.length() + 1,
  )
  assert_true(accepted.state.snapshot.audit_events.length() >= 5)
}

///|
test "local backend can publish a private draft into public search" {
  let login = miniapp_local_backend_dev_login(
    miniapp_local_backend_fixture_state(),
    "user-a",
    now_ms=6600UL,
  )
  let session = login.session_id.unwrap()
  let created = miniapp_local_backend_create_building(
    login.state,
    session,
    {
      id: "published-cli-lab",
      kind: @miniapp_contracts.AgentLab,
      title: "Published CLI Lab",
      summary: "Draft that should become public.",
      workspace_id: "workspace-user-a",
      tags: ["published-cli"],
      capabilities: ["query"],
      primary_book_id: "book-published-cli-lab",
    },
    now_ms=6610UL,
  )
  assert_eq(created.ok, true)
  let user_b_before = miniapp_local_backend_dev_login(
    created.state,
    "user-b",
    now_ms=6620UL,
  )
  let before = miniapp_local_backend_search_buildings(
    user_b_before.state,
    user_b_before.session_id.unwrap(),
    "published-cli",
    now_ms=6625UL,
  )
  assert_true(before.body.contains("results=0"))
  let published = miniapp_local_backend_publish_building(
    created.state,
    session,
    "published-cli-lab",
    now_ms=6630UL,
  )
  assert_eq(published.ok, true)
  assert_true(published.body.contains("kind=publish-building ok=true"))
  let user_b = miniapp_local_backend_dev_login(
    published.state,
    "user-b",
    now_ms=6640UL,
  )
  let search = miniapp_local_backend_search_buildings(
    user_b.state,
    user_b.session_id.unwrap(),
    "published-cli",
    now_ms=6650UL,
  )
  assert_eq(search.ok, true)
  assert_true(search.body.contains("results=1"))
  assert_true(search.body.contains("first=published-cli-lab"))
}

///|
test "local backend can share a private draft with another local user" {
  let login = miniapp_local_backend_dev_login(
    miniapp_local_backend_fixture_state(),
    "user-a",
    now_ms=6660UL,
  )
  let session = login.session_id.unwrap()
  let created = miniapp_local_backend_create_building(
    login.state,
    session,
    {
      id: "shared-cli-lab",
      kind: @miniapp_contracts.AgentLab,
      title: "Shared CLI Lab",
      summary: "Draft that should become shared private.",
      workspace_id: "workspace-user-a",
      tags: ["shared-cli"],
      capabilities: ["query"],
      primary_book_id: "book-shared-cli-lab",
    },
    now_ms=6670UL,
  )
  assert_eq(created.ok, true)
  let user_b_before = miniapp_local_backend_dev_login(
    created.state,
    "user-b",
    now_ms=6680UL,
  )
  let hidden = miniapp_local_backend_search_buildings(
    user_b_before.state,
    user_b_before.session_id.unwrap(),
    "shared-cli",
    now_ms=6690UL,
  )
  assert_true(hidden.body.contains("results=0"))
  let shared = miniapp_local_backend_share_building(
    created.state,
    session,
    "shared-cli-lab",
    "user-b",
    now_ms=6700UL,
  )
  assert_eq(shared.ok, true)
  assert_true(shared.body.contains("kind=share-building ok=true"))
  let user_b_after = miniapp_local_backend_dev_login(
    shared.state,
    "user-b",
    now_ms=6710UL,
  )
  let visible = miniapp_local_backend_search_buildings(
    user_b_after.state,
    user_b_after.session_id.unwrap(),
    "shared-cli",
    now_ms=6720UL,
  )
  assert_true(visible.body.contains("results=1"))
  assert_true(visible.body.contains("first=shared-cli-lab"))
}

///|
fn miniapp_local_backend_test_has_route(
  routes : Array[MiniappLocalBackendRoute],
  name : String,
) -> Bool {
  for route in routes {
    if route.name == name {
      return true
    }
  }
  false
}
