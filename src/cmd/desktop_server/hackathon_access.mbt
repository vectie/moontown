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
  let is_operator = roles.any(role => role == Json::string("PlatformOperator"))
  let is_enterprise_user = roles.any(role => {
    role == Json::string("EnterpriseUser")
  })
  guard is_operator || is_enterprise_user else { return None }
  Some({ account_id, is_operator, is_enterprise_user, })
}

///|
fn hackathon_public_path(path : String) -> Bool {
  path == "/api/contest-express/hackathons" ||
  path == "/contest-express/hackathons" ||
  path == "/hackathon.html" ||
  path == "/hackathon.js" ||
  path == "/hackathon.css"
}

///|
fn hackathon_action_allowed(
  identity : PublicIdentity,
  state : @hackathon.HackathonState,
  action : String,
  payload : Json,
) -> Bool {
  match action {
    "publish" | "revise-benchmark" | "evaluate" => identity.is_operator
    "join-team" =>
      (identity.is_operator || identity.is_enterprise_user) &&
      payload is { "team_id": String(_), .. }
    "register-team" => {
      let team : @hackathon.Team = @json.from_json(payload) catch {
        _ => return false
      }
      (identity.is_operator || identity.is_enterprise_user) &&
      team.members.length() == 1 &&
      team.members[0] == identity.account_id
    }
    "submit" => {
      let submission : @hackathon.Submission = @json.from_json(
        hackathon_actor_payload(action, payload, identity),
      ) catch {
        _ => return false
      }
      state.teams.any(team => {
        team.id == submission.team_id &&
        team.challenge_id == submission.challenge_id &&
        team.members.contains(identity.account_id)
      })
    }
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
        return Json::object(fields)
      }
      "evaluate" => {
        fields["reviewer"] = identity.account_id.to_json()
        fields["total"] = (0).to_json()
        fields["evaluated_ms"] = 0UL.to_json()
        return Json::object(fields)
      }
      "join-team" => {
        fields["member_id"] = identity.account_id.to_json()
        return Json::object(fields)
      }
      _ => ()
    }
  }
  payload
}

///|
fn hackathon_viewer(identity : PublicIdentity) -> Json {
  {
    "account_id": identity.account_id,
    "role": if identity.is_operator {
      "mayor"
    } else {
      "team"
    },
    "can_publish": identity.is_operator,
    "can_register_team": true,
    "can_join_team": true,
    "can_submit": true,
    "can_evaluate": identity.is_operator,
  }
}

///|
fn hackathon_safe_projection(
  state : @hackathon.HackathonState,
  identity : PublicIdentity,
) -> Json {
  let challenges : Array[Json] = []
  let leaderboards : Map[String, Json] = Map([])
  for challenge in state.challenges {
    leaderboards[challenge.id] = @hackathon.leaderboard(state, challenge.id).to_json()
    if !challenge.published {
      continue
    }
    challenges.push({
      "id": challenge.id,
      "name": challenge.name,
      "topic": challenge.topic,
      "scope": challenge.scope,
      "possibility_wiki": challenge.possibility_wiki,
      "first_person_solution": challenge.first_person_solution,
      "deadline_ms": challenge.deadline_ms,
      "benchmark_version": challenge.benchmark_version,
      "benchmark_materials": challenge.benchmark_materials,
      "rubric": challenge.rubric,
      "published": challenge.published,
    })
  }
  if identity.is_operator && state.to_json() is Object(fields) {
    fields["viewer"] = hackathon_viewer(identity)
    fields["leaderboards"] = Json::object(leaderboards)
    return Json::object(fields)
  }
  let teams : Array[Json] = []
  for team in state.teams {
    teams.push({
      "id": team.id,
      "challenge_id": team.challenge_id,
      "name": team.name,
      "is_member": team.members.contains(identity.account_id),
    })
  }
  let submissions : Array[@hackathon.Submission] = []
  for submission in state.submissions {
    if state.teams.any(team => {
        team.id == submission.team_id &&
        team.members.contains(identity.account_id)
      }) {
      submissions.push(submission)
    }
  }
  {
    "schema": state.schema,
    "revision": state.revision,
    "viewer": hackathon_viewer(identity),
    "challenges": challenges,
    "teams": teams,
    "submissions": submissions,
    "leaderboards": Json::object(leaderboards),
  }
}

