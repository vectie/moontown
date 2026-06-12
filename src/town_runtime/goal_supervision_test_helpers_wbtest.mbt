///|
async fn cleaned_goal_supervision_test_root(root : String) -> String {
  @support.ignore_checked_command("rm", ["-rf", root])
  root
}

///|
fn goal_supervision_test_state() -> @core.TownState {
  @core.empty_state(@core.TownConfig::new(id="test", name="Test Town"))
}

///|
fn detached_import_receipt_json(status? : String = "") -> String {
  if status == "" {
    "{\"proposal_id\":\"proposal-detached\",\"run_id\":\"run-detached\"}"
  } else {
    "{\"proposal_id\":\"proposal-detached\",\"run_id\":\"run-detached\",\"status\":\"\{status}\"}"
  }
}

///|
fn running_standing_watch_task(
  task_id : String,
  book_id : String,
) -> @core.TownTask {
  @core.TownTask::new(
    id=task_id,
    book_id~,
    title="Standing watch",
    prompt="watch",
    domain=@core.WorkDomain::Research,
    status=@core.TownTaskStatus::Running,
  )
}

///|
fn running_snapshot_execution_without_run_id(
  task_id : String,
  book_id : String,
  summary : String,
  heartbeat_tick : Int,
  stale_after_tick : Int,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id~,
    packet_id="pending",
    packet_path="",
    run_id=None,
    status=@core.TaskExecutionStatus::Running,
    summary~,
    output_contract="standing-watch-live-snapshot",
    assigned_worker_id=Some("watcher"),
    heartbeat_tick~,
    stale_after_tick~,
  )
}

///|
fn research_opc_book_entry(book_root : String) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id="research-opc",
    name="Research OPC",
    purpose="watch opc",
    workspace_root=book_root,
  )
}

///|
fn research_opc_book_ref(
  workspace_root : String,
  purpose? : String = "Watch OPC",
) -> @core.BookRef {
  @core.BookRef::new(
    id="research-opc",
    name="Research OPC",
    purpose~,
    workspace_root~,
  )
}

///|
fn goal_supervision_book_entry(
  id~ : String,
  name~ : String,
  purpose~ : String,
  workspace_root~ : String,
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(id~, name~, purpose~, workspace_root~)
}

///|
fn standing_watch_goal_fixture(
  id~ : String,
  title~ : String,
  prompt~ : String,
  book_id~ : String,
  cadence_ticks? : Int = 60,
  quality_threshold? : Int = 80,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id~,
    title~,
    prompt~,
    target_book_id=Some(book_id),
    cadence_ticks~,
    quality_threshold~,
  )
}

///|
fn standing_watch_execution_fixture(
  task_id~ : String,
  book_id? : String = "research-opc",
  packet_id? : String = "packet",
  packet_path~ : String,
  status~ : @core.TaskExecutionStatus,
  summary~ : String,
  heartbeat_tick? : Int = 10,
  stale_after_tick? : Int = 40,
  result_decision? : String = "",
  last_command? : String? = None,
  run_id? : String? = None,
  requires_review? : Bool = false,
  assigned_worker_id? : String? = None,
  next_retry_tick? : Int? = None,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id~,
    packet_id~,
    packet_path~,
    run_id~,
    status~,
    summary~,
    output_contract="standing-watch",
    heartbeat_tick~,
    stale_after_tick~,
    result_decision~,
    last_command~,
    requires_review~,
    assigned_worker_id~,
    next_retry_tick~,
  )
}

///|
fn review_queued_standing_watch_execution(
  task_id : String,
  book_id : String,
  packet_id : String,
  packet_path : String,
  run_id : String,
  summary : String,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id~,
    packet_id~,
    packet_path~,
    run_id=Some(run_id),
    status=@core.TaskExecutionStatus::ReviewQueued,
    summary~,
    output_contract="standing-watch",
    result_decision="NeedsReview",
    requires_review=true,
  )
}

///|
fn completed_no_change_standing_watch_execution(
  task_id~ : String,
  book_id~ : String,
  packet_id~ : String,
  packet_path~ : String,
  run_id~ : String,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id~,
    packet_id~,
    packet_path~,
    run_id=Some(run_id),
    status=@core.TaskExecutionStatus::Completed,
    summary="standing_goal_decision: no_change\ndelta_score: 0\nnew_source_count: 0\nkeeper_auto_triage: accepted",
    output_contract="standing-watch",
    result_decision="NoChange",
    requires_review=false,
  )
}

///|
async fn write_standing_watch_history_marker(
  book_root : String,
  marker : String,
  decision : String,
  delta_score : Int,
  new_source_count : Int,
  book_changed : String,
  next_check_hint? : String = "slower",
  checked_sources_count? : Int = 5,
  new_sources_found? : Int = 1,
  accepted_facts_count? : Int = 0,
  rejected_facts_count? : Int = 1,
  wiki_pages_changed_count? : Int = 0,
) -> Unit {
  @support.write_text_file(
    "\{book_root}/wiki/history/standing-watch.md",
    [
      "### \{marker}",
      "- Decision: `\{decision}`",
      "- Delta score: `\{delta_score}`",
      "- New source count: `\{new_source_count}`",
      "- Next check hint: `\{next_check_hint}`",
      "- Checked sources count: `\{checked_sources_count}`",
      "- New sources found: `\{new_sources_found}`",
      "- Accepted facts count: `\{accepted_facts_count}`",
      "- Rejected facts count: `\{rejected_facts_count}`",
      "- Wiki pages changed count: `\{wiki_pages_changed_count}`",
      "- Book changed: `\{book_changed}`",
      "- Summary: standing_goal_decision: \{decision}",
      "delta_score: \{delta_score}",
      "new_source_count: \{new_source_count}",
      "book_changed: \{book_changed}",
    ].join("\n"),
  )
}
