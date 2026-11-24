///|
let identity_cookies : Array[String] = [
  "__Host-lunanexa_enterprise_oidc", "__Host-lunanexa_enterprise_oidc_8443", "lunanexa_http_enterprise_oidc",
  "lunanexa_http_enterprise_oidc_8443",
]

///|
fn identity_header(cookie : String) -> String {
  cookie
  .split(";")
  .filter(part => {
    identity_cookies.any(name => part.trim().has_prefix(name + "="))
  })
  .map(part => part.trim().to_owned())
  .join("; ")
}

///|
fn visitor_cookie_name(origin : String) -> String {
  if origin.has_prefix("https://") {
    "__Secure-wlxk_visit"
  } else {
    "wlxk_visit"
  }
}

///|
fn visitor_token(header : String, origin : String) -> String? {
  let prefix = visitor_cookie_name(origin) + "="
  let parts = header
    .split(";")
    .filter_map(part => {
      let s = part.trim()
      if s.has_prefix(prefix) {
        Some(s[prefix.length():].to_owned())
      } else {
        None
      }
    })
    .to_array()
  match parts {
    [token] if token.length() == 64 &&
      token.all(c => c is ('0'..<='9' | 'a'..<='f')) => Some(token)
    _ => None
  }
}

///|
fn visit_cookie(origin : String, value : String) -> @http.Cookie {
  @http.Cookie(
    visitor_cookie_name(origin),
    value,
    path="/wlxk/",
    http_only=true,
    secure=origin.has_prefix("https://"),
    max_age=if value.is_empty() { 0L } else { 2592000L },
    extensions=["SameSite=Lax"],
  )
}

///|
async fn random_token() -> String {
  let source = @fs.open("/dev/urandom", mode=ReadOnly)
  defer source.close()
  @crypto.bytes_to_hex_string(source.read_exactly(32))
}

///|
async fn State::principal(self : State, cookie : String) -> (String, String)? {
  guard cookie.length() <= 16384 else { fail("Invalid session") }
  let identity = identity_header(cookie)
  if !identity.is_empty() {
    let (response, body) = @async.with_timeout(5000, () => {
      @http.get(self.identity_url, headers={ "cookie": identity })
    })
    guard response.code == 200 else { fail("Account verification unavailable") }
    match body.json() {
      { "state": "bound", "account": { "user_id": String(id), .. }, .. } if !id.is_empty() =>
        return Some(("account-" + hash(id), "account"))
      { "state": "sign-in-required", .. } => ()
      _ => fail("Account verification unavailable")
    }
  }
  if visitor_token(cookie, self.origin) is Some(token) {
    let key = "visitor-" + hash(token)
    if @fs.exists(self.path(key)) {
      return Some((key, "visitor"))
    }
  }
  None
}

///|
test "only platform identity cookies are forwarded; visitor token ambiguity rejects" {
  assert_eq(
    identity_header(
      "unrelated=private; lunanexa_http_enterprise_oidc_8443=abc; __Secure-wlxk_visit=123",
    ),
    "lunanexa_http_enterprise_oidc_8443=abc",
  )
  assert_eq(
    visitor_token("wlxk_visit=" + "a".repeat(64), "http://local"),
    Some("a".repeat(64)),
  )
  assert_eq(
    visitor_token(
      "wlxk_visit=" + "a".repeat(64) + ";wlxk_visit=" + "b".repeat(64),
      "http://local",
    ),
    None,
  )
}
