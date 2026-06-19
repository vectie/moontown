///|
pub fn moontown_target_id() -> String {
  "wenyu-codex-moontown"
}

///|
pub fn codex_main_target_id() -> String {
  "codex-main"
}

///|
pub fn codex_main_target_json(
  source_root : String,
  label? : String = "Codex ACP Worker",
) -> Json {
  codex_acp_target_json(source_root, label, command(), args(), model())
}

///|
pub fn codex_acp_target_json(
  source_root : String,
  label : String,
  command : String,
  args : Array[String],
  model : String,
) -> Json {
  {
    "backend": "codex",
    "label": label,
    "cwd": source_root,
    "workspace": source_root,
    "command": command,
    "args": args_normalized_with_model(args, model),
    "model": model,
  }
}

///|
pub fn moontown_target_json() -> Json {
  let root = moontown_workspace_root()
  {
    "backend": "codex",
    "label": "Codex Moontown Builder",
    "cwd": root,
    "workspace": root,
    "command": command(),
    "args": moontown_args(),
    "model": model(),
  }
}

///|
pub fn upsert_codex_main_target_json(
  config : Json,
  source_root : String,
  label? : String = "Codex ACP Worker",
) -> Json {
  upsert_acp_target_json(
    config,
    codex_main_target_id(),
    codex_main_target_json(source_root, label~),
  )
}

///|
pub fn upsert_moontown_target_json(config : Json, book_root : String) -> Json {
  let with_workspace = upsert_agent_default_json(
    config,
    "workspace",
    book_root.to_json(),
  )
  upsert_acp_target_json(
    with_workspace,
    moontown_target_id(),
    moontown_target_json(),
  )
}

///|
pub fn upsert_acp_target_json(
  config : Json,
  target_id : String,
  target : Json,
) -> Json {
  @core.upsert_nested_object_entry_json(
    config,
    section_key="acp",
    collection_key="targets",
    entry_key=target_id,
    entry=target,
  )
}

///|
fn upsert_agent_default_json(config : Json, key : String, value : Json) -> Json {
  let root = @core.json_object_copy(Some(config))
  let agents = @core.json_object_copy(root.get("agents"))
  let defaults = @core.json_object_copy(agents.get("defaults"))
  defaults[key] = value
  agents["defaults"] = Json::object(defaults)
  root["agents"] = Json::object(agents)
  Json::object(root)
}
