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
test "included source count accepts heading list entries with decision bullets" {
  let source_screen =
    #|# Source Screen
    #|
    #|ready_for_12k_dossier: true
    #|
    #|## Included Sources
    #|
    #|### W1
    #|- Type: web
    #|- URL: `https://example.com/report`
    #|- Decision: include
    #|- Key claims:
    #|  - Claim one.
    #|
    #|### W2
    #|- Type: web
    #|- URL: `https://example.org/paper`
    #|- Decision: include_with_caution
    #|
    #|## Excluded Or Rejected Sources
    #|
    #|### W3
    #|- Decision: include
    #|
  assert_eq(count_included_screened_sources(source_screen), 2)
}

///|
test "included source count accepts decision bullet entries outside included section" {
  let source_screen =
    #|# Source Screen
    #|
    #|### W1
    #|- URL: `https://example.com/report`
    #|- Decision: include
    #|
    #|### W2
    #|- URL: `https://example.com/search?q=llm`
    #|- Decision: discovery_only
    #|
    #|### W3
    #|- URL: `https://example.org/paper`
    #|- Decision: include_with_caution
    #|
  assert_eq(count_included_screened_sources(source_screen), 2)
}

///|
test "source screen line predicates classify included and non-included sections" {
  assert_eq(
    normalized_markdown_line("  ## Included Sources  "),
    "## included sources",
  )
  assert_true(line_starts_included_sources_section("## included sources"))
  assert_true(line_starts_included_sources_section("### included evidence"))
  assert_true(line_is_section_heading("## excluded sources"))
  assert_true(line_starts_non_included_sources_section("## excluded sources"))
  assert_true(
    line_starts_non_included_sources_section("## discovery-only candidates"),
  )
  assert_false(line_starts_non_included_sources_section("## included sources"))
}

///|
test "source screen decision predicate accepts only substantive include decisions" {
  assert_true(decision_line_includes_source("- decision: include"))
  assert_true(decision_line_includes_source("- decision: include_with_caution"))
  assert_false(decision_line_includes_source("- decision: exclude"))
  assert_false(decision_line_includes_source("- decision: discovery_only"))
  assert_false(decision_line_includes_source("- note: include"))
}
