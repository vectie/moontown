///|
async fn append_daemon_log(path : String, message : String) -> Unit {
  ensure_parent_directory(path) catch {
    _ => ()
  }
  let line = "[\{@env.now()}] \{message}\n"
  @fs.write_file(path, @encoding/utf8.encode(line), create=0o644, append=true) catch {
    _ => ()
  }
}

///|
async fn latest_daemon_log_sequence(log_path : String) -> Int {
  let text = read_text_or_empty(log_path)
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
