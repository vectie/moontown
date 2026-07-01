///|
test "default catalog path uses moontown product home" {
  assert_eq(
    default_catalog_path(),
    ".moonsuite/products/moontown/moonbooks.json",
  )
}
