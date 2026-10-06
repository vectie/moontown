///|
pub(all) struct Response {
  status : Int
  headers : Map[String, String]
  body : Bytes
} derive(Debug, Eq)

///|
fn response(
  status : Int,
  body : Bytes,
  kind : String,
  head : Bool,
  attachment? : Bool = false,
) -> Response {
  let headers : Map[String, String] = {
    "Content-Type": kind,
    "Cache-Control": "no-store",
    "X-Content-Type-Options": "nosniff",
    "Content-Security-Policy": "default-src 'none'; sandbox",
  }
  // async/http 0.19.4's supported HEAD path is WaitingBody with no length.
  // A nonzero length instead selects SendingFixed and rejects end_response.
  if !head {
    headers["Content-Length"] = body.length().to_string()
  }
  if attachment {
    headers["Content-Disposition"] = "attachment; filename=\"imported-output.bin\""
  }
  { status, headers, body: if head { b"" } else { body }, }
}

///|
fn json_response(status : Int, value : Json, head : Bool) -> Response {
  response(
    status,
    @utf8.encode(value.stringify()),
    "application/json; charset=utf-8",
    head,
  )
}

///|
fn hex_digit(c : UInt16) -> Int? {
  match c {
    '0'..='9' => Some(c.to_int() - 48)
    'a'..='f' => Some(c.to_int() - 87)
    'A'..='F' => Some(c.to_int() - 55)
    _ => None
  }
}

///|
fn query_decode(value : String) -> String? {
  let bytes = @buffer.Buffer()
  let mut i = 0
  while i < value.length() {
    if value[i] == '%' {
      guard i + 2 < value.length() &&
        hex_digit(value[i + 1]) is Some(a) &&
        hex_digit(value[i + 2]) is Some(b) else {
        return None
      }
      bytes.write_byte((a * 16 + b).to_byte())
      i += 3
    } else {
      guard value[i].to_int() < 128 else { return None }
      bytes.write_byte(
        if value[i] == '+' {
          32
        } else {
          value[i].to_int().to_byte()
        },
      )
      i += 1
    }
  }
  let text = @utf8.decode(bytes.to_bytes()) catch { _ => return None }
  Some(text)
}

///|
fn selection_query(query : String) -> (@contract.Selection, String)? {
  guard query.length() <= 16384 else { return None }
  let fields : Map[String, String] = Map([])
  for pair in query.split("&") {
    guard pair.split_once("=") is Some((key, value)) &&
      query_decode(key.to_owned()) is Some(key) &&
      query_decode(value.to_owned()) is Some(value) &&
      !fields.contains(key) else {
      return None
    }
    fields[key] = value
  }
  guard fields.length() == 8 &&
    fields.get("book_handle") is Some(book_handle) &&
    fields.get("package_sha256") is Some(package_sha256) &&
    fields.get("manifest_sha256") is Some(manifest_sha256) &&
    fields.get("artifact_id") is Some(artifact_id) &&
    fields.get("path") is Some(path) &&
    fields.get("digest") is Some(digest) &&
    fields.get("size_bytes") is Some(size) &&
    fields.get("mode") is Some(mode) &&
    (mode == "text" || mode == "download") else {
    return None
  }
  let size_bytes = @string.parse_int(size) catch { _ => return None }
  guard size_bytes.to_string() == size else { return None }
  let selection : @contract.Selection = {
    book_handle,
    package_sha256,
    manifest_sha256,
    artifact_id,
    path,
    digest,
    size_bytes,
  }
  if @contract.selection_valid(selection) {
    Some((selection, mode))
  } else {
    None
  }
}

