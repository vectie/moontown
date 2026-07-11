///|
async test "cookbook bootstrap writes manifest and MoonBook workspace" {
  let root = "/tmp/moontown-cookbook-wbtest"
  @support.ignore_checked_command("rm", ["-rf", root])
  let catalog_path = @storage.moontown_product_artifact_for_workspace_root(
    root, "moonbooks.json",
  )
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
  assert_true(@fs.exists("\{workspace_root}/wiki/describer/overview.md"))
  assert_true(@fs.exists("\{workspace_root}/book/describer/overview.html"))
  assert_true(@fs.exists("\{workspace_root}/wiki/describer/algorithms.md"))
  assert_true(@fs.exists("\{workspace_root}/book/describer/algorithms.html"))
  assert_true(@fs.exists("\{workspace_root}/wiki/describer/data-structures.md"))
  assert_true(
    @fs.exists("\{workspace_root}/book/describer/data-structures.html"),
  )
  assert_true(@fs.exists("\{workspace_root}/wiki/describer/data-flow.md"))
  assert_true(@fs.exists("\{workspace_root}/book/describer/data-flow.html"))
  assert_true(@fs.exists("\{workspace_root}/wiki/describer/core-features.md"))
  assert_true(@fs.exists("\{workspace_root}/book/describer/core-features.html"))
  assert_true(@fs.exists("\{workspace_root}/wiki/describer/feature-guide.md"))
  assert_true(@fs.exists("\{workspace_root}/book/describer/feature-guide.html"))
  assert_true(@fs.exists("\{workspace_root}/wiki/describer/content-rules.md"))
  assert_true(@fs.exists("\{workspace_root}/book/describer/content-rules.html"))
  assert_true(
    @fs.exists("\{workspace_root}/skills/cookbook-generation/SKILL.md"),
  )
  assert_true(
    @fs.exists("\{workspace_root}/book/skills/cookbook-generation.html"),
  )
  assert_true(
    @fs.exists("\{workspace_root}/raw/bootstrap/COOKBOOK_CONTRACT.md"),
  )
  assert_true(@fs.exists("\{workspace_root}/book/moonbook-ui-state.json"))
  assert_eq(
    @cookbook.cookbook_generated_site_path(),
    @policy.default_generated_site_projection_path(),
  )
  assert_true(
    @fs.exists(@cookbook.cookbook_generated_site_workspace_path(workspace_root)),
  )
  let status = inspect_moontown_cookbook(workspace_root~, manifest_path~)
  assert_true(status.ready)
  assert_eq(status.docs_count, 8)
  assert_eq(status.definition_count, 4)
  assert_eq(status.runtime_state_count, 6)
}

///|
async test "cookbook status reports stable state control book" {
  let root = "/tmp/moontown-cookbook-status-wbtest"
  @support.ignore_checked_command("rm", ["-rf", root])
  let catalog_path = @storage.moontown_product_artifact_for_workspace_root(
    root, "moonbooks.json",
  )
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
  assert_true(markdown.contains("# MoonTown Cookbook Status"))
  assert_true(markdown.contains("moontown-cookbook"))
  assert_true(markdown.contains("Docs tracked: `8`"))
  assert_true(markdown.contains("Definitions tracked: `4`"))
  assert_true(markdown.contains("Runtime states tracked: `6`"))
}
