///|
fn wenyu_test_bundle(
  task_id? : String = "wenyu-build",
  prompt? : String = "Build Wenyu Valley.",
  context_pages? : Array[String] = [],
) -> WorkerContextBundle {
  {
    book_id: "wenyu-valley",
    workspace_root: "/tmp/wenyu",
    task_id,
    prompt,
    policy: [],
    routines: [],
    skill_paths: ["skills/existing/SKILL.md"],
    context_pages,
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "test",
    output_contract: [],
  }
}

///|
test "wenyu base context helpers define reusable build artifacts" {
  assert_eq(wenyu_prd_path(), "raw/bootstrap/WENYU_VALLEY_PRD.md")
  assert_eq(wenyu_vision_path(), "raw/bootstrap/WENYU_VISION.md")
  assert_eq(wenyu_build_report_path(), "raw/bootstrap/deep-report.md")
  assert_eq(wenyu_evidence_matrix_path(), "raw/bootstrap/evidence-matrix.md")
  assert_eq(wenyu_marketing_brief_path(), "raw/bootstrap/marketing-brief.md")
  assert_eq(wenyu_local_sources_path(), "raw/bootstrap/local-sources.md")
  assert_true(wenyu_base_context_pages().contains(wenyu_prd_path()))
  assert_true(wenyu_base_context_pages().contains(wenyu_vision_path()))
  assert_true(wenyu_base_context_pages().contains(wenyu_build_report_path()))
  assert_true(wenyu_base_context_pages().contains(wenyu_evidence_matrix_path()))
  assert_true(wenyu_base_skill_paths().contains("skills/wenyu-build/SKILL.md"))
  assert_true(
    wenyu_base_skill_paths().contains("skills/wenyu-code-patch/SKILL.md"),
  )
}

///|
test "wenyu context adds base skills and pages for non-civic work" {
  let entry = moonbook_adapter_catalog_entry(
    id="wenyu-valley",
    name="Wenyu Valley",
    purpose="Build Wenyu Valley",
    workspace_root="/tmp/wenyu",
  )
  let enriched = enrich_wenyu_worker_context_bundle(entry, wenyu_test_bundle())
  assert_true(enriched.skill_paths.contains("skills/wenyu-build/SKILL.md"))
  assert_true(enriched.context_pages.contains(wenyu_prd_path()))
  assert_true(
    !enriched.skill_paths.contains("skills/wenyu-civic-service/SKILL.md"),
  )
  assert_true(
    !enriched.context_pages.contains(wenyu_civic_service_contract_path()),
  )
}

///|
test "wenyu civic context adds civic protocol skills and pages" {
  let entry = moonbook_adapter_catalog_entry(
    id="wenyu-valley",
    name="Wenyu Valley",
    purpose="Build Wenyu Valley",
    workspace_root="/tmp/wenyu",
  )
  let bundle = wenyu_test_bundle(
    task_id="policy-civic-service",
    prompt="Run civic service exchange.",
    context_pages=[
      wenyu_civic_service_contract_path(),
      "skills/domain-specialist/SKILL.md",
    ],
  )
  let enriched = enrich_wenyu_worker_context_bundle(entry, bundle)
  assert_true(
    enriched.skill_paths.contains("skills/wenyu-civic-service/SKILL.md"),
  )
  assert_true(
    enriched.skill_paths.contains("skills/domain-specialist/SKILL.md"),
  )
  assert_true(
    enriched.context_pages.contains(wenyu_civic_service_contract_path()),
  )
  assert_true(enriched.context_pages.contains("book/moonbook-ui-state.json"))
  assert_true(
    enriched.output_contract.join("\n").contains("civic_service_decision"),
  )
}