///|
async fn selected_bytes(
  selection : @contract.Selection,
  catalog_path : String,
  books_root : String,
) -> Bytes {
  let (candidates, _) = roots(catalog_path, books_root)
  guard candidates
    .iter()
    .find_first(root => handle(root.path) == selection.book_handle)
    is Some(root) else {
    fail("Book handle is no longer discovered")
  }
  check_path(root.path, directory=true)
  ignore(bounded_bytes(root.path, "book.toml", 65536))
  let (source, outputs) = exact_outputs(root.path, book_id(root.path))
  guard source.package_sha256 == selection.package_sha256 &&
    source.outputs_manifest_digest == Some(selection.manifest_sha256) &&
    outputs
    .iter()
    .find_first(output => {
      output.artifact_id == selection.artifact_id && output.included
    })
    is Some(output) &&
    output.files.any(file => {
      file.path == selection.path &&
      file.digest == selection.digest &&
      file.size_bytes == selection.size_bytes
    }) else {
    fail("Selected source or member changed")
  }
  // This single bounded snapshot is both hashed and returned. No second member
  // read can substitute bytes between verification and response serialization.
  let bytes = bounded_bytes(root.path, selection.path, MemberLimit)
  guard bytes.length() == selection.size_bytes &&
    hash(bytes) == selection.digest else {
    fail("Selected member changed since import")
  }
  // Recheck provenance after the member read to catch replacement during it.
  let (after, after_outputs) = exact_outputs(root.path, book_id(root.path))
  guard after == source && after_outputs == outputs else {
    fail("Selected source changed while reading")
  }
  bytes
}

///|
/// Socket-free response core. The desktop adapter preserves its existing access
/// gate and calls this before constructing any supervisor/runtime application.
pub async fn respond(
  method : String,
  target : String,
  catalog_path : String,
  books_root : String,
) -> Response {
  let head = method == "HEAD"
  if method != "GET" && !head {
    let result = json_response(405, { "error": "GET or HEAD required" }, false)
    result.headers["Allow"] = "GET, HEAD"
    return result
  }
  let (path, query) = match target.split_once("?") {
    Some((path, query)) => (path.to_owned(), query.to_owned())
    None => (target, "")
  }
  if path == "/api/imported-outputs" && query == "" {
    return json_response(
      200,
      discover(catalog_path, books_root).to_json(),
      head,
    )
  }
  guard path == "/api/imported-outputs/content" else {
    return json_response(
      404,
      { "error": "Unknown imported-output route" },
      head,
    )
  }
  guard selection_query(query) is Some((selection, mode)) else {
    return json_response(
      400,
      {
        "error": "Use one complete pinned output selection and text or download mode",
      },
      head,
    )
  }
  let bytes = selected_bytes(selection, catalog_path, books_root) catch {
    _ => {
      let reply : @contract.TextReply = {
        contract: "moontown.imported_output_text.v1",
        state: "unavailable",
        message: "Selected source or member is missing, unsupported, changed, or unsafe. Reload imported outputs before selecting again.",
        selection,
        content: None,
      }
      return json_response(409, reply.to_json(), head)
    }
  }
  if mode == "download" {
    let reply = response(
      200,
      bytes,
      "application/octet-stream",
      head,
      attachment=true,
    )
    reply.headers["X-Artifact-Digest"] = selection.digest
    let filename = selection.path
      .split("/")
      .last()
      .unwrap_or("imported-output.bin")
      .to_owned()
    reply.headers["Content-Disposition"] = "attachment; filename=\"imported-output.bin\"; filename*=UTF-8''" +
      @contract.query_encode(filename)
    return reply
  }
  let (state, message, content) = if bytes.length() > TextLimit {
    (
      "too_large",
      "This verified member exceeds the 4 MiB text preview limit. Download its exact bytes instead.",
      None,
    )
  } else if strict_text(bytes) is Some(text) {
    ("ready", "Verified exact member bytes shown as inert text.", Some(text))
  } else {
    (
      "opaque",
      "This verified member is not strict UTF-8 text. Download its exact bytes instead.",
      None,
    )
  }
  let reply : @contract.TextReply = {
    contract: "moontown.imported_output_text.v1",
    state,
    message,
    selection,
    content,
  }
  json_response(200, reply.to_json(), head)
}
