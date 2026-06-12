///|
test "installer policy owns unsupported and unknown template summaries" {
  assert_eq(
    registered_without_installer_summary("experimental-only"),
    "Book template `experimental-only` is registered but has no installer yet.",
  )
  assert_eq(
    unknown_template_summary("missing-template"),
    "Unknown book template: missing-template",
  )
}
