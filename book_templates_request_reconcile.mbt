///|
async fn reconcile_existing_book_template_request(
  request : @book_templates.BookTemplateRequest,
  context : BookTemplateRequestProcessContext,
  event_request_ids : Array[String],
) -> @book_templates.BookTemplateRequestProcessResult {
  if @book_templates.request_needs_event_reconcile(request, event_request_ids) {
    let generated_at_ms = @env.now()
    @book_templates.append_request_event(
      context.event_path,
      @book_templates.request_event(
        request,
        context.tick,
        generated_at_ms,
        id=@book_templates.request_reconcile_event_id(
          request.id,
          context.tick,
          generated_at_ms,
        ),
      ),
    )
    event_request_ids.push(request.id)
    @book_templates.request_process_result(
      request,
      processed=false,
      reconciled_event=true,
    )
  } else {
    @book_templates.request_process_result(
      request,
      processed=false,
      reconciled_event=false,
    )
  }
}
