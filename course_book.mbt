///|
pub fn default_wenyu_course_book_id() -> String {
  @course_book.default_wenyu_course_book_id()
}

///|
pub fn default_wenyu_course_workspace_root() -> String {
  @course_book.default_wenyu_course_workspace_root()
}

///|
pub async fn bootstrap_wenyu_game_design_course_book(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  workspace_root? : String = default_wenyu_course_workspace_root(),
  source_workspace_root? : String = @moonbook.default_workspace_root(
    "research-wenyu-game-design-course",
  ),
) -> String {
  @course_book.bootstrap_wenyu_game_design_course_book(
    book_catalog_path~,
    workspace_root~,
    source_workspace_root~,
  )
}

///|
pub async fn render_wenyu_game_design_course_status(
  workspace_root? : String = default_wenyu_course_workspace_root(),
) -> String {
  @course_book.render_wenyu_game_design_course_status(workspace_root~)
}
