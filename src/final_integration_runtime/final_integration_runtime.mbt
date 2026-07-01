///|
fn final_integration_status_path(manifest_id : String) -> String {
  "\{@storage.moontown_product_state_dir()}/integration/\{manifest_id}-status.json"
}

///|
pub async fn install_wenyu_final_integration(
  manifest_path? : String = "assets/templates/integration/wenyu-final-integration.json",
  snapshot_path? : String = @storage.default_snapshot_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> String {
  let manifest = match load_final_integration_manifest(manifest_path) {
    Some(manifest) => manifest
    None => return "Could not load final integration manifest: \{manifest_path}"
  }
  let current_tick = load_integration_daemon_tick(snapshot_path)
  let existing = @storage.load_or_create_standing_goals(path=standing_goal_path)
  let merged = @final_integration.merge_final_integration_standing_goals(
    existing,
    manifest.domain_watches,
    current_tick,
  )
  @storage.save_standing_goals_file(standing_goal_path, merged)
  let civic_workspace_summary = @civic_runtime.bootstrap_wenyu_civic_workspaces()
  let protocol_summary = @civic_runtime.bootstrap_wenyu_building_protocols()
  let install_summaries : Array[String] = []
  for spec in manifest.civic_pattern_manifests {
    install_summaries.push(
      @civic_runtime.install_civic_pattern_scenario_manifest(spec.path),
    )
  }
  for spec in manifest.civic_scenarios {
    install_summaries.push(
      @civic_runtime.install_civic_pattern_scenario_file(
        spec.path,
        due_now=false,
      ),
    )
  }
  ignore(@civic_runtime.write_wenyu_civic_status())
  let status = @final_integration.final_integration_status_json(
    manifest, merged, current_tick, civic_workspace_summary, protocol_summary, install_summaries,
  )
  let status_path = final_integration_status_path(manifest.id)
  @support.write_text_file(status_path, status.stringify(indent=2))
  [
    "# \{manifest.title}",
    "",
    "Installed \{manifest.domain_watches.length()} domain standing watch(es), \{manifest.civic_pattern_manifests.length()} civic pattern manifest(s), and \{manifest.civic_scenarios.length()} recurring scenario(s).",
    "",
    "- Current daemon tick: \{current_tick}",
    "- Standing goals: \{merged.length()}",
    "- Civic workspaces: \{civic_workspace_summary}",
    "- Building protocols: \{protocol_summary}",
    "- Pattern install: \{install_summaries.join(" / ")}",
    "- Status: `\{status_path}`",
  ].join("\n")
}

///|
pub async fn render_wenyu_final_integration_status(
  manifest_path? : String = "assets/templates/integration/wenyu-final-integration.json",
  snapshot_path? : String = @storage.default_snapshot_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> String {
  let manifest = match load_final_integration_manifest(manifest_path) {
    Some(manifest) => manifest
    None => return "Could not load final integration manifest: \{manifest_path}"
  }
  let current_tick = load_integration_daemon_tick(snapshot_path)
  let goals = @storage.load_or_create_standing_goals(path=standing_goal_path)
  let builder = StringBuilder::new()
  builder.write_string("# \{manifest.title} Status\n\n")
  builder.write_string("- Current daemon tick: \{current_tick}\n")
  builder.write_string(
    "- Domain watch coverage: \{@final_integration.final_integration_watch_coverage(manifest, goals)}\n",
  )
  builder.write_string(
    "- Civic pattern manifests: \{manifest.civic_pattern_manifests.length()}\n",
  )
  builder.write_string(
    "- Recurring scenarios: \{manifest.civic_scenarios.length()}\n\n",
  )
  builder.write_string(
    "| Order | Domain | Form | Standing Goal | Book | Next |\n",
  )
  builder.write_string("| ---: | --- | --- | --- | --- | --- |\n")
  for spec in manifest.domain_watches {
    let goal = @final_integration.find_standing_goal_by_id(goals, spec.id)
    let next = match goal {
      Some(goal) =>
        if goal.next_due_tick <= current_tick {
          "due now"
        } else {
          "in \{goal.next_due_tick - current_tick} ticks"
        }
      None => "not installed"
    }
    builder.write_string(
      "|\{spec.order}|\{spec.domain}|\{spec.form}|\{spec.id}|\{spec.target_book_id}|\{next}|\n",
    )
  }
  builder.write_string("\n## Civic Feature Forms\n\n")
  for spec in manifest.civic_pattern_manifests {
    builder.write_string(
      "- \{spec.order}. `\{spec.form}` via `\{spec.path}`: \{spec.note}\n",
    )
  }
  for spec in manifest.civic_scenarios {
    builder.write_string(
      "- \{spec.order}. `\{spec.form}` via `\{spec.path}`: \{spec.note}\n",
    )
  }
  builder.to_string()
}
