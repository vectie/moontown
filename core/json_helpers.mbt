///|
pub fn json_object_copy(value : Json?) -> Map[String, Json] {
  let copied : Map[String, Json] = {}
  match value {
    Some(Object(obj)) =>
      for key, entry in obj {
        copied[key] = entry
      }
    _ => ()
  }
  copied
}

///|
pub fn upsert_nested_object_entry_json(
  config : Json,
  section_key~ : String,
  collection_key~ : String,
  entry_key~ : String,
  entry~ : Json,
) -> Json {
  let root = json_object_copy(Some(config))
  let section = json_object_copy(root.get(section_key))
  let collection = json_object_copy(section.get(collection_key))
  collection[entry_key] = entry
  section[collection_key] = Json::object(collection)
  root[section_key] = Json::object(section)
  Json::object(root)
}

///|
pub fn upsert_moonclaw_job_profile_json(
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
