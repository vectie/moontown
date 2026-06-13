///|
pub async fn archive_pdf_evidence_watch_book(
  book_id? : String = @pdf_evidence_watch.default_pdf_evidence_watch_book_id(),
  reason? : String = "Archived by operator.",
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
  request_event_path? : String = @book_templates.request_event_path_for_request(
    @book_templates.request_path_for_snapshot(@storage.default_snapshot_path()),
  ),
) -> String {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let archived_catalog = @pdf_archive.archive_pdf_evidence_watch_catalog_entry(
    catalog, book_id, reason,
  )
  @moonbook.save_catalog_file(book_catalog_path, archived_catalog)
  let goals = @storage.load_or_create_standing_goals(path=standing_goal_path)
  let goal_id = @pdf_archive.pdf_evidence_watch_goal_id(book_id)
  let disabled_goals = @pdf_archive.disable_pdf_evidence_watch_book_standing_goals(
    goals, book_id,
  )
  let disabled_count = @pdf_archive.count_disabled_pdf_evidence_watch_book_standing_goals(
    goals, disabled_goals, book_id,
  )
  @storage.save_standing_goals_file(standing_goal_path, disabled_goals)
  let status = @pdf_evidence_watch_runtime.inspect_pdf_evidence_watch_book(
    book_id~,
    book_catalog_path~,
    standing_goal_path~,
  )
  append_pdf_evidence_watch_archive_event(
    book_id, reason, goal_id, disabled_count, status, request_event_path,
  )
  @pdf_archive.render_pdf_evidence_watch_archive_summary(
    book_id, reason, book_catalog_path, goal_id, disabled_count, request_event_path,
    status,
  )
}

///|
async fn append_pdf_evidence_watch_archive_event(
  book_id : String,
  reason : String,
  goal_id : String,
  disabled_count : Int,
  status : @pdf_evidence_watch.PdfEvidenceWatchBookStatus,
  request_event_path : String,
) -> Unit {
  let summary = "Archived PDF Evidence Watch book `\{book_id}`; standing goal `\{goal_id}` enabled=`\{status.standing_goal_enabled}`; disabled_goals=\{disabled_count}. Reason: \{reason}"
  @book_templates.append_request_event(request_event_path, {
    id: "archive-\{book_id}-\{@env.now()}",
    request_id: "archive-\{book_id}",
    template_id: "pdf-evidence-watch",
    status: "archived",
    config_path: "",
    summary,
    tick: 0,
    generated_at_ms: @env.now(),
  })
}
