///|
fn social_square_match_count() -> Int {
  social_matches().length()
}

///|
fn social_square_lead_match(model : Model) -> SocialMatchSim {
  social_square_lead_match_from_inputs(model.tick, social_matches())
}

///|
fn social_square_lead_match_from_inputs(
  tick : Int,
  matches : Array[SocialMatchSim],
) -> SocialMatchSim {
  matches[tick % matches.length()]
}
