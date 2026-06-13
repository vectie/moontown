///|
async fn process_single_book_template_request(
  request : @book_templates.BookTemplateRequest,
  context : @book_templates.BookTemplateRequestProcessContext,
  event_request_ids : Array[String],
) -> @book_templates.BookTemplateRequestProcessResult {
  if @book_templates.request_status_should_install(request.status) {
    install_book_template_request(request, context, event_request_ids)
  } else {
    reconcile_existing_book_template_request(
      request, context, event_request_ids,
    )
  }
}

///|
async fn install_book_template_request(
  request : @book_templates.BookTemplateRequest,
  context : @book_templates.BookTemplateRequestProcessContext,
  event_request_ids : Array[String],
) -> @book_templates.BookTemplateRequestProcessResult {
  let config_path = @book_templates.resolve_request_path(
    context.request_base_dir,
    request.config_path,
  )
  let summary = install_book_template_config(
    request.template_id,
    config_path,
    registry_path=context.registry_path,
    book_catalog_path=context.book_catalog_path,
    standing_goal_path=context.standing_goal_path,
  )
  let next_request = @book_templates.request_after_install_result(
    request,
    config_path,
    summary,
    context.tick,
  )
  let generated_at_ms = @env.now()
  append_request_event(
    context.event_path,
    @book_templates.request_event(
      next_request,
      context.tick,
      generated_at_ms,
      id=@book_templates.request_event_id(
        request.id,
        context.tick,
        generated_at_ms,
      ),
    ),
  )
  event_request_ids.push(request.id)
  @book_templates.request_process_result(
    next_request,
    processed=true,
    reconciled_event=false,
  )
}

///|
async fn reconcile_existing_book_template_request(
  request : @book_templates.BookTemplateRequest,
  context : @book_templates.BookTemplateRequestProcessContext,
  event_request_ids : Array[String],
) -> @book_templates.BookTemplateRequestProcessResult {
  if !@book_templates.request_needs_event_reconcile(request, event_request_ids) {
    return @book_templates.request_process_result(
      request,
      processed=false,
      reconciled_event=false,
    )
  }
  let generated_at_ms = @env.now()
  append_request_event(
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
}
