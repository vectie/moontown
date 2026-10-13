///|
/// Read v1 ledgers without discarding their civic briefs or review receipts.
pub fn decode_hackathon_state(json : Json) -> HackathonState raise {
  guard json is Object(source) else {
    fail("hackathon state must be an object")
  }
  let fields = source.copy()
  for
    key in [
      "programs", "team_profiles", "invitations", "submission_packages", "benchmark_runs",
      "appeals", "program_history",
    ] {
    if !fields.contains(key) {
      fields[key] = Json::array([])
    }
  }
  let state : HackathonState = @json.from_json(Json::object(fields))
  guard state.schema == empty_hackathon_state().schema && state.revision >= 0 else {
    fail("unsupported hackathon state")
  }
  state
}

///|
pub fn competition_program(
  state : HackathonState,
  challenge_id : String,
) -> CompetitionProgram? {
  state.programs.iter().find_first(p => p.challenge_id == challenge_id)
}

///|
fn program_brief(
  state : HackathonState,
  challenge_id : String,
) -> Challenge raise {
  guard state.challenges.iter().find_first(c => c.id == challenge_id)
    is Some(brief) else {
    fail("challenge was not found")
  }
  brief
}

///|
pub fn require_unfrozen_program(
  state : HackathonState,
  challenge_id : String,
) -> Unit raise {
  guard !(competition_program(state, challenge_id)
    is Some({ state: "final", .. })) else {
    fail("final competition is frozen")
  }
}

///|
fn finite_metric(value : Double) -> Bool {
  value == value && value > -1.0e300 && value < 1.0e300
}

///|
fn valid_program_timezone(timezone : String) -> Bool {
  if timezone == "UTC" {
    return true
  }
  let parts = timezone.split("/").to_array()
  parts.length() >= 2 &&
  [
    "Africa", "America", "Antarctica", "Arctic", "Asia", "Atlantic", "Australia",
    "Europe", "Indian", "Pacific", "Etc",
  ].contains(parts[0].to_string()) &&
  parts.all(part => {
    !part.is_empty() &&
    part
    .iter()
    .all(char => {
      (char >= 'a' && char <= 'z') ||
      (char >= 'A' && char <= 'Z') ||
      (char >= '0' && char <= '9') ||
      char == '_' ||
      char == '-' ||
      char == '+'
    })
  })
}

///|
fn validate_program_brief(
  brief : Challenge,
  program : CompetitionProgram,
) -> Unit raise {
  guard valid_id(brief.id) &&
    !brief.name.trim().is_empty() &&
    !brief.topic.trim().is_empty() &&
    !brief.scope.trim().is_empty() &&
    !brief.possibility_wiki.trim().is_empty() &&
    !brief.first_person_solution.trim().is_empty() &&
    !brief.benchmark_materials.is_empty() &&
    !brief.evaluation_materials.is_empty() &&
    brief.deadline_ms > 0UL &&
    brief.benchmark_version > 0 else {
    fail("challenge brief, deadline, and benchmark materials are required")
  }
  guard !program.tracks.any(t => t.scoring_mode == "rubric") ||
    !brief.rubric.is_empty() else {
    fail("rubric tracks require a review rubric")
  }
  let criteria : Map[String, Bool] = Map([])
  for criterion in brief.rubric {
    guard valid_id(criterion.id) &&
      !criteria.contains(criterion.id) &&
      !criterion.label.trim().is_empty() &&
      criterion.max_points > 0 else {
      fail("rubric criteria require unique IDs and positive points")
    }
    criteria[criterion.id] = true
  }
}

