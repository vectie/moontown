///|
test "Changping youth entrepreneurship policy book routes to Policy Hall" {
  let ids = policy_hall_book_ids()
  assert_true(ids.contains("wenyu-policy-hall"))
  assert_true(ids.contains("changping-youth-entrepreneurship-policy"))
}
