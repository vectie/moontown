///|
async test "native cancellation requires exact terminal receipt body and owner binding" {
  let request = fixture_request()
  let work = fixture_reserved(request)
  let reservation = work.reservation.unwrap()
  let base = no_change_fixture_binding(work)
  let receipt : Json = {
    "session_id": reservation.session_id,
    "command_id": reservation.command_id,
    "status": "runtime-cancelled",
    "owner": "other-owner",
    "command": { "text": "different request" },
  }
  let observed = observe(
    work,
    no_change_fixture_claim(work, receipt),
    base,
    base,
    "fixture-instance",
    4UL,
  )
  assert_eq(observed.state, "dispatch_uncertain")
  assert_eq(observed.blocked_reason, "native_receipt_command_binding_mismatch")
}
