///|
fn civic_generic_service_rules_section() -> String {
  civic_skill_section("Rules", civic_generic_service_rules().join("\n"))
}

///|
fn civic_generic_service_rules() -> Array[String] {
  [
    "- Read `raw/bootstrap/CIVIC_SERVICE_CONTRACT.md` and `raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md` before acting.",
    "- First identify the module mode: agent-workspace, exchange-place, projection-surface, gateway, or hybrid.",
    "- Then identify the persistence mode: workspace-backed, ledger-backed, projection-backed, handoff-ledger-backed, or mixed-memory-backed.",
    "- Do not force every civic module into research. Use research only when the module-specific skill asks for source discovery or evidence verification.",
    "- Choose the next useful service action from current book state, place state, and review gates; do not follow a fixed script.",
    "- For exchange-place modules, produce consent, ledger, match, request, or follow-up records rather than long reports.",
    "- For projection-surface modules, produce status, freshness, anomaly, and recovery records rather than domain research.",
    "- For gateway modules, produce confirmation-gated handoff packets and blockers; never imply external execution happened without approval.",
    "- For agent-workspace modules, produce the domain-specific artifact named by the dedicated skill pack.",
    "- Treat the building as a protocol place: map inputs into contributions, group compatible contributions, reduce them into a module-native output, and distribute only through allowed channels.",
    "- Use source evidence for knowledge claims and record source gaps clearly when knowledge claims are part of the module work.",
    "- Persist durable results to the MoonBook role defined in the contract and projection summaries to `book/moonbook-ui-state.json` only through review-safe records.",
    "- If the persistence mode is ledger-backed or projection-backed, prefer compact records and summaries over wiki essays.",
    "- Queue review for public, legal, financial, personal, booking, robot, or offline-impact actions.",
    "- Separate operational activity from domain progress.",
  ]
}

///|
fn civic_required_output_shape_section() -> String {
  civic_skill_section(
    "Required Output Shape",
    [
      "Return Markdown with these fields:",
      "",
      "- `civic_service_decision: update | no_change | needs_review | blocked`",
      "- `book_changed: yes | no`",
      "- `wiki_pages_changed_count: <integer>`",
      "- `changed_pages: comma-separated durable page paths, or none`",
      "- `accepted_facts_count: <integer>`",
      "- `review_items_created_count: <integer>`",
      "- `review_items: comma-separated review item ids/paths, or none`",
      "- `projection_updated: yes | no`",
      "- `projection_delta: one sentence explaining the projection-safe change, or blocked:<reason>`",
      "- `protocol_decision_basis: one sentence naming the evidence, ledger, or blocker basis for the decision`",
      "- `next_check_hint: normal | faster | slower | review`",
      "",
      civic_accepted_facts_accounting_rule(),
    ].join("\n"),
  )
}

///|
fn civic_accepted_facts_accounting_rule() -> String {
  "`accepted_facts_count` means accepted domain/service records for the module. For exchange-place, gateway, projection-surface, and hybrid modules, do not treat generic operational retries or daemon logs as accepted facts."
}

///|
fn civic_generic_service_example_section() -> String {
  civic_skill_section(
    "Concrete Example",
    [
      "```md", "civic_service_decision: needs_review", "book_changed: yes", "wiki_pages_changed_count: 2",
      "changed_pages: wiki/sources/policies.md, wiki/queries/policy-questions.md",
      "accepted_facts_count: 3", "review_items_created_count: 1", "review_items: wiki/reviews/policy-citations.md#deadline-uncertainty",
      "projection_updated: yes", "projection_delta: Added a review-safe eligibility checklist summary to the generated policy view.",
      "protocol_decision_basis: Official source metadata was accepted, but the deadline interpretation needs keeper review.",
      "next_check_hint: review", "", "Summary: Policy Hall found a new official eligibility notice, updated the checklist, and queued an uncertain deadline interpretation for keeper review.",
      "Artifacts: `wiki/sources/policies.md`, `wiki/queries/policy-questions.md`, `wiki/reviews/policy-citations.md`",
      "```",
    ].join("\n"),
  )
}
