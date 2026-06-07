///|
fn vitality_dashboard_points_flow_label(model : Model) -> String {
  "\{valley_points_issued(model)} issued / \{valley_points_redeemed(model)} redeemed"
}

///|
fn vitality_dashboard_broadcast_label(model : Model) -> String {
  if model_projection_snapshot_waiting(model) {
    "Bridge waiting"
  } else {
    "\{achievement_broadcast_count(model)} live"
  }
}
