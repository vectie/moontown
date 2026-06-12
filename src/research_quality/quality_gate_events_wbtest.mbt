///|
test "research quality gate messages are package-owned" {
  let summary = research_quality_gate_execution_summary("completed", 2, true)
  assert_eq(summary, "completed / quality_gate_failed=2 / auto_retry=true")
  let detail = research_quality_gate_event_detail(
    "research-opc",
    ["missing source screen", "short deep report"],
    1,
  )
  assert_true(detail.contains("Research quality gate failed for research-opc"))
  assert_true(detail.contains("missing source screen; short deep report"))
  assert_true(detail.contains("mayor marked 1 task(s)"))
  assert_eq(
    recovered_research_bootstrap_execution_summary("worker timeout"),
    "worker timeout / quality_gate_recovered=clean_research_projection",
  )
  assert_true(
    recovered_research_bootstrap_event_detail("research-opc").contains(
      "Research bootstrap for research-opc recovered",
    ),
  )
}
