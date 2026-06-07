///|
test "evidence accounting separates operational watcher records from domain evidence" {
  let content =
    #|# Evidence
    #|
    #|## Records
    #|
    #|### EV-standing-watch-opc-news-tick-1
    #|
    #|- Task ID: `standing-watch-opc-news-tick-1`
    #|- Status: `accepted`
    #|- Summary: standing_goal_decision: no_change
    #|delta_score: 10
    #|new_source_count: 0
    #|next_check_hint: slower
    #|checked_sources_count: 4
    #|new_sources_found: 1
    #|accepted_facts_count: 0
    #|rejected_facts_count: 1
    #|wiki_pages_changed_count: 0
    #|book_changed: no
    #|
    #|### EV-provider-standing-watch-update
    #|
    #|- Task ID: `provider-standing-watch-update`
    #|- Status: `accepted`
    #|- Summary: standing_goal_decision: update
    #|delta_score: 82
    #|new_source_count: 2
    #|next_check_hint: normal
    #|checked_sources_count: 6
    #|new_sources_found: 3
    #|accepted_facts_count: 2
    #|rejected_facts_count: 1
    #|wiki_pages_changed_count: 2
    #|book_changed: yes
    #|
    #|### EV-source-analysis
    #|
    #|- Task ID: `research-source-analysis`
    #|- Status: `accepted`
    #|- Summary: Added durable source evidence for the current research thesis.
    #|

  let accounting = evidence_accounting_from_text(content)
  assert_eq(accounting.total_count, 3)
  assert_eq(accounting.operational_count, 1)
  assert_eq(accounting.domain_count, 2)
}

///|
test "standing watcher run without marker block is operational evidence" {
  let content =
    #|# Evidence
    #|
    #|## Records
    #|
    #|### EV-standing-watch-llm-training-tick-5502
    #|
    #|- Task ID: `standing-watch-llm-training-tick-5502`
    #|- Status: `accepted`
    #|- Summary: MoonClaw run run-20260526-124123-usersk completed: Workflow completed workspace=/tmp/book/moonclaw-jobs/run-20260526-124123-usersk
    #|

  let accounting = evidence_accounting_from_text(content)
  assert_eq(accounting.total_count, 1)
  assert_eq(accounting.operational_count, 1)
  assert_eq(accounting.domain_count, 0)
}

///|
test "evidence accounting summary appends split counts" {
  let summary = append_evidence_accounting_summary("pages=17 evidence=225", {
    total_count: 225,
    domain_count: 17,
    operational_count: 208,
  })
  assert_true(summary.contains("domain_evidence=17"))
  assert_true(summary.contains("operational_evidence=208"))
  assert_true(summary.contains("total_evidence=225"))
}
