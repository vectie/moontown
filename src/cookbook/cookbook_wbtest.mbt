///|
test "cookbook artifact summary owns artifact kind counts and required drift" {
  assert_eq(
    default_manifest_path(),
    @storage.moontown_product_artifact("cookbook/stable-state.json"),
  )
  let summary = CookbookArtifactSummary::from_artifacts([
    test_cookbook_artifact("docs/A.md", "doc", required=true, exists=true),
    test_cookbook_artifact("docs/B.md", "doc", required=true, exists=false),
    test_cookbook_artifact(
      ".moonsuite/products/moontown/moonbooks.json",
      "definition",
      required=true,
      exists=true,
    ),
    test_cookbook_artifact(
      ".moonsuite/products/moontown/service.json",
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
    @support.json_string("8"),
    @support.json_string("4"),
    @support.json_string("6"),
    @support.json_string("0"),
  ).join("\n")
  assert_true(metrics.contains("\"label\":\"Docs\""))
  assert_true(metrics.contains("\"value\":\"8\""))
  assert_true(metrics.contains("restart-readable state files"))
  let readiness = cookbook_readiness_json(
    @support.json_string(".moontown/cookbook.json"),
  ).join("\n")
  assert_true(readiness.contains("Stable-state manifest"))
  assert_true(readiness.contains("raw/bootstrap/COOKBOOK_CONTRACT.md"))
  assert_true(readiness.contains("wiki/describer/algorithms.md"))
  assert_true(readiness.contains("skills/cookbook-generation/SKILL.md"))
  let families = cookbook_page_families_json().join("\n")
  assert_true(families.contains("wiki/describer/data-structures.md"))
  assert_true(families.contains("wiki/describer/data-flow.md"))
  assert_true(families.contains("wiki/describer/core-features.md"))
  let links = cookbook_links_json().join("\n")
  assert_true(links.contains("wiki/describer/content-rules.md"))
  assert_true(links.contains("skills/cookbook-generation/SKILL.md"))
}

///|
test "cookbook describer pages explain codebase algorithms and data flow" {
  let overview = cookbook_describer_overview_markdown()
  assert_true(overview.contains("# Moontown Codebase Describer"))
  assert_true(overview.contains("typed records and restart-readable files"))
  let algorithms = cookbook_algorithms_markdown()
  assert_true(algorithms.contains("## 2. Daemon Tick Phase Pipeline"))
  assert_true(algorithms.contains("## 4. Civic Building Protocol Map/Reduce"))
  assert_true(algorithms.contains("Standing-Watch Dispatch"))
  let structures = cookbook_data_structures_markdown()
  assert_true(structures.contains("`TownState`"))
  assert_true(structures.contains("`TaskExecutionRecord`"))
  assert_true(structures.contains("`BuildingReductionResult`"))
  let flow = cookbook_data_flow_markdown()
  assert_true(flow.contains("Goal Execution Flow"))
  assert_true(flow.contains("Civic Building Flow"))
  assert_true(
    flow.contains(".moonsuite/products/moontown/book-template-requests.json"),
  )
  assert_false(flow.contains(".moontown/book-template-requests.json"))
  let features = cookbook_core_features_markdown()
  assert_true(features.contains("## MoonBook/MoonClaw Execution Bridge"))
  assert_true(features.contains("## Civic Building Protocols"))
  assert_true(features.contains("Evidence to inspect:"))
  let rules = cookbook_content_rules_markdown()
  assert_true(rules.contains("## Runtime State"))
  assert_true(rules.contains("## Civic Features"))
  let skill = cookbook_skill_markdown()
  assert_true(skill.contains("name: cookbook-generation"))
  assert_true(skill.contains("Do not write a directory tour"))
  assert_true(skill.contains("Data flow"))
}

///|
test "cookbook renders markdown pages as clickable HTML" {
  let html = generated_site_html(book_entry("/tmp/clickable-cookbook"), {
    book_id: "moontown-cookbook",
    title: "Moontown Stable-State Cookbook",
    generated_by: "MoonBook",
    managed_by: "Moondesk",
    consumed_by: "Moontown",
    workspace_root: "/tmp/clickable-cookbook",
    manifest_path: "/tmp/clickable-cookbook/stable-state.json",
    artifacts: [],
  })
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
  let rendered = cookbook_rendered_markdown_html(
    "Algorithms",
    "wiki/describer/algorithms.md",
    cookbook_algorithms_markdown(),
  )
  assert_true(rendered.contains("<h1>Algorithms Used In Moontown</h1>"))
  assert_true(rendered.contains("<h2>2. Daemon Tick Phase Pipeline</h2>"))
  assert_true(rendered.contains("<pre><code>"))
  assert_true(
    rendered.contains(
      "href=\"../site/generated/index.html?v=codebase-rendered\"",
    ),
  )
  let structures = cookbook_rendered_markdown_html(
    "Data Structures",
    "wiki/describer/data-structures.md",
    cookbook_data_structures_markdown(),
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
