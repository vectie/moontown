///|
test "default catalog path uses moontown product home" {
  assert_eq(
    default_catalog_path(),
    @storage.moontown_product_artifact("moonbooks.json"),
  )
}

///|
test "default book workspaces use moonsuite book root" {
  let previous_suite_root = @env.get_env_var("MOONTOWN_SUITE_ROOT")
  @env.unset_env_var("MOONTOWN_SUITE_ROOT")
  assert_eq(
    default_workspace_root("coding"),
    @moonsuite.book_root(@storage.moontown_active_workspace_root(), "coding"),
  )
  let catalog = default_catalog()
  assert_eq(
    catalog[0].workspace_root,
    @moonsuite.book_root(@storage.moontown_active_workspace_root(), "coding"),
  )
  assert_eq(
    catalog[1].workspace_root,
    @moonsuite.book_root(@storage.moontown_active_workspace_root(), "finance"),
  )
  @env.set_env_var("MOONTOWN_SUITE_ROOT", "/tmp/moontown-catalog-suite")
  assert_eq(
    default_workspace_root("coding"),
    "/tmp/moontown-catalog-suite/books/coding",
  )
  match previous_suite_root {
    Some(root) => @env.set_env_var("MOONTOWN_SUITE_ROOT", root)
    None => @env.unset_env_var("MOONTOWN_SUITE_ROOT")
  }
}

///|
test "default moonbook checkout root uses moontown product home" {
  assert_eq(
    default_moonbook_external_root(),
    @storage.moontown_product_artifact("external/moonbook"),
  )
}
