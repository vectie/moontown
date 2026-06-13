///|
test "course worker contracts own skill and context paths" {
  assert_true(course_skill_paths().contains(wenyu_beginner_course_skill_path()))
  assert_true(course_skill_paths().contains(wiki_course_skill_path()))
  assert_true(
    course_skill_paths().contains(
      @research_policy.web_first_research_skill_path(),
    ),
  )
  assert_eq(course_outline_path(), "raw/bootstrap/course-outline.md")
  assert_eq(course_workbook_path(), "raw/bootstrap/deep-report.md")
  assert_eq(course_synthesis_page_path(), "wiki/synthesis/beginner-course.md")
  assert_true(course_context_pages().contains(course_outline_path()))
  assert_true(course_context_pages().contains(course_workbook_path()))
  assert_true(course_context_pages().contains(course_synthesis_page_path()))
}

///|
test "course worker contracts own prompt and output shape" {
  let prompt = course_worker_prompt("Wenyu Game Design", "Build a course.")
  let contract = course_output_contract_lines().join("\n")
  for path in course_required_artifact_paths() {
    assert_true(prompt.contains(path))
    assert_true(contract.contains(path))
  }
  assert_true(prompt.contains("COURSE MODE"))
  assert_true(contract.contains("beginner course workbook"))
  assert_true(
    course_worker_policy_lines().join("\n").contains("not a research-report"),
  )
  assert_true(
    course_worker_routine_lines().join("\n").contains(wiki_course_skill_path()),
  )
}
