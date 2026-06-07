///|
test "social square match count centralizes current match source" {
  assert_eq(social_square_match_count(), social_matches().length())
}

///|
test "social square lead match rotates by tick" {
  let matches = social_matches()
  assert_eq(social_square_lead_match_from_inputs(0, matches).left, matches[0].left)
  assert_eq(social_square_lead_match_from_inputs(1, matches).left, matches[1].left)
  assert_eq(
    social_square_lead_match_from_inputs(matches.length(), matches).left,
    matches[0].left,
  )
}
