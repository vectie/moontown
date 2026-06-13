///|
pub async fn bootstrap_wenyu_game_design_course_book(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  workspace_root? : String = @course_book.default_wenyu_course_workspace_root(),
  source_workspace_root? : String = @course_book.default_wenyu_course_source_workspace_root(),
) -> String {
  let entry = @course_book.wenyu_course_catalog_entry(workspace_root)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  @moonbook.save_catalog_file(
    book_catalog_path,
    merge_single_book(catalog, entry),
  )
  write_wenyu_course_workspace(entry, source_workspace_root)
  "Bootstrapped course book `\{entry.id}` at \{workspace_root}; source=\{source_workspace_root}; registered in \{book_catalog_path}."
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
  let course_body = @course_book.course_body_from_sources(
    source_course, source_report,
  )
  @support.write_text_file(
    "\{root}/wiki/index.md",
    @course_book.wenyu_course_index_markdown(entry),
  )
  @support.write_text_file(
    "\{root}/wiki/course/beginner-course.md",
    course_body,
  )
  @support.write_text_file(
    "\{root}/wiki/course/exercises.md",
    @course_book.wenyu_course_exercises_markdown(),
  )
  @support.write_text_file(
    "\{root}/wiki/course/progress-rubric.md",
    @course_book.wenyu_course_rubric_markdown(),
  )
  @support.write_text_file(
    "\{root}/raw/bootstrap/COURSE_CONTRACT.md",
    @course_book.wenyu_course_contract_markdown(),
  )
  @support.write_text_file(
    "\{root}/raw/bootstrap/course-outline.md",
    @course_book.wenyu_course_outline_markdown(),
  )
  @support.write_text_file(
    "\{root}/raw/bootstrap/source-material.md",
    @course_book.wenyu_course_source_material_markdown(
      source_workspace_root, source_course, source_report,
    ),
  )
  @support.write_text_file(
    "\{root}/skills/course-builder/SKILL.md",
    @course_book.course_builder_skill_markdown(),
  )
  @support.write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    @course_book.wenyu_course_ui_state_json(entry),
  )
  let html = @course_book.wenyu_course_generated_site_html(entry)
  @support.write_text_file("\{root}/book/Home.html", html)
  @support.write_text_file(
    @course_book.wenyu_course_generated_site_workspace_path(root),
    html,
  )
}

///|
fn merge_single_book(
  catalog : Array[@moonbook.BookCatalogEntry],
  entry : @moonbook.BookCatalogEntry,
) -> Array[@moonbook.BookCatalogEntry] {
  let merged : Array[@moonbook.BookCatalogEntry] = []
  let mut found = false
  for existing in catalog {
    if existing.id == entry.id {
      merged.push(entry)
      found = true
    } else {
      merged.push(existing)
    }
  }
  if !found {
    merged.push(entry)
  }
  merged
}
