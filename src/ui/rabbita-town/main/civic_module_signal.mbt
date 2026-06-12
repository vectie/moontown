///|
fn civic_module_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
  running_is_live~ : Bool,
) -> String {
  civic_module_signal_class_for_source(
    model.state_source,
    execution,
    running_is_live~,
  )
}

///|
fn civic_module_signal_class_for_source(
  source : StateSourceKind,
  execution : @core.TaskExecutionRecord?,
  running_is_live~ : Bool,
) -> String {
  if source == StateSourceKind::SnapshotFile {
    "module-signal-neutral"
  } else {
    civic_module_signal_class_for_execution(execution, running_is_live~)
  }
}

///|
fn civic_module_signal_class_for_execution(
  execution : @core.TaskExecutionRecord?,
  running_is_live~ : Bool,
) -> String {
  match execution {
    Some(execution) =>
      civic_module_signal_class_for_status(execution.status, running_is_live~)
    None => "module-signal-book"
  }
}

///|
fn civic_module_signal_class_for_status(
  status : @core.TaskExecutionStatus,
  running_is_live~ : Bool,
) -> String {
  match status {
    @core.TaskExecutionStatus::ReviewQueued
    | @core.TaskExecutionStatus::Failed
    | @core.TaskExecutionStatus::Stale => "module-signal-alert"
    @core.TaskExecutionStatus::AwaitingPersistence => "module-signal-review"
    @core.TaskExecutionStatus::Completed => "module-signal-live"
    @core.TaskExecutionStatus::Running
    | @core.TaskExecutionStatus::RunConfirmed =>
      civic_module_active_run_signal_class(running_is_live)
    @core.TaskExecutionStatus::PacketReady
    | @core.TaskExecutionStatus::ProposalImported => "module-signal-book"
  }
}

///|
fn civic_module_active_run_signal_class(running_is_live : Bool) -> String {
  if running_is_live {
    "module-signal-live"
  } else {
    "module-signal-book"
  }
}
