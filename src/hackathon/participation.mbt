///|
fn participation_registration_program(
  state : HackathonState,
  challenge_id : String,
  now_ms : UInt64,
) -> CompetitionProgram raise {
  guard state.programs.iter().find_first(p => p.challenge_id == challenge_id)
    is Some(program) &&
    program.state == "open" &&
    now_ms >= program.registration_open_ms &&
    now_ms <= program.registration_close_ms &&
    state.challenges.any(c => c.id == challenge_id && c.published) else {
    fail("competition registration is closed")
  }
  program
}

///|
fn participation_team(state : HackathonState, team_id : String) -> Team raise {
  guard state.teams.iter().find_first(t => t.id == team_id) is Some(team) else {
    fail("team was not found")
  }
  team
}

///|
fn participation_profile(
  state : HackathonState,
  team_id : String,
) -> TeamProfile raise {
  guard state.team_profiles.iter().find_first(p => p.team_id == team_id)
    is Some(profile) else {
    fail("competition team profile was not found")
  }
  profile
}

///|
fn register_competition_team(
  state : HackathonState,
  request : CompetitionTeamRequest,
  now_ms : UInt64,
) -> HackathonState raise {
  let team = request.team
  let profile = request.profile
  let program = participation_registration_program(
    state,
    team.challenge_id,
    now_ms,
  )
  guard profile.team_id == team.id &&
    !profile.captain_id.trim().is_empty() &&
    team.members.length() == 1 &&
    team.members[0] == profile.captain_id &&
    program.max_team_size >= 1 &&
    program.tracks.any(t => t.id == profile.track_id) else {
    fail(
      "register a captain and choose a competition track; invite members after registration",
    )
  }
  let next = register_team_unconfigured(state, team)
  let profiles = next.team_profiles.copy()
  profiles.push(profile)
  { ..next, team_profiles: profiles, }
}

///|
fn invite_competition_member(
  state : HackathonState,
  request : InvitationRequest,
  now_ms : UInt64,
) -> HackathonState raise {
  let team = participation_team(state, request.team_id)
  let profile = participation_profile(state, team.id)
  let program = participation_registration_program(
    state,
    team.challenge_id,
    now_ms,
  )
  guard valid_id(request.id) &&
    !state.invitations.any(i => i.id == request.id) &&
    request.inviter_id == profile.captain_id &&
    team.members.contains(request.inviter_id) &&
    !request.invitee_id.trim().is_empty() &&
    !state.teams.any(t => {
      t.challenge_id == team.challenge_id &&
      t.members.contains(request.invitee_id)
    }) &&
    team.members.length() < program.max_team_size &&
    !state.invitations.any(i => {
      i.team_id == team.id &&
      i.invitee_id == request.invitee_id &&
      i.state == "pending"
    }) else {
    fail("only the captain may invite an eligible resident to a team with room")
  }
  let invitations = state.invitations.copy()
  invitations.push({
    id: request.id,
    team_id: team.id,
    inviter_id: profile.captain_id,
    invitee_id: request.invitee_id,
    state: "pending",
    created_ms: now_ms,
  })
  { ..state, revision: state.revision + 1, invitations, }
}

///|
fn respond_competition_invitation(
  state : HackathonState,
  request : InvitationResponse,
  now_ms : UInt64,
) -> HackathonState raise {
  guard state.invitations.iter().find_first(i => i.id == request.invitation_id)
    is Some(invitation) &&
    invitation.state == "pending" &&
    invitation.invitee_id == request.member_id else {
    fail("only the invited resident may respond to a pending invitation")
  }
  let team = participation_team(state, invitation.team_id)
  guard !state.programs.any(p => {
    p.challenge_id == team.challenge_id && p.state == "final"
  }) else {
    fail("final competition invitations are frozen")
  }
  let invitations = state.invitations.copy()
  let teams = state.teams.copy()
  if request.accept {
    let program = participation_registration_program(
      state,
      team.challenge_id,
      now_ms,
    )
    let profile = participation_profile(state, team.id)
    guard team.members.contains(profile.captain_id) &&
      invitation.inviter_id == profile.captain_id &&
      team.members.length() < program.max_team_size &&
      !state.teams.any(t => {
        t.challenge_id == team.challenge_id &&
        t.members.contains(request.member_id)
      }) else {
      fail("resident already has a team or the invited team has no room")
    }
    for index in 0..<teams.length() {
      if teams[index].id == team.id {
        let members = teams[index].members.copy()
        members.push(request.member_id)
        teams[index] = { ..teams[index], members, }
      }
    }
  }
  for index in 0..<invitations.length() {
    if invitations[index].id == invitation.id {
      invitations[index] = {
        ..invitation,
        state: if request.accept {
          "accepted"
        } else {
          "declined"
        },
      }
    }
  }
  { ..state, revision: state.revision + 1, invitations, teams, }
}

