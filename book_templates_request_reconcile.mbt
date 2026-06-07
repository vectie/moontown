///|
async fn reconcile_existing_book_template_request(
  request : BookTemplateRequest,
  context : BookTemplateRequestProcessContext,
  event_request_ids : Array[String],
) -> BookTemplateRequestProcessResult {
  if book_template_request_needs_event_reconcile(request, event_request_ids) {
    append_book_template_request_event(
      context.event_path,
      book_template_request_event(
        request,
        context,
        id=book_template_request_reconcile_event_id(request.id, context.tick),
      ),
    )
    event_request_ids.push(request.id)
    { request, processed: false, reconciled_event: true }
  } else {
    { request, processed: false, reconciled_event: false }
  }
}

///|
fn book_template_request_needs_event_reconcile(
  request : BookTemplateRequest,
  event_request_ids : Array[String],
) -> Bool {
  (request.status == "installed" || request.status == "failed") &&
  !event_request_ids.contains(request.id)
}

///|
fn book_template_request_reconcile_event_id(
  request_id : String,
  tick : Int,
) -> String {
  "\{request_id}-reconciled-\{tick}-\{@env.now()}"
}
