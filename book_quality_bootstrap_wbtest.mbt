///|
async test "planbook bootstrap creates durable plan workspace and status" {
  let root = cleaned_book_quality_test_root("/tmp/moontown-planbook-wbtest")
  let catalog_path = "\{root}/moonbooks.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let message = bootstrap_moontown_planbook(
    book_catalog_path=catalog_path,
    workspace_root~,
  )
  assert_true(message.contains("Bootstrapped planbook"))
  assert_true(@fs.exists("\{workspace_root}/wiki/index.md"))
  assert_true(
    @fs.exists(
      "\{workspace_root}/plans/2026-05-29-book-quality-upgrade/plan.md",
    ),
  )
  assert_true(
    @fs.exists(
      "\{workspace_root}/plans/2026-05-31-editor-mode-real-pipeline/plan.md",
    ),
  )
  assert_true(@fs.exists("\{workspace_root}/skills/code-plan/SKILL.md"))
  assert_true(
    @fs.exists("\{workspace_root}/wiki/planning/operating-architecture.md"),
  )
  assert_true(
    @fs.exists("\{workspace_root}/wiki/history/daily-engineering-digest.md"),
  )
  let architecture = read_text_or_empty(
    "\{workspace_root}/wiki/planning/operating-architecture.md",
  )
  assert_true(architecture.contains("Buildings are protocol places"))
  assert_true(architecture.contains("Growth Contract"))
  let status = render_moontown_planbook_status(workspace_root~)
  assert_true(status.contains("Ready: `true`"))
  assert_true(status.contains("Missing required: `0`"))
}

///|
async test "course bootstrap creates course-shaped MoonBook workspace" {
  let root = cleaned_book_quality_test_root("/tmp/moontown-course-book-wbtest")
  let catalog_path = "\{root}/moonbooks.json"
  let workspace_root = "\{root}/books/course-wenyu-game-design"
  let source_workspace_root = "\{root}/source"
  write_text_file(
    "\{source_workspace_root}/raw/bootstrap/deep-report.md",
    "# Beginner Course\n\n## Lesson 1\n\nStart from map reading, then build one tile.",
  )
  let message = bootstrap_wenyu_game_design_course_book(
    book_catalog_path=catalog_path,
    workspace_root~,
    source_workspace_root~,
  )
  assert_true(message.contains("Bootstrapped course book"))
  assert_true(@fs.exists("\{workspace_root}/wiki/course/beginner-course.md"))
  assert_true(@fs.exists("\{workspace_root}/wiki/course/exercises.md"))
  assert_true(@fs.exists("\{workspace_root}/skills/course-builder/SKILL.md"))
  let status = render_wenyu_game_design_course_status(workspace_root~)
  assert_true(status.contains("Ready: `true`"))
  assert_true(status.contains("Missing required: `0`"))
}
