///|
test "Wenyu building protocols cover civic services" {
  let services = wenyu_civic_services()
  let protocols = wenyu_building_protocols()
  assert_eq(protocols.length(), services.length())
  for protocol in protocols {
    assert_true(!protocol.building_id.is_empty())
    assert_true(!protocol.protocol_mode.is_empty())
    assert_true(!protocol.input_channels.is_empty())
    assert_true(!protocol.output_channels.is_empty())
    assert_true(!protocol.review_gates.is_empty())
    assert_true(protocol.skill_packs.length() >= 2)
  }
}

///|
test "Social Square protocol is an exchange reducer not a research lane" {
  let protocol = wenyu_building_protocol_for_building_id("social-square").unwrap()
  assert_eq(protocol.protocol_mode, "exchange-reduce-distribute")
  assert_eq(protocol.moonbook_role, "consent-ledger-and-social-graph")
  assert_true(protocol.input_channels.contains("resident_request"))
  assert_true(protocol.output_channels.contains("match_candidate"))
  assert_true(protocol.review_gates.contains("external_introduction"))
  assert_true(protocol.reduction_policy.contains("matchmaker skill"))
}

///|
test "Protocol lookup follows canonical book bindings" {
  let protocol = wenyu_building_protocol_for_book_id("wenyu-policy-hall").unwrap()
  assert_eq(protocol.building_id, "policy-hall")
  assert_eq(protocol.protocol_mode, "work-reduce-persist")
  assert_true(protocol.output_channels.contains("cited_checklist"))
}
