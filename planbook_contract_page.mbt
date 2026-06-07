///|
fn planbook_contract_markdown() -> String {
  planbook_markdown_page(
    [
      "# Planbook Contract", "", "A planbook exists to make non-trivial change safe, resumable, and reviewable.",
      "", "## Rules", "",
    ],
    [planbook_contract_rules()],
  )
}

///|
fn planbook_contract_rules() -> Array[String] {
  [
    "- Write one durable plan per coherent change area.",
    "- Preserve the decision trail instead of creating noisy `v1`, `v2`, `v3` plan copies.",
    "- Include problem, current state, decision, alternatives, affected files, steps, acceptance criteria, validation, rollback, and follow-up.",
    "- If the task changes Moontown/MoonBook/MoonClaw/Moondesk ownership, state the boundary explicitly.",
    "- Execution must update evidence and review notes before claiming completion.",
    planbook_worker_residency_rule(),
    planbook_bookkeeper_residency_rule(),
    planbook_role_boundary_rule(),
    planbook_watcher_slot_rule(),
    planbook_building_protocol_rule(),
    planbook_durable_growth_rule(),
    "- Quality repair is allowed as review work, but the plan should aim to pass on the first implementation attempt.",
  ]
}

///|
fn planbook_worker_residency_rule() -> String {
  "- MoonClaw workers are freelance bounded executors. They spawn for a job, write result/evidence/artifacts, then leave."
}

///|
fn planbook_bookkeeper_residency_rule() -> String {
  "- MoonBook bookkeepers are resident book roles. They are logically live through scheduled/event-driven keeper ticks and own what becomes memory."
}

///|
fn planbook_role_boundary_rule() -> String {
  "- Mayor owns town-wide routing and supervision; Bookkeepers own book-local memory decisions; Workers own bounded execution only."
}

///|
fn planbook_watcher_slot_rule() -> String {
  [
    "- Every registered book must have a book-scoped watcher slot.", "Standing-watch goals are book-local protocols and should self-heal capacity",
    "instead of deferring forever because an operational book lacks a watcher.",
  ].join(" ")
}

///|
fn planbook_building_protocol_rule() -> String {
  [
    "- Buildings are protocol places. They aggregate, exchange, reduce, review,",
    "and distribute document packets; they are not generic agent containers.",
  ].join(" ")
}

///|
fn planbook_durable_growth_rule() -> String {
  "- Durable growth must be visible as changed books, ledgers, plans, code, tests, projections, or explicit no-change decisions."
}
