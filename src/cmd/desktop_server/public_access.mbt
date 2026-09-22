///|
fn public_service_host(host : String) -> Bool {
  env_value("MOONTOWN_PUBLIC_HOST") is Some(expected) && host == expected
}

///|
fn active_platform_operator(value : Json) -> Bool {
  value is { "state": String("Active"), "roles": Array(roles), .. } &&
  roles.any(role => role == Json::string("PlatformOperator"))
}

///|
async fn bounded_identity_text(reader : &@io.Reader, limit : Int) -> String? {
  let bytes = FixedArray::make(limit + 1, b'\x00')
  let mut length = 0
  while length <= limit {
    let count = reader.read(bytes, offset=length, max_len=limit + 1 - length)
    if count == 0 {
      return Some(@utf8.decode(bytes.unsafe_reinterpret_as_bytes()[:length]))
    }
    length += count
  }
  None
}

///|
async fn public_operator_authorized(cookie : String) -> Bool {
  guard !cookie.is_empty() &&
    cookie.length() <= 16384 &&
    env_value("MOONTOWN_IDENTITY_ENDPOINT") is Some(endpoint) &&
    env_value("MOONTOWN_IDENTITY_HOST") is Some(host) else {
    return false
  }
  let client = @http.Client(endpoint, headers={
    "Host": host,
    "Cookie": cookie,
    "Origin": "http://" + host,
    "Sec-Fetch-Site": "same-origin",
    "Sec-Fetch-Dest": "empty",
    "Accept": "application/json",
  })
  defer client.close()
  let response = client.get("/auth/session")
  guard response.code == 200 else { return false }
  guard bounded_identity_text(client, 16384) is Some(session_text) else {
    return false
  }
  let session = @json.parse(session_text)
  guard session is { "session_token": String(bearer), .. } &&
    bearer.has_prefix("lnxs_") else {
    return false
  }
  let account_response = client.get("/v1/auth/self", extra_headers={
    "Authorization": "Bearer " + bearer,
  })
  guard account_response.code == 200 else { return false }
  guard bounded_identity_text(client, 65536) is Some(account_text) else {
    return false
  }
  active_platform_operator(@json.parse(account_text))
}

///|
async fn public_password_login(
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
) -> Unit {
  if reject_unsafe_operator_write(request, conn) {
    return
  }
  guard request_header(request, "origin") ==
    "http://" + request_header(request, "host") else {
    return send_json(conn, 403, { "error": "same-origin login required" })
  }
  guard bounded_identity_text(body, 4096) is Some(input) else {
    return send_json(conn, 413, { "error": "login body too large" })
  }
  guard (@json.parse(input) catch { _ => Json::null() })
    is { "username": String(username), "password": String(password), .. } else {
    return send_json(conn, 400, { "error": "invalid login" })
  }
  guard env_value("MOONTOWN_IDENTITY_ENDPOINT") is Some(endpoint) &&
    env_value("MOONTOWN_IDENTITY_HOST") is Some(host) else {
    return send_json(conn, 503, { "error": "identity unavailable" })
  }
  let client = @http.Client(endpoint, headers={
    "Host": host,
    "Origin": "http://" + host,
    "Content-Type": "application/json",
  })
  defer client.close()
  let payload : Json = {
    "username": username,
    "password": password,
    "audience": "operator",
  }
  let response = client.post(
    "/auth/password",
    @utf8.encode(payload.stringify()),
  )
  // The upstream body contains a bearer. Never forward or log it.
  guard bounded_identity_text(client, 16384) is Some(_) else {
    return send_json(conn, 503, { "error": "invalid identity response" })
  }
  guard response.code == 200 || response.code == 201 else {
    return send_json(conn, if response.code == 401 { 401 } else { 503 }, {
      "error": "login rejected or identity unavailable",
    })
  }
  let cookie = response.cookies.map(c => c.name + "=" + c.value).join("; ")
  guard public_operator_authorized(cookie) else {
    return send_json(conn, 403, { "error": "active PlatformOperator required" })
  }
  conn.send_response(200, "OK", cookies=response.cookies, extra_headers={
    "Content-Type": "application/json",
    "Cache-Control": "no-store",
  })
  conn.write(b"{\"ok\":true}")
  conn.end_response()
}

///|
async fn public_access_gate(
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
) -> Bool {
  guard env_value("MOONTOWN_PUBLIC_HOST") is Some(_) else { return false }
  guard public_service_host(request_header(request, "host")) else {
    send_json(conn, 403, { "error": "unexpected host" })
    return true
  }
  if request.meth != Get &&
    request_header(request, "origin") !=
    "http://" + request_header(request, "host") {
    send_json(conn, 403, { "error": "same-origin request required" })
    return true
  }
  if request_path(request) == "/auth/password" {
    @async.with_timeout(15000, () => public_password_login(request, body, conn)) catch {
      _ => send_json(conn, 503, { "error": "identity unavailable" })
    }
    return true
  }
  let authorized = @async.with_timeout(5000, () => {
    public_operator_authorized(request_header(request, "cookie"))
  }) catch {
    _ => false
  }
  if authorized {
    return false
  }
  if request.meth == Get && request_path(request) == "/" {
    send_text(
      conn,
      401,
      "Unauthorized",
      public_login_page(),
      kind="text/html; charset=utf-8",
    )
  } else {
    send_json(conn, 401, { "error": "active PlatformOperator login required" })
  }
  true
}

///|
fn public_login_page() -> String {
  (
    #|<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>登录 MoonTown</title>
    #|<style>body{font:17px system-ui;background:#f4f6f8;color:#172330;margin:0}main{max-width:420px;margin:10vh auto;padding:24px}label{display:block;margin-top:18px}input,button{font:inherit;box-sizing:border-box;width:100%;min-height:48px;margin-top:8px;padding:10px;border:1px solid #8795a5;border-radius:8px}button{background:#173c65;color:white}a{color:#173c65}#status{min-height:3em}</style>
    #|<main><h1>登录 MoonTown</h1><p>使用现有 LunaNexa 管理员账号，进入共享工作空间。</p><form id="login"><label for="username">用户名</label><input id="username" name="username" autocomplete="username" required><label for="password">密码</label><input id="password" name="password" type="password" autocomplete="current-password" required><button id="submit">登录并进入</button></form><p id="status" role="status" aria-live="polite"></p><p>当前入口仅向平台管理员开放。密码由平台身份服务验证，不在 MoonTown 保存。</p></main>
    #|<script>document.querySelector('#login').addEventListener('submit',async e=>{e.preventDefault();const b=document.querySelector('#submit'),s=document.querySelector('#status');b.disabled=true;s.textContent='正在登录…';try{const r=await fetch('/auth/password',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({username:document.querySelector('#username').value,password:document.querySelector('#password').value})});document.querySelector('#password').value='';if(r.ok){location.replace('/')}else{s.textContent=r.status===403?'账号已验证，但没有有效的平台管理员权限，请联系管理员。':r.status===401?'用户名或密码不正确，请重新输入。':'身份服务暂时不可用，请稍后重试。'}}catch{s.textContent='身份服务暂时不可用，请稍后重试。'}finally{b.disabled=false}});</script></html>
  )
}
