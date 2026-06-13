///|
priv struct CivicServiceLatestResultEvidence {
  path : String
  found : Bool
  decision : String
  book_changed : String
  pages_changed : Int
  accepted_facts : Int
  review_items : Int
  next_check_hint : String
}

///|
async fn inspect_civic_service_latest_result(
  service : @civic.CivicServiceDefinition,
  root : String,
) -> CivicServiceLatestResultEvidence {
  let path = @civic.civic_service_result_path(service, root~)
  let latest_result = read_civic_book_result(path)
  let summary = match latest_result {
    Some(result) => result.summary
    None => ""
  }
  {
    path,
    found: latest_result != None,
    decision: civic_marker_value(
      summary,
      "civic_service_decision",
      fallback=if latest_result == None { "none" } else { "unknown" },
    ),
    book_changed: civic_marker_value(
      summary,
      "book_changed",
      fallback="unknown",
    ),
    pages_changed: civic_marker_int(
      summary,
      "wiki_pages_changed_count",
      fallback=0,
    ),
    accepted_facts: civic_marker_int(
      summary,
      "accepted_facts_count",
      fallback=0,
    ),
    review_items: civic_marker_int(
      summary,
      "review_items_created_count",
      fallback=0,
    ),
    next_check_hint: civic_marker_value(
      summary,
      "next_check_hint",
      fallback="unknown",
    ),
  }
}

///|
async fn read_civic_book_result(path : String) -> @moonbook.BookResult? {
  let text = @support.read_text_or_empty(path)
  if text.trim().is_empty() {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}