///|
fn validate_program_structure(
  program : CompetitionProgram,
  brief : Challenge,
) -> Unit raise {
  guard valid_id(program.challenge_id) && program.challenge_id == brief.id else {
    fail("program and challenge IDs must match")
  }
  guard program.max_team_size >= 1 &&
    program.max_team_size <= 100 &&
    program.daily_submission_limit >= 1 &&
    program.daily_submission_limit <= 1000 else {
    fail("team size and daily submission limit must be positive and bounded")
  }
  guard program.registration_open_ms <= program.registration_close_ms &&
    program.registration_open_ms <= program.submission_open_ms &&
    program.registration_close_ms <= brief.deadline_ms &&
    program.submission_open_ms <= brief.deadline_ms &&
    brief.deadline_ms <= program.review_close_ms &&
    program.review_close_ms <= 8640000000000000UL else {
    fail(
      "registration must open before submission and both must close before review closes",
    )
  }
  guard program.timezone.is_empty() || valid_program_timezone(program.timezone) else {
    fail("timezone must use UTC or an IANA region/location name")
  }
  let ids : Map[String, Bool] = Map([])
  for track in program.tracks {
    guard valid_id(track.id) &&
      !ids.contains(track.id) &&
      !track.name.trim().is_empty() &&
      !track.description.trim().is_empty() &&
      (track.scoring_mode == "rubric" || track.scoring_mode == "metric") else {
      fail("tracks need unique IDs, descriptions, and rubric or metric scoring")
    }
    ids[track.id] = true
    let kinds : Map[String, Bool] = Map([])
    for kind in track.required_materials {
      guard valid_id(kind) && !kinds.contains(kind) else {
        fail("required materials need unique kind IDs")
      }
      kinds[kind] = true
    }
    if track.scoring_mode == "metric" {
      guard valid_id(track.runner_key) && !track.metrics.is_empty() else {
        fail("metric tracks require a registered runner key and metrics")
      }
    } else {
      guard track.metrics.is_empty() && track.gates.is_empty() else {
        fail("rubric tracks use the challenge rubric rather than metric rules")
      }
    }
    let metrics : Map[String, Bool] = Map([])
    for metric in track.metrics {
      guard valid_id(metric.id) &&
        !metrics.contains(metric.id) &&
        !metric.label.trim().is_empty() &&
        (metric.direction == "min" || metric.direction == "max") &&
        finite_metric(metric.baseline) &&
        metric.baseline > 0.0 &&
        finite_metric(metric.weight) &&
        metric.weight > 0.0 else {
        fail(
          "metrics need unique IDs, min/max direction, positive finite baseline and weight",
        )
      }
      metrics[metric.id] = true
    }
    let gates : Map[String, Bool] = Map([])
    for gate in track.gates {
      guard valid_id(gate.id) &&
        !gates.contains(gate.id) &&
        !gate.label.trim().is_empty() &&
        metrics.contains(gate.metric_id) &&
        (gate.comparison == "gte" || gate.comparison == "lte") &&
        finite_metric(gate.threshold) else {
        fail(
          "qualification gates must reference a metric with a finite gte/lte threshold",
        )
      }
      gates[gate.id] = true
    }
  }
  let evaluators : Map[String, Bool] = Map([])
  for evaluator in program.evaluator_ids {
    guard !evaluator.trim().is_empty() && !evaluators.contains(evaluator) else {
      fail("evaluator IDs must be nonempty and unique")
    }
    evaluators[evaluator] = true
  }
  for prize in program.prizes {
    guard ids.contains(prize.track_id) &&
      !prize.place.trim().is_empty() &&
      !prize.description.trim().is_empty() else {
      fail("prizes require a track, place, and description")
    }
  }
  for partner in program.partners {
    guard !partner.name.trim().is_empty() &&
      (partner.url.has_prefix("https://") || partner.url.has_prefix("http://")) else {
      fail("partners require names and web URLs")
    }
  }
  for entry in program.faq {
    guard !entry.category.trim().is_empty() &&
      !entry.question.trim().is_empty() &&
      !entry.answer.trim().is_empty() else {
      fail("FAQ entries need category, question, and answer")
    }
  }
  guard program.contact_url.is_empty() ||
    program.contact_url.has_prefix("https://") ||
    program.contact_url.has_prefix("http://") ||
    program.contact_url.has_prefix("mailto:") else {
    fail("contact must be a web URL or email link")
  }
}

///|
/// Rabbita can show these concrete missing items before the Mayor publishes.
pub fn program_readiness(
  state : HackathonState,
  challenge_id : String,
) -> Array[String] {
  let missing : Array[String] = []
  guard competition_program(state, challenge_id) is Some(program) else {
    return ["Save a competition program"]
  }
  guard state.challenges.iter().find_first(c => c.id == challenge_id)
    is Some(brief) else {
    return ["Save the challenge brief"]
  }
  if brief.name.trim().is_empty() ||
    brief.topic.trim().is_empty() ||
    brief.scope.trim().is_empty() ||
    brief.possibility_wiki.trim().is_empty() ||
    brief.first_person_solution.trim().is_empty() {
    missing.push(
      "Complete the name, topic, scope, possibility wiki, and solution prompt",
    )
  }
  if brief.benchmark_materials.is_empty() ||
    brief.evaluation_materials.is_empty() {
    missing.push("Add benchmark and evaluation materials")
  }
  if program.tracks.any(t => t.scoring_mode == "rubric") &&
    brief.rubric.is_empty() {
    missing.push("Add the review rubric")
  }
  if program.organizer.trim().is_empty() || program.timezone.trim().is_empty() {
    missing.push("Set organizer and timezone")
  }
  if program.tracks.is_empty() {
    missing.push("Add a competition track")
  }
  if program.evaluator_ids.is_empty() {
    missing.push("Assign evaluators")
  }
  if program.registration_close_ms == 0UL ||
    brief.deadline_ms == 0UL ||
    program.review_close_ms == 0UL {
    missing.push("Set the registration, submission, and review calendar")
  }
  missing
}

