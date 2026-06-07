///|
fn hydrate_detached_import_handle_if_missing(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  let packet_id = detached_import_packet_id_for_execution(execution)
  let packet_path = detached_import_packet_path_for_execution(execution)
  if packet_id == execution.packet_id && packet_path == execution.packet_path {
    return
  }
  let updated = copy_execution_with(execution, packet_id~, packet_path~)
  state.replace_execution(updated)
  state.replace_task(task_for_supervision(state, updated))
  sync_worker_from_execution(state, updated)
}

///|
fn late_detached_import_receipt_candidate(
  execution : @core.TaskExecutionRecord,
) -> Bool {
  let command_matches = match execution.last_command {
    Some(command) => command.contains(".import.json")
    None => false
  }
  let packet_path = detached_import_packet_path_for_execution(execution)
  let packet_path_matches = !packet_path.trim().is_empty()
  execution.run_id is None &&
  !live_execution_status(execution.status) &&
  execution.result_decision == "deferred-transient-infrastructure" &&
  (command_matches || packet_path_matches)
}

///|
async fn reconcile_detached_import_receipt_if_available(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
  tick : Int,
  launch_confirmed_run? : Bool = true,
  launch_command_override? : String? = None,
) -> Bool {
  let packet_id = detached_import_packet_id_for_execution(execution)
  let packet_path = detached_import_packet_path_for_execution(execution)
  if packet_path.trim().is_empty() {
    return false
  }
  match @moonclaw.detached_import_receipt(packet_id, packet_path) {
    Some(receipt) => {
      let should_launch = launch_confirmed_run &&
        receipt.status == @core.TaskExecutionStatus::RunConfirmed
      let launch_command = match receipt.run_id {
        Some(run_id) if should_launch =>
          match launch_command_override {
            Some(command) => Some(command)
            None =>
              Some(
                @moonclaw.run_confirmed_run(
                  run_id,
                  cwd=book_workspace_root(state, execution.book_id),
                ),
              )
          }
        _ => None
      }
      let summary = match launch_command {
        Some(command) => "\{receipt.summary} Detached runner: \{command}"
        None => receipt.summary
      }
      let updated = copy_execution_with(
        execution,
        packet_id=receipt.packet_id,
        packet_path=receipt.packet_path,
        proposal_id=Some(receipt.proposal_id),
        run_id=receipt.run_id,
        status=receipt.status,
        summary~,
        heartbeat_tick=tick,
        stale_after_tick=tick + polled_execution_stale_window_ticks(execution),
        result_decision=if receipt.status ==
          @core.TaskExecutionStatus::Completed {
          "completed"
        } else {
          execution.result_decision
        },
        requires_review=if receipt.status ==
          @core.TaskExecutionStatus::Completed {
          false
        } else {
          execution.requires_review
        },
      )
      state.replace_execution(updated)
      state.replace_task(task_for_supervision(state, updated))
      sync_worker_from_execution(state, updated)
      true
    }
    None => false
  }
}
