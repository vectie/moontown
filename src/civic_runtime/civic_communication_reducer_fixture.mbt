///|
async fn fixture_civic_salon_reduction(
  scenario : CivicCommunicationScenario,
  round_id : String,
  workspace_base : String,
) -> CivicCommunicationReductionResult {
  let ideas = scenario.ideas
  persist_civic_salon_reducer_output(scenario, ideas, workspace_base)
  {
    ideas,
    status: if ideas.length() > 0 {
      @core.TaskExecutionStatus::Completed
    } else {
      @core.TaskExecutionStatus::Failed
    },
    summary: "Fixture reducer loaded \{ideas.length()} template idea(s) for explicit deterministic smoke execution of `\{round_id}`.",
    packet_id: None,
    packet_path: None,
    proposal_id: None,
    run_id: None,
    workspace_root: civic_salon_workspace_root(
      scenario.building_book_id,
      workspace_base,
    ),
    reducer_kind: "fixture",
  }
}
