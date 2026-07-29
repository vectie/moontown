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
}
