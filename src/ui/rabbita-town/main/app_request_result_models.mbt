///|
fn operator_request_success_model(
  model : Model,
  goal_id : String,
  request_id : String,
  status : String,
) -> Model {
  {
    ..model,
    request_submitting: false,
    request_status: operator_request_success_status(goal_id, request_id, status),
    standing_goals: parse_bootstrap_standing_goals(),
    standing_goals_version: standing_goals_version(),
    operator_requests: parse_bootstrap_operator_requests(),
    operator_requests_version: operator_requests_version(),
  }
}

///|
fn operator_request_failure_model(model : Model, error : String) -> Model {
  {
    ..model,
    request_submitting: false,
    request_status: operator_request_failure_status(error),
  }
}

///|
fn book_template_request_success_model(
  model : Model,
  request_id : String,
  status : String,
) -> Model {
  {
    ..model,
    book_request_submitting: false,
    book_request_status: book_template_request_success_status(
      request_id, status,
    ),
    live_autonomy: parse_bootstrap_live_autonomy(),
    live_autonomy_version: live_autonomy_version(),
  }
}

///|
fn book_template_request_failure_model(model : Model, error : String) -> Model {
  {
    ..model,
    book_request_submitting: false,
    book_request_status: book_template_request_failure_status(error),
  }
}
