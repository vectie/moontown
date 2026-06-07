///|
fn has_text(value : String) -> Bool {
  !value.trim().to_owned().is_empty()
}

///|
fn operator_request_ready(model : Model) -> Bool {
  has_text(model.request_title) && has_text(model.request_prompt)
}

///|
fn book_template_request_ready(model : Model) -> Bool {
  has_text(model.book_request_title) && has_text(model.book_request_websites)
}

///|
fn operator_request_submitting_model(model : Model) -> Model {
  {
    ..model,
    request_submitting: true,
    request_status: "Submitting request to the local Moontown standing-goal inbox...",
  }
}

///|
fn operator_request_missing_required_fields_model(model : Model) -> Model {
  {
    ..model,
    request_status: "Add both a title and a request before submitting.",
  }
}

///|
fn book_template_request_submitting_model(model : Model) -> Model {
  {
    ..model,
    book_request_submitting: true,
    book_request_status: "Queueing PDF Evidence Watch request in the book-template inbox...",
  }
}

///|
fn book_template_request_missing_required_fields_model(model : Model) -> Model {
  {
    ..model,
    book_request_status: "Add a title and at least one website before queueing the book.",
  }
}
