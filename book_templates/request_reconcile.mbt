///|
async fn reconcile_existing_book_template_request(
  request : BookTemplateRequest,
  context : BookTemplateRequestProcessContext,
  event_request_ids : Array[String],
) -> BookTemplateRequestProcessResult {
  if request_needs_event_reconcile(request, event_request_ids) {
    let generated_at_ms = @env.now()
    append_request_event(
      context.event_path,
      request_event(
        request,
        context.tick,
        generated_at_ms,
        id=request_reconcile_event_id(request.id, context.tick, generated_at_ms),
      ),
    )
    event_request_ids.push(request.id)
    request_process_result(request, processed=false, reconciled_event=true)
  } else {
    request_process_result(request, processed=false, reconciled_event=false)
  }
}
