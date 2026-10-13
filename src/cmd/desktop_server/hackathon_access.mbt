///|
struct PublicIdentity {
  account_id : String
  is_operator : Bool
  is_enterprise_user : Bool
}

///|
fn parse_public_identity(value : Json) -> PublicIdentity? {
  guard value
    is {
      "account_id": String(account_id),
      "state": String("Active"),
      "roles": Array(roles),
      ..
    } &&
    !account_id.trim().is_empty() &&
    account_id.length() <= 128 else {
    return None
  }
  let is_operator = roles.contains(Json::string("PlatformOperator"))
  let is_enterprise_user = roles.contains(Json::string("EnterpriseUser"))
  guard is_operator || is_enterprise_user else { return None }
  Some({ account_id, is_operator, is_enterprise_user, })
}

///|
fn hackathon_public_path(path : String) -> Bool {
  [
    "/api/contest-express/hackathons", "/contest-express/hackathons", "/contest-express/login",
    "/hackathon.html", "/hackathon.js", "/hackathon.css", "/competition-ui.js",
  ].contains(path)
}

///|
fn contest_fields(value : Json) -> Map[String, Json] {
  match value {
    Object(fields) => fields
    _ => Map([])
  }
}

///|
fn contest_array(value : Json, key : String) -> Array[Json] {
  match contest_fields(value).get(key) {
    Some(Array(items)) => items
    _ => []
  }
}

///|
fn contest_string(value : Json, key : String) -> String {
  match contest_fields(value).get(key) {
    Some(String(text)) => text
    _ => ""
  }
}

///|
fn contest_reviewer_challenges(
  state : @hackathon.HackathonState,
  account_id : String,
) -> Array[String] {
  contest_array(state.to_json(), "programs").filter_map(program => {
    if contest_array(program, "evaluator_ids").contains(account_id.to_json()) {
      Some(contest_string(program, "challenge_id"))
    } else {
      None
    }
  })
}

///|
fn contest_submission_challenge(
  state : @hackathon.HackathonState,
  submission_id : String,
) -> String {
  for submission in state.submissions {
    if submission.id == submission_id {
      return submission.challenge_id
    }
  }
  ""
}

///|
fn contest_review_scope(
  state : @hackathon.HackathonState,
  action : String,
  payload : Json,
) -> String {
  let submission_id = if [
      "approve-benchmark", "reject-benchmark", "retry-benchmark", "execute-benchmark",
    ].contains(action) {
    let run_id = contest_string(payload, "run_id")
    contest_array(state.to_json(), "benchmark_runs")
    .filter_map(run => {
      if contest_string(run, "id") == run_id {
        Some(contest_string(run, "submission_id"))
      } else {
        None
      }
    })
    .get(0)
    .unwrap_or("")
  } else {
    contest_string(payload, "submission_id")
  }
  contest_submission_challenge(state, submission_id)
}

///|
fn contest_owns_team(
  state : @hackathon.HackathonState,
  account_id : String,
  team_id : String,
) -> Bool {
  state.teams.any(team => {
    team.id == team_id && team.members.contains(account_id)
  })
}

///|
fn contest_captain(
  state : @hackathon.HackathonState,
  account_id : String,
  team_id : String,
) -> Bool {
  contest_array(state.to_json(), "team_profiles").any(profile => {
    contest_string(profile, "team_id") == team_id &&
    contest_string(profile, "captain_id") == account_id
  })
}

