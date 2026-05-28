///|
struct FinalIntegrationManifest {
  id : String
  title : String
  domain_watches : Array[FinalIntegrationWatchSpec]
  civic_pattern_manifests : Array[FinalIntegrationTemplateSpec]
  civic_scenarios : Array[FinalIntegrationTemplateSpec]
} derive(Debug, Eq, ToJson, FromJson)

///|
struct FinalIntegrationWatchSpec {
  order : Int
  domain : String
  form : String
  id : String
  title : String
  prompt : String
  target_book_id : String
  cadence_ticks : Int
  quality_threshold : Int
  source_policy : String
  initial_stagger_ticks : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
struct FinalIntegrationTemplateSpec {
  order : Int
  form : String
  path : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub async fn install_wenyu_final_integration(
  manifest_path? : String = "templates/integration/wenyu-final-integration.json",
  snapshot_path? : String = @storage.default_snapshot_path(),
  standing_goal_path? : String = @storage.default_standing_goal_path(),
) -> String {
  let manifest = match load_final_integration_manifest(manifest_path) {
    Some(manifest) => manifest
    None => return "Could not load final integration manifest: \{manifest_path}"
  }
  let current_tick = load_integration_daemon_tick(snapshot_path)
  let existing = @storage.load_or_create_standing_goals(path=standing_goal_path)
  let merged = merge_final_integration_standing_goals(
    existing,
    manifest.domain_watches,
    current_tick,
  )
  @storage.save_standing_goals_file(standing_goal_path, merged)
  let civic_workspace_summary = bootstrap_wenyu_civic_workspaces()
  let protocol_summary = bootstrap_wenyu_building_protocols()
  let install_summaries : Array[String] = []
  for spec in manifest.civic_pattern_manifests {
    install_summaries.push(install_civic_pattern_scenario_manifest(spec.path))
  }
  for spec in manifest.civic_scenarios {
    install_summaries.push(
      install_civic_pattern_scenario_file(spec.path, due_now=false),
    )
  }
  ignore(write_wenyu_civic_status())
  let status = final_integration_status_json(
    manifest, merged, current_tick, civic_workspace_summary, protocol_summary, install_summaries,
  )
  write_text_file(
    ".moontown/integration/\{manifest.id}-status.json",
    status.stringify(indent=2),
  )
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
    "- Status: `.moontown/integration/\{manifest.id}-status.json`",
  ].join("\n")
}

///|
pub async fn render_wenyu_final_integration_status(
  manifest_path? : String = "templates/integration/wenyu-final-integration.json",
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
    "- Domain watch coverage: \{final_integration_watch_coverage(manifest, goals)}\n",
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
    let goal = find_standing_goal_by_id(goals, spec.id)
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

///|
async fn load_final_integration_manifest(
  manifest_path : String,
) -> FinalIntegrationManifest? {
  if !@fs.exists(manifest_path) {
    return None
  }
  let text = @fs.read_file(manifest_path).text() catch { _ => return None }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed)) catch {
    _ => None
  }
}

///|
fn merge_final_integration_standing_goals(
  existing : Array[@core.StandingGoal],
  specs : Array[FinalIntegrationWatchSpec],
  current_tick : Int,
) -> Array[@core.StandingGoal] {
  let merged = existing.copy()
  for spec in specs {
    let next_due_tick = current_tick + max_int(0, spec.initial_stagger_ticks)
    let replacement = @core.StandingGoal::new(
      id=spec.id,
      title=spec.title,
      prompt=spec.prompt,
      target_book_id=Some(spec.target_book_id),
      cadence_ticks=max_int(1, spec.cadence_ticks),
      next_due_tick~,
      last_run_tick=match find_standing_goal_by_id(merged, spec.id) {
        Some(goal) => goal.last_run_tick
        None => None
      },
      enabled=true,
      source_policy=if spec.source_policy.trim().is_empty() {
        "web-first"
      } else {
        spec.source_policy
      },
      quality_threshold=min_int(100, max_int(1, spec.quality_threshold)),
    )
    upsert_standing_goal(merged, replacement)
  }
  merged
}

///|
fn upsert_standing_goal(
  goals : Array[@core.StandingGoal],
  replacement : @core.StandingGoal,
) -> Unit {
  for index, goal in goals {
    if goal.id == replacement.id {
      goals[index] = replacement
      return
    }
  }
  goals.push(replacement)
}

///|
fn find_standing_goal_by_id(
  goals : Array[@core.StandingGoal],
  id : String,
) -> @core.StandingGoal? {
  for goal in goals {
    if goal.id == id {
      return Some(goal)
    }
  }
  None
}

///|
fn final_integration_watch_coverage(
  manifest : FinalIntegrationManifest,
  goals : Array[@core.StandingGoal],
) -> String {
  let mut installed = 0
  for spec in manifest.domain_watches {
    match find_standing_goal_by_id(goals, spec.id) {
      Some(_) => installed += 1
      None => ()
    }
  }
  "\{installed}/\{manifest.domain_watches.length()}"
}

///|
async fn load_integration_daemon_tick(snapshot_path : String) -> Int {
  let base = @path.Path::dirname(snapshot_path).to_string()
  let path = if base == "." || base == "" {
    ".moontown/daemon.json"
  } else {
    "\{base}/daemon.json"
  }
  if !@fs.exists(path) {
    return 0
  }
  let text = @fs.read_file(path).text() catch { _ => return 0 }
  let parsed = @json.parse(text) catch { _ => return 0 }
  let daemon : @scheduler.DaemonState = @json.from_json(parsed) catch {
    _ => return 0
  }
  daemon.tick_sequence
}

///|
fn final_integration_status_json(
  manifest : FinalIntegrationManifest,
  goals : Array[@core.StandingGoal],
  current_tick : Int,
  civic_workspace_summary : String,
  protocol_summary : String,
  install_summaries : Array[String],
) -> Json {
  @json.parse(
    [
      "{",
      "  \"id\": \{json_string(manifest.id)},",
      "  \"title\": \{json_string(manifest.title)},",
      "  \"current_tick\": \{current_tick},",
      "  \"domain_watch_count\": \{manifest.domain_watches.length()},",
      "  \"domain_watch_coverage\": \{json_string(final_integration_watch_coverage(manifest, goals))},",
      "  \"standing_goal_count\": \{goals.length()},",
      "  \"civic_pattern_manifest_count\": \{manifest.civic_pattern_manifests.length()},",
      "  \"civic_scenario_count\": \{manifest.civic_scenarios.length()},",
      "  \"civic_workspace_summary\": \{json_string(civic_workspace_summary)},",
      "  \"protocol_summary\": \{json_string(protocol_summary)},",
      "  \"install_summaries\": \{json_string_array(install_summaries)}",
      "}",
    ].join("\n"),
  ) catch {
    _ => Json::object({})
  }
}

///|
fn max_int(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}

///|
fn min_int(left : Int, right : Int) -> Int {
  if left < right {
    left
  } else {
    right
  }
}
