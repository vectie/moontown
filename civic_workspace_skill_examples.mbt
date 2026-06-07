///|
fn civic_skill_example(service : @civic.CivicServiceDefinition) -> String {
  let first_page = service.wiki_pages.get(0).unwrap_or("wiki/civic/module.md")
  let review_page = service.review_queues
    .get(0)
    .unwrap_or("wiki/reviews/module.md")
  [
    "```md",
    "civic_service_decision: update",
    "book_changed: yes",
    "wiki_pages_changed_count: 2",
    "accepted_facts_count: 4",
    "review_items_created_count: 1",
    "projection_updated: yes",
    "next_check_hint: normal",
    "",
    civic_skill_example_summary(service, first_page, review_page),
    "",
    "Evidence and judgment:",
    "- What changed: one concrete service fact, exchange record, gateway request, projection state, or operating condition.",
    "- Why it matters: resident/operator impact.",
    "- What remains uncertain: source, policy, consent, budget, privacy, or offline-action risk.",
    "",
    "Artifacts:",
    "- `\{first_page}`",
    "- `\{review_page}`",
    "- `book/moonbook-ui-state.json`",
    "```",
  ].join("\n")
}

///|
fn civic_skill_example_summary(
  service : @civic.CivicServiceDefinition,
  first_page : String,
  review_page : String,
) -> String {
  [
    "Summary: \{service.title} followed `\{service.module_mode}` / `\{service.skill_mode}` mode,",
    "selected the most useful module-native action from current book and place state,",
    "updated `\{first_page}`,",
    "and queued one review item in `\{review_page}` because the action affects public/user-facing service behavior.",
  ].join(" ")
}
