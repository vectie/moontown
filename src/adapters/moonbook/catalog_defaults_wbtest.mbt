///|
test "default catalog path uses moontown product home" {
  assert_eq(
    default_catalog_path(),
    @storage.moontown_product_artifact("moonbooks.json"),
  )
}
