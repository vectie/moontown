///|
fn assert_moonbook_skill_quality(label : String, text : String) -> Unit raise {
  ignore(label)
  assert_true(moonbook_skill_quality_is_strong(text))
}

///|
test "MoonBook skill quality contract exposes simple metrics" {
  let text = moonbook_skill_quality_contract_section()
  assert_true(moonbook_skill_quality_has_depth(text))
  assert_true(moonbook_skill_quality_has_breadth(text))
  assert_true(moonbook_skill_quality_generates_questions(text))
  assert_true(moonbook_skill_quality_generates_directions(text))
  assert_true(moonbook_skill_quality_prefers_meaningful_length(text))
}

///|
test "Moontown generated skill templates keep exploration quality" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-policy-hall",
    name="Wenyu Policy Hall",
    purpose="Policy support module",
    workspace_root="/tmp/wenyu-policy-hall",
    tags=[],
  )
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  assert_moonbook_skill_quality("code-plan", code_plan_skill_markdown())
  assert_moonbook_skill_quality("code-review", code_review_skill_markdown())
  assert_moonbook_skill_quality("doc-sync", doc_sync_skill_markdown())
  assert_moonbook_skill_quality(
    "planbook-repair",
    planbook_repair_skill_markdown(),
  )
  assert_moonbook_skill_quality(
    "operational-keeper",
    default_operational_skill("Operations Book"),
  )
  assert_moonbook_skill_quality(
    "course-builder",
    course_builder_skill_markdown(),
  )
  assert_moonbook_skill_quality(
    "cookbook-generation",
    cookbook_skill_markdown(),
  )
  assert_moonbook_skill_quality(
    "editor-feature-rater",
    editor_feature_rater_skill_markdown(),
  )
  assert_moonbook_skill_quality(
    "wenyu-civic-service",
    wenyu_civic_service_skill_text(),
  )
  assert_moonbook_skill_quality(
    "wenyu-civic-module",
    civic_module_skill_text(service),
  )
  assert_moonbook_skill_quality("wenyu-build", wenyu_build_skill_text(entry))
  assert_moonbook_skill_quality(
    "wenyu-code-patch",
    wenyu_code_patch_skill_text(entry),
  )
  assert_moonbook_skill_quality(
    "wenyu-asset-pack",
    wenyu_asset_pack_skill_text(entry),
  )
}

///|
async test "Moontown static book skill templates keep exploration quality" {
  for
    path in [
      "templates/books/app-tool-book/skills/tool-watch/SKILL.md", "templates/books/app-tool-book/skills/tool-build/SKILL.md",
      "templates/books/pdf-evidence-watch/skills/pdf-watch/SKILL.md", "templates/books/pdf-evidence-watch/skills/pdf-analysis/SKILL.md",
    ] {
    assert_moonbook_skill_quality(path, @fs.read_file(path).text())
  }
}

///|
async test "MoonBook seed wiki skills keep exploration quality" {
  for
    path in [
      "../moonbook/seed/wiki/skills/claim-audit/SKILL.md", "../moonbook/seed/wiki/skills/concept-revise/SKILL.md",
      "../moonbook/seed/wiki/skills/contradiction-review/SKILL.md", "../moonbook/seed/wiki/skills/entity-revise/SKILL.md",
      "../moonbook/seed/wiki/skills/index-maintain/SKILL.md", "../moonbook/seed/wiki/skills/memory-prune/SKILL.md",
      "../moonbook/seed/wiki/skills/planbook/SKILL.md", "../moonbook/seed/wiki/skills/query-promote/SKILL.md",
      "../moonbook/seed/wiki/skills/research-report/SKILL.md", "../moonbook/seed/wiki/skills/review-decision/SKILL.md",
      "../moonbook/seed/wiki/skills/source-diarize/SKILL.md", "../moonbook/seed/wiki/skills/standing-watch/SKILL.md",
      "../moonbook/seed/wiki/skills/synthesis-revise/SKILL.md", "../moonbook/seed/wiki/skills/wiki-course/SKILL.md",
      "../moonbook/seed/wiki/skills/wiki-ingest/SKILL.md", "../moonbook/seed/wiki/skills/wiki-lint/SKILL.md",
      "../moonbook/seed/wiki/skills/wiki-marketing/SKILL.md", "../moonbook/seed/wiki/skills/wiki-memory/SKILL.md",
      "../moonbook/seed/wiki/skills/wiki-query/SKILL.md", "../moonbook/seed/wiki/skills/wiki-review/SKILL.md",
    ] {
    assert_moonbook_skill_quality(path, @fs.read_file(path).text())
  }
}
