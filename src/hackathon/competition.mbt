///|
fn valid_id(id : String) -> Bool {
  !id.is_empty() &&
  id.length() <= 64 &&
  id
  .iter()
  .all(fn(char) {
    (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') || char == '-'
  })
}

///|
pub fn publish_challenge(
  state : HackathonState,
  challenge : Challenge,
) -> HackathonState raise {
  guard valid_id(challenge.id) &&
    !challenge.name.trim().is_empty() &&
    !challenge.topic.trim().is_empty() &&
    !challenge.scope.trim().is_empty() &&
    !challenge.possibility_wiki.trim().is_empty() &&
    !challenge.first_person_solution.trim().is_empty() &&
    !challenge.benchmark_materials.is_empty() &&
    !challenge.evaluation_materials.is_empty() &&
    challenge.deadline_ms > 0UL &&
    challenge.benchmark_version > 0 &&
    !challenge.rubric.is_empty() else {
    fail("challenge brief, deadline, benchmark, and rubric are required")
  }
  guard !state.challenges.any(c => c.id == challenge.id) else {
    fail("challenge ID already exists")
  }
  let criterion_ids : Map[String, Bool] = Map([])
  for criterion in challenge.rubric {
    guard valid_id(criterion.id) &&
      !criterion.label.trim().is_empty() &&
      criterion.max_points > 0 &&
      !criterion_ids.contains(criterion.id) else {
      fail("rubric criteria require unique IDs and positive points")
    }
    criterion_ids[criterion.id] = true
  }
  let challenges = state.challenges.copy()
  challenges.push({ ..challenge, published: true, })
  { ..state, revision: state.revision + 1, challenges, }
}

///|
pub fn register_team(
  state : HackathonState,
  team : Team,
) -> HackathonState raise {
  guard valid_id(team.id) &&
    !team.name.trim().is_empty() &&
    !team.members.is_empty() &&
    state.challenges.any(c => c.id == team.challenge_id && c.published) else {
    fail("team requires a published challenge, name, and members")
  }
  guard !state.teams.any(t => t.id == team.id) else {
    fail("team ID already exists")
  }
  let members : Map[String, Bool] = Map([])
  for member in team.members {
    guard !member.trim().is_empty() &&
      !members.contains(member) &&
      !state.teams.any(t => {
        t.challenge_id == team.challenge_id && t.members.contains(member)
      }) else {
      fail("a resident may belong to only one team in a challenge")
    }
    members[member] = true
  }
  let teams = state.teams.copy()
  teams.push(team)
  { ..state, revision: state.revision + 1, teams, }
}

///|
/// A resident opts in to an existing team. Membership is never inferred from
/// an organizer's list or another resident's request.
pub fn join_team(
  state : HackathonState,
  team_id : String,
  member_id : String,
) -> HackathonState raise {
  guard !member_id.trim().is_empty() &&
    !state.teams.any(t => {
      t.members.contains(member_id) &&
      state.teams.any(target => {
        target.id == team_id && target.challenge_id == t.challenge_id
      })
    }) else {
    fail("resident already belongs to a team in this challenge")
  }
  let teams = state.teams.copy()
  for index in 0..<teams.length() {
    if teams[index].id == team_id {
      guard state.challenges.any(c => {
        c.id == teams[index].challenge_id && c.published
      }) else {
        fail("challenge is closed")
      }
      let members = teams[index].members.copy()
      members.push(member_id)
      teams[index] = { ..teams[index], members, }
      return { ..state, revision: state.revision + 1, teams, }
    }
  }
  fail("team was not found")
}

///|
/// Changing evaluation inputs advances the benchmark version. Existing scores
/// remain as receipts, but no longer appear on the current leaderboard.
pub fn revise_benchmark(
  state : HackathonState,
  challenge_id : String,
  benchmark_materials : Array[String],
  evaluation_materials : Array[String],
  rubric : Array[RubricCriterion],
) -> HackathonState raise {
  guard !benchmark_materials.is_empty() &&
    !evaluation_materials.is_empty() &&
    !rubric.is_empty() else {
    fail("benchmark, evaluation materials, and rubric are required")
  }
  let challenges = state.challenges.copy()
  let history = state.challenge_history.copy()
  let mut found = false
  for index in 0..<challenges.length() {
    if challenges[index].id == challenge_id {
      history.push(challenges[index])
      let candidate = {
        ..challenges[index],
        benchmark_version: challenges[index].benchmark_version + 1,
        benchmark_materials,
        evaluation_materials,
        rubric,
      }
      // Reuse publication validation for rubric integrity.
      let _ = publish_challenge(empty_hackathon_state(), candidate)
      challenges[index] = candidate
      found = true
      break
    }
  }
  guard found else { fail("challenge was not found") }
  {
    ..state,
    revision: state.revision + 1,
    challenges,
    challenge_history: history,
  }
}

///|
pub fn submit_solution(
  state : HackathonState,
  submission : Submission,
) -> HackathonState raise {
  guard valid_id(submission.id) &&
    (
      submission.artifact_url.has_prefix("https://") ||
      submission.artifact_url.has_prefix("http://")
    ) &&
    !submission.first_person_solution.trim().is_empty() &&
    state.teams.any(t => {
      t.id == submission.team_id && t.challenge_id == submission.challenge_id
    }) else {
    fail("submission requires a registered team, artifact, and solution")
  }
  guard state.challenges.any(c => {
    c.id == submission.challenge_id &&
    c.published &&
    submission.submitted_ms <= c.deadline_ms
  }) else {
    fail("challenge is closed or deadline passed")
  }
  guard !state.submissions.any(s => s.id == submission.id) else {
    fail("submission ID already exists")
  }
  let next_version = 1 +
    state.submissions.fold(init=0, fn(current, s) {
      if s.team_id == submission.team_id &&
        s.challenge_id == submission.challenge_id &&
        s.version > current {
        s.version
      } else {
        current
      }
    })
  let submissions = state.submissions.copy()
  submissions.push({ ..submission, version: next_version, })
  { ..state, revision: state.revision + 1, submissions, }
}

///|
pub fn record_evaluation(
  state : HackathonState,
  evaluation : Evaluation,
) -> HackathonState raise {
  guard state.submissions
    .iter()
    .find_first(s => s.id == evaluation.submission_id)
    is Some(submission) else {
    fail("submission was not found")
  }
  guard state.challenges.iter().find_first(c => c.id == submission.challenge_id)
    is Some(challenge) else {
    fail("challenge was not found")
  }
  guard evaluation.benchmark_version == challenge.benchmark_version &&
    !evaluation.reviewer.trim().is_empty() &&
    evaluation.scores.length() == challenge.rubric.length() else {
    fail("evaluation requires the current benchmark and complete rubric")
  }
  guard !state.teams.any(t => {
    t.id == submission.team_id && t.members.contains(evaluation.reviewer)
  }) else {
    fail("a team member cannot evaluate their own submission")
  }
  let mut total = 0
  let scored : Map[String, Bool] = Map([])
  for score in evaluation.scores {
    guard challenge.rubric.iter().find_first(c => c.id == score.criterion_id)
      is Some(criterion) &&
      !scored.contains(score.criterion_id) &&
      score.points >= 0 &&
      score.points <= criterion.max_points &&
      !score.evidence.trim().is_empty() else {
      fail("evaluation score is invalid or lacks evidence")
    }
    scored[score.criterion_id] = true
    total += score.points
  }
  let evaluations = state.evaluations.copy()
  evaluations.push({ ..evaluation, total, })
  { ..state, revision: state.revision + 1, evaluations, }
}

///|
pub fn leaderboard(
  state : HackathonState,
  challenge_id : String,
) -> Array[LeaderboardEntry] {
  let entries : Array[LeaderboardEntry] = []
  let current_benchmark = match
    state.challenges.iter().find_first(c => c.id == challenge_id) {
    Some(challenge) => challenge.benchmark_version
    None => return entries
  }
  for team in state.teams {
    if team.challenge_id != challenge_id {
      continue
    }
    let mut best : Evaluation? = None
    let mut best_submission : Submission? = None
    for submission in state.submissions {
      if submission.team_id != team.id ||
        submission.challenge_id != challenge_id {
        continue
      }
      let mut latest : Evaluation? = None
      for evaluation in state.evaluations {
        if evaluation.submission_id == submission.id &&
          evaluation.benchmark_version == current_benchmark {
          latest = Some(evaluation)
        }
      }
      if latest is Some(evaluation) &&
        (
          best is None ||
          (best is Some(current) && evaluation.total > current.total)
        ) {
        best = Some(evaluation)
        best_submission = Some(submission)
      }
    }
    if best is Some(evaluation) && best_submission is Some(submission) {
      entries.push({
        rank: 0,
        team_id: team.id,
        team_name: team.name,
        submission_id: submission.id,
        total: evaluation.total,
        evaluated_ms: evaluation.evaluated_ms,
      })
    }
  }
  entries.sort_by(fn(a, b) {
    if a.total != b.total {
      b.total.compare(a.total)
    } else if a.evaluated_ms != b.evaluated_ms {
      a.evaluated_ms.compare(b.evaluated_ms)
    } else {
      a.team_id.compare(b.team_id)
    }
  })
  for index in 0..<entries.length() {
    entries[index] = { ..entries[index], rank: index + 1, }
  }
  entries
}
