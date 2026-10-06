///|
async test "native Book review read never falls back to compiling or initializing missing workspace" {
  let root = @fs.tmpdir(prefix="book-readonly-query-")
  let keys = [
    "HOME", "MOONTOWN_SUITE_ROOT", "MOONSUITE_ROOT", "MOONTOWN_WORKSPACE_ROOT", "MOONTOWN_MOONBOOK_BIN",
    "MOONBOOK_BIN", "MOON",
  ]
  let before = keys.map(key => @env.get_env_var(key))
  defer (for index, key in keys {
    match before[index] {
      Some(value) => @env.set_env_var(key, value)
      None => @env.unset_env_var(key)
    }
  })
  for key in keys {
    @env.unset_env_var(key)
  }
  @env.set_env_var("HOME", root + "/missing-home")
  @env.set_env_var("MOONTOWN_SUITE_ROOT", root + "/missing-suite")
  @env.set_env_var("MOONSUITE_ROOT", root + "/missing-suite")
  @env.set_env_var("MOONTOWN_WORKSPACE_ROOT", root + "/missing-workspace")
  @env.set_env_var("MOON", "/must-never-run-a-compiler")
  let entry = BookCatalogEntry::new(
    id="book",
    name="Book",
    purpose="Synthetic",
    workspace_root=root + "/missing-book",
  )
  try
    read_native_wenyu_review(
      entry,
      "work",
      "request",
      "payload",
      "task",
      moonbook_root=root,
    )
  catch {
    error =>
      assert_true(
        error.to_string().contains("requires_existing_moonbook_executable"),
      )
  } noraise {
    _ => fail("missing reader must not be fabricated")
  }
  assert_true(@fs.readdir(root).is_empty())
}