///|
fn hackathon_action_allowed(
  identity : PublicIdentity,
  state : @hackathon.HackathonState,
  action : String,
  payload : Json,
) -> Bool {
  match action {
    "publish"
    | "revise-benchmark"
    | "save-program"
    | "publish-program"
    | "transition-program"
    | "announce"
    | "resolve-appeal"
    | "sync-workspaces"
    | "recover-interrupted-benchmark" => identity.is_operator
    "record-benchmark-result" | "start-benchmark" => false
    "evaluate"
    | "queue-benchmark"
    | "approve-benchmark"
    | "reject-benchmark"
    | "retry-benchmark"
    | "execute-benchmark" =>
      identity.is_operator ||
      contest_reviewer_challenges(state, identity.account_id).contains(
        contest_review_scope(state, action, payload),
      )
    "join-team" => payload is { "team_id": String(_), .. }
    "register-team" => {
      let team : @hackathon.Team = @json.from_json(payload) catch {
        _ => return false
      }
      team.members.length() == 1 && team.members[0] == identity.account_id
    }
    "register-competition-team" =>
      payload
      is { "team": { "members": Array(members), .. }, "profile": { .. }, .. } &&
      members.length() == 1 &&
      members[0] == identity.account_id.to_json()
    "submit" | "submit-package" => {
      let submission = if action == "submit-package" {
        contest_fields(payload).get("submission").unwrap_or(Json::null())
      } else {
        payload
      }
      state.teams.any(team => {
        team.id == contest_string(submission, "team_id") &&
        team.challenge_id == contest_string(submission, "challenge_id") &&
        team.members.contains(identity.account_id)
      })
    }
    "invite-member" | "remove-member" =>
      contest_captain(
        state,
        identity.account_id,
        contest_string(payload, "team_id"),
      )
    "respond-invitation" =>
      contest_array(state.to_json(), "invitations").any(invitation => {
        contest_string(invitation, "id") ==
        contest_string(payload, "invitation_id") &&
        contest_string(invitation, "invitee_id") == identity.account_id
      })
    "open-appeal" =>
      state.submissions.any(submission => {
        submission.id == contest_string(payload, "submission_id") &&
        contest_owns_team(state, identity.account_id, submission.team_id)
      })
    _ => false
  }
}

///|
fn hackathon_actor_payload(
  action : String,
  payload : Json,
  identity : PublicIdentity,
) -> Json {
  if payload is Object(fields) {
    match action {
      "submit" => {
        fields["version"] = (0).to_json()
        fields["submitted_ms"] = 0UL.to_json()
      }
      "submit-package" => {
        let submission = contest_fields(
          fields.get("submission").unwrap_or(Json::null()),
        )
        submission["version"] = (0).to_json()
        submission["submitted_ms"] = 0UL.to_json()
        fields["submission"] = Json::object(submission)
      }
      "evaluate" => {
        fields["reviewer"] = identity.account_id.to_json()
        fields["total"] = (0).to_json()
        fields["evaluated_ms"] = 0UL.to_json()
      }
      "queue-benchmark" | "approve-benchmark" | "reject-benchmark" =>
        fields["reviewer_id"] = identity.account_id.to_json()
      "join-team" | "respond-invitation" | "open-appeal" =>
        fields["member_id"] = identity.account_id.to_json()
      "invite-member" => fields["inviter_id"] = identity.account_id.to_json()
      "remove-member" => fields["captain_id"] = identity.account_id.to_json()
      "register-competition-team" => {
        let profile = contest_fields(
          fields.get("profile").unwrap_or(Json::null()),
        )
        profile["captain_id"] = identity.account_id.to_json()
        fields["profile"] = Json::object(profile)
      }
      _ => ()
    }
    Json::object(fields)
  } else {
    payload
  }
}

///|
fn hackathon_viewer(
  identity : PublicIdentity?,
  can_review : Bool,
  local_operator? : Bool = false,
  review_challenge_ids? : Array[String] = [],
) -> Json {
  let operator = identity is Some({ is_operator: true, .. })
  let signed_in = identity is Some(_)
  {
    "account_id": match identity {
      Some(principal) => principal.account_id
      None => ""
    },
    "role": if operator {
      "mayor"
    } else if can_review {
      "evaluator"
    } else if signed_in {
      "team"
    } else {
      "anonymous"
    },
    "can_publish": operator,
    "can_register_team": signed_in,
    "can_join_team": signed_in,
    "can_submit": signed_in,
    "can_evaluate": operator || can_review,
    "can_run_benchmark": operator || can_review,
    "can_resolve_appeal": operator,
    "local_operator": local_operator,
    "review_challenge_ids": review_challenge_ids,
  }
}

///|
fn hackathon_safe_projection(
  state : @hackathon.HackathonState,
  identity : PublicIdentity,
) -> Json {
  hackathon_competition_projection(state, Some(identity))
}

