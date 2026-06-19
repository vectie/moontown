///|
fn default_moonclaw_root() -> String {
  match @sys.get_env_var("MOONTOWN_MOONCLAW_ROOT") {
    Some(root) if !root.is_empty() => root
    _ =>
      match @sys.get_env_var("MOONCLAW_ROOT") {
        Some(root) if !root.is_empty() => root
        _ => ".moontown/external/moonclaw"
      }
  }
}

///|
fn moon_command() -> String {
  match @sys.get_env_var("MOON_BIN") {
    Some(value) if !value.is_empty() => value
    _ =>
      match @sys.get_env_var("HOME") {
        Some(home) if !home.is_empty() => home + "/.moon/bin/moon"
        _ => "moon"
      }
  }
}

///|
fn build_detached_shell_command(
  command : String,
  args : Array[String],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("nohup ")
  builder.write_string(shell_quote(command))
  for arg in args {
    builder.write_char(' ')
    builder.write_string(shell_quote(arg))
  }
  builder.write_string(" >/dev/null 2>&1 &")
  builder.to_string()
}

///|
fn build_detached_shell_command_with_output(
  command : String,
  args : Array[String],
  stdout_path : String,
  stderr_path : String,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("nohup ")
  builder.write_string(shell_quote(command))
  for arg in args {
    builder.write_char(' ')
    builder.write_string(shell_quote(arg))
  }
  builder.write_string(" >")
  builder.write_string(shell_quote(stdout_path))
  builder.write_string(" 2>")
  builder.write_string(shell_quote(stderr_path))
  builder.write_string(" &")
  builder.to_string()
}

///|
fn shell_quote(text : String) -> String {
  let escaped = text.replace(old="'", new="'\"'\"'")
  "'\{escaped}'"
}
