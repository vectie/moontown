///|
fn render_book_template_composer(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  article(class="request-composer book-template-composer", [
    render_book_template_request_header(dispatch, model),
    p(class="request-last", book_template_request_intro()),
    render_book_template_request_field_grid(dispatch, model),
    render_request_textarea_field(
      "Websites",
      "https://example.org/reports\nhttps://example.com/publications",
      model.book_request_websites,
      value => dispatch(SetBookRequestWebsites(value)),
      compact=true,
    ),
    render_request_textarea_field(
      "Purpose",
      "Describe what this book should watch and what counts as new knowledge.",
      model.book_request_purpose,
      value => dispatch(SetBookRequestPurpose(value)),
      compact=true,
    ),
    render_request_textarea_field(
      "Analysis method override",
      "Optional. Leave blank to use the template method, or describe the exact analysis rules.",
      model.book_request_analysis_method,
      value => dispatch(SetBookRequestAnalysisMethod(value)),
      compact=true,
    ),
    render_request_status_line(model.book_request_status),
  ])
}

///|
fn book_template_request_submit_label(submitting : Bool) -> String {
  if submitting {
    "Queueing..."
  } else {
    "Queue PDF Watch Book"
  }
}

///|
fn book_template_request_intro() -> String {
  "Use this for domain-specific books that fetch PDFs from approved websites, extract text, apply your method, and notify only when accepted knowledge changes."
}

///|
fn book_template_request_target_label() -> String {
  "Writes \{@book_templates.request_file_name()}"
}

///|
fn render_book_template_request_header(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  div(class="request-composer-head", [
    div([
      p(class="eyebrow", "New MoonBook"),
      h3("Create a PDF evidence watch"),
    ]),
    div(class="request-composer-actions-top", [
      status_chip(book_template_request_target_label(), "chip-book"),
      button(
        class="control-button request-submit",
        on_click=dispatch(SubmitBookTemplateRequest),
        book_template_request_submit_label(model.book_request_submitting),
      ),
    ]),
  ])
}

///|
fn render_book_template_request_field_grid(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  div(class="request-field-grid", [
    render_request_input_field(
      "Book title",
      "One Person Company PDF Watch",
      model.book_request_title,
      value => dispatch(SetBookRequestTitle(value)),
      wide=true,
    ),
    render_request_input_field(
      "Book id",
      "research-opc-pdf-watch",
      model.book_request_book_id,
      value => dispatch(SetBookRequestBookId(value)),
    ),
    render_request_input_field(
      "Cadence ticks",
      "60",
      model.book_request_cadence,
      value => dispatch(SetBookRequestCadence(value)),
    ),
  ])
}
