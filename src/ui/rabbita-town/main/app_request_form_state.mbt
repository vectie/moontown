///|
priv enum OperatorRequestFormField {
  OperatorRequestTitle(String)
  OperatorRequestPrompt(String)
  OperatorRequestBookId(String)
  OperatorRequestCadence(String)
  OperatorRequestQualityThreshold(String)
}

///|
priv enum BookTemplateRequestFormField {
  BookTemplateRequestTitle(String)
  BookTemplateRequestBookId(String)
  BookTemplateRequestPurpose(String)
  BookTemplateRequestWebsites(String)
  BookTemplateRequestCadence(String)
  BookTemplateRequestAnalysisMethod(String)
}

///|
fn update_operator_request_form(
  model : Model,
  field : OperatorRequestFormField,
) -> Model {
  match field {
    OperatorRequestTitle(value) => { ..model, request_title: value }
    OperatorRequestPrompt(value) => { ..model, request_prompt: value }
    OperatorRequestBookId(value) => { ..model, request_book_id: value }
    OperatorRequestCadence(value) => { ..model, request_cadence: value }
    OperatorRequestQualityThreshold(value) =>
      { ..model, request_quality_threshold: value }
  }
}

///|
fn update_book_template_request_form(
  model : Model,
  field : BookTemplateRequestFormField,
) -> Model {
  match field {
    BookTemplateRequestTitle(value) => { ..model, book_request_title: value }
    BookTemplateRequestBookId(value) => { ..model, book_request_book_id: value }
    BookTemplateRequestPurpose(value) =>
      { ..model, book_request_purpose: value }
    BookTemplateRequestWebsites(value) =>
      { ..model, book_request_websites: value }
    BookTemplateRequestCadence(value) =>
      { ..model, book_request_cadence: value }
    BookTemplateRequestAnalysisMethod(value) =>
      { ..model, book_request_analysis_method: value }
  }
}
