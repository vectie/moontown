///|
let guest_issue_window : Ref[(Int64, Int32)] = Ref((0L, 0))

///|
let creative_upload_readers : Ref[Int32] = Ref(0)

///|
fn guest_cookie_name(origin : String, scope : String) -> String {
  let suffix = @account_system.account_token_digest(scope)
  .strip_prefix("sha256:")
  .unwrap()[:16].to_owned()
  (if origin.has_prefix("https://") {
    "__Host-moontown_creator_"
  } else {
    "moontown_creator_preview_"
  }) +
  suffix
}

///|
fn guest_token(header : String, origin : String, scope : String) -> String? {
  if header.length() > 16384 {
    return None
  }
  let prefix = guest_cookie_name(origin, scope) + "="
  let matches = header
    .split(";")
    .filter_map(part => {
      let part = part.trim()
      if part.has_prefix(prefix) {
        Some(part[prefix.length():].to_owned())
      } else {
        None
      }
    })
    .to_array()
  if matches is [value] &&
    value.length() == 64 &&
    value.all(c => c is ('0'..<='9' | 'a'..<='f')) {
    Some(value)
  } else {
    None
  }
}

///|
fn guest_actor(token : String) -> String {
  "guest:" +
  @account_system.account_token_digest(token)
  .strip_prefix("sha256:")
  .unwrap()
  .to_owned()
}

///|
async fn issue_guest() -> String {
  let now = @async.now() / 60000L
  let (window, count) = guest_issue_window.val
  let count = if now == window { count } else { 0 }
  guard count < 120 else { fail("Visitor session admission limit") }
  guest_issue_window.val = (now, count + 1)
  let random = @fs.open("/dev/urandom", mode=ReadOnly)
  defer random.close()
  let bytes = random.read_exactly(32)
  // Hash only encodes OS entropy; the raw capability never enters JSON/JS.
  @account_system.account_token_digest(@base64.encode(bytes))
  .strip_prefix("sha256:")
  .unwrap()
  .to_owned()
}

///|
fn guest_cookie(
  token : String,
  origin : String,
  scope : String,
  claimed~ : Bool = false,
) -> @http.Cookie {
  @http.Cookie(
    guest_cookie_name(origin, scope),
    if claimed {
      ""
    } else {
      token
    },
    path="/",
    http_only=true,
    secure=origin.has_prefix("https://"),
    max_age=if claimed { 0L } else { 2592000L },
    extensions=["SameSite=Lax"],
  )
}

///|
async fn creative_upload_body(reader : &@io.Reader) -> String? {
  let limit = 11200000
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
