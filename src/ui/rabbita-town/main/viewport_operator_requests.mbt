///|
fn render_request_composer(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  article(class="request-composer", [
    render_operator_request_header(dispatch, model),
    render_watch_request_mode(dispatch, model),
    render_operator_request_field_grid(dispatch, model),
    render_request_textarea_field(
      "Request",
      "Describe what the mayor should watch, what counts as a useful change, and what MoonBook should update.",
      model.request_prompt,
      value => dispatch(SetRequestPrompt(value)),
      disabled=model.request_submitting,
    ),
    render_material_watch_request_fields(dispatch, model),
    render_request_status_line(model.request_status),
    render_operator_request_last(model),
    render_material_watch_saved_requests(model),
  ])
}

///|
fn operator_request_submit_label(submitting : Bool) -> String {
  if submitting {
    "Saving watch..."
  } else {
    "Save Watch"
  }
}

///|
fn render_operator_request_header(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  div(class="request-composer-head", [
    div([p(class="eyebrow", "New Request"), h3("Ask the town to keep watching")]),
    div(class="request-composer-actions-top", [
      status_chip("Saves a durable watch", "chip-book"),
      button(
        class="control-button request-submit",
        disabled=model.request_submitting,
        on_click=dispatch(SubmitOperatorRequest),
        operator_request_submit_label(model.request_submitting),
      ),
    ]),
  ])
}

///|
fn render_operator_request_field_grid(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  div(class="request-field-grid", [
    render_request_input_field(
      "Title",
      "Track AI tooling news",
      model.request_title,
      value => dispatch(SetRequestTitle(value)),
      wide=true,
      disabled=model.request_submitting,
    ),
    render_request_input_field(
      "Target book",
      "research-topic",
      model.request_book_id,
      value => dispatch(SetRequestBookId(value)),
      disabled=model.request_submitting,
    ),
    div([
      render_request_input_field(
        "Check interval (ticks)",
        "60",
        model.request_cadence,
        value => dispatch(SetRequestCadence(value)),
        disabled=model.request_submitting,
      ),
      p(class="request-status", operator_request_cadence_help()),
    ]),
    render_request_input_field(
      "Quality threshold",
      "85",
      model.request_quality_threshold,
      value => dispatch(SetRequestQualityThreshold(value)),
      disabled=model.request_submitting,
    ),
  ])
}

///|
fn render_operator_request_last(model : Model) -> @rabbita.Html {
  p(class="request-last", operator_request_last_summary(model))
}

///|
fn operator_request_cadence_help() -> String {
  "One tick is one town-loop step. Elapsed time depends on the running town; 60 ticks does not mean 60 minutes."
}
