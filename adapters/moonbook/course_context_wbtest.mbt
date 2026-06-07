///|
fn course_test_bundle() -> WorkerContextBundle {
  {
    book_id: "research-wenyu-game-design-course",
    workspace_root: "/tmp/course",
    task_id: "course-workbook",
    prompt: "Build a beginner course workbook.",
    policy: [],
    routines: [],
    skill_paths: ["skills/existing/SKILL.md"],
    context_pages: ["wiki/index.md"],
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "test",
    output_contract: [],
  }
}

///|
test "course context helpers define course-specific artifacts" {
  assert_eq(course_outline_path(), "raw/bootstrap/course-outline.md")
  assert_eq(course_workbook_path(), "raw/bootstrap/deep-report.md")
  assert_eq(course_synthesis_page_path(), "wiki/synthesis/beginner-course.md")
  assert_true(course_context_pages().contains(course_outline_path()))
  assert_true(course_context_pages().contains(course_workbook_path()))
  assert_true(course_context_pages().contains(course_synthesis_page_path()))
}

///|
test "course worker context adds course skills and pages once" {
  let entry = moonbook_adapter_catalog_entry(
    id="research-wenyu-game-design-course",
    name="Wenyu Game Design Course",
    purpose="Teach game design",
    workspace_root="/tmp/course",
  )
  let enriched = course_worker_context_bundle(entry, course_test_bundle())
  assert_true(
    enriched.skill_paths.contains("skills/wenyu-beginner-course/SKILL.md"),
  )
  assert_true(enriched.skill_paths.contains("skills/wiki-course/SKILL.md"))
  assert_true(enriched.context_pages.contains(course_outline_path()))
  assert_true(enriched.context_pages.contains(course_workbook_path()))
  assert_true(enriched.context_pages.contains(course_synthesis_page_path()))
}

///|
test "course prompt and output contract use course artifact helpers" {
  let entry = moonbook_adapter_catalog_entry(
    id="research-wenyu-game-design-course",
    name="Wenyu Game Design Course",
    purpose="Teach game design",
    workspace_root="/tmp/course",
  )
  let prompt = course_worker_prompt(entry, course_test_bundle())
  let contract = course_output_contract_lines().join("\n")
  for path in course_required_artifact_paths() {
    assert_true(prompt.contains(path))
    assert_true(contract.contains(path))
  }
  assert_true(contract.contains("beginner course workbook"))
}
