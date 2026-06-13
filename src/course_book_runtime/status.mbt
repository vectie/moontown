///|
pub async fn render_wenyu_game_design_course_status(
  workspace_root? : String = @course_book.default_wenyu_course_workspace_root(),
) -> String {
  let missing = missing_wenyu_course_required_paths(workspace_root)
  [
    "# Wenyu Course Book Status",
    "",
    "- Book: `\{@course_book.default_wenyu_course_book_id()}`",
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
async fn missing_wenyu_course_required_paths(
  workspace_root : String,
) -> Array[String] {
  let missing : Array[String] = []
  for path in @course_book.wenyu_course_status_required_paths() {
    if !@fs.exists("\{workspace_root}/\{path}") {
      missing.push(path)
    }
  }
  missing
}
