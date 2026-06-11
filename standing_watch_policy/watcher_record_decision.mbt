///|
pub fn watcher_record_effective_decision(
  record : @core.WatcherRunRecord,
) -> @core.WatcherDecisionKind {
  if standing_watch_orphaned_running_failure_summary(record.detail) &&
    watcher_record_has_zero_material_delta(record) {
    return @core.WatcherDecisionKind::Deferred
  }
  if record.decision == @core.WatcherDecisionKind::Failed &&
    watcher_record_has_zero_material_delta(record) &&
    standing_watch_detached_import_log_noise_summary(record.detail) {
    return @core.WatcherDecisionKind::Deferred
  }
  if record.decision == @core.WatcherDecisionKind::Failed &&
    watcher_record_has_zero_material_delta(record) &&
    standing_watch_infrastructure_failure_summary(record.detail) &&
    @runtime_error_policy.transient_external_dependency_error(record.detail) {
    return @core.WatcherDecisionKind::Deferred
  }
  if record.decision != @core.WatcherDecisionKind::NeedsReview {
    return record.decision
  }
  if watcher_record_has_zero_material_delta(record) &&
    standing_watch_operational_no_change_summary(record.detail) {
    return @core.WatcherDecisionKind::NoChange
  }
  if watcher_record_has_zero_material_delta(record) &&
    standing_watch_infrastructure_failure_summary(record.detail) {
    return @core.WatcherDecisionKind::Failed
  }
  record.decision
}

///|
pub fn watcher_record_has_zero_material_delta(
  record : @core.WatcherRunRecord,
) -> Bool {
  record.delta_score == 0 && record.new_source_count == 0
}

///|
fn watcher_record_same_terminal_identity(
  left : @core.WatcherRunRecord,
  right : @core.WatcherRunRecord,
) -> Bool {
  left.goal_id == right.goal_id &&
  left.tick == right.tick &&
  left.task_id == right.task_id &&
  left.run_id == right.run_id
}

///|
fn watcher_record_observation_quality(record : @core.WatcherRunRecord) -> Int {
  if record.decision == @core.WatcherDecisionKind::Deferred {
    return 0
  }
  if record.detail.contains("standing_goal_decision:") ||
    record.detail.contains("standing_goal_decision=") ||
    record.detail.contains("book_watch_record_id:") {
    return 4
  }
  if record.decision == @core.WatcherDecisionKind::NeedsReview &&
    record.delta_score == 0 &&
    record.new_source_count == 0 &&
    record.detail.contains("Workflow completed") {
    return 1
  }
  if watcher_record_effective_decision(record) != record.decision {
    return 3
  }
  2
}

///|
pub fn watcher_record_prefer_candidate(
  current : @core.WatcherRunRecord,
  candidate : @core.WatcherRunRecord,
) -> Bool {
  if candidate.tick > current.tick {
    return true
  }
  if candidate.tick < current.tick {
    return false
  }
  if watcher_record_same_terminal_identity(current, candidate) {
    return watcher_record_observation_quality(candidate) >
      watcher_record_observation_quality(current)
  }
  true
}
