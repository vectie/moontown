///|
async fn reduce_civic_salon_ideas(
  scenario : CivicCommunicationScenario,
  round_id? : String = "civic-salon-round-001",
  round_number? : Int = 1,
  workspace_base? : String = "",
  mode? : CivicCommunicationReductionMode = MoonClawReducer,
  run_inline? : Bool = moontown_moonclaw_inline_enabled(),
) -> CivicCommunicationReductionResult {
  if mode == FixtureReducer {
    fixture_civic_salon_reduction(scenario, round_id, workspace_base)
  } else if mode == PersistedReducer {
    persisted_civic_salon_reduction(scenario, round_id, workspace_base)
  } else {
    moonclaw_civic_salon_reduction(
      scenario, round_id, round_number, workspace_base, run_inline,
    )
  }
}
