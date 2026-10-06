///|
const MemberLimit : Int = 16 * 1024 * 1024

///|
const TextLimit : Int = 4 * 1024 * 1024

///|
fn hash(bytes : Bytes) -> String {
  "sha256:" + @crypto.bytes_to_hex_string(@crypto.sha256(bytes))
}

///|
fn absolute_path_valid(path : String) -> Bool {
  path.has_prefix("/") &&
  path.length() > 1 &&
  @contract.relative_path_valid(path[1:].to_owned())
}

///|
/// A local read-only viewer, not an atomic filesystem transaction: checks reject
/// existing aliases/special nodes before open and repeat them after reading.
/// Concurrent hostile rename races require OS descriptor-relative open support.
async fn check_path(path : String, directory~ : Bool) -> Unit {
  guard absolute_path_valid(path) else { fail("Invalid server-owned path") }
  let parts = path[1:].split("/").to_array()
  let mut current = ""
  for i, part in parts {
    current += "/" + part.to_owned()
    let expected = if i < parts.length() - 1 || directory {
      @fs.Directory
    } else {
      @fs.Regular
    }
    guard @fs.kind(current, follow_symlink=false) == expected else {
      fail("Missing, aliased or special filesystem node")
    }
  }
  guard @fs.realpath(path) == path else { fail("Path alias is unsupported") }
}

///|
async fn bounded_bytes(root : String, relative : String, limit : Int) -> Bytes {
  guard @contract.relative_path_valid(relative) else {
    fail("Unsafe member path")
  }
  let path = root + "/" + relative
  check_path(path, directory=false)
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  guard file.kind() == Regular else { fail("Expected regular file") }
  let size = file.size()
  let modified = file.mtime()
  let changed = file.ctime()
  guard size >= 0L && size <= limit.to_int64() else {
    fail("File exceeds size limit")
  }
  let bytes = @buffer.Buffer(size_hint=size.to_int().min(8192))
  while file.read_some(max_len=(limit - bytes.length() + 1).min(65536))
        is Some(chunk) {
    guard bytes.length() + chunk.length() <= limit else {
      fail("File grew beyond size limit")
    }
    bytes.write_bytes(chunk)
  }
  guard bytes.length().to_int64() == size &&
    file.size() == size &&
    file.mtime() == modified &&
    file.ctime() == changed else {
    fail("File changed while reading")
  }
  check_path(path, directory=false)
  bytes.to_bytes()
}

///|
async fn bounded_absolute(path : String, limit : Int) -> Bytes {
  guard absolute_path_valid(path) &&
    path.rev_find("/") is Some(index) &&
    index > 0 else {
    fail("Invalid catalog path")
  }
  bounded_bytes(path[:index].to_owned(), path[index + 1:].to_owned(), limit)
}

///|
async fn present(path : String) -> Bool {
  try {
    ignore(@fs.kind(path, follow_symlink=false))
    true
  } catch {
    @os_error.OSError(_) as error if error.is_ENOENT() => false
    // An unreadable node is still a candidate, and must surface unavailable.
    _ => true
  }
}

///|
fn strict_text(bytes : Bytes) -> String? {
  let text = @utf8.decode(bytes, ignore_bom=false) catch { _ => return None }
  // NUL and nontext controls are binary even when technically valid UTF-8.
  if text
    .iter()
    .any(c => (c < ' ' && c != '\n' && c != '\r' && c != '\t') || c == '\u007f') {
    None
  } else {
    Some(text)
  }
}