///|
fn remove_competition_member(
  state : HackathonState,
  request : RemoveMemberRequest,
  now_ms : UInt64,
) -> HackathonState raise {
  let team = participation_team(state, request.team_id)
  let profile = participation_profile(state, team.id)
  let _ = participation_registration_program(state, team.challenge_id, now_ms)
  guard request.captain_id == profile.captain_id &&
    team.members.contains(request.captain_id) &&
    request.member_id != profile.captain_id &&
    team.members.contains(request.member_id) &&
    !state.submissions.any(s => s.team_id == team.id) else {
    fail(
      "only the captain may remove a member before the team's first submission",
    )
  }
  let teams = state.teams.copy()
  for index in 0..<teams.length() {
    if teams[index].id == team.id {
      teams[index] = {
        ..team,
        members: team.members.filter(m => m != request.member_id),
      }
    }
  }
  { ..state, revision: state.revision + 1, teams, }
}

///|
fn valid_material_url(url : String) -> Bool {
  let address = if url.has_prefix("https://") {
    url.substring(start=8).to_string()
  } else if url.has_prefix("http://") {
    url.substring(start=7).to_string()
  } else {
    return false
  }
  !address.is_empty() &&
  !address.has_prefix("/") &&
  !url.iter().any(c => c == ' ' || c == '\n' || c == '\r' || c == '\t')
}

///|
fn valid_material_hash(hash : String) -> Bool {
  hash.length() == 64 &&
  hash
  .iter()
  .all(c => {
    (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
  })
}

///|
fn submit_competition_package(
  state : HackathonState,
  request : SubmissionPackageRequest,
  now_ms : UInt64,
) -> HackathonState raise {
  let submission = { ..request.submission, submitted_ms: now_ms, }
  let bundle = request.package
  let team = participation_team(state, submission.team_id)
  let profile = participation_profile(state, team.id)
  guard state.programs
    .iter()
    .find_first(p => p.challenge_id == team.challenge_id)
    is Some(program) &&
    program.state == "open" &&
    now_ms >= program.submission_open_ms &&
    state.challenges.iter().find_first(c => c.id == team.challenge_id)
    is Some(challenge) &&
    challenge.published &&
    now_ms <= challenge.deadline_ms else {
    fail("competition submissions are closed")
  }
  guard submission.challenge_id == team.challenge_id &&
    bundle.submission_id == submission.id &&
    bundle.track_id == profile.track_id &&
    program.tracks.iter().find_first(t => t.id == profile.track_id)
    is Some(track) &&
    team.members.contains(profile.captain_id) &&
    team.members.length() <= program.max_team_size else {
    fail("submission must use the registered team's track and roster")
  }
  let kinds : Map[String, Bool] = Map([])
  for material in bundle.materials {
    guard valid_id(material.kind) &&
      !kinds.contains(material.kind) &&
      valid_material_url(material.url) &&
      valid_material_hash(material.sha256) else {
      fail(
        "submission materials require unique kinds, HTTP URLs, and SHA-256 hashes",
      )
    }
    kinds[material.kind] = true
  }
  guard track.required_materials.all(kind => kinds.contains(kind)) else {
    fail("submission is missing a required material")
  }
  let day = now_ms / 86400000UL
  let count = state.submissions
    .filter(s => {
      s.team_id == team.id &&
      s.challenge_id == team.challenge_id &&
      s.submitted_ms / 86400000UL == day
    })
    .length()
  guard count < program.daily_submission_limit else {
    fail("team has reached its daily submission limit")
  }
  let next = submit_solution_unconfigured(state, submission)
  let packages = next.submission_packages.copy()
  packages.push({ ..bundle, benchmark_version: challenge.benchmark_version, })
  { ..next, submission_packages: packages, }
}

///|
/// Apply a configured competition's membership or submission action. Unrelated
/// actions return None; accepted actions validate again against the locked ledger.
pub fn apply_participation_action(
  state : HackathonState,
  action : String,
  payload : Json,
  now_ms : UInt64,
) -> HackathonState? raise {
  match action {
    "register-competition-team" =>
      Some(register_competition_team(state, @json.from_json(payload), now_ms))
    "invite-member" =>
      Some(invite_competition_member(state, @json.from_json(payload), now_ms))
    "respond-invitation" =>
      Some(
        respond_competition_invitation(state, @json.from_json(payload), now_ms),
      )
    "remove-member" =>
      Some(remove_competition_member(state, @json.from_json(payload), now_ms))
    "submit-package" =>
      Some(submit_competition_package(state, @json.from_json(payload), now_ms))
    _ => None
  }
}
