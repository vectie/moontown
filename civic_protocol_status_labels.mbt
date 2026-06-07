///|
fn protocol_status_is_ready(status : String) -> Bool {
  status == "reduced" || status == "review"
}

///|
fn protocol_status_label(
  inbox_count~ : Int,
  contribution_count~ : Int,
  reduction_count~ : Int,
  outbox_count~ : Int,
  review_count~ : Int,
) -> String {
  if review_count > 0 {
    "review"
  } else if reduction_count > 0 && outbox_count > 0 {
    "reduced"
  } else if reduction_count > 0 {
    "reducing"
  } else if contribution_count > 0 {
    "aggregating"
  } else if inbox_count > 0 {
    "inbox"
  } else {
    "defined"
  }
}
