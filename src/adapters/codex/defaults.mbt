///|
pub fn model() -> String {
  match optional_env_text("MOONTOWN_CODEX_ACP_MODEL") {
    Some(model) => model
    None => "gpt-5.5"
  }
}

///|
pub fn command() -> String {
  match optional_env_text("CODEX_BIN") {
    Some(command) => command
    None => "/Users/kq/.nvm/versions/node/v22.22.1/bin/node"
  }
}

///|
pub fn args() -> Array[String] {
  args_with_tail([])
}

///|
pub fn moontown_args() -> Array[String] {
  args_with_tail(["--cd", moontown_workspace_root()])
}

///|
pub fn moontown_workspace_root() -> String {
  match optional_env_text("MOONTOWN_WORKSPACE_ROOT") {
    Some(root) => root
    None => @env.current_dir().unwrap_or(".")
  }
}

///|
fn args_with_tail(tail : Array[String]) -> Array[String] {
  let model = model()
  let args = match optional_env_text("CODEX_BIN") {
    Some(_) => ["exec", "--model", model, "--sandbox", "workspace-write"]
    None =>
      [
        "/Users/kq/.nvm/versions/node/v22.22.1/lib/node_modules/@openai/codex/bin/codex.js",
        "exec", "--model", model, "--sandbox", "workspace-write",
      ]
  }
  for arg in tail {
    args.push(arg)
  }
  args
}

///|
pub fn args_normalized_with_model(
  args : Array[String],
  model : String,
) -> Array[String] {
  let normalized : Array[String] = []
  let mut saw_model = false
  let mut skip_next = false
  for index in 0..<args.length() {
    let arg = args[index]
    if skip_next {
      skip_next = false
      continue
    }
    if arg == "--model" {
      normalized.push("--model")
      normalized.push(model)
      saw_model = true
      skip_next = true
    } else {
      normalized.push(arg)
    }
  }
  if !saw_model {
    normalized.push("--model")
    normalized.push(model)
  }
  normalized
}

///|
fn optional_env_text(key : String) -> String? {
  match @sys.get_env_var(key) {
    Some(value) => {
      let trimmed = value.trim().to_owned()
      if trimmed.is_empty() {
        None
      } else {
        Some(trimmed)
      }
    }
    None => None
  }
}
