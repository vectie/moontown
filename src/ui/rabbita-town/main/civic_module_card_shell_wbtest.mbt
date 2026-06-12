///|
test "civic module card class centralizes default and custom composition" {
  assert_eq(
    civic_module_card_class(),
    "civic-module-card civic-module-card-featured",
  )
  assert_eq(
    civic_module_card_class(extra="civic-module-card-social-square"),
    "civic-module-card civic-module-card-featured civic-module-card-social-square",
  )
}
