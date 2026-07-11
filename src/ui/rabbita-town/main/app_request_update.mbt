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
  ignore(goal_id)
  ignore(request_id)
  ignore(status)
  "Watch accepted. MoonTown will run it on the next check."
}

///|
fn operator_request_failure_status(error : String) -> String {
  "Could not save the watch: \{error}"
}

///|
fn book_template_request_success_status(
  request_id : String,
  status : String,
) -> String {
  ignore(request_id)
  ignore(status)
  "Book request queued. MoonTown will install it through the book workflow."
}

///|
fn book_template_request_failure_status(error : String) -> String {
  "Could not queue the book request: \{error}"
}
