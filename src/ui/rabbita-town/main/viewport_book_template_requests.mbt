///|
fn render_book_template_composer(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  article(class="request-composer book-template-composer", [
    render_book_template_request_header(dispatch, model),
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
    render_advanced_details(
      "检查频率与分析规则",
      needs_attention=advanced_integer_needs_attention(
        model.book_request_cadence,
        max=2147483647,
      ),
      [
        render_request_input_field(
          "Check frequency",
          "60",
          model.book_request_cadence,
          value => dispatch(SetBookRequestCadence(value)),
        ),
        render_request_textarea_field(
          "Special analysis rules",
          "Optional. Leave blank to use the template method, or describe the exact analysis rules.",
          model.book_request_analysis_method,
          value => dispatch(SetBookRequestAnalysisMethod(value)),
          compact=true,
        ),
      ],
    ),
    render_request_status_line(model.book_request_status),
    div(class="request-submit-row", [
      button(
        class="control-button request-submit",
        disabled=model.book_request_submitting,
        on_click=dispatch(SubmitBookTemplateRequest),
        town_ui_label(
          "plus",
          book_template_request_submit_label(model.book_request_submitting),
        ),
      ),
    ]),
  ])
}

///|
fn book_template_request_submit_label(submitting : Bool) -> String {
  if submitting {
    "提交中…"
  } else {
    "创建研究"
  }
}

///|
fn book_template_request_intro() -> String {
  "Use this for domain-specific books that fetch PDFs from approved websites, extract text, apply your method, and notify only when accepted knowledge changes."
}

///|
fn book_template_request_target_label() -> String {
  "Queues a new book"
}

///|
fn render_book_template_request_header(
  _dispatch : Dispatch[Msg],
  _model : Model,
) -> @rabbita.Html {
  div(class="request-composer-head", [h3("研究什么？")])
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
  ])
}
