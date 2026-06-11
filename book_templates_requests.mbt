///|
pub async fn process_book_template_requests(
  request_path? : String = @book_templates.request_path_for_snapshot(
    @storage.default_snapshot_path(),
  ),
  registry_path? : String = @book_templates.default_registry_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
  tick? : Int = 0,
) -> String {
  let ledger = @book_templates.load_request_ledger(request_path)
  if ledger.requests.is_empty() {
    return @book_templates.render_request_process_summary(
      ledger,
      processed=0,
      reconciled_events=0,
    )
  }
  let event_path = @book_templates.request_event_path_for_request(request_path)
  let event_request_ids = @book_templates.load_request_event_request_ids(
    event_path,
  )
  let context = book_template_request_process_context(
    request_path, event_path, registry_path, book_catalog_path, standing_goal_path,
    tick,
  )
  let outcome = process_book_template_request_ledger(
    ledger, context, event_request_ids,
  )
  @book_templates.save_request_ledger(request_path, outcome.ledger)
  @book_templates.render_request_process_summary(
    outcome.ledger,
    processed=outcome.processed,
    reconciled_events=outcome.reconciled_events,
  )
}

///|
fn book_template_request_process_context(
  request_path : String,
  event_path : String,
  registry_path : String,
  book_catalog_path : String,
  standing_goal_path : String,
  tick : Int,
) -> BookTemplateRequestProcessContext {
  {
    request_base_dir: @path.Path::dirname(request_path).to_string(),
    event_path,
    registry_path,
    book_catalog_path,
    standing_goal_path,
    tick,
  }
}

///|
async fn process_book_template_request_ledger(
  ledger : @book_templates.BookTemplateRequestLedger,
  context : BookTemplateRequestProcessContext,
  event_request_ids : Array[String],
) -> @book_templates.BookTemplateRequestProcessingOutcome {
  let results : Array[@book_templates.BookTemplateRequestProcessResult] = []
  for request in ledger.requests {
    results.push(
      process_single_book_template_request(request, context, event_request_ids),
    )
  }
  @book_templates.request_processing_outcome(results)
}
