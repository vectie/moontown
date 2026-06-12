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

///|
pub fn upsert_nested_object_entry_json(
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
