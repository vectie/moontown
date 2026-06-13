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
test "OPC wiki quality rejects runtime entity contamination" {
  let entry = opc_research_catalog_entry("/tmp/moontown-opc-wiki-quality-bad")
  let gaps = research_wiki_materialization_gaps_from_observation(
    entry,
    "opc",
    research_quality_observation_fixture(
      has_runtime_entity_contamination=true,
      has_topic_entity_page=false,
      has_topic_concept_page=false,
      has_topic_source_page=true,
    ),
  )
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
test "OPC wiki quality accepts topic materialization pages" {
  let entry = opc_research_catalog_entry("/tmp/moontown-opc-wiki-quality-good")
  assert_eq(
    research_wiki_materialization_gaps_from_observation(
      entry,
      "opc",
      research_quality_observation_fixture(),
    ).length(),
    0,
  )
}

///|
test "OPC generated site quality rejects static scaffold" {
  let gaps = research_generated_site_gaps_from_observation(
    "opc",
    research_quality_observation_fixture(
      generated_site=Some(
        "<!doctype html><title>LLM Wiki Website</title><h1>Markdown. Wiki. Website.</h1><p>Turn a maintained knowledge workspace into something people can understand.</p>",
      ),
      site_entry=Some(
        "<!doctype html><title>LLM Wiki Website</title><h1>Markdown. Wiki. Website.</h1>",
      ),
    ),
  )
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
test "OPC generated site quality accepts topic marketing and deep research" {
  assert_eq(
    research_generated_site_gaps_from_observation(
      "opc",
      research_quality_observation_fixture(
        generated_site=Some(
          "<!doctype html><title>One Person Company (OPC) Marketing Projection</title><h1>Build a real company before you build a full team.</h1><section><p>Deep research</p><h2>One Person Company (OPC): Deep Research Analysis</h2><h3>Executive Summary</h3><table class=\"report-table\"><tr><td>Claim</td></tr></table></section>",
        ),
        site_entry=Some(
          "<!doctype html><meta http-equiv=\"refresh\" content=\"0; url=./generated/index.html\"><title>One Person Company (OPC) Marketing Projection</title>",
        ),
      ),
    ).length(),
    0,
  )
}