///|
fn contest_review_run(run : Json) -> Json {
  let fields = contest_fields(run)
  let evidence = contest_array(run, "evidence")
  let safe_evidence = evidence.filter(item => {
    match item {
      String(reference) =>
        reference.has_prefix("https://") ||
        reference.has_prefix("http://") ||
        reference.has_prefix("ledger:") ||
        reference.has_prefix("moonbook:")
      _ => false
    }
  })
  fields["evidence"] = Json::array(safe_evidence)
  fields["has_local_evidence"] = (safe_evidence.length() != evidence.length()).to_json()
  Json::object(fields)
}

///|
fn contest_team_run_reason(run : Json) -> String {
  let reason = contest_string(run, "reason")
  if contest_string(run, "state") == "failed" ||
    reason.contains("Failure(") ||
    reason.contains("/tmp/") ||
    reason.contains("/Users/") ||
    reason.contains("src/") ||
    reason.contains(".mbt:") {
    "Benchmark did not complete. The review desk has the execution receipt."
  } else {
    reason
  }
}

///|
fn hackathon_competition_projection(
  state : @hackathon.HackathonState,
  identity : PublicIdentity?,
  local_operator? : Bool = false,
) -> Json {
  let account_id = match identity {
    Some(principal) => principal.account_id
    None => ""
  }
  let operator = identity is Some({ is_operator: true, .. })
  let review_challenges = contest_reviewer_challenges(state, account_id)
  let raw = state.to_json()
  let fields = contest_fields(raw)
  let visible_challenges : Array[String] = []
  let challenges : Array[Json] = []
  let leaderboards : Map[String, Json] = Map([])
  let boards : Map[String, Json] = Map([])
  let readiness : Map[String, Json] = Map([])
  for challenge in state.challenges {
    if !operator && !challenge.published {
      continue
    }
    visible_challenges.push(challenge.id)
    if operator {
      readiness[challenge.id] = @hackathon.program_readiness(
        state,
        challenge.id,
      ).to_json()
    }
    leaderboards[challenge.id] = @hackathon.leaderboard(state, challenge.id).to_json()
    let brief = contest_fields(challenge.to_json())
    if !operator && !review_challenges.contains(challenge.id) {
      brief.remove("evaluation_materials") |> ignore
    }
    challenges.push(Json::object(brief))
    for program in contest_array(raw, "programs") {
      if contest_string(program, "challenge_id") == challenge.id {
        for track in contest_array(program, "tracks") {
          let track_id = contest_string(track, "id")
          boards[challenge.id + ":" + track_id] = @hackathon.competition_leaderboard(
            state,
            challenge.id,
            track_id,
          ).to_json()
        }
      }
    }
  }
  let visible_review_challenges = review_challenges.filter(id => {
    visible_challenges.contains(id)
  })
  fields["viewer"] = hackathon_viewer(
    identity,
    !visible_review_challenges.is_empty(),
    local_operator~,
    review_challenge_ids=visible_review_challenges,
  )
  fields["leaderboards"] = Json::object(leaderboards)
  fields["competition_boards"] = Json::object(boards)
  if operator {
    fields["program_readiness"] = Json::object(readiness)
    fields["benchmark_runs"] = Json::array(
      contest_array(raw, "benchmark_runs").map(contest_review_run),
    )
    return Json::object(fields)
  }
  let own_teams = state.teams.filter_map(team => {
    if !account_id.is_empty() && team.members.contains(account_id) {
      Some(team.id)
    } else {
      None
    }
  })
  let readable_submissions = state.submissions.filter_map(submission => {
    if own_teams.contains(submission.team_id) ||
      review_challenges.contains(submission.challenge_id) {
      Some(submission.id)
    } else {
      None
    }
  })
  fields["challenges"] = Json::array(challenges)
  fields["challenge_history"] = Json::array([])
  fields["program_history"] = Json::array([])
  fields["programs"] = Json::array(
    contest_array(raw, "programs").filter_map(program => {
      if !visible_challenges.contains(contest_string(program, "challenge_id")) {
        return None
      }
      let program_fields = contest_fields(program)
      program_fields.remove("evaluator_ids") |> ignore
      Some(Json::object(program_fields))
    }),
  )
  fields["teams"] = Json::array(
    state.teams.filter_map(team => {
      if !visible_challenges.contains(team.challenge_id) {
        return None
      }
      let member = own_teams.contains(team.id)
      let team_fields = contest_fields(team.to_json())
      if !member {
        team_fields.remove("members") |> ignore
      }
      team_fields["is_member"] = member.to_json()
      Some(Json::object(team_fields))
    }),
  )
  fields["team_profiles"] = Json::array(
    contest_array(raw, "team_profiles").filter(profile => {
      own_teams.contains(contest_string(profile, "team_id"))
    }),
  )
  fields["invitations"] = Json::array(
    contest_array(raw, "invitations").filter(invitation => {
      !account_id.is_empty() &&
      (
        own_teams.contains(contest_string(invitation, "team_id")) ||
        contest_string(invitation, "invitee_id") == account_id
      )
    }),
  )
  fields["submissions"] = Json::array(
    state.submissions
    .filter(submission => readable_submissions.contains(submission.id))
    .map(submission => submission.to_json()),
  )
  for key in ["submission_packages", "appeals"] {
    fields[key] = Json::array(
      contest_array(raw, key).filter(record => {
        readable_submissions.contains(contest_string(record, "submission_id"))
      }),
    )
  }
  fields["evaluations"] = Json::array(
    contest_array(raw, "evaluations").filter_map(evaluation => {
      let submission_id = contest_string(evaluation, "submission_id")
      if !readable_submissions.contains(submission_id) {
        return None
      }
      let evaluation_fields = contest_fields(evaluation)
      if !review_challenges.contains(
          contest_submission_challenge(state, submission_id),
        ) {
        evaluation_fields.remove("reviewer") |> ignore
      }
      Some(Json::object(evaluation_fields))
    }),
  )
  fields["benchmark_runs"] = Json::array(
    contest_array(raw, "benchmark_runs").filter_map(run => {
      let submission_id = contest_string(run, "submission_id")
      if !readable_submissions.contains(submission_id) {
        return None
      }
      if review_challenges.contains(
          contest_submission_challenge(state, submission_id),
        ) {
        return Some(contest_review_run(run))
      }
      let run_fields = contest_fields(run)
      run_fields["reason"] = contest_team_run_reason(run).to_json()
      for
        key in [
          "reviewer_id", "worker_run_id", "input_hash", "output_hash", "evidence",
        ] {
        run_fields.remove(key) |> ignore
      }
      Some(Json::object(run_fields))
    }),
  )
  Json::object(fields)
}

