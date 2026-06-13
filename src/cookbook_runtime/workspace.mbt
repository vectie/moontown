///|
async fn write_moontown_cookbook_workspace(
  entry : @moonbook.BookCatalogEntry,
  manifest : @cookbook.MoontownCookbookManifest,
) -> Unit {
  let root = entry.workspace_root
  @support.write_text_file(
    "\{root}/wiki/index.md",
    @cookbook.cookbook_index_markdown(entry, manifest),
  )
  @support.write_text_file(
    "\{root}/wiki/definitions/stable-state.md",
    @cookbook.cookbook_stable_state_markdown(manifest),
  )
  @support.write_text_file(
    "\{root}/wiki/definitions/ownership.md",
    @cookbook.cookbook_ownership_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/definitions/book-types.md",
    @cookbook.cookbook_book_types_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/definitions/runtime-boundaries.md",
    @cookbook.cookbook_runtime_boundaries_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/definitions/live-autonomy-spine.md",
    @cookbook.cookbook_live_autonomy_spine_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/describer/overview.md",
    @cookbook.cookbook_describer_overview_markdown(),
  )
  @support.write_text_file(
    "\{root}/book/describer/overview.html",
    @cookbook.cookbook_rendered_markdown_html(
      "Moontown Codebase Describer",
      "wiki/describer/overview.md",
      @cookbook.cookbook_describer_overview_markdown(),
    ),
  )
  @support.write_text_file(
    "\{root}/wiki/describer/algorithms.md",
    @cookbook.cookbook_algorithms_markdown(),
  )
  @support.write_text_file(
    "\{root}/book/describer/algorithms.html",
    @cookbook.cookbook_rendered_markdown_html(
      "Algorithms Used In Moontown",
      "wiki/describer/algorithms.md",
      @cookbook.cookbook_algorithms_markdown(),
    ),
  )
  @support.write_text_file(
    "\{root}/wiki/describer/data-structures.md",
    @cookbook.cookbook_data_structures_markdown(),
  )
  @support.write_text_file(
    "\{root}/book/describer/data-structures.html",
    @cookbook.cookbook_rendered_markdown_html(
      "Moontown Data Structures",
      "wiki/describer/data-structures.md",
      @cookbook.cookbook_data_structures_markdown(),
    ),
  )
  @support.write_text_file(
    "\{root}/wiki/describer/data-flow.md",
    @cookbook.cookbook_data_flow_markdown(),
  )
  @support.write_text_file(
    "\{root}/book/describer/data-flow.html",
    @cookbook.cookbook_rendered_markdown_html(
      "Moontown Data Flow",
      "wiki/describer/data-flow.md",
      @cookbook.cookbook_data_flow_markdown(),
    ),
  )
  @support.write_text_file(
    "\{root}/wiki/describer/core-features.md",
    @cookbook.cookbook_core_features_markdown(),
  )
  @support.write_text_file(
    "\{root}/book/describer/core-features.html",
    @cookbook.cookbook_rendered_markdown_html(
      "Core Features In Code",
      "wiki/describer/core-features.md",
      @cookbook.cookbook_core_features_markdown(),
    ),
  )
  @support.write_text_file(
    "\{root}/wiki/describer/feature-guide.md",
    @cookbook.cookbook_feature_guide_markdown(),
  )
  @support.write_text_file(
    "\{root}/book/describer/feature-guide.html",
    @cookbook.cookbook_rendered_markdown_html(
      "Moontown Feature Guide",
      "wiki/describer/feature-guide.md",
      @cookbook.cookbook_feature_guide_markdown(),
    ),
  )
  @support.write_text_file(
    "\{root}/wiki/describer/content-rules.md",
    @cookbook.cookbook_content_rules_markdown(),
  )
  @support.write_text_file(
    "\{root}/book/describer/content-rules.html",
    @cookbook.cookbook_rendered_markdown_html(
      "Content-Specific Description Rules",
      "wiki/describer/content-rules.md",
      @cookbook.cookbook_content_rules_markdown(),
    ),
  )
  @support.write_text_file(
    "\{root}/wiki/history/stable-state-ledger.md",
    @cookbook.cookbook_stable_state_ledger_markdown(manifest),
  )
  @support.write_text_file(
    "\{root}/wiki/operating-procedures/doctor.md",
    @cookbook.cookbook_doctor_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/operating-procedures/book-governance.md",
    @cookbook.cookbook_book_governance_markdown(),
  )
  @support.write_text_file(
    "\{root}/raw/bootstrap/COOKBOOK_CONTRACT.md",
    @cookbook.cookbook_contract_markdown(),
  )
  @support.write_text_file(
    "\{root}/schemas/stable-state-manifest.schema.md",
    @cookbook.cookbook_schema_markdown(),
  )
  @support.write_text_file(
    "\{root}/skills/cookbook-generation/SKILL.md",
    @cookbook.cookbook_skill_markdown(),
  )
  @support.write_text_file(
    "\{root}/book/skills/cookbook-generation.html",
    @cookbook.cookbook_rendered_skill_html(
      "Moontown Cookbook Generation Skill",
      "skills/cookbook-generation/SKILL.md",
      @cookbook.cookbook_skill_markdown(),
    ),
  )
  @support.write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    @cookbook.ui_state_json(entry, manifest),
  )
  let html = @cookbook.generated_site_html(entry, manifest)
  @support.write_text_file("\{root}/book/Home.html", html)
  @support.write_text_file(
    @cookbook.cookbook_generated_site_workspace_path(root),
    html,
  )
}
