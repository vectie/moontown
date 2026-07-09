///|
priv struct LiveAutonomyOperatorView {
  template_request_count : Int
  pending_template_request_count : Int
  failed_template_request_count : Int
}

///|
fn live_autonomy_operator_view(
  model : Model,
  fallback_active_workers~ : Int,
) -> LiveAutonomyOperatorView {
  match model.live_autonomy {
    Some(spine) =>
      live_autonomy_connected_operator_view(
        spine, fallback_active_workers,
      )
    None => live_autonomy_disconnected_operator_view(fallback_active_workers)
  }
}

///|
fn live_autonomy_connected_operator_view(
  spine : LiveAutonomySnapshot,
  _fallback_active_workers : Int,
) -> LiveAutonomyOperatorView {
  {
    template_request_count: spine.book_template_request_count,
    pending_template_request_count: spine.pending_book_template_request_count,
    failed_template_request_count: spine.failed_book_template_request_count,
  }
}

///|
fn live_autonomy_disconnected_operator_view(
  fallback_active_workers : Int,
) -> LiveAutonomyOperatorView {
  ignore(fallback_active_workers)
  {
    template_request_count: 0,
    pending_template_request_count: 0,
    failed_template_request_count: 0,
  }
}

///|
fn live_autonomy_spine_tone(spine : LiveAutonomySnapshot) -> String {
  if spine.failed_book_template_request_count > 0 ||
    spine.planbook_repair_active_count > 0 {
    "alert"
  } else if spine.pending_book_template_request_count > 0 ||
    spine.planbook_open_count > 0 {
    "book"
  } else {
    match spine.status {
      "needs-recovery" => "alert"
      "working" => "live"
      "reviewing" => "alert"
      _ => "calm"
    }
  }
}
