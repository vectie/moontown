///|
fn env_value(name : String) -> String? {
  match @env.get_env_var(name) {
    Some(value) if !value.trim().is_empty() => Some(value.trim().to_owned())
    _ => None
  }
}

///|
fn resource_root() -> String {
  env_value("LEPUSA_RESOURCE_DIR").unwrap_or(".")
}

///|
fn static_root() -> String {
  env_value("MOONTOWN_DESKTOP_STATIC_ROOT").unwrap_or(resource_root() + "/ui")
}

///|
fn state_root() -> String {
  @storage.moontown_product_state_dir()
}

///|
fn books_root() -> String {
  @storage.moontown_active_workspace_root() + "/books"
}

///|
fn operator_policy_path() -> String {
  env_value("MOONTOWN_OPERATOR_POLICY_PATH").unwrap_or(
    resource_root() + "/operator-policy.json",
  )
}

///|
let operator_nonce_rng : @random.Rand = @random.Rand::chacha8()

///|
fn operator_nonce() -> String {
  operator_nonce_rng.uint64().to_string(radix=16)
}

///|
fn iso_timestamp(timestamp_ms : UInt64) -> String {
  let seconds = (timestamp_ms / 1000UL).reinterpret_as_int64()
  let nanosecond = (timestamp_ms % 1000UL).to_int() * 1000000
  let value = @time.PlainDateTime::from_unix_second(
    seconds, nanosecond, @time.utc_offset,
  ) catch {
    _ => return "1970-01-01T00:00:00.000Z"
  }
  value.to_string() + "Z"
}

///|
fn request_path(request : @http.Request) -> String {
  let raw = request.path
  match raw.find("?") {
    Some(index) => raw[:index].to_owned()
    None => raw
  }
}

///|
fn content_type(path : String) -> String {
  if path.has_suffix(".html") {
    "text/html; charset=utf-8"
  } else if path.has_suffix(".css") {
    "text/css; charset=utf-8"
  } else if path.has_suffix(".js") || path.has_suffix(".mjs") {
    "text/javascript; charset=utf-8"
  } else if path.has_suffix(".json") || path.has_suffix(".jsonl") {
    "application/json; charset=utf-8"
  } else if path.has_suffix(".md") {
    "text/markdown; charset=utf-8"
  } else if path.has_suffix(".svg") {
    "image/svg+xml"
  } else if path.has_suffix(".png") {
    "image/png"
  } else if path.has_suffix(".jpg") || path.has_suffix(".jpeg") {
    "image/jpeg"
  } else if path.has_suffix(".webp") {
    "image/webp"
  } else if path.has_suffix(".woff2") {
    "font/woff2"
  } else {
    "application/octet-stream"
  }
}

///|
async fn send_text(
  conn : @http.ServerConnection,
  code : Int,
  reason : String,
  body : String,
  kind? : String = "text/plain; charset=utf-8",
) -> Unit {
  conn.send_response(code, reason, extra_headers={
    "Content-Type": kind,
    "Cache-Control": "no-store",
  })
  conn.write(body)
  conn.end_response()
}

///|
async fn send_json(
  conn : @http.ServerConnection,
  code : Int,
  value : Json,
) -> Unit {
  send_text(
    conn,
    code,
    if code < 400 {
      "OK"
    } else {
      "Error"
    },
    value.stringify(indent=2),
    kind="application/json; charset=utf-8",
  )
}

///|
fn request_header(request : @http.Request, name : String) -> String {
  request.headers.get(name).unwrap_or("").trim().to_owned()
}

///|
fn local_service_host(host : String) -> Bool {
  host == "127.0.0.1:17842" || host == "localhost:17842"
}

///|
async fn reject_unsafe_operator_write(
  request : @http.Request,
  conn : @http.ServerConnection,
) -> Bool {
  if !(request.meth is Post) {
    send_json(conn, 405, { "ok": false, "error": "POST required" })
    return true
  }
  let host = request_header(request, "host").to_lower()
  if !local_service_host(host) {
    send_json(conn, 403, { "ok": false, "error": "localhost request required" })
    return true
  }
  let content_type = request_header(request, "content-type").to_lower()
  if !content_type.has_prefix("application/json") {
    send_json(conn, 415, { "ok": false, "error": "application/json required" })
    return true
  }
  let origin = request_header(request, "origin").to_lower()
  if !origin.is_empty() && origin != "http://" + host {
    send_json(conn, 403, {
      "ok": false,
      "error": "same-origin request required",
    })
    return true
  }
  let content_length = request_header(request, "content-length")
  let transfer_encoding = request_header(request, "transfer-encoding")
  if !transfer_encoding.is_empty() || content_length.is_empty() {
    send_json(conn, 411, {
      "ok": false,
      "error": "bounded content-length required",
    })
    return true
  }
  let size = @string.parse_int(content_length) catch {
    _ => {
      send_json(conn, 400, { "ok": false, "error": "invalid content-length" })
      return true
    }
  }
  if size < 0 || size > 128 * 1024 {
    send_json(conn, 413, { "ok": false, "error": "request body too large" })
    return true
  }
  false
}

