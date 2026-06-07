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

///|
test "cookbook artifact summary owns artifact kind counts and required drift" {
  let summary = CookbookArtifactSummary::from_artifacts([
    test_cookbook_artifact("docs/A.md", "doc", required=true, exists=true),
    test_cookbook_artifact("docs/B.md", "doc", required=true, exists=false),
    test_cookbook_artifact(
      ".moontown/books.json",
      "definition",
      required=true,
      exists=true,
    ),
    test_cookbook_artifact(
      ".moontown/daemon.json",
      "runtime-state",
      required=false,
      exists=false,
    ),
    test_cookbook_artifact("scratch.txt", "note", required=false, exists=false),
  ])
  assert_eq(summary.docs_count, 2)
  assert_eq(summary.definition_count, 1)
  assert_eq(summary.runtime_state_count, 1)
  assert_eq(summary.required_missing_count(), 1)
  assert_eq(summary.required_missing_paths.length(), 1)
  assert_eq(summary.required_missing_paths[0], "docs/B.md")
}

///|
test "cookbook projection helpers render stable UI contracts" {
  let chips = cookbook_status_chips_json().join("\n")
  assert_true(chips.contains("\"label\":\"cookbook\""))
  assert_true(chips.contains("\"tone\":\"review\""))
  let metrics = cookbook_metrics_json(
    json_string("8"),
    json_string("4"),
    json_string("6"),
    json_string("0"),
  ).join("\n")
  assert_true(metrics.contains("\"label\":\"Docs\""))
  assert_true(metrics.contains("\"value\":\"8\""))
  assert_true(metrics.contains("restart-readable state files"))
  let readiness = cookbook_readiness_json(
    json_string(".moontown/cookbook.json"),
  ).join("\n")
  assert_true(readiness.contains("Stable-state manifest"))
  assert_true(readiness.contains("raw/bootstrap/COOKBOOK_CONTRACT.md"))
}

///|
test "cookbook generated site escapes artifact cards" {
  let artifact = test_cookbook_artifact(
    "docs/<A>.md",
    "doc",
    required=true,
    exists=false,
  )
  let card = cookbook_artifact_card_html({
    ..artifact,
    owner: "MoonBook & Moondesk",
    stable_role: "stable \"contract\"",
  })
  assert_true(card.contains("docs/&lt;A&gt;.md"))
  assert_true(card.contains("MoonBook &amp; Moondesk"))
  assert_true(card.contains("stable &quot;contract&quot;"))
  assert_true(card.contains("required=true; exists=false"))
  assert_true(cookbook_site_style_html().contains("grid-template-columns"))
}

///|
fn test_cookbook_artifact(
  path : String,
  kind : String,
  required~ : Bool,
  exists~ : Bool,
) -> CookbookArtifact {
  { path, kind, owner: "test", stable_role: "test artifact", required, exists }
}
