///|
test "communication patterns describe reusable building protocols" {
  let patterns = civic_communication_patterns()
  assert_true(patterns.length() >= 8)
  match civic_communication_pattern_for_id("research-salon") {
    Some(pattern) => {
      assert_eq(pattern.title, "Research Salon")
      assert_eq(pattern.protocol_mode, "exchange-reduce-distribute")
      assert_eq(pattern.output_contract, "civic.salon.idea_reduction.v1")
    }
    None => fail("expected research salon pattern")
  }
}

///|
test "communication pattern mapping follows civic service kind" {
  let service = wenyu_civic_services().filter(fn(item) {
      item.id == "social-square"
    })[0]
  assert_eq(civic_communication_pattern_id_for_service(service), "match-market")
}
