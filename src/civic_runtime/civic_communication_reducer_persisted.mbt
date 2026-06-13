///|
async fn persisted_civic_communication_reduction(
  scenario : CivicCommunicationScenario,
  round_id : String,
  workspace_base : String,
) -> CivicCommunicationReductionResult {
  let root = civic_communication_workspace_root(
    scenario.building_book_id,
    workspace_base,
  )
  match
    load_persisted_civic_communication_reducer_output(scenario, workspace_base) {
    Some(loaded) => {
      let ideas = loaded
      CivicCommunicationReductionResult::{
        ideas,
        status: if ideas.length() > 0 {
          @core.TaskExecutionStatus::Completed
        } else {
          @core.TaskExecutionStatus::Failed
        },
        summary: if ideas.length() > 0 {
          "Persisted reducer replayed \{ideas.length()} prior MoonClaw idea(s) for projection refresh of `\{round_id}`."
        } else {
          "Persisted reducer output exists but contains no valid CivicCommunicationIdea records for `\{round_id}`."
        },
        packet_id: None,
        packet_path: None,
        proposal_id: None,
        run_id: None,
        workspace_root: root,
        reducer_kind: "persisted",
      }
    }
    None =>
      {
        ideas: [],
        status: @core.TaskExecutionStatus::Failed,
        summary: "No persisted civic communication reducer output found at `\{@civic.civic_reducer_output_relative_path()}`; refresh skipped instead of falling back to template seed ideas.",
        packet_id: None,
        packet_path: None,
        proposal_id: None,
        run_id: None,
        workspace_root: root,
        reducer_kind: "persisted",
      }
  }
}
