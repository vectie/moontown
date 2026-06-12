///|
fn operator_request_form_model_for_msg(model : Model, msg : Msg) -> Model? {
  match msg {
    SetRequestTitle(value) =>
      Some(update_operator_request_form(model, OperatorRequestTitle(value)))
    SetRequestPrompt(value) =>
      Some(update_operator_request_form(model, OperatorRequestPrompt(value)))
    SetRequestBookId(value) =>
      Some(update_operator_request_form(model, OperatorRequestBookId(value)))
    SetRequestCadence(value) =>
      Some(update_operator_request_form(model, OperatorRequestCadence(value)))
    SetRequestQualityThreshold(value) =>
      Some(
        update_operator_request_form(
          model,
          OperatorRequestQualityThreshold(value),
        ),
      )
    _ => None
  }
}

///|
fn book_template_request_form_model_for_msg(model : Model, msg : Msg) -> Model? {
  match msg {
    SetBookRequestTitle(value) =>
      Some(
        update_book_template_request_form(
          model,
          BookTemplateRequestTitle(value),
        ),
      )
    SetBookRequestBookId(value) =>
      Some(
        update_book_template_request_form(
          model,
          BookTemplateRequestBookId(value),
        ),
      )
    SetBookRequestPurpose(value) =>
      Some(
        update_book_template_request_form(
          model,
          BookTemplateRequestPurpose(value),
        ),
      )
    SetBookRequestWebsites(value) =>
      Some(
        update_book_template_request_form(
          model,
          BookTemplateRequestWebsites(value),
        ),
      )
    SetBookRequestCadence(value) =>
      Some(
        update_book_template_request_form(
          model,
          BookTemplateRequestCadence(value),
        ),
      )
    SetBookRequestAnalysisMethod(value) =>
      Some(
        update_book_template_request_form(
          model,
          BookTemplateRequestAnalysisMethod(value),
        ),
      )
    _ => None
  }
}

///|
fn form_model_for_msg(model : Model, msg : Msg) -> Model? {
  match operator_request_form_model_for_msg(model, msg) {
    Some(next) => Some(next)
    None => book_template_request_form_model_for_msg(model, msg)
  }
}
