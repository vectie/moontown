///|
pub fn default_hackathon_path() -> String {
  @storage.moontown_product_state_dir() + "/contest-express/hackathons.json"
}

///|
async fn hackathon_lock(path : String) -> @fs.File {
  let lock_path = path + ".lock"
  @support.ensure_parent_directory(lock_path)
  let file = @fs.open(
    lock_path,
    mode=ReadWrite,
    create_mode=OpenOrCreate,
    permission=0o600,
  )
  file.lock(Exclusive)
  file
}

///|
async fn load_hackathon_unlocked(path : String) -> HackathonState {
  if !@fs.exists(path) {
    return empty_hackathon_state()
  }
  guard @fs.kind(path, follow_symlink=false) is Regular else {
    fail("hackathon state is not a regular file")
  }
  let state : HackathonState = @json.from_json(
    @json.parse(@fs.read_file(path).text()),
  )
  guard state.schema == empty_hackathon_state().schema && state.revision >= 0 else {
    fail("unsupported hackathon state")
  }
  state
}

///|
pub async fn load_hackathons(
  path? : String = default_hackathon_path(),
) -> HackathonState {
  let lock = hackathon_lock(path)
  defer lock.close()
  defer lock.unlock()
  load_hackathon_unlocked(path)
}

///|
async fn save_hackathon_unlocked(path : String, state : HackathonState) -> Unit {
  let temporary = path + ".next"
  @fs.write_file(
    temporary,
    state.to_json().stringify(indent=2) + "\n",
    create_mode=CreateOrTruncate,
    permission=0o600,
    sync=Full,
  )
  @fs.rename(temporary, path, replace=true)
}

///|
pub async fn apply_hackathon_action(
  action : String,
  payload : Json,
  now_ms : UInt64,
  path? : String = default_hackathon_path(),
) -> HackathonState {
  let lock = hackathon_lock(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_hackathon_unlocked(path)
  let payload = server_owned_hackathon_fields(action, payload, now_ms)
  let next = match action {
    "publish" => {
      let challenge : Challenge = @json.from_json(payload)
      guard challenge.deadline_ms > now_ms else {
        fail("challenge deadline must be in the future")
      }
      publish_challenge(state, challenge)
    }
    "register-team" => {
      let team : Team = @json.from_json(payload)
      guard state.challenges.any(c => {
        c.id == team.challenge_id && now_ms <= c.deadline_ms
      }) else {
        fail("team registration is closed")
      }
      register_team(state, team)
    }
    "join-team" => {
      let request : JoinTeamRequest = @json.from_json(payload)
      guard state.teams.any(t => {
        t.id == request.team_id &&
        state.challenges.any(c => {
          c.id == t.challenge_id && now_ms <= c.deadline_ms
        })
      }) else {
        fail("team registration is closed")
      }
      join_team(state, request.team_id, request.member_id)
    }
    "submit" => {
      let submission : Submission = @json.from_json(payload)
      submit_solution(state, { ..submission, submitted_ms: now_ms, })
    }
    "evaluate" => {
      let evaluation : Evaluation = @json.from_json(payload)
      record_evaluation(state, { ..evaluation, evaluated_ms: now_ms, })
    }
    "revise-benchmark" => {
      let revision : BenchmarkRevision = @json.from_json(payload)
      revise_benchmark(
        state,
        revision.challenge_id,
        revision.benchmark_materials,
        revision.evaluation_materials,
        revision.rubric,
      )
    }
    _ => fail("unsupported hackathon action")
  }
  save_hackathon_unlocked(path, next)
  next
}

///|
fn server_owned_hackathon_fields(
  action : String,
  payload : Json,
  now_ms : UInt64,
) -> Json {
  guard payload is Object(fields) else { return payload }
  match action {
    "submit" => {
      fields["version"] = ToJson::to_json(0)
      fields["submitted_ms"] = now_ms.to_json()
    }
    "evaluate" => {
      fields["total"] = ToJson::to_json(0)
      fields["evaluated_ms"] = now_ms.to_json()
    }
    _ => ()
  }
  Json::object(fields)
}

///|
struct BenchmarkRevision {
  challenge_id : String
  benchmark_materials : Array[String]
  evaluation_materials : Array[String]
  rubric : Array[RubricCriterion]
} derive(FromJson)

///|
struct JoinTeamRequest {
  team_id : String
  member_id : String
} derive(FromJson)