///|
async fn serve_file(conn : @http.ServerConnection, path : String) -> Bool {
  guard @fs.exists(path) && @fs.kind(path) is Regular else { return false }
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  conn.send_response(200, "OK", extra_headers={
    "Content-Type": content_type(path),
    "Content-Length": file.size().to_string(),
    "Cache-Control": "no-store",
  })
  conn.write_reader(file)
  conn.end_response()
  true
}

///|
fn safe_relative_path(path : String) -> Bool {
  !path.has_prefix("/") &&
  !path
  .split("/")
  .any(fn(part) {
    part.is_empty() || part == "." || part == ".." || part.contains("\\")
  })
}

///|
async fn serve_static(conn : @http.ServerConnection, path : String) -> Bool {
  let relative = if path == "/" {
    "index.html"
  } else {
    path.trim(chars="/").to_owned()
  }
  guard safe_relative_path(relative) else { return false }
  serve_file(conn, static_root() + "/" + relative)
}

///|
fn allowed_book_output(relative : String) -> Bool {
  relative == "book/Home.html" ||
  relative == "book/index.html" ||
  relative == "book/site/generated/index.html" ||
  relative == "book/synthesis/report.html" ||
  relative == "book/synthesis/overview.html" ||
  relative == "book/synthesis/evidence.html" ||
  relative == "book/reviews/pending.html" ||
  relative.has_prefix("book/site/generated/")
}

///|
async fn serve_book_output(
  conn : @http.ServerConnection,
  relative : String,
) -> Bool {
  guard safe_relative_path(relative) && !relative.contains("%") else {
    return false
  }
  guard relative.find("/") is Some(separator) else { return false }
  let book_id = relative[:separator].to_owned()
  let output = relative[separator + 1:].to_owned()
  guard book_id == safe_slug(book_id) && allowed_book_output(output) else {
    return false
  }
  let root = @fs.realpath(books_root()) catch { _ => return false }
  let book = @fs.realpath(books_root() + "/" + book_id) catch {
    _ => return false
  }
  guard book == root + "/" + book_id else { return false }
  let file = @fs.realpath(book + "/" + output) catch { _ => return false }
  guard file.has_prefix(book + "/") else { return false }
  serve_file(conn, file)
}

///|
async fn operator_requests_json() -> Json {
  let path = state_root() + "/operator-requests/requests.jsonl"
  let rows : Array[Json] = []
  let text = @support.read_text_or_empty(path)
  for line in text.split("\n") {
    let trimmed = line.trim().to_owned()
    if trimmed.is_empty() {
      continue
    }
    let value = @json.parse(trimmed) catch { _ => continue }
    rows.push(value)
  }
  rows.to_json()
}

///|
fn json_string_field(fields : Map[String, Json], key : String) -> String {
  match fields.get(key) {
    Some(String(value)) => value.trim().to_owned()
    _ => ""
  }
}

///|
async fn operator_source_policy() -> String {
  let path = operator_policy_path()
  let parsed = @json.parse(@support.read_text_or_empty(path))
  let fields = match parsed {
    Object(fields) => fields
    _ => fail("operator policy must be a JSON object: \{path}")
  }
  let source_policy = json_string_field(fields, "standing_goal_source_policy")
  if source_policy.is_empty() {
    fail("operator policy is missing standing_goal_source_policy: \{path}")
  }
  source_policy
}

///|
fn json_int_field(
  fields : Map[String, Json],
  key : String,
  fallback : Int,
  minimum : Int,
  maximum : Int,
) -> Int {
  let value = match fields.get(key) {
    Some(Number(value, ..)) => value.trunc().to_int()
    _ => fallback
  }
  value.clamp(min=minimum, max=maximum)
}

///|
fn safe_slug(value : String) -> String {
  let builder = StringBuilder::new()
  let mut last_dash = false
  for char in value.to_lower() {
    if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
      builder.write_char(char)
      last_dash = false
    } else if !last_dash {
      builder.write_char('-')
      last_dash = true
    }
  }
  let slug = builder.to_string().trim(chars="-").to_owned()
  if slug.is_empty() {
    "request"
  } else {
    slug
  }
}

///|
async fn append_operator_request(request : Json) -> Unit {
  let path = state_root() + "/operator-requests/requests.jsonl"
  @fs.write_file(
    path,
    request.stringify() + "\n",
    create_mode=OpenOrCreate,
    append=true,
  )
}

