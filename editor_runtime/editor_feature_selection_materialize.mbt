///|
async fn materialize_editor_feature_selection_task(
  snapshot_path : String,
  workspace_root : String,
  dispatch : Bool,
) -> EditorFeatureSelectionTask {
  ignore(snapshot_path)
  let workspace_root = editor_feature_absolute_path(workspace_root)
  let task_id = "editor-feature-selection"
  let packet_path = editor_feature_selection_packet_path(
    workspace_root, task_id,
  )
  let result_path = editor_feature_selection_result_path(workspace_root)
  write_editor_feature_selection_workspace(workspace_root)
  let packet = editor_feature_selection_packet(task_id, result_path)
  let mut proposal_id : String? = None
  let mut run_id : String? = None
  let mut status = "queued"
  let mut summary = "Queued bounded MoonClaw selection packet. The AI must read the course book and choose the lowest-scoring missing editor feature; Moontown does not choose the feature name."
  if dispatch {
    let imported = @moonclaw.import_packet(
      packet,
      packet_path,
      home="\{workspace_root}/.moonclaw",
      cwd=workspace_root,
      confirm=true,
      run_inline=moontown_moonclaw_inline_enabled(),
    ) catch {
      error =>
        return {
          id: task_id,
          status: "blocked",
          workspace_root,
          packet_path,
          result_path,
          proposal_id: None,
          run_id: None,
          summary: "MoonClaw feature-selection dispatch failed: \{error}",
          generated_at_ms: @env.now(),
        }
    }
    proposal_id = Some(imported.proposal_id)
    run_id = imported.run_id
    let launch_command = match imported.run_id {
      Some(run_id) if !moontown_moonclaw_inline_enabled() =>
        Some(
          @moonclaw.run_confirmed_run(
            run_id,
            home="\{workspace_root}/.moonclaw",
            cwd=workspace_root,
          ),
        )
      _ => None
    }
    status = if imported.run_id is Some(_) { "dispatched" } else { "queued" }
    summary = match launch_command {
      Some(command) => "\{imported.summary} Detached runner: \{command}"
      None => imported.summary
    }
  } else {
    @moonclaw.save_packet_file(packet_path, packet)
  }
  {
    id: task_id,
    status,
    workspace_root,
    packet_path,
    result_path,
    proposal_id,
    run_id,
    summary,
    generated_at_ms: @env.now(),
  }
}
