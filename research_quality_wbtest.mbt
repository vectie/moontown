///|
test "external research topic detector accepts acronym-led reports" {
  assert_true(
    research_text_contains_topic(
      "本报告分析 euv 光刻的 high-na、nil 和 dsa 路线。", "euv-lithography-machine-new-advantages-and-supplements",
    ),
  )
}

///|
test "external deep report word gate applies when source base is broad" {
  let source_screen =
    #|# Source Screen
    #|
    #|| Source ID | Decision |
    #|| --- | --- |
    #|| W1 | include |
    #|| W2 | include |
    #|| W3 | include |
    #|| W4 | include with caution |
    #|| W5 | include |
    #|| W6 | include |
    #|
  let report =
    #|# EUV Lithography Machine New Advantages And Supplements: Deep Research Analysis
    #|
    #|## Executive Summary
    #|EUV research report with enough sources but not enough words.
    #|
  let gaps = deep_report_word_count_gaps(
    "euv-lithography-machine-new-advantages-and-supplements", report, source_screen,
  )
  assert_eq(gaps.length(), 1)
  let gap = gaps[0]
  assert_true(gap.contains("English word tokens"))
  assert_true(gap.contains("6 included screened sources"))
  assert_true(gap.contains("12k-15k English words"))
}

///|
test "external deep report word gate is skipped when source base is thin" {
  let source_screen =
    #|# Source Screen
    #|
    #|| Source ID | Decision |
    #|| --- | --- |
    #|| W1 | include |
    #|| W2 | include |
    #|
  let report =
    #|# EUV Lithography Machine New Advantages And Supplements: Deep Research Analysis
    #|
    #|## Executive Summary
    #|EUV research report with a thin source base.
    #|
  assert_eq(
    deep_report_word_count_gaps(
      "euv-lithography-machine-new-advantages-and-supplements", report, source_screen,
    ).length(),
    0,
  )
}

///|
test "external source depth gate rejects thin source screens" {
  let source_screen =
    #|# Source Screen
    #|
    #|| Source ID | Decision |
    #|| --- | --- |
    #|| W1 | include |
    #|| W2 | include |
    #|
  let gaps = source_depth_quality_gaps(
    "euv-lithography-machine-new-advantages-and-supplements", source_screen,
  )
  assert_eq(gaps.length(), 1)
  assert_true(gaps[0].contains("only 2 included inspected sources"))
  assert_true(gaps[0].contains("at least six"))
}

///|
test "included source count ignores search and index discovery pages" {
  let source_screen =
    #|# Source Screen
    #|
    #|| Source ID | Source type | URL | Decision | Risk |
    #|| --- | --- | --- | --- | --- |
    #|| W1 | web primary | `https://example.com/report` | include | inspected evidence |
    #|| W2 | web research/index | `https://example.com/search?query=euv` | include | search page is discovery-heavy |
    #|| W3 | web market/index | `https://example.org/news-resources` | include | index page, not claim evidence |
    #|| W4 | web independent | `https://example.net/analysis` | include | inspected evidence |
    #|
  assert_eq(count_included_screened_sources(source_screen), 2)
}

///|
test "included source count accepts included sources section without decision column" {
  let source_screen =
    #|# Source Screen
    #|
    #|## Included Sources
    #|
    #|| Source ID | Source type | URL | Include rationale |
    #|| --- | --- | --- | --- |
    #|| W1 | web | `https://example.com/report` | inspected evidence |
    #|| W2 | web | `https://example.com/search?q=euv` | discovery-only search page |
    #|| W3 | web | `https://example.org/analysis` | inspected evidence |
    #|
    #|## Discovery-Only or Candidate Sources
    #|
    #|| Source ID | URL | Decision |
    #|| --- | --- | --- |
    #|| D1 | `https://example.org/index` | discovery_only |
    #|
  assert_eq(count_included_screened_sources(source_screen), 2)
}

///|
test "thin weak native search requires command-line fallback record" {
  let source_screen =
    #|# Source Screen
    #|
    #|| Source ID | Decision |
    #|| --- | --- |
    #|| W1 | include |
    #|
  let search_log =
    #|# Search Log
    #|
    #|| Query | Tool result |
    #|| --- | --- |
    #|| EUV route map | native `web_search` returned DuckDuckGo URL only; weak_search_page |
    #|
  let gaps = source_discovery_fallback_gaps(
    "euv-lithography-machine-new-advantages-and-supplements", search_log, source_screen,
    "",
  )
  assert_eq(gaps.length(), 1)
  assert_true(gaps[0].contains("execute_command/curl fallback"))
}

///|
test "thin weak native search accepts recorded command fallback" {
  let source_screen =
    #|# Source Screen
    #|
    #|| Source ID | Decision |
    #|| --- | --- |
    #|| W1 | include |
    #|
  let search_log =
    #|# Search Log
    #|
    #|| Query | Tool result |
    #|| --- | --- |
    #|| EUV route map | native `web_search` returned DuckDuckGo URL only; weak_search_page |
    #|
    #|## Command Fallback Attempts
    #|
    #|- execute_command: `curl -L --max-time 12 https://example.com/search?q=euv`
    #|
  assert_eq(
    source_discovery_fallback_gaps(
      "euv-lithography-machine-new-advantages-and-supplements", search_log, source_screen,
      "",
    ).length(),
    0,
  )
}

///|
test "quality topic prefers explicit research topic tag over storage id" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-euv-native-quality-v4",
    name="Storage-only book",
    purpose="Research EUV",
    workspace_root="/tmp/research-euv-native-quality-v4",
    tags=[
      "research", "euv-lithography-machine-new-advantages-and-supplements", "topic:euv-lithography-machine-new-advantages-and-supplements",
    ],
  )
  assert_eq(
    quality_topic_for_entry(entry),
    "euv-lithography-machine-new-advantages-and-supplements",
  )
}

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
