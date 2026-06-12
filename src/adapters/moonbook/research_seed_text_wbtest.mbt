///|
test "research search log seed uses shared blocker artifact paths" {
  let seed = research_search_log_seed_text(
    moonbook_adapter_opc_research_entry(),
  )
  assert_true(seed.contains(research_source_screen_path()))
  assert_true(seed.contains(research_tool_blockers_path()))
  assert_true(seed.contains("Retry `{bad request}` once"))
}

///|
test "external research source hints use shared local artifact path" {
  let hints = research_source_hints_text(moonbook_adapter_opc_research_entry())
  assert_true(hints.contains(research_local_sources_path()))
  assert_true(hints.contains("No local repository is implied"))
  assert_true(hints.contains("## Web Search First"))
}

///|
test "project research question seed still permits local follow-up after web" {
  let entry = moonbook_adapter_catalog_entry(
    id="research-moonbook",
    name="MoonBook",
    purpose="Research MoonBook",
    workspace_root="/tmp/research-moonbook",
  )
  let seed = research_question_seed_text(entry)
  assert_true(seed.contains("Inspect local files only after web discovery"))
  assert_true(!seed.contains("No local repository is implied"))
}
