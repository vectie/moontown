///|
fn default_moonclaw_root() -> String {
  match @sys.get_env_var("MOONTOWN_MOONCLAW_ROOT") {
    Some(root) if !root.is_empty() => root
    _ =>
      match @sys.get_env_var("MOONCLAW_ROOT") {
        Some(root) if !root.is_empty() => root
        _ => @storage.moontown_product_artifact("external/moonclaw")
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
async fn installed_moonclaw_command() -> String? {
  match @sys.get_env_var("MOONTOWN_MOONCLAW_BIN") {
    Some(value) if !value.trim().is_empty() =>
      return Some(value.trim().to_owned())
    _ => ()
  }
  match @sys.get_env_var("MOONCLAW_BIN") {
    Some(value) if !value.trim().is_empty() =>
      return Some(value.trim().to_owned())
    _ => ()
  }
  let candidate = @storage.moontown_active_workspace_root() + "/bin/moonclaw"
  if @fs.exists(candidate) {
    Some(candidate)
  } else {
    None
  }
}

///|
async fn moonclaw_runtime_invocation(
  moonclaw_root : String,
  cli_args : Array[String],
) -> (String, Array[String]) {
  match installed_moonclaw_command() {
    Some(command) => (command, cli_args)
    None =>
      (
        moon_command(),
        ["-C", moonclaw_root, "run", "cmd/main", "--", ..cli_args],
      )
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
