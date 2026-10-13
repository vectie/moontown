///|
fn action_string(payload : Json, key : String) -> String {
  match payload {
    Object(fields) =>
      match fields.get(key) {
        Some(String(value)) => value
        _ => ""
      }
    _ => ""
  }
}

///|
fn action_submission(
  state : HackathonState,
  action : String,
  payload : Json,
) -> Submission? {
  let id = if action == "approve-benchmark" ||
    action == "reject-benchmark" ||
    action == "retry-benchmark" ||
    action == "execute-benchmark" ||
    action == "start-benchmark" {
    let run_id = action_string(payload, "run_id")
    match state.benchmark_runs.iter().find_first(run => run.id == run_id) {
      Some(run) => run.submission_id
      None => ""
    }
  } else {
    action_string(payload, "submission_id")
  }
  state.submissions.iter().find_first(submission => submission.id == id)
}

///|
fn actor_team_member(
  state : HackathonState,
  team_id : String,
  actor_id : String,
) -> Bool {
  state.teams.any(team => team.id == team_id && team.members.contains(actor_id))
}

///|
fn actor_can_review(
  state : HackathonState,
  submission : Submission,
  actor_id : String,
  operator : Bool,
) -> Bool {
  !actor_team_member(state, submission.team_id, actor_id) &&
  (match competition_program(state, submission.challenge_id) {
    Some(program) => program.evaluator_ids.contains(actor_id)
    None => operator
  })
}

///|
/// The hosted adapter supplies identity, and the ledger repeats authorization
/// under its exclusive lock so membership changes cannot race a write.
pub fn competition_action_authorized(
  state : HackathonState,
  action : String,
  payload : Json,
  actor_id : String,
  actor_is_operator : Bool,
) -> Bool {
  if actor_id.trim().is_empty() {
    return false
  }
  match action {
    "record-benchmark-result" => false
    "publish"
    | "save-program"
    | "publish-program"
    | "transition-program"
    | "announce"
    | "revise-benchmark"
    | "resolve-appeal"
    | "sync-workspaces"
    | "recover-interrupted-benchmark" => actor_is_operator
    "register-team" => {
      let team : Team = @json.from_json(payload) catch { _ => return false }
      team.members.length() == 1 && team.members[0] == actor_id
    }
    "register-competition-team" => {
      let request : CompetitionTeamRequest = @json.from_json(payload) catch {
        _ => return false
      }
      request.profile.captain_id == actor_id &&
      request.team.members.length() == 1 &&
      request.team.members[0] == actor_id
    }
    "join-team" => !action_string(payload, "team_id").is_empty()
    "invite-member" | "remove-member" => {
      let team_id = action_string(payload, "team_id")
      actor_team_member(state, team_id, actor_id) &&
      state.team_profiles.any(profile => {
        profile.team_id == team_id && profile.captain_id == actor_id
      })
    }
    "respond-invitation" =>
      state.invitations.any(invite => {
        invite.id == action_string(payload, "invitation_id") &&
        invite.invitee_id == actor_id
      })
    "submit" =>
      actor_team_member(state, action_string(payload, "team_id"), actor_id)
    "submit-package" => {
      let request : SubmissionPackageRequest = @json.from_json(payload) catch {
        _ => return false
      }
      actor_team_member(state, request.submission.team_id, actor_id)
    }
    "evaluate"
    | "queue-benchmark"
    | "approve-benchmark"
    | "reject-benchmark"
    | "retry-benchmark"
    | "execute-benchmark"
    | "start-benchmark" =>
      match action_submission(state, action, payload) {
        Some(submission) =>
          actor_can_review(state, submission, actor_id, actor_is_operator)
        None => false
      }
    "open-appeal" =>
      match action_submission(state, action, payload) {
        Some(submission) =>
          actor_team_member(state, submission.team_id, actor_id)
        None => false
      }
    _ => false
  }
}

///|
fn bind_competition_actor(
  action : String,
  payload : Json,
  actor_id : String,
) -> Json {
  guard payload is Object(source) else { return payload }
  let fields = source.copy()
  match action {
    "evaluate" => fields["reviewer"] = actor_id.to_json()
    "queue-benchmark" | "approve-benchmark" | "reject-benchmark" =>
      fields["reviewer_id"] = actor_id.to_json()
    "join-team" | "respond-invitation" | "open-appeal" =>
      fields["member_id"] = actor_id.to_json()
    "invite-member" => fields["inviter_id"] = actor_id.to_json()
    "remove-member" => fields["captain_id"] = actor_id.to_json()
    _ => ()
  }
  Json::object(fields)
}
