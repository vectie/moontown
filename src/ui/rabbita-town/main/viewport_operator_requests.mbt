///|
fn render_request_composer(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  article(class="request-composer", [
    render_operator_request_header(dispatch, model),
    render_operator_request_field_grid(dispatch, model),
    render_request_textarea_field(
      "Request",
      "Describe what the mayor should watch, what counts as a useful change, and what MoonBook should update.",
      model.request_prompt,
      value => dispatch(SetRequestPrompt(value)),
    ),
    render_request_status_line(model.request_status),
    render_operator_request_last(model),
  ])
}

///|
fn operator_request_submit_label(submitting : Bool) -> String {
  if submitting {
    "Submitting..."
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
    ),
    render_request_input_field(
      "Target book",
      "research-topic",
      model.request_book_id,
      value => dispatch(SetRequestBookId(value)),
    ),
    render_request_input_field("Check frequency", "60", model.request_cadence, value => {
      dispatch(SetRequestCadence(value))
    }),
    render_request_input_field(
      "Quality threshold",
      "85",
      model.request_quality_threshold,
      value => dispatch(SetRequestQualityThreshold(value)),
    ),
  ])
}

///|
fn render_operator_request_last(model : Model) -> @rabbita.Html {
  p(class="request-last", operator_request_last_summary(model))
}
