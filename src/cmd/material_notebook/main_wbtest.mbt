///|
async test "CLI error output preserves the message of a real typed authoring failure" {
  let store : @authoring.Store = { root: "", catalog_path: "", }
  try store.import_material("example", []) catch {
    error =>
      assert_eq(
        error_output(error),
        "material_notebook: Choose 1–16 source files from registered Books\n",
      )
  } noraise {
    _ => fail("Expected an invalid selection error")
  }
}

///|
test "CLI error output preserves direct path owner and quote Failure messages" {
  for
    message in [
      "Select an imported Book and source path", "Assign consistent named human review and objection owners",
      "Select each exact, nonempty source passage once (up to 2000 characters)",
    ] {
    assert_eq(
      error_output(Failure(message)),
      "material_notebook: " + message + "\n",
    )
  }
}
