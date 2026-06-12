///|
test "talent avenue signal aggregations are reusable without model" {
  let signals = [
    talent_signal_fixture(activity=60, evidence_status="Verified evidence"),
    talent_signal_fixture(activity=90, evidence_status="Review queued"),
    talent_signal_fixture(activity=75, evidence_status="Verified evidence"),
  ]
  assert_eq(talent_avenue_activity_score_from_signals(signals), 75)
  assert_eq(talent_avenue_verified_card_count_from_signals(signals), 2)
  assert_eq(talent_avenue_verified_card_bonus(2), 16)
  assert_eq(talent_avenue_activity_score_from_signals([]), 0)
}

///|
fn talent_signal_fixture(
  activity~ : Int,
  evidence_status~ : String,
) -> TalentSignalSim {
  {
    name: "Signal",
    domain: "Robotics",
    project: "Demo",
    skills: "AI, hardware",
    recent_achievement: "Shipped a tour artifact",
    evidence_status,
    reception_note: "Use this signal in the route.",
    activity,
  }
}
