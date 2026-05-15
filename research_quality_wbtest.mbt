///|
test "OPC deep report rejects repository interpretation" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-opc",
    name="One Person Company",
    purpose="Track OPC",
    workspace_root="/tmp/research-opc",
  )
  let report =
    #|# OPC: Deep Research Analysis
    #|
    #|## Executive Summary
    #|This run inspected github.com/vectie/opc and treated OPC as a MoonBit package.
    #|
    #|## Evidence Table
    #|| Claim | Source |
    #|| --- | --- |
    #|| C1 | W1 |
    #|
    #|## Diagram
    #|```mermaid
    #|graph TD
    #|A[OPC] --> B[MoonBit]
    #|```
    #|
    #|## Market
    #|## Sources
    #|## Risks
    #|## Operations
    #|## Gaps
    #|## Next Research
    #|
  let gaps = deep_report_quality_gaps(entry, report)
  assert_true(
    gaps.contains(
      "OPC report incorrectly treats the lane as a Vectie/local repository",
    ),
  )
  assert_true(
    gaps.contains(
      "OPC report incorrectly treats the lane as a MoonBit software package",
    ),
  )
}

///|
async test "OPC wiki quality rejects runtime entity contamination" {
  let root = "/tmp/moontown-opc-wiki-quality-bad"
  ignore_checked_command("rm", ["-rf", root])
  write_text_file(root + "/wiki/entities/moonclaw.md", "# MoonClaw\n")
  write_text_file(
    root + "/wiki/sources/research-evidence.md",
    "# Research Evidence\n\nOne Person Company evidence.\n",
  )
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-opc",
    name="One Person Company",
    purpose="Track OPC",
    workspace_root=root,
  )
  let gaps = research_wiki_materialization_gaps(entry, root, "opc")
  assert_true(
    gaps.contains(
      "OPC wiki materialization promoted Moon* runtime entities instead of only OPC domain entities",
    ),
  )
  assert_true(
    gaps.contains(
      "missing OPC-specific durable entity page under `wiki/entities/`",
    ),
  )
  assert_true(
    gaps.contains(
      "missing OPC-specific durable concept page under `wiki/concepts/`",
    ),
  )
}

///|
async test "OPC wiki quality accepts topic materialization pages" {
  let root = "/tmp/moontown-opc-wiki-quality-good"
  ignore_checked_command("rm", ["-rf", root])
  write_text_file(root + "/wiki/entities/opc.md", "# One Person Company\n")
  write_text_file(
    root + "/wiki/concepts/opc-research-thesis.md",
    "# OPC Research Thesis\n",
  )
  write_text_file(
    root + "/wiki/sources/research-evidence.md",
    "# Research Evidence\n\nOne Person Company evidence.\n",
  )
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-opc",
    name="One Person Company",
    purpose="Track OPC",
    workspace_root=root,
  )
  assert_eq(research_wiki_materialization_gaps(entry, root, "opc").length(), 0)
}

///|
async test "OPC generated site quality rejects static scaffold" {
  let root = "/tmp/moontown-opc-site-quality-bad"
  ignore_checked_command("rm", ["-rf", root])
  write_text_file(
    root + "/book/site/generated/index.html",
    "<!doctype html><title>LLM Wiki Website</title><h1>Markdown. Wiki. Website.</h1><p>Turn a maintained knowledge workspace into something people can understand.</p>",
  )
  write_text_file(
    root + "/book/site/index.html",
    "<!doctype html><title>LLM Wiki Website</title><h1>Markdown. Wiki. Website.</h1>",
  )
  let gaps = research_generated_site_gaps(root, "opc")
  assert_true(
    gaps.contains(
      "generated marketing projection is still the generic MoonBook scaffold",
    ),
  )
  assert_true(
    gaps.contains(
      "generated marketing projection is not topic-specific for `opc`",
    ),
  )
  assert_true(
    gaps.contains(
      "default marketing entrypoint is still the generic MoonBook scaffold",
    ),
  )
}

///|
async test "OPC generated site quality accepts topic marketing and deep research" {
  let root = "/tmp/moontown-opc-site-quality-good"
  ignore_checked_command("rm", ["-rf", root])
  write_text_file(
    root + "/book/site/generated/index.html",
    "<!doctype html><title>One Person Company (OPC) Marketing Projection</title><h1>Build a real company before you build a full team.</h1><section><p>Deep research</p><h2>One Person Company (OPC): Deep Research Analysis</h2><h3>Executive Summary</h3><table class=\"report-table\"><tr><td>Claim</td></tr></table></section>",
  )
  write_text_file(
    root + "/book/site/index.html",
    "<!doctype html><meta http-equiv=\"refresh\" content=\"0; url=./generated/index.html\"><title>One Person Company (OPC) Marketing Projection</title>",
  )
  assert_eq(research_generated_site_gaps(root, "opc").length(), 0)
}

///|
test "clean research projection recovers late failed bootstrap execution" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="worker-research-opc",
      name="Research Worker",
      book_id="research-opc",
      role=@core.WorkerRole::Harness,
      status=@core.WorkerStatus::Blocked,
    ),
  )
  let task_id = "goal-research-opc-research-bootstrap-ingest"
  state.enqueue_task(
    @core.TownTask::new(
      id=task_id,
      book_id="research-opc",
      title="Bootstrap verified research coverage",
      prompt="research",
      domain=@core.WorkDomain::Research,
      status=@core.TownTaskStatus::Failed,
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id~,
      book_id="research-opc",
      packet_id="packet",
      packet_path="packet.json",
      status=@core.TaskExecutionStatus::Failed,
      summary="worker timeout",
      output_contract="research",
      assigned_worker_id=Some("worker-research-opc"),
    ),
  )
  complete_recovered_research_bootstrap_if_clean(state, "research-opc", [
    task_id,
  ])
  assert_eq(
    @core.find_execution(state, task_id).unwrap().status,
    @core.TaskExecutionStatus::Completed,
  )
  assert_eq(
    @core.find_task(state, task_id).unwrap().status,
    @core.TownTaskStatus::Done,
  )
  assert_eq(state.workers[0].status, @core.WorkerStatus::Idle)
  assert_true(state.events.any(fn(event) { event.kind == "recovery" }))
}
