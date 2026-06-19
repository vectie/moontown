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
    ReviewQueued
    | Failed
    | Stale => "module-signal-alert"
    AwaitingPersistence => "module-signal-review"
    Completed => "module-signal-live"
    Running
    | RunConfirmed =>
      civic_module_active_run_signal_class(running_is_live)
    PacketReady
    | ProposalImported => "module-signal-book"
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
