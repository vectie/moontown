///|
priv struct CivicPatternScenarioManifest {
  templates : Array[String]
} derive(FromJson)

///|
pub async fn install_civic_pattern_scenario_manifest(
  manifest_path : String,
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  if !@fs.exists(manifest_path) {
    return "Could not load civic communication pattern manifest: \{manifest_path}"
  }
  let text = @fs.read_file(manifest_path).text() catch {
    _ =>
      return "Could not read civic communication pattern manifest: \{manifest_path}"
  }
  let parsed = @json.parse(text) catch {
    _ =>
      return "Could not parse civic communication pattern manifest: \{manifest_path}"
  }
  let manifest : CivicPatternScenarioManifest = @json.from_json(parsed) catch {
    _ => return "Invalid civic communication pattern manifest: \{manifest_path}"
  }
  let summaries : Array[String] = []
  let base_dir = @path.Path::dirname(manifest_path).to_string()
  let mut due_ms = @env.now() + 300_000UL
  for template in manifest.templates {
    match
      load_civic_communication_scenario_file(
        resolve_manifest_template_path(base_dir, template),
      ) {
      Some(scenario) => {
        let schedule = install_civic_pattern_scenario(
          scenario, snapshot_path, due_ms,
        )
        summaries.push("\{schedule.id}@\{schedule.building_id}")
        due_ms = due_ms + 300_000UL
      }
      None => summaries.push("missing:\{template}")
    }
  }
  "Installed \{summaries.length()} civic communication pattern scenario(s): \{summaries.join(", ")}"
}

///|
fn resolve_manifest_template_path(
  base_dir : String,
  template : String,
) -> String {
  if template.has_prefix("/") || base_dir == "." || base_dir == "" {
    template
  } else {
    "\{base_dir}/\{template}"
  }
}
