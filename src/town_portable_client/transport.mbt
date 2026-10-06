///|
/// Only an origin is accepted. No embedded credentials, query, fragment or
/// base path can leak or redirect the request-scoped session.
pub fn native_exchange(base_url : String) -> Exchange raise {
  let origin = if base_url.has_suffix("/") {
    base_url[:base_url.length() - 1].to_owned()
  } else {
    base_url
  }
  let prefix = if origin.has_prefix("https://") {
    8
  } else if origin.has_prefix("http://") {
    7
  } else {
    raise ClientError("invalid_base_url")
  }
  let authority = origin[prefix:]
  if authority.is_empty() ||
    authority
    .iter()
    .any(c => {
      c <= ' ' ||
      c >= '\u007f' ||
      c == '/' ||
      c == '\\' ||
      c == '@' ||
      c == '?' ||
      c == '#' ||
      c == '%'
    }) {
    raise ClientError("invalid_base_url")
  }
  (request, send_body, receive) => {
    // Content-Length is supplied on this request, never constructor defaults.
    let connection = @http.Client(origin)
    defer connection.close()
    connection.request(
      request.meth,
      request.path,
      extra_headers=request.headers,
    )
    send_body(connection)
    let response = connection.end_request()
    // There is intentionally no Location processing or redirect retry.
    receive(response, connection)
  }
}

///|
async fn PortableClient::headers(self : PortableClient) -> Map[String, String] {
  let token = (self.session_supplier)() catch {
    _ => raise ClientError("session_unavailable")
  }
  if token.is_empty() ||
    token.length() > 4096 ||
    token.iter().any(c => c <= ' ' || c >= '\u007f') {
    raise ClientError("invalid_session")
  }
  {
    "x-miniapp-session": token,
    "accept-encoding": "identity",
    "content-length": "0",
  }
}

///|
fn response_identity(response : @http.Response) -> Unit raise {
  if response.code >= 300 && response.code < 400 {
    raise ClientError("redirect_rejected")
  }
  match response.headers.get("content-encoding") {
    None | Some("identity") => ()
    _ => raise ClientError("content_encoding_rejected")
  }
  if response.headers.contains("transfer-encoding") {
    raise ClientError("transfer_encoding_rejected")
  }
}

///|
fn decimal_length(raw : String, limit : Int) -> Int raise {
  if raw.is_empty() {
    raise ClientError("invalid_content_length")
  }
  for c in raw; n = 0 {
    if c < '0' || c > '9' {
      raise ClientError("invalid_content_length")
    }
    let digit = c.to_int() - 48
    if n > (limit - digit) / 10 || digit > limit {
      raise ClientError("invalid_content_length")
    }
    continue n * 10 + digit
  } nobreak {
    n
  }
}

///|
fn response_length(response : @http.Response, limit : Int) -> Int raise {
  guard response.headers.get("content-length") is Some(length) else {
    raise ClientError("missing_content_length")
  }
  decimal_length(length, limit)
}

///|
async fn read_bounded(
  reader : &@io.Reader,
  limit : Int,
  idle_ms : Int,
) -> Bytes {
  let buffer = Buffer()
  for ;; {
    let bytes = @async.with_timeout(idle_ms, () => {
      reader.read_some(max_len=Int::min(8192, limit - buffer.length() + 1))
    })
    guard bytes is Some(bytes) else { break }
    if bytes.length() > limit - buffer.length() {
      raise ClientError("metadata_too_large")
    }
    buffer.write_bytes(bytes)
  }
  buffer.contents()
}

///|
/// Feature-local read bound, matching the private transfer index. Control
/// request bodies and explicit binding files retain their 128 KiB bounds.
let response_metadata_limit : Int = 8 * 1024 * 1024

///|
async fn read_payload(
  response : @http.Response,
  reader : &@io.Reader,
  idle_ms : Int,
) -> Json {
  response_identity(response)
  if response.code < 200 || response.code >= 300 {
    // Do not echo an arbitrary server error body (which may contain secrets).
    raise ClientError("http_status_\{response.code}")
  }
  if response.headers.get("content-type") != Some("application/json") &&
    response.headers.get("content-type") !=
    Some("application/json; charset=utf-8") {
    raise ClientError("invalid_metadata_content_type")
  }
  let expected = response_length(response, response_metadata_limit)
  let bytes = read_bounded(reader, response_metadata_limit, idle_ms)
  if bytes.length() != expected {
    raise ClientError("metadata_length_mismatch")
  }
  let parsed = @json.parse(@utf8.decode(bytes)) catch {
    _ => raise ClientError("invalid_metadata_json")
  }
  guard parsed is { "ok": true, "payload": payload, .. } else {
    raise ClientError("invalid_metadata_envelope")
  }
  payload
}

///|
async fn PortableClient::control(
  self : PortableClient,
  path : String,
  body : Json?,
) -> Json {
  let headers = self.headers()
  let bytes = match body {
    Some(body) => @utf8.encode(body.stringify())
    None => b""
  }
  if bytes.length() > 128 * 1024 {
    raise ClientError("metadata_too_large")
  }
  headers["content-length"] = bytes.length().to_string()
  headers["accept"] = "application/json"
  if body is Some(_) {
    headers["content-type"] = "application/json"
  }
  let request : @http.Request = {
    meth: if body is Some(_) {
      Post
    } else {
      Get
    },
    path,
    headers,
  }
  let result : Ref[Json?] = Ref(None)
  @async.with_timeout(self.limits.total_timeout_ms, () => {
    (self.exchange)(request, writer => writer.write(bytes), (response, reader) => {
      if result.val is Some(_) {
        raise ClientError("duplicate_response")
      }
      result.val = Some(
        read_payload(response, reader, self.limits.idle_timeout_ms),
      )
    })
  }) catch {
    ClientError(_) as error => raise error
    _ => raise ClientError("transfer_failed")
  }
  guard result.val is Some(value) else { raise ClientError("missing_response") }
  value
}
