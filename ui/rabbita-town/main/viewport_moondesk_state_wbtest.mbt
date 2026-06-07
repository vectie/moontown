test "handoff artifact status tone keeps artifact-specific states" {
  assert_true(handoff_artifact_status_tone("ready") is Ready)
  assert_true(handoff_artifact_status_tone("simple-only") is Simple)
  assert_true(handoff_artifact_status_tone("reference-only") is Reference)
  assert_true(handoff_artifact_status_tone("review") is Review)
  assert_true(handoff_artifact_status_tone("failed") is Neutral)
}

///|
test "bridge record status tone keeps bridge lifecycle states" {
  assert_true(bridge_record_status_tone("ready") is Ready)
  assert_true(bridge_record_status_tone("accepted") is Ready)
  assert_true(bridge_record_status_tone("completed") is Ready)
  assert_true(bridge_record_status_tone("review") is Review)
  assert_true(bridge_record_status_tone("needs-review") is Review)
  assert_true(bridge_record_status_tone("failed") is Alert)
  assert_true(bridge_record_status_tone("simple-only") is Neutral)
}

///|
test "artifact and bridge status class adapters preserve public css policy" {
  assert_eq(artifact_status_class("ready"), "artifact-status-ready")
  assert_eq(artifact_status_class("simple-only"), "artifact-status-simple")
  assert_eq(
    artifact_status_class("reference-only"),
    "artifact-status-reference",
  )
  assert_eq(artifact_status_class("review"), "artifact-status-review")
  assert_eq(artifact_status_class("failed"), "artifact-status-neutral")
  assert_eq(bridge_record_status_class("completed"), "artifact-status-ready")
  assert_eq(bridge_record_status_class("needs-review"), "artifact-status-review")
  assert_eq(bridge_record_status_class("failed"), "artifact-status-alert")
  assert_eq(bridge_record_status_class("unknown"), "artifact-status-neutral")
}
