///|
fn town_report_status_counts_sentence(
  complete_count : Int,
  running_count : Int,
  review_count : Int,
  failed_count : Int,
) -> String {
  "The latest town run has \{complete_count} completed lanes, \{running_count} running lanes, \{review_count} review-queued lanes, and \{failed_count} failed lanes. "
}

///|
fn town_report_final_status_verdict() -> String {
  "That status is strong enough for a town-level report, provided the lane `deep-report.md` files remain present and substantive.\n\n"
}

///|
fn town_report_interim_status_verdict() -> String {
  "That status means the town report should be treated as interim rather than final.\n\n"
}

///|
fn town_report_reading_surface_note() -> String {
  "The next improvement is to stop treating generated marketing pages as the final reading surface. The source of truth for research quality is now the deep report in each MoonBook lane plus this town-level synthesis."
}
