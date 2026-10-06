///|
/// Saved-state projection omits prompt, native body, root/configuration
/// fields, baseline and raw receipts. Ordinary source diagnostics are kept.
pub(all) struct Status {
  id : String
  kind : String
  book_id : String
  criterion_id : String
  generation : Int
  state : String
  control_state : String
  blocked_reason : String
  blocker_help : String
  observed_at_ms : UInt64
  retry_after_ms : UInt64
  session_id : String
  command_id : String
  engineering_status : String
  output : String
} derive(ToJson)

///|
pub fn status(work : Work) -> Status {
  {
    id: work.id,
    kind: work.request.kind,
    book_id: work.request.book_id,
    criterion_id: work.request.criterion_id,
    generation: work.request.generation,
    state: owner_status(work),
    control_state: work.control.map(item => item.status).unwrap_or("none"),
    blocked_reason: public_blocker(work.blocked_reason),
    blocker_help: blocker_help(work.blocked_reason, work.reservation is Some(_)),
    observed_at_ms: work.last_attempt_at_ms,
    retry_after_ms: work.retry_after_ms,
    session_id: work.reservation.map(item => item.session_id).unwrap_or(""),
    command_id: work.reservation.map(item => item.command_id).unwrap_or(""),
    engineering_status: text(work.receipt, "engineering_status"),
    output: work.output,
  }
}

///|
/// These two transport failures contain private control/daemon record paths.
/// Preserve all ordinary owner/source diagnostics and the saved recovery data.
fn public_blocker(reason : String) -> String {
  if reason.has_prefix("control_unavailable:") {
    "control_unavailable"
  } else if reason.has_prefix("runtime_unavailable:") {
    "runtime_unavailable"
  } else {
    reason
  }
}

///|
fn blocker_help(reason : String, reserved : Bool) -> String {
  if reason == "control_unavailable" ||
    reason.has_prefix("control_unavailable:") ||
    reason.has_prefix("control_path_invalid:") {
    if reserved {
      "Restore the saved control/execution-sandbox/moonclaw.json reference in the owner's native-work/state.json (reservation.config_path), then retry. MOONTOWN_MOONCODE_CONTROL_CONFIG or MOONDESK_EXECUTION_SANDBOX_CONFIG select new work only; changing them does not rebind reserved work."
    } else {
      "Check the owner's existing control/execution-sandbox/moonclaw.json selected by MOONTOWN_MOONCODE_CONTROL_CONFIG or MOONDESK_EXECUTION_SANDBOX_CONFIG (otherwise the default Desk application-support control file), then retry."
    }
  } else if reason == "runtime_unavailable" ||
    reason.has_prefix("runtime_unavailable:") {
    "Check that MoonClaw is running for the Town owner workspace and its local daemon.json record exists, then retry."
  } else {
    ""
  }
}