///|
async fn persist_operator_request(body : String) -> Json {
  let parsed = @json.parse(body)
  let fields = match parsed {
    Object(fields) => fields
    _ => fail("request body must be a JSON object")
  }
  let title = json_string_field(fields, "title")
  let prompt = json_string_field(fields, "prompt")
  if title.is_empty() || prompt.is_empty() {
    fail("title and prompt are required")
  }
  let target_book_id = {
    let value = json_string_field(fields, "target_book_id")
    if value.is_empty() {
      "research-opc"
    } else {
      safe_slug(value)
    }
  }
  let cadence_ticks = json_int_field(fields, "cadence_ticks", 60, 1, 2147483647)
  let quality_threshold = json_int_field(
    fields, "quality_threshold", 85, 1, 100,
  )
  let source_policy = operator_source_policy()
  let timestamp = @env.now()
  let slug = safe_slug(title)
  let nonce = operator_nonce()
  let request_id = "operator-\{timestamp}-\{nonce}-\{slug}"
  let explicit_goal_id = json_string_field(fields, "goal_id")
  let goal_id = if explicit_goal_id.is_empty() {
    "standing-goal-\{timestamp}-\{nonce}-\{slug}"
  } else {
    safe_slug(explicit_goal_id)
  }
  let request : Json = {
    "id": request_id,
    "status": "accepted",
    "created_at": iso_timestamp(timestamp),
    "title": title,
    "prompt": prompt,
    "target_book_id": target_book_id,
    "cadence_ticks": cadence_ticks,
    "source_policy": source_policy,
    "quality_threshold": quality_threshold,
    "standing_goal_id": goal_id,
  }
  let goal : Json = {
    "id": goal_id,
    "title": title,
    "prompt": prompt,
    "target_book_id": target_book_id,
    "cadence_ticks": cadence_ticks,
    "next_due_tick": 0,
    "enabled": true,
    "source_policy": source_policy,
    "quality_threshold": quality_threshold,
  }
  let goals_path = state_root() + "/standing-goals.json"
  let goals_text = @support.read_text_or_empty(goals_path)
  let goals_json = if goals_text.trim().is_empty() {
    ([] : Array[Json]).to_json()
  } else {
    @json.parse(goals_text)
  }
  let goals : Array[Json] = match goals_json {
    Array(items) => items
    _ => fail("standing-goals.json must contain a JSON array")
  }
  let mut replaced = false
  for index, existing in goals {
    guard existing is Object(existing_fields) else { continue }
    if json_string_field(existing_fields, "id") == goal_id {
      goals[index] = goal
      replaced = true
      break
    }
  }
  if !replaced {
    goals.push(goal)
  }
  let request_path = state_root() + "/operator-requests/" + request_id + ".json"
  let preparing : Json = {
    "id": request_id,
    "status": "preparing",
    "created_at": iso_timestamp(timestamp),
    "title": title,
    "prompt": prompt,
    "target_book_id": target_book_id,
    "cadence_ticks": cadence_ticks,
    "source_policy": source_policy,
    "quality_threshold": quality_threshold,
    "standing_goal_id": goal_id,
  }
  @support.write_text_file(request_path, preparing.stringify(indent=2))
  let mut goal_activated = false
  try {
    @support.write_text_file(goals_path, goals.to_json().stringify(indent=2))
    goal_activated = true
    @support.write_text_file(request_path, request.stringify(indent=2))
    append_operator_request(request)
  } catch {
    error => {
      if goal_activated {
        @support.write_text_file(
          goals_path,
          if goals_text.trim().is_empty() {
            "[]"
          } else {
            goals_text
          },
        ) catch {
          _ => ()
        }
      }
      let failed : Json = {
        "id": request_id,
        "status": "failed",
        "created_at": iso_timestamp(timestamp),
        "title": title,
        "prompt": prompt,
        "target_book_id": target_book_id,
        "cadence_ticks": cadence_ticks,
        "source_policy": source_policy,
        "quality_threshold": quality_threshold,
        "standing_goal_id": goal_id,
        "error": "Operator request persistence did not complete.",
      }
      @support.write_text_file(request_path, failed.stringify(indent=2)) catch {
        _ => ()
      }
      raise error
    }
  }
  {
    "ok": true,
    "request_id": request_id,
    "standing_goal_id": goal_id,
    "status": "accepted",
  }
}

///|
async fn handle_request(
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
) -> Unit {
  let path = request_path(request)
  if request.meth is Get && path == "/health" {
    send_json(conn, 200, { "ok": true, "service": "moontown-desktop" })
    return
  }
  if path == "/energy-valley-runtime.json" {
    if !(request.meth is Get) {
      send_json(conn, 405, { "ok": false, "error": "GET required" })
      return
    }
    send_json(conn, 200, energy_valley_runtime_projection())
    return
  }
  if path == "/api/operator-requests" {
    if reject_unsafe_operator_write(request, conn) {
      return
    }
    let result = persist_operator_request(body.read_all().text()) catch {
      error => {
        send_json(conn, 400, { "ok": false, "error": "\{error}" })
        return
      }
    }
    send_json(conn, 200, result)
    return
  }
  if request.meth is Get && path.has_prefix("/book-output/") {
    let relative = path["/book-output/".length():].to_owned()
    if serve_book_output(conn, relative) {
      return
    }
  }
  if request.meth is Get && serve_static(conn, path) {
    return
  }
  send_json(conn, 404, { "ok": false, "error": "not found" })
}

///|
async fn main {
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:17842"))
  println(
    "MoonTown desktop service listening at http://127.0.0.1:17842; suite=\{@storage.moontown_active_workspace_root()}",
  )
  server.run_forever(handle_request, max_connections=1)
}