///|
fn local_hackathon_projection(state : @hackathon.HackathonState) -> Json {
  hackathon_competition_projection(
    state,
    Some({
      account_id: "local-mayor",
      is_operator: true,
      is_enterprise_user: true,
    }),
    local_operator=true,
  )
}

///|
fn contest_workspace_sync_status(status : Json, revision : Int) -> Json {
  if status is { "synced_revision": Number(synced_revision, ..), .. } &&
    synced_revision == revision.to_double() {
    return status
  }
  let fields = contest_fields(status).copy()
  fields["ready"] = false.to_json()
  fields["message"] = "Private MoonBook receipts need reconciliation for the current competition revision".to_json()
  Json::object(fields)
}

///|
async fn hackathon_response(
  state : @hackathon.HackathonState,
  identity : PublicIdentity?,
  local_operator? : Bool = false,
) -> Json {
  let fields = contest_fields(
    hackathon_competition_projection(state, identity, local_operator~),
  )
  if identity is Some({ is_operator: true, .. }) {
    fields["workspace_sync"] = contest_workspace_sync_status(
      @hackathon.competition_workspace_sync_status(),
      state.revision,
    )
  }
  Json::object(fields)
}

///|
async fn local_hackathon_response(state : @hackathon.HackathonState) -> Json {
  hackathon_response(
    state,
    Some({
      account_id: "local-mayor",
      is_operator: true,
      is_enterprise_user: true,
    }),
    local_operator=true,
  )
}

