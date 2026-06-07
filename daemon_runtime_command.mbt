///|
fn daemon_command_uses_moon_runner(command : String) -> Bool {
  let name = path_basename(command).to_lower()
  name == "moon" || name == "moon.exe"
}

///|
fn daemon_process_args(command : String, tail : Array[String]) -> Array[String] {
  let args : Array[String] = []
  if daemon_command_uses_moon_runner(command) {
    args.push("run")
    args.push("cmd/main")
    args.push("--")
  }
  for item in tail {
    args.push(item)
  }
  args
}

///|
fn daemon_shell_quote(text : String) -> String {
  let builder = StringBuilder::new()
  builder.write_char('\'')
  for char in text {
    if char == '\'' {
      builder.write_string("'\\''")
    } else {
      builder.write_char(char)
    }
  }
  builder.write_char('\'')
  builder.to_string()
}

///|
fn daemon_process_command_line(
  command : String,
  tail : Array[String],
) -> String {
  let parts : Array[String] = [daemon_shell_quote(command)]
  for arg in daemon_process_args(command, tail) {
    parts.push(daemon_shell_quote(arg))
  }
  parts.join(" ")
}

///|
fn daemon_command_or_current(command : String) -> String {
  if !command.is_empty() {
    return command
  }
  match @sys.get_env_var("MOONTOWN_DAEMON_COMMAND") {
    Some(value) if !value.is_empty() => value
    _ =>
      match @sys.get_env_var("MOON_BIN") {
        Some(value) if !value.is_empty() => value
        _ =>
          match @sys.get_env_var("HOME") {
            Some(home) if !home.is_empty() => home + "/.moon/bin/moon"
            _ => "moon"
          }
      }
  }
}
