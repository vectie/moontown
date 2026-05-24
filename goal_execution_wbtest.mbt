///|
async test "research persistence handoff uses topic artifacts instead of runtime plumbing" {
  let root = "/tmp/moontown-research-persist-handoff"
  ignore_checked_command("rm", ["-rf", root])
  write_text_file(
    root + "/raw/bootstrap/synthesis-brief.md",
    "# Synthesis Brief\n\nOne Person Company (OPC) is an evidence-limited solo-founder operating model.\n",
  )
  write_text_file(
    root + "/raw/bootstrap/source-screen.md",
    "# Source Screen\n\n| Source ID | Decision |\n| --- | --- |\n| W1 | include |\n",
  )
  write_text_file(
    root + "/raw/bootstrap/evidence-matrix.md",
    "# Evidence Matrix\n\n| Claim ID | Claim |\n| --- | --- |\n| C1 | OPC uses leverage. |\n",
  )
  write_text_file(
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
  assert_eq(candidates[0].target_page, Some("sources/opc-screened-sources.md"))
  assert_eq(candidates[1].target_page, Some("entities/opc.md"))
  assert_eq(candidates[2].target_page, Some("concepts/opc-research-thesis.md"))
  assert_eq(candidates[3].target_page, Some("synthesis/opc-research-thesis.md"))
}

///|
test "moonclaw supervision seconds parser accepts only positive integers" {
  assert_eq(parse_positive_seconds("900", fallback=3600), 900)
  assert_eq(parse_positive_seconds(" 1800 ", fallback=3600), 1800)
  assert_eq(parse_positive_seconds("", fallback=3600), 3600)
  assert_eq(parse_positive_seconds("0", fallback=3600), 3600)
  assert_eq(parse_positive_seconds("10m", fallback=3600), 3600)
}
