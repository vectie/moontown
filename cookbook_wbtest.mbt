///|
async test "cookbook bootstrap writes manifest and MoonBook workspace" {
  let root = "/tmp/moontown-cookbook-wbtest"
  @support.ignore_checked_command("rm", ["-rf", root])
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
  @support.ignore_checked_command("rm", ["-rf", root])
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
  let summary = @cookbook.CookbookArtifactSummary::from_artifacts([
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
  let chips = @cookbook.cookbook_status_chips_json().join("\n")
  assert_true(chips.contains("\"label\":\"cookbook\""))
  assert_true(chips.contains("\"tone\":\"review\""))
  let metrics = @cookbook.cookbook_metrics_json(
    json_string("8"),
    json_string("4"),
    json_string("6"),
    json_string("0"),
  ).join("\n")
  assert_true(metrics.contains("\"label\":\"Docs\""))
  assert_true(metrics.contains("\"value\":\"8\""))
  assert_true(metrics.contains("restart-readable state files"))
  let readiness = @cookbook.cookbook_readiness_json(
    json_string(".moontown/cookbook.json"),
  ).join("\n")
  assert_true(readiness.contains("Stable-state manifest"))
  assert_true(readiness.contains("raw/bootstrap/COOKBOOK_CONTRACT.md"))
  assert_true(readiness.contains("wiki/describer/algorithms.md"))
  assert_true(readiness.contains("skills/cookbook-generation/SKILL.md"))
  let families = @cookbook.cookbook_page_families_json().join("\n")
  assert_true(families.contains("wiki/describer/data-structures.md"))
  assert_true(families.contains("wiki/describer/data-flow.md"))
  assert_true(families.contains("wiki/describer/core-features.md"))
  let links = @cookbook.cookbook_links_json().join("\n")
  assert_true(links.contains("wiki/describer/content-rules.md"))
  assert_true(links.contains("skills/cookbook-generation/SKILL.md"))
}

///|
test "cookbook describer pages explain codebase algorithms and data flow" {
  let overview = @cookbook.cookbook_describer_overview_markdown()
  assert_true(overview.contains("# Moontown Codebase Describer"))
  assert_true(overview.contains("typed records and restart-readable files"))
  let algorithms = @cookbook.cookbook_algorithms_markdown()
  assert_true(algorithms.contains("## 2. Daemon Tick Phase Pipeline"))
  assert_true(algorithms.contains("## 4. Civic Building Protocol Map/Reduce"))
  assert_true(algorithms.contains("Standing-Watch Dispatch"))
  let structures = @cookbook.cookbook_data_structures_markdown()
  assert_true(structures.contains("`TownState`"))
  assert_true(structures.contains("`TaskExecutionRecord`"))
  assert_true(structures.contains("`BuildingReductionResult`"))
  let flow = @cookbook.cookbook_data_flow_markdown()
  assert_true(flow.contains("Goal Execution Flow"))
  assert_true(flow.contains("Civic Building Flow"))
  let features = @cookbook.cookbook_core_features_markdown()
  assert_true(features.contains("## MoonBook/MoonClaw Execution Bridge"))
  assert_true(features.contains("## Civic Building Protocols"))
  assert_true(features.contains("Evidence to inspect:"))
  let rules = @cookbook.cookbook_content_rules_markdown()
  assert_true(rules.contains("## Runtime State"))
  assert_true(rules.contains("## Civic Features"))
  let skill = @cookbook.cookbook_skill_markdown()
  assert_true(skill.contains("name: cookbook-generation"))
  assert_true(skill.contains("Do not write a directory tour"))
  assert_true(skill.contains("Data flow"))
}

///|
test "cookbook renders markdown pages as clickable HTML" {
  let html = @cookbook.generated_site_html(
    @cookbook.book_entry("/tmp/clickable-cookbook"),
    @cookbook.MoontownCookbookManifest::{
      book_id: "moontown-cookbook",
      title: "Moontown Stable-State Cookbook",
      generated_by: "MoonBook",
      managed_by: "Moondesk",
      consumed_by: "Moontown",
      workspace_root: "/tmp/clickable-cookbook",
      manifest_path: "/tmp/clickable-cookbook/stable-state.json",
      artifacts: [],
    },
  )
  assert_true(
    html.contains(
      "href=\"../../describer/algorithms.html?v=codebase-rendered\"",
    ),
  )
  assert_true(html.contains("Open rendered page"))
  assert_true(
    html.contains(
      "href=\"../../skills/cookbook-generation.html?v=codebase-rendered\"",
    ),
  )
  let rendered = @cookbook.cookbook_rendered_markdown_html(
    "Algorithms",
    "wiki/describer/algorithms.md",
    @cookbook.cookbook_algorithms_markdown(),
  )
  assert_true(rendered.contains("<h1>Algorithms Used In Moontown</h1>"))
  assert_true(rendered.contains("<h2>2. Daemon Tick Phase Pipeline</h2>"))
  assert_true(rendered.contains("<pre><code>"))
  assert_true(
    rendered.contains(
      "href=\"../site/generated/index.html?v=codebase-rendered\"",
    ),
  )
  let structures = @cookbook.cookbook_rendered_markdown_html(
    "Data Structures",
    "wiki/describer/data-structures.md",
    @cookbook.cookbook_data_structures_markdown(),
  )
  assert_true(structures.contains("<table><tbody>"))
  assert_true(structures.contains("<code>TownState</code>"))
  assert_false(structures.contains("<td>---</td>"))
}

///|
test "cookbook generated site escapes artifact cards" {
  let artifact = test_cookbook_artifact(
    "docs/<A>.md",
    "doc",
    required=true,
    exists=false,
  )
  let card = @cookbook.cookbook_artifact_card_html({
    ..artifact,
    owner: "MoonBook & Moondesk",
    stable_role: "stable \"contract\"",
  })
  assert_true(card.contains("docs/&lt;A&gt;.md"))
  assert_true(card.contains("MoonBook &amp; Moondesk"))
  assert_true(card.contains("stable &quot;contract&quot;"))
  assert_true(card.contains("required=true; exists=false"))
  assert_true(
    @cookbook.cookbook_site_style_html().contains("grid-template-columns"),
  )
}

///|
fn test_cookbook_artifact(
  path : String,
  kind : String,
  required~ : Bool,
  exists~ : Bool,
) -> @cookbook.CookbookArtifact {
  { path, kind, owner: "test", stable_role: "test artifact", required, exists }
}
