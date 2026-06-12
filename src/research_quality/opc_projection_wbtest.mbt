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
  let root = cleaned_research_quality_test_root(
    "/tmp/moontown-opc-wiki-quality-bad",
  )
  @support.write_text_file(root + "/wiki/entities/moonclaw.md", "# MoonClaw\n")
  @support.write_text_file(
    root + "/wiki/sources/research-evidence.md",
    "# Research Evidence\n\nOne Person Company evidence.\n",
  )
  let entry = opc_research_catalog_entry(root)
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
  let root = cleaned_research_quality_test_root(
    "/tmp/moontown-opc-wiki-quality-good",
  )
  @support.write_text_file(
    root + "/wiki/entities/opc.md",
    "# One Person Company\n",
  )
  @support.write_text_file(
    root + "/wiki/concepts/opc-research-thesis.md",
    "# OPC Research Thesis\n",
  )
  @support.write_text_file(
    root + "/wiki/sources/research-evidence.md",
    "# Research Evidence\n\nOne Person Company evidence.\n",
  )
  let entry = opc_research_catalog_entry(root)
  assert_eq(research_wiki_materialization_gaps(entry, root, "opc").length(), 0)
}

///|
async test "OPC generated site quality rejects static scaffold" {
  let root = cleaned_research_quality_test_root(
    "/tmp/moontown-opc-site-quality-bad",
  )
  assert_eq(
    research_quality_generated_site_path(),
    @policy.default_generated_site_projection_path(),
  )
  @support.write_text_file(
    research_quality_generated_site_workspace_path(root),
    "<!doctype html><title>LLM Wiki Website</title><h1>Markdown. Wiki. Website.</h1><p>Turn a maintained knowledge workspace into something people can understand.</p>",
  )
  @support.write_text_file(
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
  let root = cleaned_research_quality_test_root(
    "/tmp/moontown-opc-site-quality-good",
  )
  @support.write_text_file(
    research_quality_generated_site_workspace_path(root),
    "<!doctype html><title>One Person Company (OPC) Marketing Projection</title><h1>Build a real company before you build a full team.</h1><section><p>Deep research</p><h2>One Person Company (OPC): Deep Research Analysis</h2><h3>Executive Summary</h3><table class=\"report-table\"><tr><td>Claim</td></tr></table></section>",
  )
  @support.write_text_file(
    root + "/book/site/index.html",
    "<!doctype html><meta http-equiv=\"refresh\" content=\"0; url=./generated/index.html\"><title>One Person Company (OPC) Marketing Projection</title>",
  )
  assert_eq(research_generated_site_gaps(root, "opc").length(), 0)
}
