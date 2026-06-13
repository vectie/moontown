///|
async test "generic civic communication runtime facade exposes schedule status" {
  let root = "/tmp/moontown-civic-communication-facade"
  let snapshot_path = "\{root}/town.json"
  ignore(cleaned_civic_protocol_test_root(root))
  let status = render_civic_communication_schedule_status(snapshot_path~)
  assert_true(status.contains("Civic Communication Pattern Schedule Status"))
}
