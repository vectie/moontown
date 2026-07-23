///|
pub async fn append_daemon_log(path : String, message : String) -> Unit {
  @support.ensure_parent_directory(path) catch {
    _ => ()
  }
  let line = "[\{@env.now()}] \{message}\n"
  @fs.write_file(
    path,
    @encoding/utf8.encode(line),
    create_mode=OpenOrCreate,
    permission=0o644,
    append=true,
  ) catch {
    _ => ()
  }
}

///|
pub async fn latest_daemon_log_sequence(log_path : String) -> Int {
  let text = @support.read_text_or_empty(log_path)
  let mut latest = 0
  for line in text.split("\n") {
    if !line.contains("sequence=") {
      continue
    }
    let parts = line.split("sequence=").to_array()
    match parts.get(parts.length() - 1) {
      Some(suffix) =>
        match first_non_negative_int(suffix.to_owned()) {
          Some(value) => if value > latest { latest = value }
          None => ()
        }
      None => ()
    }
  }
  latest
}

///|
fn first_non_negative_int(text : String) -> Int? {
  let mut seen = false
  let mut value = 0
  for char in text {
    if char >= '0' && char <= '9' {
      value = value * 10 + (char.to_int() - '0'.to_int())
      seen = true
    } else if seen {
      return Some(value)
    }
  }
  if seen {
    Some(value)
  } else {
    None
  }
}
