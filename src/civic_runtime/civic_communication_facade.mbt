///|
/// Generic name for running due civic communication pattern schedules.
pub async fn run_due_civic_communication_patterns(
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  tick? : Int = 0,
  now_ms? : UInt64 = @env.now(),
  reducer_mode? : CivicCommunicationReductionMode = MoonClawReducer,
  run_inline? : Bool = moontown_moonclaw_inline_enabled(),
) -> String {
  run_due_civic_salons(
    snapshot_path~,
    book_catalog_path~,
    tick~,
    now_ms~,
    reducer_mode~,
    run_inline~,
  )
}

///|
/// Generic name for bootstrapping a civic communication scenario.
pub async fn bootstrap_civic_communication_scenario(
  scenario : CivicCommunicationScenario,
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  round_id? : String = "",
  round_number? : Int = 1,
  workspace_base? : String = "",
  reducer_mode? : CivicCommunicationReductionMode = MoonClawReducer,
) -> String {
  bootstrap_civic_salon_scenario(
    scenario,
    book_catalog_path~,
    round_id~,
    round_number~,
    workspace_base~,
    reducer_mode~,
  )
}

///|
/// Generic name for bootstrapping a scenario template file.
pub async fn bootstrap_civic_communication_scenario_file(
  template_path : String,
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  round_id? : String = "",
  round_number? : Int = 1,
  workspace_base? : String = "",
  reducer_mode? : CivicCommunicationReductionMode = MoonClawReducer,
) -> String {
  bootstrap_civic_salon_scenario_file(
    template_path,
    book_catalog_path~,
    round_id~,
    round_number~,
    workspace_base~,
    reducer_mode~,
  )
}

///|
/// Generic name for rendering communication schedule status.
pub async fn render_civic_communication_schedule_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  render_civic_salon_schedule_status(snapshot_path~)
}