///|
async fn public_hackathon_request(
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
) -> Unit {
  let path = request_path(request)
  let identity = public_identity(request_header(request, "cookie"))
  guard identity is Some(principal) else {
    if request.meth is Get &&
      (path == "/contest-express/hackathons" || path == "/hackathon.html") {
      send_text(
        conn,
        401,
        "Unauthorized",
        public_hackathon_login_page(),
        kind="text/html; charset=utf-8",
      )
    } else {
      send_json(conn, 401, { "error": "active hackathon login required" })
    }
    return
  }
  if path != "/api/contest-express/hackathons" {
    if !(request.meth is Get) {
      send_json(conn, 405, { "error": "GET required" })
      return
    }
    let asset = match path {
      "/contest-express/hackathons" | "/hackathon.html" => "hackathon.html"
      "/hackathon.js" => "hackathon.js"
      "/hackathon.css" => "hackathon.css"
      _ => ""
    }
    if asset.is_empty() || !serve_file(conn, static_root() + "/" + asset) {
      send_json(conn, 404, { "error": "hackathon page unavailable" })
    }
    return
  }
  if request.meth is Get {
    let state = @hackathon.load_hackathons() catch {
      _ => {
        send_json(conn, 503, { "error": "hackathon state unavailable" })
        return
      }
    }
    send_json(conn, 200, hackathon_safe_projection(state, principal))
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
  let actor_payload = hackathon_actor_payload(action, payload, principal)
  let next = @hackathon.apply_hackathon_action(
    action,
    actor_payload,
    @env.now(),
  ) catch {
    error => {
      send_json(conn, 400, { "error": hackathon_error_message("\{error}") })
      return
    }
  }
  send_json(conn, 200, hackathon_safe_projection(next, principal))
}

///|
fn public_hackathon_login_page() -> String {
  (
    #|<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>登录 Contest Express</title>
    #|<style>body{font:17px system-ui;background:#f4f6f8;color:#172330;margin:0}main{max-width:420px;margin:10vh auto;padding:24px}label{display:block;margin-top:18px}input,button{font:inherit;box-sizing:border-box;width:100%;min-height:48px;margin-top:8px;padding:10px;border:1px solid #8795a5;border-radius:8px}button{background:#173c65;color:white}#status{min-height:3em}</style>
    #|<main><h1>登录 Contest Express</h1><p>使用 LunaNexa 企业账号参与 MoonTown 挑战。</p><form id="login"><label for="username">用户名</label><input id="username" name="username" autocomplete="username" required><label for="password">密码</label><input id="password" name="password" type="password" autocomplete="current-password" required><button id="submit">登录并进入</button></form><p id="status" role="status" aria-live="polite"></p></main>
    #|<script>document.querySelector('#login').addEventListener('submit',async e=>{e.preventDefault();const b=document.querySelector('#submit'),s=document.querySelector('#status');b.disabled=true;s.textContent='正在登录…';try{const r=await fetch('/auth/hackathon-password',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({username:document.querySelector('#username').value,password:document.querySelector('#password').value})});document.querySelector('#password').value='';if(r.ok){location.replace('/contest-express/hackathons')}else{s.textContent=r.status===403?'账号已验证，但没有有效的参与权限。':r.status===401?'用户名或密码不正确，请重新输入。':'身份服务暂时不可用，请稍后重试。'}}catch{s.textContent='身份服务暂时不可用，请稍后重试。'}finally{b.disabled=false}});</script></html>
  )
}
