///|
test "Policy Hall publication highlight accepts canonical module aliases" {
  assert_true(golden_policy_hall_publication_highlight(Some("policy-hall")))
  assert_true(
    golden_policy_hall_publication_highlight(Some("wenyu-policy-hall")),
  )
  assert_true(!golden_policy_hall_publication_highlight(Some("vitality-tower")))
  assert_true(!golden_policy_hall_publication_highlight(None))
  assert_eq(golden_policy_hall_publication_badge(), "昌平青创政策")
}
