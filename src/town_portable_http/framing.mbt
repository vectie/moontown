///|
fn path_only(raw : String) -> String {
  match raw.find("?") {
    Some(i) => raw[:i].to_owned()
    None => raw
  }
}

///|
pub fn is_transfer_path(raw : String) -> Bool {
  let path = path_only(raw)
  [
    @town_contract.portable_packages_path(),
    @town_contract.portable_package_content_path(),
    @town_contract.portable_package_preview_path(),
    @town_contract.portable_package_grants_path(),
    @town_contract.portable_package_revoke_path(),
    @town_contract.portable_package_withdraw_path(),
  ].contains(path)
}

///|
fn header(request : @http.Request, name : String) -> String {
  request.headers.get(name).unwrap_or("")
}

///|
fn reject(code : Int, reason : String) -> Unit raise {
  raise @town_portable_transfer.TransferError(code, reason)
}

///|
fn exact_identifier(value : String) -> Bool {
  if value.is_empty() || value.length() > 128 {
    return false
  }
  value
  .iter()
  .all(c => {
    (c >= 'a' && c <= 'z') ||
    (c >= 'A' && c <= 'Z') ||
    (c >= '0' && c <= '9') ||
    c == '-' ||
    c == '_' ||
    c == '.' ||
    c == ':'
  })
}

///|
fn query_id(raw : String, name : String) -> String raise {
  guard raw.find("?") is Some(start) else {
    reject(400, "exact_identifier_required")
    return ""
  }
  let query = raw[start + 1:].to_owned()
  let prefix = name + "="
  if !query.has_prefix(prefix) || query.contains("&") {
    reject(400, "invalid_exact_query")
  }
  let value = query[prefix.length():].to_owned()
  if !exact_identifier(value) {
    reject(400, "invalid_exact_identifier")
  }
  value
}

///|
fn bounded_length(request : @http.Request, maximum : Int) -> Int raise {
  let raw = header(request, "content-length")
  if raw.is_empty() {
    reject(411, "content_length_required")
  }
  let mut length = 0
  for char in raw {
    if char < '0' || char > '9' {
      reject(411, "invalid_content_length")
    }
    let digit = char.to_int() - '0'.to_int()
    if length > (maximum - digit) / 10 {
      reject(413, "transfer_limit_exceeded")
    }
    length = length * 10 + digit
    if length > maximum {
      reject(413, "transfer_limit_exceeded")
    }
  }
  if length <= 0 {
    reject(411, "positive_content_length_required")
  }
  length
}

///|
fn identity_framing(request : @http.Request) -> Unit raise {
  if request.headers.contains("transfer-encoding") {
    reject(415, "transfer_encoding_not_supported")
  }
  let encoding = header(request, "content-encoding").to_lower()
  if encoding != "" && encoding != "identity" {
    reject(415, "identity_content_encoding_required")
  }
}

///|
async fn control_body(request : @http.Request, body : &@io.Reader) -> Json {
  identity_framing(request)
  if header(request, "content-type").to_lower() != "application/json" {
    reject(415, "application_json_required")
  }
  let length = bounded_length(request, 128 * 1024)
  let bytes = @async.with_timeout(30000, () => body.read_exactly(length))
  if @async.with_timeout(30000, () => body.read_some(max_len=1)) is Some(_) {
    reject(422, "body_length_mismatch")
  }
  @json.parse(@utf8.decode(bytes)) catch {
    _ => {
      reject(400, "invalid_json_body")
      Json::null()
    }
  }
}

///|
fn exact_object(value : Json, keys : Array[String]) -> Map[String, Json] raise {
  guard value is Object(fields) else {
    reject(400, "invalid_control_fields")
    return {}
  }
  if fields.length() != keys.length() || keys.any(key => !fields.contains(key)) {
    reject(400, "invalid_control_fields")
  }
  fields
}

///|
fn control_string(fields : Map[String, Json], key : String) -> String raise {
  guard fields.get(key) is Some(String(value)) else {
    reject(400, "invalid_control_field")
    return ""
  }
  value
}

///|
fn grant_draft(value : Json) -> @town_portable_transfer.GrantDraft raise {
  ignore(
    exact_object(value, [
      "grant_id", "package_id", "binding_digest", "grantee_principal_id", "expires_at_ms",
    ]),
  )
  @json.from_json(value) catch {
    _ => {
      reject(400, "invalid_package_grant")
      fail("unreachable")
    }
  }
}
