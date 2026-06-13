///|
async test "course book runtime bootstraps catalog workspace and status" {
  let root = "/tmp/moontown-course-book-runtime-wbtest-\{@async.now().to_int()}"
  @support.ignore_checked_command("rm", ["-rf", root])
  let catalog_path = "\{root}/catalog/books.json"
  let workspace_root = "\{root}/books/course-wenyu-game-design"
  let source_root = "\{root}/books/research-wenyu-game-design-course"
  @support.write_text_file(
    "\{source_root}/wiki/synthesis/beginner-course.md",
    "# Beginner Course\n\n## Lesson\n\nExercise: place roads before buildings.",
  )
  let message = bootstrap_wenyu_game_design_course_book(
    book_catalog_path=catalog_path,
    workspace_root~,
    source_workspace_root=source_root,
  )
  assert_true(message.contains("Bootstrapped course book"))
  assert_true(@fs.exists(catalog_path))
  assert_true(@fs.exists("\{workspace_root}/wiki/index.md"))
  assert_true(@fs.exists("\{workspace_root}/wiki/course/beginner-course.md"))
  assert_true(
    @fs.exists(
      "\{workspace_root}/\{@course_book.wenyu_course_generated_site_path()}",
    ),
  )
  let course_text = @fs.read_file(
    "\{workspace_root}/wiki/course/beginner-course.md",
  ).text()
  assert_true(course_text.contains("place roads before buildings"))
  let status = render_wenyu_game_design_course_status(workspace_root~)
  assert_true(status.contains("- Ready: `true`"))
  assert_true(status.contains("- Missing required: `0`"))
}
