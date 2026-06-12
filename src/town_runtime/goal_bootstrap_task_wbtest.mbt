///|
test "bootstrap ingest prompt keeps Wenyu and research policies separate" {
  let wenyu = bootstrap_ingest_prompt(
    "Build Wenyu Valley AI Innovation Town according to docs/WENYU_VALLEY_PRD.md",
  )
  assert_true(wenyu.contains("../../../docs/WENYU_VALLEY_PRD.md"))
  assert_true(wenyu.contains("must not collapse all Wenyu modules"))
  assert_true(wenyu.contains("web search before local file search"))
  let research = bootstrap_ingest_prompt(
    "Research how LLMs are trained in very detail",
  )
  assert_true(research.contains("Work as a researcher"))
  assert_true(research.contains("every major claim must cite"))
  assert_true(!research.contains("WENYU_VALLEY_PRD"))
}

///|
test "bootstrap ingest target pages compose raw and wiki coverage groups" {
  let raw_pages = bootstrap_ingest_raw_pages()
  let wiki_pages = bootstrap_ingest_wiki_pages()
  let pages = bootstrap_ingest_target_pages()
  assert_eq(raw_pages.length(), 7)
  assert_eq(wiki_pages.length(), 6)
  assert_eq(pages.length(), raw_pages.length() + wiki_pages.length())
  assert_true(pages.contains("raw/bootstrap/source-screen.md"))
  assert_true(pages.contains("raw/bootstrap/evidence-matrix.md"))
  assert_true(pages.contains("wiki/sources"))
  assert_true(pages.contains("wiki/log.md"))
}

///|
test "Wenyu bootstrap clauses keep implementation contract explicit" {
  assert_true(wenyu_bootstrap_scope_clause().contains("WENYU_VALLEY_PRD.md"))
  assert_true(
    wenyu_bootstrap_research_order_clause().contains(
      "web search before local file search",
    ),
  )
  assert_true(wenyu_bootstrap_output_clause().contains("acceptance criteria"))
  assert_true(wenyu_bootstrap_output_clause().contains("risk list"))
  assert_true(wenyu_bootstrap_specificity_clause().contains("specific"))
  assert_true(
    wenyu_bootstrap_specificity_clause().contains("must not collapse"),
  )
}

///|
test "research bootstrap clauses keep evidence-first workflow explicit" {
  assert_true(research_bootstrap_scope_clause().contains("research question"))
  assert_true(
    research_bootstrap_workflow_clause().contains("Work as a researcher"),
  )
  assert_true(
    research_bootstrap_workflow_clause().contains(
      "web search before local file search",
    ),
  )
  assert_true(
    research_bootstrap_workflow_clause().contains(
      "screen authoritative sources",
    ),
  )
  assert_true(
    research_bootstrap_specificity_clause().contains("source ID or local path"),
  )
}
