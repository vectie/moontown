///|
async fn load_civic_salon_reducer_output_after_run(
  scenario : CivicSalonScenario,
  workspace_base : String,
  root : String,
  run_id : String?,
) -> Array[CivicSalonIdea] {
  let run_ideas = match run_id {
    Some(run_id) =>
      load_civic_salon_reducer_run_output(run_id, root).unwrap_or([])
    None => []
  }
  if run_ideas.length() > 0 {
    persist_civic_salon_reducer_output(scenario, run_ideas, workspace_base)
    return run_ideas
  }
  match load_persisted_civic_salon_reducer_output(scenario, workspace_base) {
    Some(ideas) => ideas
    None => []
  }
}

///|
async fn load_civic_salon_reducer_run_output(
  run_id : String,
  root : String,
) -> Array[CivicSalonIdea]? {
  let workspace_dir = match @moonclaw.run_workspace_dir(run_id, cwd=root) {
    Some(workspace_dir) => workspace_dir
    None => return None
  }
  load_civic_salon_ideas_file(
    civic_salon_reducer_output_path_in_workspace(workspace_dir),
  )
}

///|
async fn load_persisted_civic_salon_reducer_output(
  scenario : CivicSalonScenario,
  workspace_base : String,
) -> Array[CivicSalonIdea]? {
  match
    load_civic_salon_ideas_file(
      civic_salon_scenario_output_path(scenario, workspace_base),
    ) {
    Some(ideas) => return Some(ideas)
    None => ()
  }
  load_civic_salon_ideas_file(
    civic_salon_reducer_output_path(scenario, workspace_base),
  )
}

///|
async fn load_civic_salon_ideas_file(path : String) -> Array[CivicSalonIdea]? {
  let parsed = match @support.read_optional_json_file(path) {
    Some(json) => json
    None => return None
  }
  let ideas = match parsed {
    Array(_) => {
      let values : Array[CivicSalonIdea] = @json.from_json(parsed) catch {
        _ => return None
      }
      values
    }
    Object(object) =>
      match object.get("ideas") {
        Some(value) => {
          let values : Array[CivicSalonIdea] = @json.from_json(value) catch {
            _ => return None
          }
          values
        }
        _ => return None
      }
    _ => return None
  }
  Some(ideas)
}

///|
async fn persist_civic_salon_reducer_output(
  scenario : CivicSalonScenario,
  ideas : Array[CivicSalonIdea],
  workspace_base : String,
) -> Unit {
  @support.write_text_file(
    civic_salon_reducer_output_path(scenario, workspace_base),
    Json::object({ "ideas": ideas.to_json() }).stringify(indent=2),
  )
  @support.write_text_file(
    civic_salon_scenario_output_path(scenario, workspace_base),
    Json::object({ "ideas": ideas.to_json() }).stringify(indent=2),
  )
}

///|
fn civic_salon_scenario_output_path(
  scenario : CivicSalonScenario,
  workspace_base : String,
) -> String {
  "\{civic_salon_workspace_root(scenario.building_book_id, workspace_base)}/raw/bootstrap/\{scenario.id}-ideas.json"
}

///|
async fn write_civic_salon_reducer_blocker(
  scenario : CivicSalonScenario,
  reduction : CivicSalonReductionResult,
  round_id : String,
) -> Unit {
  @support.write_text_file(
    "\{reduction.workspace_root}/\{@civic.civic_reducer_blocker_relative_path()}",
    [
      "# Civic Communication Reducer Blocker",
      "",
      "- Scenario: `\{scenario.id}`",
      "- Round: `\{round_id}`",
      "- Reducer: `\{reduction.reducer_kind}`",
      "- Status: `\{reduction.status}`",
      "",
      reduction.summary,
      "",
      "Moontown did not fall back to template seed ideas. The next retry must run the MoonClaw reducer or use an explicit fixture mode in tests.",
    ].join("\n"),
  )
}
