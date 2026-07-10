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

///|
test "civic module card visual slugs match district assets" {
  assert_eq(civic_module_card_visual_slug("Town Shell"), "town_shell")
  assert_eq(
    civic_module_card_visual_slug("Vitality Dashboard"),
    "vitality_dashboard",
  )
  assert_eq(civic_module_card_visual_slug("Social Square"), "social_square")
  assert_eq(
    civic_module_card_visual_slug("Physical Bridge"),
    "physical_bridge",
  )
}
