///|
fn upsert_moonclaw_job_profile_json(
  config : Json,
  profile_id : String,
  profile : Json,
) -> Json {
  upsert_nested_object_entry_json(
    config,
    section_key="jobs",
    collection_key="profiles",
    entry_key=profile_id,
    entry=profile,
  )
}

///|
fn upsert_nested_object_entry_json(
  config : Json,
  section_key~ : String,
  collection_key~ : String,
  entry_key~ : String,
  entry~ : Json,
) -> Json {
  @core.upsert_nested_object_entry_json(
    config,
    section_key~,
    collection_key~,
    entry_key~,
    entry~,
  )
}

///|
fn upsert_acp_target_json(
  config : Json,
  target_id : String,
  target : Json,
) -> Json {
  upsert_nested_object_entry_json(
    config,
    section_key="acp",
    collection_key="targets",
    entry_key=target_id,
    entry=target,
  )
}

///|
fn upsert_agent_default_json(config : Json, key : String, value : Json) -> Json {
  let root = json_object_copy(Some(config))
  let agents = json_object_copy(root.get("agents"))
  let defaults = json_object_copy(agents.get("defaults"))
  defaults[key] = value
  agents["defaults"] = Json::object(defaults)
  root["agents"] = Json::object(agents)
  Json::object(root)
}
