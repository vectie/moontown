///|
test "external research topic detector accepts acronym-led reports" {
  assert_true(
    research_text_contains_topic(
      "本报告分析 euv 光刻的 high-na、nil 和 dsa 路线。", "euv-lithography-machine-new-advantages-and-supplements",
    ),
  )
}

///|
test "external research topic detector accepts llm training aliases" {
  assert_true(
    research_text_contains_topic(
      "the strongest supported picture is a staged industrial pipeline for large language model training.",
      "how-llm-are-trained-in-very-detail",
    ),
  )
}

///|
test "external deep report word gate applies when source base is broad" {
  let source_screen = included_source_screen(6)
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
  let source_screen = included_source_screen(2)
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
  let source_screen = included_source_screen(2)
  let gaps = source_depth_quality_gaps(
    "euv-lithography-machine-new-advantages-and-supplements", source_screen,
  )
  assert_eq(gaps.length(), 1)
  assert_true(gaps[0].contains("only 2 included inspected sources"))
  assert_true(gaps[0].contains("at least six"))
}

///|
test "external source depth gate centralizes source threshold and applicability" {
  let source_screen = included_source_screen(2)
  let external = inspect_external_source_depth_gate(
    "how-llm-are-trained-in-very-detail", source_screen,
  )
  assert_true(external.applies)
  assert_eq(external.included_sources, 2)
  assert_eq(external.minimum_sources, reference_grade_source_threshold())
  assert_eq(reference_grade_source_threshold(), 6)
  let internal = inspect_external_source_depth_gate("moontown", source_screen)
  assert_false(internal.applies)
  assert_eq(internal.included_sources, 2)
}

///|
test "thin weak native search requires command-line fallback record" {
  let source_screen = included_source_screen(1)
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
  let source_screen = included_source_screen(1)
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
test "quality topic uses civic-owned Wenyu identity" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-town-shell",
    name="Wenyu Valley / Town Shell",
    purpose="Build the town shell.",
    workspace_root="/tmp/wenyu-town-shell",
    tags=["civic-service"],
  )
  assert_eq(quality_topic_for_entry(entry), "town shell")
}
