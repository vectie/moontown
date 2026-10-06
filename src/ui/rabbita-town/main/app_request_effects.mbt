///|
fn parse_request_submit_result(text : String) -> RequestSubmitResult {
  let parsed = @json.parse(text) catch {
    _ =>
      return {
        ok: false,
        request_id: None,
        standing_goal_id: None,
        status: None,
        error: Some("Request endpoint returned invalid JSON."),
        material_watch: None,
      }
  }
  @json.from_json(parsed) catch {
    _ =>
      {
        ok: false,
        request_id: None,
        standing_goal_id: None,
        status: None,
        error: Some(
          "Request endpoint response did not match the expected contract.",
        ),
        material_watch: None,
      }
  }
}

///|
fn submit_operator_request_cmd(dispatch : Dispatch[Msg], model : Model) -> Cmd {
  @rabbita.perform(
    fn(raw) {
      dispatch(OperatorRequestSubmitted(model.request_submission_id, raw))
    },
    async fn() noraise {
      wait_request_response_json(submit_operator_request_model_json(model))
    },
  )
}

///|
fn submit_book_template_request_cmd(
  dispatch : Dispatch[Msg],
  model : Model,
) -> Cmd {
  @rabbita.perform(fn(raw) { dispatch(BookTemplateRequestSubmitted(raw)) }, async fn() noraise {
    wait_request_response_json(
      submit_book_template_request_json(
        model.book_request_title,
        model.book_request_book_id,
        model.book_request_purpose,
        model.book_request_websites,
        model.book_request_cadence,
        model.book_request_analysis_method,
      ),
    )
  })
}
