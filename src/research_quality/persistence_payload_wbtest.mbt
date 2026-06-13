///|
async test "research persistence handoff uses topic artifacts instead of runtime plumbing" {
  let root = "/tmp/moontown-research-persist-handoff"
  @support.ignore_checked_command("rm", ["-rf", root])
  @support.write_text_file(
    root + "/raw/bootstrap/synthesis-brief.md",
    "# Synthesis Brief\n\nOne Person Company (OPC) is an evidence-limited solo-founder operating model.\n",
  )
  @support.write_text_file(
    root + "/raw/bootstrap/source-screen.md",
    "# Source Screen\n\n| Source ID | Decision |\n| --- | --- |\n| W1 | include |\n",
  )
  @support.write_text_file(
    root + "/raw/bootstrap/evidence-matrix.md",
    "# Evidence Matrix\n\n| Claim ID | Claim |\n| --- | --- |\n| C1 | OPC uses leverage. |\n",
  )
  @support.write_text_file(
    root + "/raw/bootstrap/deep-report.md",
    "# One Person Company (OPC): Deep Research Analysis\n\n## Executive Summary\n\nOPC research summary.\n",
  )
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-opc",
    name="One Person Company",
    purpose="Track OPC",
    workspace_root=root,
  )
  let execution = @core.TaskExecutionRecord::new(
    task_id="goal-research-opc-research-bootstrap-ingest",
    book_id="research-opc",
    packet_id="packet-opc",
    packet_path="packet-opc.json",
    run_id=Some("run-opc"),
    status=@core.TaskExecutionStatus::Completed,
    summary="MoonClaw run run-opc completed: Workflow completed",
    output_contract="moontown.research.raw.v1",
  )
  let summary = research_persist_summary(entry, execution)
  assert_true(summary.contains("One Person Company (OPC)"))
  assert_true(!summary.contains("MoonClaw run"))
  let artifacts = research_persist_artifacts(entry, execution)
  assert_true(artifacts.contains("raw/bootstrap/deep-report.md"))
  let candidates = research_persist_memory_candidates(entry, execution)
  assert_eq(candidates.length(), 4)
  assert_true(
    candidates[0].target_page == Some("sources/opc-screened-sources.md"),
  )
  assert_true(candidates[1].target_page == Some("entities/opc.md"))
  assert_true(
    candidates[2].target_page == Some("concepts/opc-research-thesis.md"),
  )
  assert_true(
    candidates[3].target_page == Some("synthesis/opc-research-thesis.md"),
  )
  @support.ignore_checked_command("rm", ["-rf", root])
}

///|
async test "research persistence handoff accepts tagged research book" {
  let root = "/tmp/moontown-tagged-research-persist-handoff"
  @support.ignore_checked_command("rm", ["-rf", root])
  @support.write_text_file(
    root + "/raw/bootstrap/synthesis-brief.md",
    "# Synthesis Brief\n\nTagged OPC synthesis.\n",
  )
  let entry = @moonbook.BookCatalogEntry::new(
    id="opc-lab",
    name="OPC Lab",
    purpose="Track OPC",
    workspace_root=root,
    tags=["research", "topic:opc"],
  )
  let execution = @core.TaskExecutionRecord::new(
    task_id="goal-opc-lab-research-bootstrap-ingest",
    book_id="opc-lab",
    packet_id="packet-opc",
    packet_path="packet-opc.json",
    status=@core.TaskExecutionStatus::Completed,
    summary="completed",
    output_contract="moontown.research.raw.v1",
  )
  let summary = research_persist_summary(entry, execution)
  assert_true(summary.contains("Research bootstrap completed"))
  let artifacts = research_persist_artifacts(entry, execution)
  assert_true(artifacts.contains("raw/bootstrap/deep-report.md"))
  @support.ignore_checked_command("rm", ["-rf", root])
}
