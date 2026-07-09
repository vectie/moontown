///|
test "request status tone kind classifies failed accepted ready and neutral text" {
  assert_true(request_status_tone_kind("Submission failed") is RequestAlert)
  assert_true(
    request_status_tone_kind("failed to write request") is RequestAlert,
  )
  assert_true(
    request_status_tone_kind("Accepted standing watch") is RequestCalm,
  )
  assert_true(request_status_tone_kind("Ready to submit") is RequestCalm)
  assert_true(request_status_tone_kind("Waiting for input") is RequestNeutral)
}

///|
test "request status tone adapter preserves css tone strings" {
  assert_eq(request_status_tone_from_kind(RequestAlert), "alert")
  assert_eq(request_status_tone_from_kind(RequestCalm), "calm")
  assert_eq(request_status_tone_from_kind(RequestNeutral), "neutral")
  assert_eq(request_status_tone("Submission failed"), "alert")
  assert_eq(request_status_tone("Accepted standing watch"), "calm")
  assert_eq(request_status_tone("Waiting for input"), "neutral")
}

///|
test "watcher small text helpers keep display fallbacks" {
  assert_eq(one_line("first line\nsecond line"), "first line")
}
