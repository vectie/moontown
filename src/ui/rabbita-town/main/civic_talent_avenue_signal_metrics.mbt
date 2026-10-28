///|
fn talent_avenue_verified_card_bonus(verified_cards : Int32) -> Int32 {
  verified_cards * 8
}

///|
fn talent_avenue_activity_score(model : Model) -> Int32 {
  talent_avenue_activity_score_from_signals(talent_signals(model))
}

///|
fn talent_avenue_activity_score_from_signals(
  signals : Array[TalentSignalSim],
) -> Int32 {
  if signals.is_empty() {
    return 0
  }
  let mut total = 0
  for signal in signals {
    total += signal.activity
  }
  total / signals.length()
}

///|
fn talent_avenue_verified_card_count(model : Model) -> Int32 {
  talent_avenue_verified_card_count_from_signals(talent_signals(model))
}

///|
fn talent_avenue_verified_card_count_from_signals(
  signals : Array[TalentSignalSim],
) -> Int32 {
  let mut count = 0
  for signal in signals {
    if signal.evidence_status == "Verified evidence" {
      count += 1
    }
  }
  count
}