///|
fn put_program(
  state : HackathonState,
  program : CompetitionProgram,
) -> HackathonState {
  let programs = state.programs.copy()
  let history = state.program_history.copy()
  for index in 0..<programs.length() {
    if programs[index].challenge_id == program.challenge_id {
      history.push(programs[index])
      programs[index] = program
      return {
        ..state,
        revision: state.revision + 1,
        programs,
        program_history: history,
      }
    }
  }
  programs.push(program)
  { ..state, revision: state.revision + 1, programs, program_history: history, }
}

///|
fn save_competition_program(
  state : HackathonState,
  request : SaveProgramRequest,
  now_ms : UInt64,
  force_benchmark_revision? : Bool = false,
) -> HackathonState raise {
  let previous = competition_program(state, request.program.challenge_id)
  require_unfrozen_program(state, request.program.challenge_id)
  guard request.program.state == "draft" ||
    (
      previous is Some({ state: existing, .. }) &&
      request.program.state == existing
    ) else {
    fail("program lifecycle changes require transition-program")
  }
  let lifecycle = match previous {
    Some(p) => p.state
    None => "draft"
  }
  let published = lifecycle != "draft"
  let program = {
    ..request.program,
    state: lifecycle,
    announcements: match previous {
      Some(p) => p.announcements
      None => []
    },
  }
  let old_brief = state.challenges
    .iter()
    .find_first(c => c.id == request.brief.id)
  guard !(previous is None && old_brief is Some({ published: true, .. })) else {
    fail(
      "published legacy challenges retain their original rules; create a competition draft with a new ID",
    )
  }
  // Registration commits contestants to the published competition contract.
  if state.teams.any(t => t.challenge_id == program.challenge_id) &&
    previous is Some(old) &&
    old_brief is Some(old_challenge) {
    guard old.tracks.to_json() == program.tracks.to_json() &&
      old.max_team_size == program.max_team_size &&
      old.daily_submission_limit == program.daily_submission_limit &&
      old_challenge.scope == request.brief.scope &&
      old.timezone == program.timezone &&
      old.registration_open_ms == program.registration_open_ms &&
      old.submission_open_ms == program.submission_open_ms else {
      fail(
        "tracks, eligibility scope, team policy, quota, timezone, and opening times are fixed after team registration",
      )
    }
    guard program.registration_close_ms >= old.registration_close_ms &&
      request.brief.deadline_ms >= old_challenge.deadline_ms &&
      program.review_close_ms >= old.review_close_ms else {
      fail("competition windows may only be extended after team registration")
    }
  }
  let active_runs = state.benchmark_runs.filter(r => {
    ["queued", "running", "review"].contains(r.state) &&
    state.submissions.any(s => {
      s.id == r.submission_id && s.challenge_id == program.challenge_id
    })
  })
  guard active_runs.all(r => program.evaluator_ids.contains(r.reviewer_id)) else {
    fail(
      "assigned evaluators must remain on the roster while their benchmark runs are pending",
    )
  }
  let benchmark_version = match old_brief {
    Some(old) =>
      if force_benchmark_revision ||
        old.benchmark_materials.to_json() !=
        request.brief.benchmark_materials.to_json() ||
        old.evaluation_materials.to_json() !=
        request.brief.evaluation_materials.to_json() ||
        old.rubric.to_json() != request.brief.rubric.to_json() {
        old.benchmark_version + 1
      } else {
        old.benchmark_version
      }
    None => 1
  }
  let brief = { ..request.brief, published, benchmark_version, }
  guard active_runs.is_empty() ||
    (old_brief is Some(old) && old.benchmark_version == benchmark_version) else {
    fail(
      "complete or reject pending benchmark runs before amending benchmark materials or scoring",
    )
  }
  let program = if published {
    let announcements = program.announcements.copy()
    let mut receipt_id = "amendment-\{state.revision + 1}"
    while announcements.any(a => a.id == receipt_id) {
      receipt_id += "-receipt"
    }
    announcements.push({
      id: receipt_id,
      title: "Competition amended",
      published_ms: now_ms,
      body: "The Mayor amended the competition brief or program. Current benchmark version: \{benchmark_version}. Earlier brief and program versions remain in the receipt history.",
    })
    { ..program, announcements, }
  } else {
    program
  }
  validate_program_structure(program, brief)
  let challenges = state.challenges.copy()
  let challenge_history = state.challenge_history.copy()
  let mut replaced = false
  for index in 0..<challenges.length() {
    if challenges[index].id == brief.id {
      challenge_history.push(challenges[index])
      challenges[index] = brief
      replaced = true
      break
    }
  }
  if !replaced {
    challenges.push(brief)
  }
  let next = put_program({ ..state, challenges, challenge_history, }, program)
  if published {
    guard program_readiness(next, brief.id).is_empty() else {
      fail("published programs must remain complete")
    }
    validate_program_brief(brief, program)
  }
  next
}

