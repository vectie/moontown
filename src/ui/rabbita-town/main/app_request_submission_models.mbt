///|
fn has_text(value : String) -> Bool {
  !value.trim().to_owned().is_empty()
}

///|
fn operator_request_ready(model : Model) -> Bool {
  !model.request_submitting &&
  has_text(model.request_title) &&
  has_text(model.request_prompt) &&
  (
    model.request_watch_mode == CadenceWatch ||
    material_watch_request_ready(model)
  )
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
    request_submission_id: model.request_submission_id + 1,
    request_follow_result: true,
    request_status: "Saving this watch. Please wait before editing or saving again. Closing this panel will not cancel the save.",
  }
}

///|
fn reopen_pending_operator_request_model(model : Model) -> Model {
  {
    ..close_town_transient_surfaces(model),
    energy_request_open: true,
    selection: Overview,
    request_composer: StandingWatchComposer,
  }
}

///|
fn operator_request_missing_required_fields_model(model : Model) -> Model {
  {
    ..model,
    request_status: if model.request_watch_mode == LocalMaterialWatch {
      "Add a title, request intent, target Book, existing Book-relative UTF-8 source paths, acceptance criteria, and next owner action before saving."
    } else {
      "Add both a title and a request before submitting."
    },
  }
}

///|
fn book_template_request_submitting_model(model : Model) -> Model {
  {
    ..model,
    book_request_submitting: true,
    book_request_status: "Queueing this PDF Evidence Watch book...",
  }
}

///|
fn book_template_request_missing_required_fields_model(model : Model) -> Model {
  {
    ..model,
    book_request_status: "Add a title and at least one website before queueing the book.",
  }
}
