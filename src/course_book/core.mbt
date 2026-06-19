///|
pub fn default_wenyu_course_book_id() -> String {
  "course-wenyu-game-design"
}

///|
pub fn default_wenyu_course_workspace_root() -> String {
  @moonbook.default_workspace_root(default_wenyu_course_book_id())
}

///|
pub fn wenyu_course_generated_site_path() -> String {
  @policy.default_generated_site_projection_path()
}

///|
pub fn wenyu_course_generated_site_workspace_path(root : String) -> String {
  "\{root}/\{wenyu_course_generated_site_path()}"
}

///|
pub fn wenyu_course_status_required_paths() -> Array[String] {
  [
    "wiki/index.md",
    "wiki/course/beginner-course.md",
    "raw/bootstrap/COURSE_CONTRACT.md",
    "raw/bootstrap/course-outline.md",
    "skills/course-builder/SKILL.md",
    "book/moonbook-ui-state.json",
    wenyu_course_generated_site_path(),
  ]
}

///|
pub fn default_wenyu_course_source_workspace_root() -> String {
  @moonbook.default_workspace_root("research-wenyu-game-design-course")
}

///|
pub fn wenyu_course_catalog_entry(
  workspace_root : String,
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id=default_wenyu_course_book_id(),
    name="MoonBook / Course / Wenyu Valley Game Design",
    purpose="Beginner course workspace for learning 2.5D/isometric tile-map design, asset pipelines, map planning, editor/view modes, and Wenyu Valley UI implementation.",
    workspace_root~,
    memory_scope=BookPrivate,
    tags=["course", "beginner", "game-design", "tile-map", "wenyu-valley"],
    skills=[
      "course-builder", "lesson-designer", "exercise-review", "beginner-teaching",
    ],
  )
}
