///|
test "artifact status tone class centralizes css classes" {
  assert_eq(artifact_status_tone_class(Ready), "artifact-status-ready")
  assert_eq(artifact_status_tone_class(Live), "artifact-status-live")
  assert_eq(artifact_status_tone_class(Simple), "artifact-status-simple")
  assert_eq(artifact_status_tone_class(Reference), "artifact-status-reference")
  assert_eq(artifact_status_tone_class(Review), "artifact-status-review")
  assert_eq(artifact_status_tone_class(Alert), "artifact-status-alert")
  assert_eq(artifact_status_tone_class(Neutral), "artifact-status-neutral")
}
