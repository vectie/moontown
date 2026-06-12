///|
pub async fn write_workspace(
  entry : @moonbook.BookCatalogEntry,
  manifest : MoontownCookbookManifest,
) -> Unit {
  let root = entry.workspace_root
  write_text_file(
    "\{root}/wiki/index.md",
    cookbook_index_markdown(entry, manifest),
  )
  write_text_file(
    "\{root}/wiki/definitions/stable-state.md",
    cookbook_stable_state_markdown(manifest),
  )
  write_text_file(
    "\{root}/wiki/definitions/ownership.md",
    cookbook_ownership_markdown(),
  )
  write_text_file(
    "\{root}/wiki/definitions/book-types.md",
    cookbook_book_types_markdown(),
  )
  write_text_file(
    "\{root}/wiki/definitions/runtime-boundaries.md",
    cookbook_runtime_boundaries_markdown(),
  )
  write_text_file(
    "\{root}/wiki/definitions/live-autonomy-spine.md",
    cookbook_live_autonomy_spine_markdown(),
  )
  write_text_file(
    "\{root}/wiki/describer/overview.md",
    cookbook_describer_overview_markdown(),
  )
  write_text_file(
    "\{root}/book/describer/overview.html",
    cookbook_rendered_markdown_html(
      "Moontown Codebase Describer",
      "wiki/describer/overview.md",
      cookbook_describer_overview_markdown(),
    ),
  )
  write_text_file(
    "\{root}/wiki/describer/algorithms.md",
    cookbook_algorithms_markdown(),
  )
  write_text_file(
    "\{root}/book/describer/algorithms.html",
    cookbook_rendered_markdown_html(
      "Algorithms Used In Moontown",
      "wiki/describer/algorithms.md",
      cookbook_algorithms_markdown(),
    ),
  )
  write_text_file(
    "\{root}/wiki/describer/data-structures.md",
    cookbook_data_structures_markdown(),
  )
  write_text_file(
    "\{root}/book/describer/data-structures.html",
    cookbook_rendered_markdown_html(
      "Moontown Data Structures",
      "wiki/describer/data-structures.md",
      cookbook_data_structures_markdown(),
    ),
  )
  write_text_file(
    "\{root}/wiki/describer/data-flow.md",
    cookbook_data_flow_markdown(),
  )
  write_text_file(
    "\{root}/book/describer/data-flow.html",
    cookbook_rendered_markdown_html(
      "Moontown Data Flow",
      "wiki/describer/data-flow.md",
      cookbook_data_flow_markdown(),
    ),
  )
  write_text_file(
    "\{root}/wiki/describer/core-features.md",
    cookbook_core_features_markdown(),
  )
  write_text_file(
    "\{root}/book/describer/core-features.html",
    cookbook_rendered_markdown_html(
      "Core Features In Code",
      "wiki/describer/core-features.md",
      cookbook_core_features_markdown(),
    ),
  )
  write_text_file(
    "\{root}/wiki/describer/feature-guide.md",
    cookbook_feature_guide_markdown(),
  )
  write_text_file(
    "\{root}/book/describer/feature-guide.html",
    cookbook_rendered_markdown_html(
      "Moontown Feature Guide",
      "wiki/describer/feature-guide.md",
      cookbook_feature_guide_markdown(),
    ),
  )
  write_text_file(
    "\{root}/wiki/describer/content-rules.md",
    cookbook_content_rules_markdown(),
  )
  write_text_file(
    "\{root}/book/describer/content-rules.html",
    cookbook_rendered_markdown_html(
      "Content-Specific Description Rules",
      "wiki/describer/content-rules.md",
      cookbook_content_rules_markdown(),
    ),
  )
  write_text_file(
    "\{root}/wiki/history/stable-state-ledger.md",
    cookbook_stable_state_ledger_markdown(manifest),
  )
  write_text_file(
    "\{root}/wiki/operating-procedures/doctor.md",
    cookbook_doctor_markdown(),
  )
  write_text_file(
    "\{root}/wiki/operating-procedures/book-governance.md",
    cookbook_book_governance_markdown(),
  )
  write_text_file(
    "\{root}/raw/bootstrap/COOKBOOK_CONTRACT.md",
    cookbook_contract_markdown(),
  )
  write_text_file(
    "\{root}/schemas/stable-state-manifest.schema.md",
    cookbook_schema_markdown(),
  )
  write_text_file(
    "\{root}/skills/cookbook-generation/SKILL.md",
    cookbook_skill_markdown(),
  )
  write_text_file(
    "\{root}/book/skills/cookbook-generation.html",
    cookbook_rendered_skill_html(
      "Moontown Cookbook Generation Skill",
      "skills/cookbook-generation/SKILL.md",
      cookbook_skill_markdown(),
    ),
  )
  write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    ui_state_json(entry, manifest),
  )
  let html = generated_site_html(entry, manifest)
  write_text_file("\{root}/book/Home.html", html)
  write_text_file(cookbook_generated_site_workspace_path(root), html)
}

///|
fn cookbook_generated_site_path() -> String {
  @policy.default_generated_site_projection_path()
}

///|
fn cookbook_generated_site_workspace_path(root : String) -> String {
  "\{root}/\{cookbook_generated_site_path()}"
}
