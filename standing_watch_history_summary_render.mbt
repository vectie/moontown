///|
fn render_standing_watch_decision_summary(
  fields : StandingWatchHistoryDecisionFields,
) -> String {
  [
    "standing_goal_decision: \{fields.decision}",
    "delta_score: \{fields.delta_score}",
    "new_source_count: \{fields.new_source_count}",
    "next_check_hint: \{fields.next_check_hint}",
    "checked_sources_count: \{fields.checked_sources_count}",
    "new_sources_found: \{fields.new_sources_found}",
    "accepted_facts_count: \{fields.accepted_facts_count}",
    "rejected_facts_count: \{fields.rejected_facts_count}",
    "wiki_pages_changed_count: \{fields.wiki_pages_changed_count}",
    "book_changed: \{fields.book_changed}",
    "book_watch_record_id: \{fields.block_id}",
    fields.summary,
  ].join("\n")
}
