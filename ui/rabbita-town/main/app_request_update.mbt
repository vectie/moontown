///|
fn submit_operator_request_update(
  dispatch : Dispatch[Msg],
  model : Model,
) -> (Cmd, Model) {
  if operator_request_ready(model) {
    (
      submit_operator_request_cmd(dispatch, model),
      operator_request_submitting_model(model),
    )
  } else {
    model_only_update(operator_request_missing_required_fields_model(model))
  }
}

///|
fn submit_book_template_request_update(
  dispatch : Dispatch[Msg],
  model : Model,
) -> (Cmd, Model) {
  if book_template_request_ready(model) {
    (
      submit_book_template_request_cmd(dispatch, model),
      book_template_request_submitting_model(model),
    )
  } else {
    model_only_update(
      book_template_request_missing_required_fields_model(model),
    )
  }
}

///|
fn operator_request_result_update(raw : String, model : Model) -> (Cmd, Model) {
  let result = parse_request_submit_result(raw)
  if result.ok {
    let goal_id = result.standing_goal_id.unwrap_or("standing-goal")
    let request_id = result.request_id.unwrap_or("operator-request")
    let status = result.status.unwrap_or("accepted")
    model_only_update(
      operator_request_success_model(model, goal_id, request_id, status),
    )
  } else {
    let error = result.error.unwrap_or("unknown error")
    model_only_update(operator_request_failure_model(model, error))
  }
}

///|
fn book_template_request_result_update(
  raw : String,
  model : Model,
) -> (Cmd, Model) {
  let result = parse_request_submit_result(raw)
  if result.ok {
    let request_id = result.request_id.unwrap_or("book-template-request")
    let status = result.status.unwrap_or("pending")
    model_only_update(
      book_template_request_success_model(model, request_id, status),
    )
  } else {
    let error = result.error.unwrap_or("unknown error")
    model_only_update(book_template_request_failure_model(model, error))
  }
}

///|
fn operator_request_success_status(
  goal_id : String,
  request_id : String,
  status : String,
) -> String {
  "Accepted as `\{goal_id}` via `\{request_id}` (`\{status}`). The daemon will pick it up on the next standing-goal dispatch tick."
}

///|
fn operator_request_failure_status(error : String) -> String {
  "Request failed: \{error}"
}

///|
fn book_template_request_success_status(
  request_id : String,
  status : String,
) -> String {
  "Queued `\{request_id}` (`\{status}`). The daemon will install it through the book-template request job."
}

///|
fn book_template_request_failure_status(error : String) -> String {
  "Book request failed: \{error}"
}
