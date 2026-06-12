///|
test "research bootstrap prompt keeps evidence-first workflow explicit" {
  let prompt = research_bootstrap_ingest_prompt()
  assert_true(prompt.contains("Work as a researcher"))
  assert_true(prompt.contains("web search before local file search"))
  assert_true(prompt.contains("screen authoritative sources"))
  assert_true(prompt.contains("source ID or local path"))
  assert_true(!prompt.contains("WENYU_VALLEY_PRD"))
}

///|
test "research bootstrap target pages compose raw and wiki coverage groups" {
  let raw_pages = research_bootstrap_ingest_raw_pages()
  let wiki_pages = research_bootstrap_ingest_wiki_pages()
  let pages = research_bootstrap_ingest_target_pages()
  assert_eq(raw_pages.length(), 7)
  assert_eq(wiki_pages.length(), 6)
  assert_eq(pages.length(), raw_pages.length() + wiki_pages.length())
  assert_true(pages.contains("raw/bootstrap/source-screen.md"))
  assert_true(pages.contains("raw/bootstrap/evidence-matrix.md"))
  assert_true(pages.contains("wiki/sources"))
  assert_true(pages.contains("wiki/log.md"))
}

///|
test "research bootstrap task uses harness role and ingest contract" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-llm-training",
    name="LLM Training",
    purpose="Research LLM training.",
    workspace_root="/tmp/research-llm-training",
  )
  let task = research_bootstrap_ingest_task(
    entry, " Research how LLMs are trained ",
  )
  assert_eq(task.id, "goal-research-llm-training-research-bootstrap-ingest")
  assert_true(task.goal is Some("Research how LLMs are trained"))
  assert_eq(task.title, "Bootstrap verified research coverage")
  assert_eq(task.kind, "ingest")
  assert_true(task.requires_review)
  assert_true(task.required_role is Some(Harness))
}
