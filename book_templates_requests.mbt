///|
pub async fn process_book_template_requests(
  request_path? : String = default_book_template_request_path(),
  registry_path? : String = default_book_template_registry_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
  tick? : Int = 0,
) -> String {
  let ledger = load_book_template_request_ledger(request_path)
  if ledger.requests.is_empty() {
    return render_book_template_request_process_summary(
      ledger,
      processed=0,
      reconciled_events=0,
    )
  }
  let event_path = default_book_template_request_event_path(request_path~)
  let event_request_ids = load_book_template_request_event_request_ids(
    event_path,
  )
  let context = book_template_request_process_context(
    request_path, event_path, registry_path, book_catalog_path, standing_goal_path,
    tick,
  )
  let outcome = process_book_template_request_ledger(
    ledger, context, event_request_ids,
  )
  save_book_template_request_ledger(request_path, outcome.ledger)
  render_book_template_request_process_summary(
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
priv struct BookTemplateRequestProcessingOutcome {
  ledger : BookTemplateRequestLedger
  processed : Int
  reconciled_events : Int
}

///|
async fn process_book_template_request_ledger(
  ledger : BookTemplateRequestLedger,
  context : BookTemplateRequestProcessContext,
  event_request_ids : Array[String],
) -> BookTemplateRequestProcessingOutcome {
  let mut processed = 0
  let mut reconciled_events = 0
  let updated : Array[BookTemplateRequest] = []
  for request in ledger.requests {
    let result = process_single_book_template_request(
      request, context, event_request_ids,
    )
    if result.processed {
      processed += 1
    }
    if result.reconciled_event {
      reconciled_events += 1
    }
    updated.push(result.request)
  }
  { ledger: { requests: updated }, processed, reconciled_events }
}
