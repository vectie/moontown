///|
test "hackathon errors expose only approved validation messages" {
  let failure = "Failure(src/hackathon/competition.mbt:220:5-220:63 FAILED: a team member cannot evaluate their own submission)"
  assert_eq(
    hackathon_error_message(failure),
    "a team member cannot evaluate their own submission",
  )
  assert_eq(
    hackathon_error_message("Failure(/private/path: unexpected decoder detail)"),
    "Hackathon action could not be completed. Check the fields and try again.",
  )
}
