///|
fn talent_route_stops(model : Model) -> Array[TalentRouteStopSim] {
  match talent_signals(model) {
    [hardware, software, operator, ..] =>
      [
        talent_route_stop(
          order=1,
          stop_title="Arrival proof stop",
          signal_name=hardware.name,
          talking_point="Open with a shipping artifact so visitors see real district output before hearing abstractions.",
          operator_note=hardware.reception_note,
          evidence_status=hardware.evidence_status,
          readiness=clamp_metric(hardware.activity + 10),
        ),
        talent_route_stop(
          order=2,
          stop_title="Software contrast stop",
          signal_name=software.name,
          talking_point="Shift into rapid-service delivery to show that Wenyu talent spans more than one founder archetype.",
          operator_note=software.reception_note,
          evidence_status=software.evidence_status,
          readiness=clamp_metric(software.activity + 6),
        ),
        talent_route_stop(
          order=3,
          stop_title="Operator close-out",
          signal_name=operator.name,
          talking_point="End on the district workflow layer so the route lands on matching, planning, and next-action evidence.",
          operator_note=operator.reception_note,
          evidence_status=operator.evidence_status,
          readiness=clamp_metric(operator.activity + 4),
        ),
      ]
    _ => []
  }
}

///|
fn talent_route_stop(
  order~ : Int,
  stop_title~ : String,
  signal_name~ : String,
  talking_point~ : String,
  operator_note~ : String,
  evidence_status~ : String,
  readiness~ : Int,
) -> TalentRouteStopSim {
  {
    order,
    stop_title,
    signal_name,
    talking_point,
    operator_note,
    evidence_status,
    readiness,
  }
}