///|
async fn public_hackathon_request(
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
) -> Unit {
  let path = request_path(request)
  if path != "/api/contest-express/hackathons" {
    if !(request.meth is Get) {
      send_json(conn, 405, { "error": "GET required" })
      return
    }
    if path == "/contest-express/login" {
      send_text(
        conn,
        200,
        "OK",
        public_hackathon_login_page(),
        kind="text/html; charset=utf-8",
      )
      return
    }
    let asset = match path {
      "/contest-express/hackathons" | "/hackathon.html" => "hackathon.html"
      "/hackathon.js" => "hackathon.js"
      "/hackathon.css" => "hackathon.css"
      "/competition-ui.js" => "competition-ui.js"
      _ => ""
    }
    if asset.is_empty() || !serve_file(conn, static_root() + "/" + asset) {
      send_json(conn, 404, { "error": "hackathon page unavailable" })
    }
    return
  }
  let identity = @async.with_timeout(5000, () => {
    public_identity(request_header(request, "cookie"))
  }) catch {
    _ => None
  }
  if request.meth is Get {
    let state = @hackathon.load_hackathons() catch {
      _ => {
        send_json(conn, 503, { "error": "hackathon state unavailable" })
        return
      }
    }
    send_json(conn, 200, hackathon_response(state, identity))
    return
  }
  guard identity is Some(principal) else {
    send_json(conn, 401, { "error": "active hackathon login required" })
    return
  }
  if reject_unsafe_operator_write(request, conn) {
    return
  }
  guard bounded_identity_text(body, 131072) is Some(input_text) else {
    send_json(conn, 413, { "error": "hackathon request too large" })
    return
  }
  let input = @json.parse(input_text) catch {
    _ => {
      send_json(conn, 400, { "error": "invalid JSON" })
      return
    }
  }
  guard input is { "action": String(action), "payload": payload, .. } else {
    send_json(conn, 400, { "error": "action and payload required" })
    return
  }
  let current = @hackathon.load_hackathons() catch {
    _ => {
      send_json(conn, 503, { "error": "hackathon state unavailable" })
      return
    }
  }
  guard hackathon_action_allowed(principal, current, action, payload) else {
    send_json(conn, 403, { "error": "hackathon action denied" })
    return
  }
  let next = @hackathon.apply_hackathon_action(
    action,
    hackathon_actor_payload(action, payload, principal),
    @env.now(),
    actor_id=Some(principal.account_id),
    actor_is_operator=principal.is_operator,
  ) catch {
    error => {
      send_json(conn, 400, { "error": hackathon_error_message("\{error}") })
      return
    }
  }
  send_json(conn, 200, hackathon_response(next, Some(principal)))
}

///|
fn public_hackathon_login_page() -> String {
  (
    #|<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>登录 Contest Express</title>
    #|<style>body{font:17px system-ui;background:#f4f6f8;color:#172330;margin:0}main{max-width:420px;margin:10vh auto;padding:24px}label{display:block;margin-top:18px}input,button{font:inherit;box-sizing:border-box;width:100%;min-height:48px;margin-top:8px;padding:10px;border:1px solid #8795a5;border-radius:8px}button{background:#173c65;color:white}#status{min-height:3em}</style>
    #|<main><h1>登录 Contest Express</h1><p>使用 LunaNexa 企业账号参与 MoonTown 挑战。</p><form id="login"><label for="username">用户名</label><input id="username" name="username" autocomplete="username" required><label for="password">密码</label><input id="password" name="password" type="password" autocomplete="current-password" required><button id="submit">登录并进入</button></form><p id="status" role="status" aria-live="polite"></p><a href="/contest-express/hackathons">浏览公开竞赛</a></main>
    #|<script>document.querySelector('#login').addEventListener('submit',async e=>{e.preventDefault();const b=document.querySelector('#submit'),s=document.querySelector('#status');b.disabled=true;s.textContent='正在登录…';try{const r=await fetch('/auth/hackathon-password',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({username:document.querySelector('#username').value,password:document.querySelector('#password').value})});document.querySelector('#password').value='';if(r.ok){location.replace('/contest-express/hackathons')}else{s.textContent=r.status===403?'账号已验证，但没有有效的参与权限。':r.status===401?'用户名或密码不正确，请重新输入。':'身份服务暂时不可用，请稍后重试。'}}catch{s.textContent='身份服务暂时不可用，请稍后重试。'}finally{b.disabled=false}});</script></html>
  )
}
