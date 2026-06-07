///|
test "civic communication patterns describe reusable protocol shapes" {
  let patterns = civic_communication_patterns()
  assert_true(patterns.length() >= 8)
  match civic_communication_pattern_for_id("research-salon") {
    Some(pattern) => {
      assert_eq(pattern.title, "Research Salon")
      assert_eq(pattern.protocol_mode, "exchange-reduce-distribute")
    }
    None => fail("expected research salon pattern")
  }
  let service = @civic.wenyu_civic_services().filter(fn(item) {
      item.id == "social-square"
    })[0]
  assert_eq(civic_communication_pattern_id_for_service(service), "match-market")
}
