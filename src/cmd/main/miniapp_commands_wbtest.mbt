///|
async test "miniapp routes command exposes local backend catalog" {
  let output = render_cli_command(["miniapp", "routes"])
  assert_true(output.contains("MoonTown miniapp local backend routes"))
  assert_true(output.contains("route=dev-login"))
  assert_true(output.contains("route=share-building"))
  assert_true(output.contains("route=publish-building"))
  assert_true(output.contains("route=archive-building"))
  assert_true(output.contains("route=chat-send"))
  assert_true(output.contains("route=accept-run"))
}

///|
async test "miniapp serve command points to local HTTP wrapper" {
  let output = render_cli_command(["miniapp", "serve"])
  assert_true(output.contains("scripts/miniapp-local-backend.mjs"))
  assert_true(output.contains("backendBaseUrl=http://127.0.0.1:18191"))
  assert_true(
    output.contains("--state .moontown/miniapp-local-backend-state.json"),
  )
  assert_true(output.contains("--reset-state"))
}

///|
async test "miniapp snapshot and search commands use dev login fixture" {
  let snapshot = render_cli_command(["miniapp", "snapshot", "user-a"])
  assert_true(snapshot.contains("kind=snapshot ok=true"))
  assert_true(snapshot.contains("buildings="))
  assert_true(snapshot.contains("messages="))
  let search = render_cli_command([
    "miniapp", "buildings", "search", "user-a", "policy",
  ])
  assert_true(search.contains("kind=search-buildings ok=true"))
  assert_true(search.contains("first=policy-hall"))
}

///|
async test "miniapp agent chat and run commands render local backend responses" {
  let agent = render_cli_command(["miniapp", "agents", "create", "user-a"])
  assert_true(agent.contains("kind=create-agent ok=true"))
  let chat = render_cli_command(["miniapp", "chat", "send", "user-a"])
  assert_true(chat.contains("kind=chat-send ok=true"))
  let cancel = render_cli_command([
    "miniapp", "runs", "cancel", "user-a", "run-policy-hall-1",
  ])
  assert_true(cancel.contains("kind=cancel-run ok=true"))
  let accept = render_cli_command([
    "miniapp", "reviews", "accept", "user-a", "run-policy-hall-1",
  ])
  assert_true(accept.contains("kind=accept-run ok=true"))
}

///|
async test "miniapp publish command renders local publication response" {
  let output = render_cli_command(["miniapp", "buildings", "publish", "user-a"])
  assert_true(output.contains("kind=publish-building ok=true"))
  assert_true(output.contains("object=cli-published-lab"))
}

///|
async test "miniapp share command renders local sharing response" {
  let output = render_cli_command(["miniapp", "buildings", "share", "user-a"])
  assert_true(output.contains("kind=share-building ok=true"))
  assert_true(output.contains("object=cli-shared-lab"))
}

///|
async test "miniapp archive command renders local archive response" {
  let output = render_cli_command(["miniapp", "buildings", "archive", "user-a"])
  assert_true(output.contains("kind=archive-building ok=true"))
  assert_true(output.contains("object=cli-archived-lab"))
}
