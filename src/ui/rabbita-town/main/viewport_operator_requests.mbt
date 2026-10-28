///|
fn render_request_composer(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  article(class="request-composer", [
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
    render_operator_request_settings(dispatch, model),
    render_request_status_line(model.request_status),
    div(class="request-submit-row", [
      button(
        class="control-button request-submit",
        disabled=model.request_submitting,
        on_click=dispatch(SubmitOperatorRequest),
        town_ui_label(
          "plus",
          operator_request_submit_label(model.request_submitting),
        ),
      ),
    ]),
    render_operator_request_last(model),
    render_material_watch_saved_requests(model),
  ])
}

///|
fn operator_request_submit_label(submitting : Bool) -> String {
  if submitting {
    "保存中…"
  } else {
    "保存关注"
  }
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
  ])
}

///|
fn render_operator_request_settings(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  render_advanced_details(
    "检查频率与质量",
    needs_attention=advanced_integer_needs_attention(
        model.request_cadence,
        max=2147483647,
      ) ||
      advanced_integer_needs_attention(model.request_quality_threshold, max=100),
    [
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
    ],
  )
}

///|
fn render_operator_request_last(model : Model) -> @rabbita.Html {
  match latest_operator_request(model) {
    None => @html.nothing
    Some(request) =>
      div([
        p(class="request-last", "已保存：\{request.title}"),
        render_advanced_details("上次请求详情", [
          p(class="request-last", operator_request_last_summary(model)),
        ]),
      ])
  }
}

///|
fn operator_request_cadence_help() -> String {
  "One tick is one town-loop step. Elapsed time depends on the running town; 60 ticks does not mean 60 minutes."
}
