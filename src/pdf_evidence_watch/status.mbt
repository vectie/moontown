///|
pub(all) struct PdfEvidenceWatchBookStatus {
  book_id : String
  workspace_root : String
  required_count : Int
  missing_count : Int
  missing_paths : Array[String]
  has_catalog_entry : Bool
  has_standing_goal : Bool
  standing_goal_enabled : Bool
  ready : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn render_pdf_evidence_watch_book_status(
  status : PdfEvidenceWatchBookStatus,
) -> String {
  [
    "# PDF Evidence Watch Book Status",
    "",
    "- Book: `\{status.book_id}`",
    "- Workspace: `\{status.workspace_root}`",
    "- Ready: `\{status.ready}`",
    "- Catalog entry: `\{status.has_catalog_entry}`",
    "- Standing goal: `\{status.has_standing_goal}`",
    "- Standing goal enabled: `\{status.standing_goal_enabled}`",
    "- Missing required: `\{status.missing_count}` / `\{status.required_count}`",
    "",
    "## Missing",
    "",
    if status.missing_paths.is_empty() {
      "- none"
    } else {
      markdown_bullets(status.missing_paths)
    },
  ].join("\n")
}

///|
pub fn pdf_evidence_watch_resolved_workspace_root(
  book_id : String,
  workspace_root : String,
) -> String {
  if workspace_root.is_empty() {
    default_pdf_evidence_watch_workspace_root(book_id~)
  } else {
    workspace_root
  }
}

///|