///|
/// Dispatch only program actions; other Contest Express actions return None.
pub fn apply_program_action(
  state : HackathonState,
  action : String,
  payload : Json,
  now_ms : UInt64,
) -> HackathonState? raise {
  match action {
    "save-program" =>
      Some(save_competition_program(state, @json.from_json(payload), now_ms))
    "revise-benchmark" => {
      let request : BenchmarkRevision = @json.from_json(payload)
      guard competition_program(state, request.challenge_id) is Some(program) else {
        return None
      }
      let brief = program_brief(state, request.challenge_id)
      Some(
        save_competition_program(
          state,
          {
            program,
            brief: {
              ..brief,
              benchmark_materials: request.benchmark_materials,
              evaluation_materials: request.evaluation_materials,
              rubric: request.rubric,
            },
          },
          now_ms,
          force_benchmark_revision=true,
        ),
      )
    }
    "publish-program" => {
      let request : ProgramIdentityRequest = @json.from_json(payload)
      guard competition_program(state, request.challenge_id) is Some(program) &&
        program.state == "draft" else {
        fail("only a saved draft can be published")
      }
      let brief = program_brief(state, request.challenge_id)
      guard program_readiness(state, request.challenge_id).is_empty() &&
        brief.deadline_ms > now_ms &&
        program.registration_close_ms > now_ms else {
        fail(
          "complete the preview checklist and set future competition windows",
        )
      }
      validate_program_structure(program, brief)
      validate_program_brief(brief, program)
      let challenges = state.challenges.map(c => {
        if c.id == brief.id {
          { ..c, published: true, }
        } else {
          c
        }
      })
      Some(put_program({ ..state, challenges, }, { ..program, state: "open", }))
    }
    "transition-program" => {
      let request : ProgramTransitionRequest = @json.from_json(payload)
      guard competition_program(state, request.challenge_id) is Some(program) else {
        fail("program was not found")
      }
      guard !request.reason.trim().is_empty() else {
        fail("lifecycle changes require a reason")
      }
      require_unfrozen_program(state, request.challenge_id)
      let allowed = (
          program.state == "open" &&
          (request.state == "paused" || request.state == "evaluating")
        ) ||
        (
          program.state == "paused" &&
          (request.state == "open" || request.state == "evaluating")
        ) ||
        (
          program.state == "evaluating" &&
          (request.state == "paused" || request.state == "final")
        )
      guard allowed else { fail("invalid competition lifecycle transition") }
      let brief = program_brief(state, request.challenge_id)
      if request.state == "open" {
        guard now_ms <= brief.deadline_ms else {
          fail("cannot reopen after the submission deadline")
        }
      }
      if request.state == "evaluating" {
        guard now_ms > brief.deadline_ms else {
          fail("review phase starts after submissions close")
        }
      }
      if request.state == "final" {
        guard now_ms >= program.review_close_ms &&
          competition_finalization_ready(state, request.challenge_id) else {
          fail(
            "finalization requires the review deadline, resolved appeals, and completed reviews",
          )
        }
      }
      let announcements = program.announcements.copy()
      let mut receipt_id = "lifecycle-\{state.revision + 1}"
      while announcements.any(a => a.id == receipt_id) {
        receipt_id += "-receipt"
      }
      announcements.push({
        id: receipt_id,
        title: "Competition \{request.state}",
        body: "\{program.state} → \{request.state}: \{request.reason}",
        published_ms: now_ms,
      })
      Some(
        put_program(state, { ..program, state: request.state, announcements, }),
      )
    }
    "announce" => {
      let request : AnnouncementRequest = @json.from_json(payload)
      guard competition_program(state, request.challenge_id) is Some(program) &&
        program.state != "draft" else {
        fail("announcements require a published program")
      }
      guard valid_id(request.id) &&
        !request.title.trim().is_empty() &&
        !request.body.trim().is_empty() &&
        !program.announcements.any(a => a.id == request.id) else {
        fail("announcement requires a unique ID, title, and body")
      }
      let announcements = program.announcements.copy()
      announcements.push({
        id: request.id,
        title: request.title,
        body: request.body,
        published_ms: now_ms,
      })
      Some(put_program(state, { ..program, announcements, }))
    }
    _ => None
  }
}
