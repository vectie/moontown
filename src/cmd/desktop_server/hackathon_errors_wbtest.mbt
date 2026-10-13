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
  assert_eq(
    hackathon_error_message(
      "Failure(src/hackathon/program.mbt:88: registration must open before submission and both must close before review closes)",
    ),
    "registration must open before submission and both must close before review closes",
  )
  assert_eq(
    hackathon_error_message(
      "Failure(src/hackathon/evaluation_operations.mbt:19: competition program was not found)",
    ),
    "competition program was not found",
  )
}
