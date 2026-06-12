///|
test "operator request form updates one field at a time" {
  let model = init_model()
  let titled = update_operator_request_form(
    model,
    OperatorRequestTitle("Watch hardware"),
  )
  assert_eq(titled.request_title, "Watch hardware")
  assert_eq(titled.request_prompt, model.request_prompt)
  let prompted = update_operator_request_form(
    model,
    OperatorRequestPrompt("Find new accepted evidence."),
  )
  assert_eq(prompted.request_prompt, "Find new accepted evidence.")
  assert_eq(prompted.request_title, model.request_title)
  let qualified = update_operator_request_form(
    model,
    OperatorRequestQualityThreshold("92"),
  )
  assert_eq(qualified.request_quality_threshold, "92")
}

///|
test "book template request form updates one field at a time" {
  let model = init_model()
  let named = update_book_template_request_form(
    model,
    BookTemplateRequestTitle("EUV PDF Watch"),
  )
  assert_eq(named.book_request_title, "EUV PDF Watch")
  assert_eq(named.book_request_websites, model.book_request_websites)
  let sourced = update_book_template_request_form(
    model,
    BookTemplateRequestWebsites("https://example.org/euv"),
  )
  assert_eq(sourced.book_request_websites, "https://example.org/euv")
  assert_eq(sourced.book_request_title, model.book_request_title)
  let method_update = update_book_template_request_form(
    model,
    BookTemplateRequestAnalysisMethod("Extract claims and compare baselines."),
  )
  assert_eq(
    method_update.book_request_analysis_method,
    "Extract claims and compare baselines.",
  )
}
