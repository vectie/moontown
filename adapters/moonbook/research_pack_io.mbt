///|
async fn ensure_moontown_research_moonclaw_profile(root : String) -> Unit {
  let path = "\{root}/moonclaw.jobs.json"
  let existing = match moonbook_read_optional_json_file(path) {
    Some(json) => json
    None => Json::object({})
  }
  let profile = moontown_research_bootstrap_profile_json()
  write_workspace_text(
    path,
    @core.upsert_moonclaw_job_profile_json(
      existing, "moontown_research_bootstrap_worker", profile,
    ).stringify(indent=2),
  )
}
