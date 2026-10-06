///|
fn operator_request_success_model(
  model : Model,
  goal_id : String,
  request_id : String,
  status : String,
  material_watch? : MaterialWatchSnapshot? = None,
) -> Model {
  // A background save must not replace the work the user navigated to.
  let follow_saved_watch = model.request_follow_result &&
    model.energy_request_open &&
    model.request_composer == StandingWatchComposer
  if follow_saved_watch {
    replace_browser_query_param("work-request", request_id)
    replace_browser_query_param("work", "")
  }
  {
    ..model,
    spatial_request_id: if follow_saved_watch {
      request_id
    } else {
      model.spatial_request_id
    },
    spatial_selected_work_id: if follow_saved_watch {
      ""
    } else {
      model.spatial_selected_work_id
    },
    request_submitting: false,
    request_material_receipt: match material_watch {
      Some(saved) =>
        Some(
          (request_id, goal_id, model.request_book_id.trim().to_owned(), saved),
        )
      None => model.request_material_receipt
    },
    request_status: if material_watch is Some(_) {
      "Local material watch saved. Its first due check will establish the baseline; later changes enter Book review."
    } else {
      operator_request_success_status(goal_id, request_id, status)
    },
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
    book_template_requests: parse_bootstrap_book_template_requests(),
    book_template_requests_version: book_template_requests_version(),
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
