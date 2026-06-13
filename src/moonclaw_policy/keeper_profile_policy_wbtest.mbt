///|
test "keeper profile override is policy-owned for planbook and civic books" {
  match
    keeper_profile_override_for_catalog_entry(
      "plan-moontown-quality",
      "Moontown PlanBook",
      ["planning"],
    ) {
    Some(profile) => assert_eq(profile, planbook_keeper_profile())
    None => fail("expected planbook profile override")
  }
  match
    keeper_profile_override_for_catalog_entry(
      "wenyu-policy-hall",
      "Wenyu Policy Hall",
      ["civic-service"],
    ) {
    Some(profile) => assert_eq(profile, civic_keeper_profile())
    None => fail("expected civic profile override")
  }
  assert_true(
    keeper_profile_override_for_catalog_entry("research-opc", "OPC Research", [
      "research", "topic:opc",
    ])
    is None,
  )
}
