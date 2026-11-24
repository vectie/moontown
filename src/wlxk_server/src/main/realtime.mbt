///|
struct Peer {
  ws : @websocket.Conn
  send_lock : @async.Mutex
  mut profile : Json
  mut pose : Json
  mut last_send : Int64
  mut last_save : Int64
}

///|
async fn Peer::send(self : Peer, value : Json) -> Unit {
  @async.with_timeout(500, () => {
    self.send_lock.acquire()
    defer self.send_lock.release()
    self.ws.send_text(value.stringify())
  }) catch {
    _ => self.ws.close()
  }
}

///|
async fn State::broadcast(self : State, except : String, value : Json) -> Unit {
  let recipients = self.peers
    .iter()
    .filter_map(pair => {
      let (key, peer) = pair
      if key == except {
        None
      } else {
        Some(peer)
      }
    })
    .to_array()
  @async.with_task_group(group => {
    for peer in recipients {
      group.spawn_bg(() => peer.send(value))
    }
  })
}

///|
async fn State::connect(
  self : State,
  request : @http.Request,
  conn : @http.ServerConnection,
) -> Unit {
  let cookie = request.headers.get("cookie").unwrap_or("")
  guard self.principal(cookie) is Some((key, _)) &&
    self.read(key) is Some(profile) else {
    reply(conn, 401, { "ok": false, "err": "Session required" })
    return
  }
  guard request.path == "/wlxk/ws?session=" + hash(key) else {
    reply(conn, 409, { "ok": false, "err": "Account changed" })
    return
  }
  guard self.peers.length() < 64 else {
    reply(conn, 503, { "ok": false, "err": "园区繁忙，请稍后再试" })
    return
  }
  let ws = @websocket.from_http_server(request, conn)
  defer ws.close()
  if self.peers.get(key) is Some(old) {
    old.send({ "t": "kick", "reason": "此存档已在另一窗口打开" })
    old.ws.close()
  }
  let peer : Peer = {
    ws,
    send_lock: @async.Mutex(),
    profile,
    pose: { "st": "menu" },
    last_send: 0L,
    last_save: 0L,
  }
  self.peers[key] = peer
  let players = self.peers
    .iter()
    .filter_map(pair => {
      let (id, p) = pair
      if id == key {
        None
      } else {
        Some(public_player(p.profile, p.pose))
      }
    })
    .to_array()
  peer.send({ "t": "init", "id": field(profile, "id"), "players": players })
  self.broadcast(key, { "t": "join", "p": public_player(profile, peer.pose) })
  @async.with_task_group(group => {
    group.spawn_bg(() => {
      while true {
        @async.sleep(10000)
        let principal = self.principal(cookie) catch { _ => None }
        guard principal is Some((same, _)) && same == key else {
          peer.send({
            "t": "kick",
            "reason": "登录已失效，请重新进入",
          })
          ws.close()
          return
        }
      }
    })
    while true {
      let msg = ws.recv() catch { _ => break }
      guard msg.kind is Text else { break }
      let input = @async.with_timeout(5000, () => read_json(msg)) catch {
        _ => break
      }
      let now = @async.now()
      match text_field(input, "t") {
        "pos" => {
          if now - peer.last_send < 65L {
            continue
          }
          peer.last_send = now
          let st = text_field(input, "st")
          guard ["menu", "heli", "para", "walk", "drive"].contains(st) else {
            continue
          }
          let pose : Map[String, Json] = { "st": Json(st) }
          if clean_pos(input) is Some(Object(fields)) {
            for k, v in fields {
              pose[k] = v
            }
            pose["y"] = if valid_number(field(input, "y"), 5000.0) {
              field(input, "y")
            } else {
              Json(0)
            }
          }
          peer.pose = Json::object(pose)
          pose["t"] = Json("pos")
          pose["id"] = field(profile, "id")
          self.broadcast(key, Json::object(pose))
        }
        "look" => {
          if now - peer.last_save < 250L {
            continue
          }
          peer.profile = merge_save(peer.profile, {
            "look": field(input, "look"),
          })
          self.broadcast(key, {
            "t": "look",
            "id": field(profile, "id"),
            "look": field(peer.profile, "look"),
          })
        }
        "save" => {
          if now - peer.last_save < 1000L {
            continue
          }
          peer.last_save = now
          guard self.principal(cookie) is Some((same, _)) && same == key else {
            break
          }
          let payload = merge_save(input, {
            "pos": peer.pose,
            "look": field(peer.profile, "look"),
          })
          peer.profile = self.save(key, payload)
          peer.send({ "t": "saved" })
        }
        _ => ()
      }
    }
    group.return_immediately(())
  }) catch {
    _ => ()
  }
  // A replacement connection must not be removed by the old connection's cleanup.
  if self.peers.get(key) is Some(current) && physical_equal(current, peer) {
    self.peers.remove(key)
    self.broadcast(key, {
      "t": "leave",
      "id": field(profile, "id"),
      "name": field(profile, "name"),
    })
  }
}
