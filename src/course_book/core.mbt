///|
pub fn default_wenyu_course_book_id() -> String {
  "course-wenyu-game-design"
}

///|
pub fn default_wenyu_course_workspace_root() -> String {
  @moonbook.default_workspace_root(default_wenyu_course_book_id())
}

///|
pub async fn bootstrap_wenyu_game_design_course_book(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  workspace_root? : String = default_wenyu_course_workspace_root(),
  source_workspace_root? : String = @moonbook.default_workspace_root(
    "research-wenyu-game-design-course",
  ),
) -> String {
  let entry = wenyu_course_catalog_entry(workspace_root)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  @moonbook.save_catalog_file(
    book_catalog_path,
    merge_single_book(catalog, entry),
  )
  write_wenyu_course_workspace(entry, source_workspace_root)
  "Bootstrapped course book `\{entry.id}` at \{workspace_root}; source=\{source_workspace_root}; registered in \{book_catalog_path}."
}

///|
pub async fn render_wenyu_game_design_course_status(
  workspace_root? : String = default_wenyu_course_workspace_root(),
) -> String {
  let checks = [
    "wiki/index.md", "wiki/course/beginner-course.md", "raw/bootstrap/COURSE_CONTRACT.md",
    "raw/bootstrap/course-outline.md", "skills/course-builder/SKILL.md", "book/moonbook-ui-state.json",
    "book/site/generated/index.html",
  ]
  let missing : Array[String] = []
  for path in checks {
    if !@fs.exists("\{workspace_root}/\{path}") {
      missing.push(path)
    }
  }
  [
    "# Wenyu Course Book Status",
    "",
    "- Book: `\{default_wenyu_course_book_id()}`",
    "- Workspace: `\{workspace_root}`",
    "- Ready: `\{missing.is_empty()}`",
    "- Missing required: `\{missing.length()}`",
    "",
    "## Missing",
    "",
    if missing.is_empty() {
      "- none"
    } else {
      @support.markdown_bullets(missing)
    },
  ].join("\n")
}

///|
fn wenyu_course_catalog_entry(
  workspace_root : String,
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id=default_wenyu_course_book_id(),
    name="MoonBook / Course / Wenyu Valley Game Design",
    purpose="Beginner course workspace for learning 2.5D/isometric tile-map design, asset pipelines, map planning, editor/view modes, and Wenyu Valley UI implementation.",
    workspace_root~,
    memory_scope=@core.MemoryScope::BookPrivate,
    tags=["course", "beginner", "game-design", "tile-map", "wenyu-valley"],
    skills=[
      "course-builder", "lesson-designer", "exercise-review", "beginner-teaching",
    ],
  )
}

///|
async fn write_wenyu_course_workspace(
  entry : @moonbook.BookCatalogEntry,
  source_workspace_root : String,
) -> Unit {
  let root = entry.workspace_root
  let source_report = @support.read_text_or_empty(
    "\{source_workspace_root}/raw/bootstrap/deep-report.md",
  )
  let source_course = @support.read_text_or_empty(
    "\{source_workspace_root}/wiki/synthesis/beginner-course.md",
  )
  let course_body = course_body_from_sources(source_course, source_report)
  @support.write_text_file(
    "\{root}/wiki/index.md",
    wenyu_course_index_markdown(entry),
  )
  @support.write_text_file(
    "\{root}/wiki/course/beginner-course.md",
    course_body,
  )
  @support.write_text_file(
    "\{root}/wiki/course/exercises.md",
    wenyu_course_exercises_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/course/progress-rubric.md",
    wenyu_course_rubric_markdown(),
  )
  @support.write_text_file(
    "\{root}/raw/bootstrap/COURSE_CONTRACT.md",
    wenyu_course_contract_markdown(),
  )
  @support.write_text_file(
    "\{root}/raw/bootstrap/course-outline.md",
    wenyu_course_outline_markdown(),
  )
  @support.write_text_file(
    "\{root}/raw/bootstrap/source-material.md",
    wenyu_course_source_material_markdown(
      source_workspace_root, source_course, source_report,
    ),
  )
  @support.write_text_file(
    "\{root}/skills/course-builder/SKILL.md",
    course_builder_skill_markdown(),
  )
  @support.write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    wenyu_course_ui_state_json(entry),
  )
  let html = wenyu_course_generated_site_html(entry)
  @support.write_text_file("\{root}/book/Home.html", html)
  @support.write_text_file("\{root}/book/site/generated/index.html", html)
}
