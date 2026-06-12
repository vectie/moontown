///|
fn goal_run_research_entry(
  id~ : String,
  name~ : String,
  workspace_root~ : String,
  purpose? : String = "test",
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(id~, name~, purpose~, workspace_root~)
}

///|
fn goal_run_wenyu_entry(
  id~ : String,
  name~ : String,
  workspace_root~ : String,
  purpose? : String = "test",
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(id~, name~, purpose~, workspace_root~)
}

///|
fn goal_run_wenyu_policy_hall_entry() -> @moonbook.BookCatalogEntry {
  goal_run_wenyu_entry(
    id="wenyu-policy-hall",
    name="Wenyu Valley / Policy Hall",
    workspace_root="/tmp/wenyu-policy-hall",
  )
}

///|
fn goal_run_wenyu_town_shell_entry() -> @moonbook.BookCatalogEntry {
  goal_run_wenyu_entry(
    id="wenyu-town-shell",
    name="Wenyu Valley / Town Shell",
    workspace_root="/tmp/wenyu-town-shell",
  )
}

///|
fn goal_run_wenyu_bootstrap_like_task() -> @moonbook.BookTask {
  @moonbook.BookTask::new(
    id="goal-wenyu-policy-hall-research-bootstrap-ingest",
    title="Bootstrap research",
    kind="research-bootstrap-ingest",
    prompt="Research Wenyu Valley Policy Hall.",
    priority=999,
    requires_review=false,
  )
}

///|
fn goal_run_test_state() -> @core.TownState {
  @core.empty_state(@core.TownConfig::new(id="test", name="Test Town"))
}

///|
fn goal_run_book_summary(
  book_id~ : String,
  root? : String = "/tmp/goal-run-book",
  page_count? : Int = 4,
  source_count? : Int = 1,
  entity_count? : Int = 1,
  concept_count? : Int = 1,
  pending_review_count? : Int = 0,
  keeper_memory_count? : Int = 0,
  keeper_working_count? : Int = 0,
  evidence_count? : Int = 1,
  total_evidence_count? : Int = evidence_count,
  operational_evidence_count? : Int = total_evidence_count - evidence_count,
  summary? : String = "goal run summary",
) -> @moonbook.BookStateSummary {
  @moonbook.BookStateSummary::new(
    book_id~,
    root~,
    page_count~,
    source_count~,
    entity_count~,
    concept_count~,
    pending_review_count~,
    keeper_memory_count~,
    keeper_working_count~,
    evidence_count~,
    total_evidence_count~,
    operational_evidence_count~,
    summary~,
  )
}

///|
fn goal_run_research_shaped_report() -> String {
  goal_run_deep_report_fixture(
    title="MoonBook: Deep Research Analysis",
    executive_summary="MoonBook is a lane-specific research subject.",
    architecture_role="Book | Memory",
    implementation_section=None,
  )
}

///|
fn goal_run_wenyu_deep_report() -> String {
  goal_run_deep_report_fixture(
    title="Town Shell: Deep Research Analysis",
    executive_summary="The town shell is the operator surface for Wenyu Valley.",
    architecture_role="Shell | Runtime projection",
    implementation_section=Some("## Implementation\n\nText.\n"),
  )
}

///|
fn goal_run_deep_report_fixture(
  title~ : String,
  executive_summary~ : String,
  architecture_role~ : String,
  implementation_section~ : String?,
) -> String {
  [
    "# \{title}",
    "",
    "## Executive Summary",
    "",
    executive_summary,
    "",
    "## Context",
    "",
    "Text.",
    "",
    "## Architecture",
    "",
    "| Layer | Role |",
    "| --- | --- |",
    "|\{architecture_role}|",
    "",
    "## Evidence",
    "",
    "Text.",
    "",
    implementation_section.unwrap_or(""),
    "## Integration",
    "",
    "```mermaid",
    "flowchart TB",
    "A-->B",
    "```",
    "",
    "## Maturity",
    "",
    "Text.",
    "",
    "## Risks",
    "",
    "Text.",
    "",
    "## Trajectory",
    "",
    "Text.",
  ].join("\n")
}

///|
fn goal_run_shallow_process_report() -> String {
  [
    "# Run Notes", "", "## Summary", "", "This run is pending enrichment and has placeholder notes.",
  ].join("\n")
}

///|
fn goal_run_lane_execution(
  task_id~ : String,
  book_id~ : String,
  status~ : @core.TaskExecutionStatus,
  summary~ : String,
  output_contract? : String = "test",
  packet_id? : String = "",
) -> @core.TaskExecutionRecord {
  let resolved_packet_id = if packet_id == "" {
    "packet-\{task_id}"
  } else {
    packet_id
  }
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id~,
    packet_id=resolved_packet_id,
    packet_path="\{resolved_packet_id}.json",
    status~,
    summary~,
    output_contract~,
  )
}
