///|
async fn process_single_book_template_request(
  request : BookTemplateRequest,
  context : BookTemplateRequestProcessContext,
  event_request_ids : Array[String],
) -> BookTemplateRequestProcessResult {
  if book_template_request_should_install(request) {
    install_book_template_request(request, context, event_request_ids)
  } else {
    reconcile_existing_book_template_request(
      request, context, event_request_ids,
    )
  }
}

///|
async fn install_book_template_request(
  request : BookTemplateRequest,
  context : BookTemplateRequestProcessContext,
  event_request_ids : Array[String],
) -> BookTemplateRequestProcessResult {
  let config_path = resolve_book_template_request_path(
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
  let next_request = {
    ..request,
    config_path,
    status: if book_template_install_summary_success(summary) {
      "installed"
    } else {
      "failed"
    },
    summary,
    last_processed_tick: context.tick,
  }
  append_book_template_request_event(
    context.event_path,
    book_template_request_event(
      next_request,
      context,
      id=book_template_request_event_id(request.id, context.tick),
    ),
  )
  event_request_ids.push(request.id)
  { request: next_request, processed: true, reconciled_event: false }
}

///|
fn book_template_request_should_install(request : BookTemplateRequest) -> Bool {
  request.status == "pending" || request.status == "retry"
}

///|
fn book_template_request_event_id(request_id : String, tick : Int) -> String {
  "\{request_id}-\{tick}-\{@env.now()}"
}

///|
fn book_template_request_event(
  request : BookTemplateRequest,
  context : BookTemplateRequestProcessContext,
  id~ : String,
) -> BookTemplateRequestEvent {
  {
    id,
    request_id: request.id,
    template_id: request.template_id,
    status: request.status,
    config_path: request.config_path,
    summary: request.summary,
    tick: context.tick,
    generated_at_ms: @env.now(),
  }
}
