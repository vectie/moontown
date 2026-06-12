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
test "Wenyu bootstrap task uses build-readiness contract" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-town-shell",
    name="Wenyu Valley / Town Shell",
    purpose="Build town shell.",
    workspace_root="/tmp/wenyu-town-shell",
  )
  let task = wenyu_bootstrap_ingest_task(
    entry, " Build Wenyu Valley AI Innovation Town ",
  )
  assert_eq(task.id, "goal-wenyu-town-shell-research-bootstrap-ingest")
  assert_true(task.goal is Some("Build Wenyu Valley AI Innovation Town"))
  assert_eq(task.title, "Bootstrap Wenyu Valley module coverage")
  assert_eq(task.kind, "ingest")
  assert_true(task.prompt.contains("../../../docs/WENYU_VALLEY_PRD.md"))
  assert_true(task.prompt.contains("must not collapse all Wenyu modules"))
  assert_true(task.prompt.contains("web search before local file search"))
  assert_true(task.target_pages.contains("raw/bootstrap/source-screen.md"))
  assert_true(task.required_role is Some(Harness))
}
