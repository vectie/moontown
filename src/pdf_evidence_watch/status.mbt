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
pub async fn inspect_pdf_evidence_watch_book(
  book_id? : String = default_pdf_evidence_watch_book_id(),
  workspace_root? : String = "",
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> PdfEvidenceWatchBookStatus {
  let root = pdf_evidence_watch_resolved_workspace_root(book_id, workspace_root)
  let required = pdf_evidence_watch_required_paths()
  let missing = missing_pdf_evidence_watch_required_paths(root)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let goals = @storage.load_or_create_standing_goals(path=standing_goal_path)
  let has_catalog_entry = @moonbook.entry_for_book_id(catalog, book_id)
    is Some(_)
  let goal_id = pdf_evidence_watch_goal_id(book_id)
  let has_standing_goal = pdf_evidence_watch_goal_in(goals, goal_id)
  let standing_goal_enabled = pdf_evidence_watch_goal_enabled_in(goals, goal_id)
  {
    book_id,
    workspace_root: root,
    required_count: required.length(),
    missing_count: missing.length(),
    missing_paths: missing,
    has_catalog_entry,
    has_standing_goal,
    standing_goal_enabled,
    ready: missing.is_empty() &&
    has_catalog_entry &&
    has_standing_goal &&
    standing_goal_enabled,
  }
}

///|
pub async fn render_pdf_evidence_watch_book_status(
  book_id? : String = default_pdf_evidence_watch_book_id(),
  workspace_root? : String = "",
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> String {
  let status = inspect_pdf_evidence_watch_book(
    book_id~,
    workspace_root~,
    book_catalog_path~,
    standing_goal_path~,
  )
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
fn pdf_evidence_watch_resolved_workspace_root(
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
async fn missing_pdf_evidence_watch_required_paths(
  workspace_root : String,
) -> Array[String] {
  workspace_missing_relative_paths(
    workspace_root,
    pdf_evidence_watch_required_paths(),
  )
}
