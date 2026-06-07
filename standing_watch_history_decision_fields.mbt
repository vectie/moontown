///|
priv struct StandingWatchHistoryDecisionFields {
  block_id : String
  decision : String
  delta_score : String
  new_source_count : String
  next_check_hint : String
  checked_sources_count : String
  new_sources_found : String
  accepted_facts_count : String
  rejected_facts_count : String
  wiki_pages_changed_count : String
  book_changed : String
  summary : String
}

///|
fn standing_watch_history_decision_fields(
  block_id : String,
  lines : Array[String],
) -> StandingWatchHistoryDecisionFields {
  let summary_text = standing_watch_history_summary_text(lines)
  let decision = standing_watch_history_field(lines, "- Decision: `").unwrap_or(
    "unknown",
  )
  let new_source_count = standing_watch_history_field(
    lines, "- New source count: `",
  ).unwrap_or("0")
  {
    block_id,
    decision,
    delta_score: standing_watch_history_field(lines, "- Delta score: `").unwrap_or(
      "0",
    ),
    new_source_count,
    next_check_hint: standing_watch_history_field(lines, "- Next check hint: `").unwrap_or(
      "normal",
    ),
    checked_sources_count: standing_watch_history_checked_sources_count(
      lines, summary_text,
    ),
    new_sources_found: standing_watch_history_new_sources_found(
      lines, summary_text, new_source_count,
    ),
    accepted_facts_count: standing_watch_history_accepted_facts_count(
      lines, summary_text, decision,
    ),
    rejected_facts_count: standing_watch_history_rejected_facts_count(
      lines, summary_text,
    ),
    wiki_pages_changed_count: standing_watch_history_wiki_pages_changed_count(
      lines, summary_text, decision,
    ),
    book_changed: standing_watch_history_book_changed(
      lines, summary_text, decision,
    ),
    summary: standing_watch_history_normalized_summary(summary_text),
  }
}

///|
fn standing_watch_history_checked_sources_count(
  lines : Array[String],
  summary_text : String,
) -> String {
  standing_watch_history_field(lines, "- Checked sources count: `").unwrap_or(
    standing_watch_marker_int(summary_text, "checked_sources_count", fallback=0).to_string(),
  )
}

///|
fn standing_watch_history_new_sources_found(
  lines : Array[String],
  summary_text : String,
  new_source_count : String,
) -> String {
  standing_watch_history_field(lines, "- New sources found: `").unwrap_or(
    standing_watch_marker_int(
      summary_text,
      "new_sources_found",
      fallback=first_non_negative_int(new_source_count).unwrap_or(0),
    ).to_string(),
  )
}

///|
fn standing_watch_history_accepted_facts_count(
  lines : Array[String],
  summary_text : String,
  decision : String,
) -> String {
  standing_watch_history_field(lines, "- Accepted facts count: `").unwrap_or(
    standing_watch_marker_int(
      summary_text,
      "accepted_facts_count",
      fallback=if standing_watch_decision_text_marks_update(decision) {
        1
      } else {
        0
      },
    ).to_string(),
  )
}

///|
fn standing_watch_history_rejected_facts_count(
  lines : Array[String],
  summary_text : String,
) -> String {
  standing_watch_history_field(lines, "- Rejected facts count: `").unwrap_or(
    standing_watch_marker_int(summary_text, "rejected_facts_count", fallback=0).to_string(),
  )
}

///|
fn standing_watch_history_wiki_pages_changed_count(
  lines : Array[String],
  summary_text : String,
  decision : String,
) -> String {
  standing_watch_history_field(lines, "- Wiki pages changed count: `").unwrap_or(
    standing_watch_marker_int(
      summary_text,
      "wiki_pages_changed_count",
      fallback=if standing_watch_decision_text_marks_book_changed(decision) {
        1
      } else {
        0
      },
    ).to_string(),
  )
}

///|
fn standing_watch_history_book_changed(
  lines : Array[String],
  summary_text : String,
  decision : String,
) -> String {
  standing_watch_history_field(lines, "- Book changed: `").unwrap_or(
    standing_watch_marker_value(summary_text, "book_changed").unwrap_or(
      if standing_watch_decision_text_marks_book_changed(decision) {
        "yes"
      } else {
        "no"
      },
    ),
  )
}

///|
fn standing_watch_history_normalized_summary(summary_text : String) -> String {
  if summary_text.is_blank() {
    "MoonBook recorded a standing-watch decision."
  } else {
    summary_text
  }
}
