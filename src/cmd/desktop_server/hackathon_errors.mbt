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
    "final competition is frozen", "challenge brief, deadline, and benchmark materials are required",
    "rubric tracks require a review rubric", "program and challenge IDs must match",
    "team size and daily submission limit must be positive and bounded", "competition windows must end registration and submission before review closes",
    "tracks need unique IDs, descriptions, and rubric or metric scoring", "required materials need unique kind IDs",
    "metric tracks require a registered runner key and metrics", "rubric tracks use the challenge rubric rather than metric rules",
    "metrics need unique IDs, min/max direction, positive finite baseline and weight",
    "qualification gates must reference a metric with a finite gte/lte threshold",
    "evaluator IDs must be nonempty and unique", "prizes require a track, place, and description",
    "partners require names and web URLs", "FAQ entries need category, question, and answer",
    "contact must be a web URL or email link", "program lifecycle changes require transition-program",
    "tracks and metric rules cannot change after submissions arrive", "published programs must remain complete",
    "only a saved draft can be published", "complete the preview checklist and set future competition windows",
    "program was not found", "lifecycle changes require a reason", "invalid competition lifecycle transition",
    "cannot reopen after the submission deadline", "review phase starts after submissions close",
    "finalization requires the review deadline, resolved appeals, and completed reviews",
    "announcements require a published program", "announcement requires a unique ID, title, and body",
    "competition registration is closed", "competition team profile was not found",
    "register a captain and choose a competition track; invite members after registration",
    "only the captain may invite an eligible resident to a team with room", "only the invited resident may respond to a pending invitation",
    "resident already has a team or the invited team has no room", "only the captain may remove a member before the team's first submission",
    "competition submissions are closed", "submission must use the registered team's track and roster",
    "submission materials require unique kinds, HTTP URLs, and SHA-256 hashes", "submission is missing a required material",
    "team has reached its daily submission limit", "competition review is closed",
    "reviewer is not assigned to this competition", "a team member cannot review their own submission",
    "submission package was not found", "competition track was not found", "submission uses an outdated benchmark; submit a new package",
    "benchmark result requires every configured metric", "benchmark metric is unknown, duplicated, or not finite and positive",
    "benchmark run was not found", "benchmark run ID is invalid or already exists",
    "track requires a configured metric runner", "submission already has an active benchmark run",
    "benchmark run is not queued", "only a running benchmark can accept a worker receipt",
    "benchmark version changed during execution", "worker receipt requires input/output hashes and worker identity",
    "worker receipt requires evidence", "failed benchmark requires a reason", "the assigned reviewer must decide a measured result",
    "benchmark version changed before approval", "only a failed benchmark can be retried",
    "appeals are closed", "appeal requires a unique ID and reason; an unresolved appeal already exists",
    "only a submission team member can appeal", "appeal requires a completed evaluation receipt",
    "appeal was not found", "only an open appeal can be resolved before finalization",
    "benchmark execution is already claimed or complete", "final competition receipts are frozen",
    "only a failed or outdated pending review can be retried", "recovering an interrupted queued or running worker requires an operator reason before finalization",
    "registration must open before submission and both must close before review closes",
    "timezone must use UTC or an IANA region/location name", "published legacy challenges retain their original rules; create a competition draft with a new ID",
    "tracks, eligibility scope, team policy, quota, timezone, and opening times are fixed after team registration",
    "competition windows may only be extended after team registration", "assigned evaluators must remain on the roster while their benchmark runs are pending",
    "complete or reject pending benchmark runs before amending benchmark materials or scoring",
    "use competition registration and invitations for this event", "join this competition team by accepting an invitation",
    "final competition benchmark is frozen", "use a submission package for this competition",
    "final competition reviews are frozen", "review requires a rubric package; metric tracks require measured benchmark results",
    "final competition invitations are frozen", "competition program was not found",
    "benchmark metric is unknown, duplicated, negative or nonfinite; minimizing metrics must be positive",
    "approval requires a complete reproducibility receipt",
  ]
  let mut approved = ""
  for message in messages {
    if error.contains(message) && message.length() > approved.length() {
      approved = message
    }
  }
  if approved.is_empty() {
    "Hackathon action could not be completed. Check the fields and try again."
  } else {
    approved
  }
}
