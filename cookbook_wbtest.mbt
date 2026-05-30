///|
async test "cookbook bootstrap writes manifest and MoonBook workspace" {
  let root = "/tmp/moontown-cookbook-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let catalog_path = "\{root}/moonbooks.json"
  let workspace_root = "\{root}/books/moontown-cookbook"
  let manifest_path = "\{root}/stable-state.json"
  let message = bootstrap_moontown_cookbook(
    book_catalog_path=catalog_path,
    workspace_root~,
    manifest_path~,
  )
  assert_true(message.contains("Bootstrapped MoonBook cookbook"))
  assert_true(@fs.exists(manifest_path))
  assert_true(@fs.exists("\{workspace_root}/wiki/index.md"))
  assert_true(@fs.exists("\{workspace_root}/wiki/definitions/stable-state.md"))
  assert_true(
    @fs.exists("\{workspace_root}/raw/bootstrap/COOKBOOK_CONTRACT.md"),
  )
  assert_true(@fs.exists("\{workspace_root}/book/moonbook-ui-state.json"))
  assert_true(@fs.exists("\{workspace_root}/book/site/generated/index.html"))
  let status = inspect_moontown_cookbook(workspace_root~, manifest_path~)
  assert_true(status.ready)
  assert_eq(status.docs_count, 8)
  assert_eq(status.definition_count, 4)
  assert_eq(status.runtime_state_count, 6)
}

///|
async test "cookbook status reports stable state control book" {
  let root = "/tmp/moontown-cookbook-status-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let catalog_path = "\{root}/moonbooks.json"
  let workspace_root = "\{root}/books/moontown-cookbook"
  let manifest_path = "\{root}/stable-state.json"
  ignore(
    bootstrap_moontown_cookbook(
      book_catalog_path=catalog_path,
      workspace_root~,
      manifest_path~,
    ),
  )
  let markdown = render_moontown_cookbook_status(
    workspace_root~,
    manifest_path~,
  )
  assert_true(markdown.contains("# Moontown Cookbook Status"))
  assert_true(markdown.contains("moontown-cookbook"))
  assert_true(markdown.contains("Docs tracked: `8`"))
  assert_true(markdown.contains("Definitions tracked: `4`"))
  assert_true(markdown.contains("Runtime states tracked: `6`"))
}
