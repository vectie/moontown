///|
pub fn digest_valid(value : String) -> Bool {
  value.length() == 71 &&
  value.has_prefix("sha256:") &&
  value[7:].iter().all(c => c is ('0'..='9' | 'a'..='f'))
}

///|
pub fn relative_path_valid(value : String) -> Bool {
  !value.is_empty() &&
  value.length() <= 4096 &&
  !value.has_prefix("/") &&
  !value.contains("\\") &&
  !value.iter().any(c => c < ' ' || c == '\u007f') &&
  value.split("/").all(part => part != "" && part != "." && part != "..")
}

///|
pub fn selection_valid(value : Selection) -> Bool {
  value.book_handle.length() == 69 &&
  value.book_handle.has_prefix("book-") &&
  value.book_handle[5:].iter().all(c => c is ('0'..='9' | 'a'..='f')) &&
  digest_valid(value.package_sha256) &&
  digest_valid(value.manifest_sha256) &&
  digest_valid(value.digest) &&
  relative_path_valid(value.artifact_id) &&
  !value.artifact_id.contains("/") &&
  relative_path_valid(value.path) &&
  value.path.has_prefix("portable/outputs/" + value.artifact_id + "/") &&
  value.size_bytes >= 0 &&
  value.size_bytes <= 16 * 1024 * 1024
}

///|
pub fn parse_catalog(text : String) -> Catalog? {
  guard @utf8.encode(text).length() <= catalog_wire_limit() else { return None }
  let value : Catalog = @json.from_json(@json.parse(text)) catch {
    _ => return None
  }
  guard value.contract == "moontown.imported_outputs.v1" &&
    ["ready", "empty", "unavailable"].contains(value.state) &&
    value.books.length() <= 256 &&
    (value.state != "empty" || value.books.is_empty()) else {
    return None
  }
  let handles : Map[String, Unit] = Map([])
  for book in value.books {
    guard book.handle.length() == 69 &&
      book.handle.has_prefix("book-") &&
      book.handle[5:].iter().all(c => c is ('0'..='9' | 'a'..='f')) &&
      !handles.contains(book.handle) &&
      !book.book_id.is_empty() &&
      ["ready", "empty", "unsupported", "unavailable"].contains(book.state) else {
      return None
    }
    handles[book.handle] = ()
    if book.source is Some(source) {
      guard !source.agent_id.trim().is_empty() &&
        !source.agent_version.trim().is_empty() &&
        digest_valid(source.package_sha256) else {
        return None
      }
      if source.outputs_manifest_digest is Some(digest) && !digest_valid(digest) {
        return None
      }
    }
    if book.state == "unavailable" || book.state == "unsupported" {
      guard book.outputs.is_empty() else { return None }
      continue
    }
    guard book.source is Some(source) &&
      !source.agent_id.trim().is_empty() &&
      !source.agent_version.trim().is_empty() &&
      digest_valid(source.package_sha256) &&
      (book.state != "empty" || book.outputs.is_empty()) &&
      (book.state != "ready" || !book.outputs.is_empty()) &&
      book.outputs.length() <= 4096 else {
      return None
    }
    if source.outputs_manifest_digest is Some(digest) && !digest_valid(digest) {
      return None
    }
    guard book.outputs.is_empty() || source.outputs_manifest_digest is Some(_) else {
      return None
    }
    let ids : Map[String, Unit] = Map([])
    let paths : Map[String, Unit] = Map([])
    for output in book.outputs {
      guard relative_path_valid(output.artifact_id) &&
        !output.artifact_id.contains("/") &&
        !ids.contains(output.artifact_id) &&
        !output.label.trim().is_empty() &&
        output.mime_type.contains("/") &&
        output.mime_type.trim() == output.mime_type else {
        return None
      }
      ids[output.artifact_id] = ()
      if !output.included {
        guard output.files.is_empty() &&
          output.preview_path is None &&
          output.app_entrypoint is None &&
          output.reference is Some(reference) &&
          !reference.trim().is_empty() else {
          return None
        }
        if output.declared_digest is Some(digest) && !digest_valid(digest) {
          return None
        }
      } else {
        guard !output.files.is_empty() &&
          output.reference is None &&
          output.declared_digest is None else {
          return None
        }
        for file in output.files {
          guard paths.length() < 8192 &&
            !paths.contains(file.path) &&
            relative_path_valid(file.path) &&
            file.path.has_prefix("portable/outputs/" + output.artifact_id + "/") &&
            digest_valid(file.digest) &&
            file.size_bytes >= 0 &&
            file.size_bytes <= 16 * 1024 * 1024 else {
            return None
          }
          paths[file.path] = ()
        }
        for link in [output.preview_path, output.app_entrypoint] {
          if link is Some(path) && !output.files.any(file => file.path == path) {
            return None
          }
        }
      }
    }
  }
  Some(value)
}

///|
pub fn parse_text_reply(text : String) -> TextReply? {
  guard @utf8.encode(text).length() <= text_wire_limit() else { return None }
  let value : TextReply = @json.from_json(@json.parse(text)) catch {
    _ => return None
  }
  guard value.contract == "moontown.imported_output_text.v1" &&
    ["ready", "unavailable", "opaque", "too_large"].contains(value.state) &&
    selection_valid(value.selection) &&
    (if value.state == "ready" {
      value.content is Some(_)
    } else {
      value.content is None
    }) else {
    return None
  }
  if value.content is Some(content) {
    let size = @utf8.encode(content).length()
    guard size == value.selection.size_bytes &&
      size <= text_preview_limit() &&
      !content
      .iter()
      .any(c => {
        (c < ' ' && c != '\n' && c != '\r' && c != '\t') || c == '\u007f'
      }) else {
      return None
    }
  }
  Some(value)
}

///|
pub fn query_encode(value : String) -> String {
  let out = StringBuilder()
  let hex = "0123456789ABCDEF"
  for byte in @utf8.encode(value) {
    let code = byte.to_int()
    if code is (65..=90 | 97..=122 | 48..=57 | 45 | 46 | 95 | 126) {
      out.write_char(code.unsafe_to_char())
    } else {
      out.write_char('%')
      out.write_char(hex.get_char(code / 16).unwrap())
      out.write_char(hex.get_char(code % 16).unwrap())
    }
  }
  out.to_string()
}

///|
pub fn catalog_wire_limit() -> Int {
  4 * 1024 * 1024
}

///|
pub fn text_preview_limit() -> Int {
  4 * 1024 * 1024
}

///|
/// Includes the worst-case JSON escaping overhead and selection metadata.
pub fn text_wire_limit() -> Int {
  24 * 1024 * 1024 + 65536
}

///|
pub fn content_path(selection : Selection, mode~ : String) -> String {
  "/api/imported-outputs/content?" +
  [
    ("book_handle", selection.book_handle),
    ("package_sha256", selection.package_sha256),
    ("manifest_sha256", selection.manifest_sha256),
    ("artifact_id", selection.artifact_id),
    ("path", selection.path),
    ("digest", selection.digest),
    ("size_bytes", selection.size_bytes.to_string()),
    ("mode", mode),
  ]
  .map(pair => pair.0 + "=" + query_encode(pair.1))
  .join("&")
}
