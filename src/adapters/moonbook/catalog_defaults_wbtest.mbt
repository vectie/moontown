///|
test "default catalog path uses moontown product home" {
  assert_eq(
    default_catalog_path(),
    @storage.moontown_product_artifact("moonbooks.json"),
  )
}

///|
test "default book workspaces use moonsuite book root" {
  assert_eq(
    default_workspace_root("coding"),
    @moonsuite.book_root("", "coding"),
  )
  let catalog = default_catalog()
  assert_eq(catalog[0].workspace_root, @moonsuite.book_root("", "coding"))
  assert_eq(catalog[1].workspace_root, @moonsuite.book_root("", "finance"))
}
