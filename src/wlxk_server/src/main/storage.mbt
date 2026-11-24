///|
struct State {
  origin : String
  identity_url : String
  dir : String
  lock : @async.Mutex
  peers : Map[String, Peer]
  mut issued_minute : Int64
  mut issued_count : Int32
}

///|
fn State::path(self : State, key : String) -> String {
  self.dir + "/" + key + ".json"
}

///|
async fn State::read(self : State, key : String) -> Json? {
  if !@fs.exists(self.path(key)) {
    return None
  }
  Some(@json.parse(@fs.read_file(self.path(key)).text()))
}

///|
async fn State::write(self : State, key : String, data : Json) -> Unit {
  // Caller holds the state mutex: atomic replacement prevents partial saves.
  let path = self.path(key)
  @fs.write_file(path + ".tmp", data.stringify(), permission=0o600)
  @fs.rename(path + ".tmp", path, replace=true)
}

///|
async fn State::save(self : State, key : String, data : Json) -> Json {
  self.lock.acquire()
  defer self.lock.release()
  guard self.read(key) is Some(previous) else { fail("Session missing") }
  let current = merge_save(previous, data)
  self.write(key, current)
  current
}

///|
async fn State::visit(
  self : State,
  cookie : String,
  input : Json,
) -> (Json, String?) {
  let principal = self.principal(cookie)
  let name = text_field(input, "name").trim().to_owned()
  guard valid_name(name) else {
    fail("昵称限 1–10 个中英文、数字或下划线")
  }
  self.lock.acquire()
  defer self.lock.release()
  let (key, kind, token) = match principal {
    Some((key, kind)) => (key, kind, None)
    None => {
      let minute = @async.now() / 60000L
      if self.issued_minute != minute {
        self.issued_minute = minute
        self.issued_count = 0
      }
      guard self.issued_count < 120 else { fail("请稍后重试") }
      self.issued_count += 1
      let token = random_token()
      ("visitor-" + hash(token), "visitor", Some(token))
    }
  }
  if self.read(key) is Some(profile) {
    return (profile, token)
  }
  let profile : Json = {
    "id": hash(key),
    "kind": kind,
    "name": name,
    "look": clean_look(field(input, "look")),
    "visited": [],
    "metGuide": false,
    "pos": null,
  }
  self.write(key, profile)
  (profile, token)
}
