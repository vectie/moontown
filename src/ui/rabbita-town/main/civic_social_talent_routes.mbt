///|
fn talent_route_stops(model : Model) -> Array[TalentRouteStopSim] {
  match talent_signals(model) {
    [hardware, software, operator, ..] =>
      [
        talent_route_stop(
          order=1,
          stop_title="Arrival proof stop",
          signal_name=hardware.name,
          talking_point="示例：从硬件项目开始了解团队方向；真实成果需另行核验。",
          operator_note=hardware.reception_note,
          evidence_status=hardware.evidence_status,
          readiness=0,
        ),
        talent_route_stop(
          order=2,
          stop_title="Software contrast stop",
          signal_name=software.name,
          talking_point="示例：继续了解软件服务的潜在合作方向。",
          operator_note=software.reception_note,
          evidence_status=software.evidence_status,
          readiness=0,
        ),
        talent_route_stop(
          order=3,
          stop_title="Operator close-out",
          signal_name=operator.name,
          talking_point="示例：汇总来访者需求，尚未安排实际接待。",
          operator_note=operator.reception_note,
          evidence_status=operator.evidence_status,
          readiness=0,
        ),
      ]
    _ => []
  }
}

///|
fn talent_route_stop(
  order~ : Int32,
  stop_title~ : String,
  signal_name~ : String,
  talking_point~ : String,
  operator_note~ : String,
  evidence_status~ : String,
  readiness~ : Int32,
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
