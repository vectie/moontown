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
test "course projection labels come from policy package" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="course-wenyu-game-design",
    name="Wenyu Game Design Course",
    purpose="course",
    workspace_root="/tmp/course",
  )
  let state = wenyu_course_ui_state_json(entry)
  assert_true(
    state.contains(
      "{\"label\":\{@support.json_string(@policy.course_type())},\"tone\":\"healthy\"}",
    ),
  )
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

///|
test "course book generated site path follows policy default" {
  assert_eq(
    wenyu_course_generated_site_path(),
    @policy.default_generated_site_projection_path(),
  )
  assert_true(
    wenyu_course_status_required_paths().contains(
      @policy.default_generated_site_projection_path(),
    ),
  )
  assert_eq(
    wenyu_course_generated_site_workspace_path("/tmp/course"),
    "/tmp/course/\{@policy.default_generated_site_projection_path()}",
  )
}
