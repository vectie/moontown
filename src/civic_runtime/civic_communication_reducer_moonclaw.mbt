///|
async fn moonclaw_civic_salon_reduction(
  scenario : CivicCommunicationScenario,
  round_id : String,
  round_number : Int,
  workspace_base : String,
  run_inline : Bool,
) -> CivicCommunicationReductionResult {
  let root = civic_salon_workspace_root(
    scenario.building_book_id,
    workspace_base,
  )
  write_civic_salon_reducer_workspace(scenario, root, round_id, round_number)
  let packet_id = "civic-communication-reducer-\{scenario.id}-\{round_id}"
  let packet_path = civic_salon_reducer_packet_path(
    scenario, round_id, workspace_base,
  )
  let packet = civic_salon_reducer_packet(
    scenario, packet_id, round_id, round_number,
  )
  let imported = @moonclaw.import_packet(
    packet,
    packet_path,
    cwd=root,
    confirm=true,
    run_inline~,
  ) catch {
    error =>
      return failed_civic_salon_reduction(
        root,
        Some(packet_id),
        Some(packet_path),
        "MoonClaw reducer import failed for `\{scenario.id}`: \{error}",
      )
  }
  let execution = match imported.run_id {
    Some(run_id) => ensure_run_execution(packet_id, run_id, root)
    None => None
  }
  let status = execution
    .map(fn(result) { result.0.status })
    .unwrap_or(imported.status)
  let worker_summary = execution
    .map(fn(result) { result.0.summary })
    .unwrap_or(imported.summary)
  let ideas = load_civic_salon_reducer_output_after_run(
    scenario,
    workspace_base,
    root,
    imported.run_id,
  )
  if status is @core.TaskExecutionStatus::Completed && ideas.length() > 0 {
    persist_civic_salon_reducer_output(scenario, ideas, workspace_base)
    {
      ideas,
      status,
      summary: "MoonClaw reducer completed with \{ideas.length()} idea(s). \{worker_summary}",
      packet_id: Some(packet_id),
      packet_path: Some(packet_path),
      proposal_id: Some(imported.proposal_id),
      run_id: imported.run_id,
      workspace_root: root,
      reducer_kind: "moonclaw",
    }
  } else if civic_salon_reduction_status_live(status) {
    {
      ideas: [],
      status,
      summary: "MoonClaw reducer is still active for `\{scenario.id}`. status=\{status}; \{worker_summary}",
      packet_id: Some(packet_id),
      packet_path: Some(packet_path),
      proposal_id: Some(imported.proposal_id),
      run_id: imported.run_id,
      workspace_root: root,
      reducer_kind: "moonclaw",
    }
  } else {
    failed_civic_salon_reduction(
      root,
      Some(packet_id),
      Some(packet_path),
      "MoonClaw reducer did not produce a valid non-empty CivicCommunicationIdea contract. status=\{status}; \{worker_summary}",
      proposal_id=Some(imported.proposal_id),
      run_id=imported.run_id,
    )
  }
}
