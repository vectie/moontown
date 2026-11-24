///|
async fn read_json(body : &@io.Reader) -> Json {
  let buf = FixedArray::make(16385, b'\x00')
  let mut size = 0
  while size < buf.length() {
    let n = body.read(buf, offset=size, max_len=buf.length() - size)
    if n == 0 {
      break
    }
    size += n
  }
  guard size <= 16384 else { fail("Payload too large") }
  @json.parse(@utf8.decode(Bytes::from_array(buf[:size].to_owned())))
}

///|
async fn reply(
  conn : @http.ServerConnection,
  code : Int32,
  value : Json,
  cookies~ : Array[@http.Cookie] = [],
) -> Unit {
  conn.send_response(
    code,
    if code == 200 {
      "OK"
    } else {
      "Request failed"
    },
    extra_headers={
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
    },
    cookies~,
  )
  conn.write(value.stringify())
  conn.end_response()
}

///|
async fn State::handle(
  self : State,
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
) -> Unit {
  let path = request.path.split("?").to_array()[0].to_owned()
  let cookie = request.headers.get("cookie").unwrap_or("")
  if path == "/wlxk/api/health" && request.meth == Get {
    reply(conn, 200, { "ok": true, "service": "wlxk-realtime", "protocol": 1 })
    return
  }
  if request.meth != Get || path == "/wlxk/ws" {
    guard request.headers.get("origin") == Some(self.origin) else {
      reply(conn, 403, { "ok": false, "err": "Origin rejected" })
      return
    }
  }
  if path == "/wlxk/ws" && request.meth == Get {
    self.connect(request, conn)
    return
  }
  match (request.meth, path) {
    (Get, "/wlxk/api/session") => {
      let principal = self.principal(cookie)
      if principal is Some((key, kind)) {
        if self.read(key) is Some(profile) {
          reply(conn, 200, { "ok": true, "player": profile })
          return
        }
        reply(conn, 200, { "ok": true, "player": null, "kind": kind })
      } else {
        reply(conn, 200, { "ok": true, "player": null, "kind": "visitor" })
      }
    }
    (Post, "/wlxk/api/visit") => {
      let input = @async.with_timeout(5000, () => read_json(body))
      let (player, token) = self.visit(cookie, input)
      reply(
        conn,
        200,
        { "ok": true, "player": player },
        cookies=match token {
          Some(v) => [visit_cookie(self.origin, v)]
          None => []
        },
      )
    }
    (Post, "/wlxk/api/save") => {
      guard self.principal(cookie) is Some((key, _)) else {
        reply(conn, 401, { "ok": false, "err": "Session expired" })
        return
      }
      let input = @async.with_timeout(5000, () => read_json(body))
      guard field(input, "session") == Json(hash(key)) else {
        reply(conn, 409, {
          "ok": false,
          "err": "Account changed; reload the tour",
        })
        return
      }
      let _ = self.save(key, input)
      reply(conn, 200, { "ok": true })
    }
    (Post, "/wlxk/api/leave") => {
      if self.principal(cookie) is Some((key, "visitor")) {
        if self.peers.get(key) is Some(peer) {
          peer.ws.close()
        }
      }
      reply(conn, 200, { "ok": true }, cookies=[visit_cookie(self.origin, "")])
    }
    _ => reply(conn, 404, { "ok": false, "err": "Not found" })
  }
}

///|
async fn main {
  let dir = @env.get_env_var("WLXK_STATE_DIR").unwrap_or(".wlxk-state")
  if !@fs.exists(dir) {
    @fs.mkdir(dir, recursive=true, permission=0o700)
  }
  let state : State = {
    origin: @env.get_env_var("WLXK_ORIGIN").unwrap_or("http://127.0.0.1:17888"),
    identity_url: @env.get_env_var("WLXK_IDENTITY_URL").unwrap_or(
      "http://moontown-platform:8082/moontown/account/self.json",
    ),
    dir,
    lock: @async.Mutex(),
    peers: {},
    issued_minute: 0L,
    issued_count: 0,
  }
  let server = @http.Server(
    @socket.Addr::parse(
      @env.get_env_var("WLXK_BIND").unwrap_or("127.0.0.1:17888"),
    ),
    reuse_addr=true,
  )
  println("WLXK realtime listening")
  server.run_forever(
    (request, body, conn) => {
      state.handle(request, body, conn) catch {
        _ =>
          reply(conn, 503, {
            "ok": false,
            "err": "暂时无法保存或验证账户，请重试",
          })
      }
    },
    max_connections=192,
    allow_failure=true,
  )
}
