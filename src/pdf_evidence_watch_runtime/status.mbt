///|
pub async fn inspect_pdf_evidence_watch_book(
  book_id? : String = @pdf_evidence_watch.default_pdf_evidence_watch_book_id(),
  workspace_root? : String = "",
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> @pdf_evidence_watch.PdfEvidenceWatchBookStatus {
  let root = @pdf_evidence_watch.pdf_evidence_watch_resolved_workspace_root(
    book_id, workspace_root,
  )
  let required = @pdf_evidence_watch.pdf_evidence_watch_required_paths()
  let missing = workspace_missing_relative_paths(root, required)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let goals = @storage.load_or_create_standing_goals(path=standing_goal_path)
  let has_catalog_entry = @moonbook.entry_for_book_id(catalog, book_id)
    is Some(_)
  let goal_id = @pdf_evidence_watch.pdf_evidence_watch_goal_id(book_id)
  let has_standing_goal = @pdf_evidence_watch.pdf_evidence_watch_goal_in(
    goals, goal_id,
  )
  let standing_goal_enabled = @pdf_evidence_watch.pdf_evidence_watch_goal_enabled_in(
    goals, goal_id,
  )
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
  book_id? : String = @pdf_evidence_watch.default_pdf_evidence_watch_book_id(),
  workspace_root? : String = "",
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> String {
  @pdf_evidence_watch.render_pdf_evidence_watch_book_status(
    inspect_pdf_evidence_watch_book(
      book_id~,
      workspace_root~,
      book_catalog_path~,
      standing_goal_path~,
    ),
  )
}
