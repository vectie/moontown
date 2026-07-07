///|
async test "miniapp routes command exposes local backend catalog" {
  let output = render_cli_command(["miniapp", "routes"])
  assert_true(output.contains("Moontown miniapp local backend routes"))
  assert_true(output.contains("route=dev-login"))
  assert_true(output.contains("route=chat-send"))
  assert_true(output.contains("route=accept-run"))
}

///|
async test "miniapp serve command points to local HTTP wrapper" {
  let output = render_cli_command(["miniapp", "serve"])
  assert_true(output.contains("scripts/miniapp-local-backend.mjs"))
  assert_true(output.contains("backendBaseUrl=http://127.0.0.1:18191"))
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
