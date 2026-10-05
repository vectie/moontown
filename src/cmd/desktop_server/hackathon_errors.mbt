///|
/// MoonBit failures include source locations. Return only approved domain
/// messages to the browser, including when decoding an invalid payload fails.
fn hackathon_error_message(error : String) -> String {
  let messages = [
    "challenge deadline must be in the future", "team registration is closed", "unsupported hackathon action",
    "challenge brief, deadline, benchmark, and rubric are required", "challenge ID already exists",
    "rubric criteria require unique IDs and positive points", "team requires a published challenge, name, and members",
    "team ID already exists", "a resident may belong to only one team in a challenge",
    "resident already belongs to a team in this challenge", "challenge is closed or deadline passed",
    "challenge is closed", "team was not found", "benchmark, evaluation materials, and rubric are required",
    "challenge was not found", "submission requires a registered team, artifact, and solution",
    "submission ID already exists", "submission was not found", "evaluation requires the current benchmark and complete rubric",
    "a team member cannot evaluate their own submission", "evaluation score is invalid or lacks evidence",
  ]
  for message in messages {
    if error.contains(message) {
      return message
    }
  }
  "Hackathon action could not be completed. Check the fields and try again."
}
