///|
async test "Social Square protocol proof slice has inbox reduction outbox and review" {
  let root = cleaned_civic_protocol_test_root(
    "/tmp/moontown-protocol-social-square",
  )
  let registry_path = "\{root}/protocols.json"
  let status_path = "\{root}/protocol-status.json"
  ignore(bootstrap_wenyu_building_protocols(registry_path~, status_path~))
  let portfolio = inspect_wenyu_building_protocols(status_path~, registry_path~)
  let social = portfolio.protocols
    .filter(fn(item) { item.building_id == "social-square" })
    .get(0)
    .unwrap()
  assert_eq(social.protocol_mode, "exchange-reduce-distribute")
  assert_eq(social.status, "review")
  assert_true(social.ready)
  assert_true(social.inbox_count >= 1)
  assert_true(social.contribution_count >= 1)
  assert_true(social.reduction_count >= 1)
  assert_true(social.outbox_count >= 1)
  assert_true(social.review_count >= 1)
  assert_true(!social.latest_reduction_summary.is_empty())
  assert_true(@fs.exists(status_path))
}
