///|
pub async fn bootstrap_pdf_evidence_watch_book(
  book_id? : String = @pdf_evidence_watch.default_pdf_evidence_watch_book_id(),
  title? : String = "PDF Evidence Watch",
  purpose? : String = @pdf_evidence_watch.default_pdf_evidence_watch_purpose(),
  websites? : Array[String] = [],
  analysis_method? : String = "",
  cadence_ticks? : Int = 60,
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
  workspace_root? : String = "",
  template_root? : String = @pdf_evidence_watch.default_pdf_evidence_watch_template_root(),
) -> String {
  let root = if workspace_root.is_empty() {
    @pdf_evidence_watch.default_pdf_evidence_watch_workspace_root(book_id~)
  } else {
    workspace_root
  }
  let entry = @pdf_evidence_watch.pdf_evidence_watch_catalog_entry(
    book_id, title, purpose, root,
  )
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  @moonbook.save_catalog_file(
    book_catalog_path,
    @pdf_evidence_watch.merge_single_book(catalog, entry),
  )
  write_pdf_evidence_watch_workspace(
    entry, title, purpose, websites, analysis_method, cadence_ticks, template_root,
  )
  let goals = @storage.load_or_create_standing_goals(path=standing_goal_path)
  let goal = @pdf_evidence_watch.pdf_evidence_watch_standing_goal(
    book_id, title, purpose, websites, cadence_ticks,
  )
  @storage.save_standing_goals_file(
    standing_goal_path,
    @pdf_evidence_watch.upsert_pdf_evidence_watch_standing_goal(goals, goal),
  )
  let status = inspect_pdf_evidence_watch_book(
    book_id~,
    workspace_root=root,
    book_catalog_path~,
    standing_goal_path~,
  )
  [
    "book_template_install_status: installed",
    "Bootstrapped PDF Evidence Watch book `\{book_id}`.",
    "- Workspace: `\{root}`",
    "- Catalog: `\{book_catalog_path}`",
    "- Standing goal: `\{goal.id}` in `\{standing_goal_path}`",
    "- Websites: `\{websites.length()}`",
    "- Ready: `\{status.ready}`",
    "- Missing required: `\{status.missing_count}`",
  ].join("\n")
}
