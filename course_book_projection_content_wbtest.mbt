///|
test "course generated site keeps course identity and beginner sections" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="course-wenyu-game-design",
    name="Wenyu Game Design Course",
    purpose="course",
    workspace_root="/tmp/course",
  )
  let html = wenyu_course_generated_site_html(entry)
  assert_true(html.contains("<title>Wenyu Valley Game Design Course</title>"))
  assert_true(html.contains("MoonBook Course"))
  assert_true(html.contains("<h2>Learn</h2>"))
  assert_true(html.contains("<h2>Build</h2>"))
  assert_true(html.contains("<h2>Review</h2>"))
  assert_true(!html.contains("Deep Research Analysis"))
}

///|
test "course generated site escapes workspace root in hero" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="course-wenyu-game-design",
    name="Wenyu Game Design Course",
    purpose="course",
    workspace_root="/tmp/course/<unsafe>",
  )
  let html = wenyu_course_generated_site_html(entry)
  assert_true(html.contains("/tmp/course/&lt;unsafe&gt;"))
  assert_true(!html.contains("/tmp/course/<unsafe>"))
}
