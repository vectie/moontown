///|
fn render_wenyu_civic_portfolio(portfolio : CivicServicePortfolio) -> String {
  let builder = StringBuilder::new()
  builder.write_string(civic_status_title_section())
  builder.write_string(civic_status_portfolio_summary_line(portfolio))
  builder.write_string(civic_status_table_header())
  for service in portfolio.services {
    builder.write_string(civic_service_markdown_row(service))
  }
  builder.write_string(civic_status_notes_heading())
  for service in portfolio.services {
    builder.write_string(civic_service_note_line(service))
  }
  builder.to_string()
}

///|
fn civic_service_markdown_row(service : CivicServiceHealth) -> String {
  civic_status_table_row(civic_service_markdown_cells(service))
}

///|
fn civic_service_note_line(service : CivicServiceHealth) -> String {
  "- \{service.title}: \{service.notes.join("; ")}\n"
}

///|
fn civic_status_title_section() -> String {
  "# Wenyu Civic Service Status\n\n"
}

///|
fn civic_status_portfolio_summary_line(
  portfolio : CivicServicePortfolio,
) -> String {
  [
    "Total: \{portfolio.total};",
    "operable: \{portfolio.operable_count};",
    "proven by result: \{portfolio.proven_count};",
    "review: \{portfolio.review_count};",
    "blocked: \{portfolio.blocked_count};",
    "missing/incomplete: \{portfolio.missing_count}.",
  ].join(" ") +
  "\n\n"
}

///|
fn civic_status_table_header() -> String {
  civic_status_table_row(civic_status_table_columns()) +
  civic_status_table_row(civic_status_table_alignments())
}

///|
fn civic_status_table_columns() -> Array[String] {
  [
    " Service ", " Mode ", " Skill ", " Protocol ", " Status ", " Operable ", " Latest decision ",
    " Changed pages ", " Accepted facts ", " Review items ", " Missing paths ",
  ]
}

///|
fn civic_status_table_alignments() -> Array[String] {
  [
    "---", "---", "---", "---:", "---:", "---:", "---", "---:", "---:", "---:", "---",
  ]
}

///|
fn civic_service_markdown_cells(service : CivicServiceHealth) -> Array[String] {
  [
    service.title,
    service.module_mode,
    service.skill_mode,
    service.protocol_status,
    service.status,
    yes_no(service.operable),
    service.latest_decision,
    service.latest_pages_changed.to_string(),
    service.latest_accepted_facts.to_string(),
    service.latest_review_items.to_string(),
    compact_missing_paths(service.missing_required_paths),
  ]
}

///|
fn civic_status_table_row(cells : Array[String]) -> String {
  "|\{cells.join("|")}|\n"
}

///|
fn civic_status_notes_heading() -> String {
  "\n## Notes\n\n"
}

///|
fn compact_missing_paths(paths : Array[String]) -> String {
  if paths.is_empty() {
    return "none"
  }
  if paths.length() <= 3 {
    return paths.join("<br>")
  }
  "\{paths[0]}<br>\{paths[1]}<br>\{paths[2]}<br>+\{paths.length() - 3} more"
}

///|
fn yes_no(value : Bool) -> String {
  if value {
    "yes"
  } else {
    "no"
  }
}
