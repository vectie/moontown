///|
pub async fn bootstrap_civic_salon_scenario_file(
  template_path : String,
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  round_id? : String = "",
  round_number? : Int = 1,
  workspace_base? : String = "",
  reducer_mode? : CivicCommunicationReductionMode = MoonClawReducer,
) -> String {
  match load_civic_salon_scenario_file(template_path) {
    Some(scenario) => {
      let resolved_round_id = civic_pattern_round_id_for_scenario(
        scenario, round_id, round_number,
      )
      let summary = bootstrap_civic_salon_scenario(
        scenario,
        book_catalog_path~,
        round_id=resolved_round_id,
        round_number~,
        workspace_base~,
        reducer_mode~,
      )
      install_civic_salon_scenario_for_daemon(
        scenario, workspace_base, resolved_round_id, round_number, summary,
      )
      summary
    }
    None => "Could not load civic salon scenario template: \{template_path}"
  }
}

///|
pub async fn install_civic_pattern_scenario_file(
  template_path : String,
  snapshot_path? : String = @storage.default_snapshot_path(),
  due_now? : Bool = false,
) -> String {
  match load_civic_salon_scenario_file(template_path) {
    Some(scenario) => {
      let now_ms = @env.now()
      let due_ms = if due_now { now_ms } else { now_ms + 1_800_000UL }
      let schedule = install_civic_pattern_scenario(
        scenario, snapshot_path, due_ms,
      )
      "Installed civic communication pattern `\{schedule.id}` for `\{schedule.building_id}`; next_due_ms=\{schedule.next_due_ms}."
    }
    None =>
      "Could not load civic communication pattern scenario: \{template_path}"
  }
}

///|
fn civic_pattern_round_id_for_scenario(
  scenario : CivicCommunicationScenario,
  round_id : String,
  round_number : Int,
) -> String {
  if round_id.trim().is_empty() {
    "\{scenario.id}-round-\{round_number}"
  } else {
    round_id
  }
}

///|
async fn install_civic_pattern_scenario(
  scenario : CivicCommunicationScenario,
  snapshot_path : String,
  first_due_ms : UInt64,
) -> CivicCommunicationSchedule {
  @support.write_text_file(
    civic_salon_scenario_path(scenario.id, snapshot_path~),
    scenario.to_json().stringify(indent=2),
  )
  upsert_civic_salon_schedule_for_scenario(
    scenario,
    path=default_civic_salon_schedule_path(snapshot_path~),
    now_ms=first_due_ms,
  )
}

///|
async fn install_civic_salon_scenario_for_daemon(
  scenario : CivicCommunicationScenario,
  workspace_base : String,
  round_id : String,
  round_number : Int,
  summary : String,
) -> Unit {
  let snapshot_path = civic_salon_snapshot_path_for_workspace_base(
    workspace_base,
  )
  let now_ms = @env.now()
  let schedule_path = default_civic_salon_schedule_path(snapshot_path~)
  let installed = install_civic_pattern_scenario(
    scenario, snapshot_path, now_ms,
  )
  let next = if summary.has_prefix("Blocked ") {
    retry_civic_salon_schedule(installed, now_ms, round_id, summary)
  } else {
    mark_civic_salon_schedule_after_template_round(
      installed, now_ms, round_id, round_number, summary,
    )
  }
  let schedules = load_or_create_civic_salon_schedules(path=schedule_path)
  save_civic_salon_schedules(
    schedule_path,
    schedules.map(fn(schedule) {
      if schedule.id == scenario.id {
        next
      } else {
        schedule
      }
    }),
  )
}

///|
fn mark_civic_salon_schedule_after_template_round(
  schedule : CivicCommunicationSchedule,
  now_ms : UInt64,
  round_id : String,
  round_number : Int,
  summary : String,
) -> CivicCommunicationSchedule {
  let interval = if schedule.interval_ms < 1UL {
    1_800_000UL
  } else {
    schedule.interval_ms
  }
  {
    ..schedule,
    last_run_ms: now_ms,
    next_due_ms: now_ms + interval,
    round_count: if schedule.round_count > round_number {
      schedule.round_count
    } else {
      round_number
    },
    latest_round_id: round_id,
    latest_summary: summary,
  }
}

///|
fn civic_salon_snapshot_path_for_workspace_base(
  workspace_base : String,
) -> String {
  if workspace_base.trim().is_empty() {
    @storage.default_snapshot_path()
  } else {
    "\{workspace_base}/town.json"
  }
}

///|
async fn load_civic_salon_scenario_file(
  path : String,
) -> CivicCommunicationScenario? {
  let parsed = match @support.read_optional_json_file(path) {
    Some(json) => json
    None => return None
  }
  Some(@json.from_json(parsed)) catch {
    _ => None
  }
}

///|
async fn load_civic_salon_scenario_for_schedule(
  schedule : CivicCommunicationSchedule,
  snapshot_path : String,
) -> CivicCommunicationScenario? {
  let template_path = civic_salon_scenario_path(schedule.id, snapshot_path~)
  load_civic_salon_scenario_file(template_path)
}
