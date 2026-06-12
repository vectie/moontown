///|
fn count_included_screened_sources(text : String) -> Int {
  let mut count = 0
  let mut in_included_section = false
  let mut in_non_included_source_section = false
  let mut pending_source_heading = false
  for raw in text.split("\n") {
    let line = normalized_markdown_line(raw)
    if line_starts_included_sources_section(line) {
      in_included_section = true
      in_non_included_source_section = false
      pending_source_heading = false
      continue
    }
    if line_is_section_heading(line) {
      in_included_section = false
      in_non_included_source_section = line_starts_non_included_sources_section(
        line,
      )
      pending_source_heading = false
    }
    if in_included_section && is_source_entry_heading(line) {
      count += 1
      pending_source_heading = false
      continue
    }
    if !in_included_section &&
      !in_non_included_source_section &&
      is_source_entry_heading(line) {
      pending_source_heading = true
      continue
    }
    if is_substantive_included_source_line(line) ||
      (
        in_included_section &&
        is_substantive_source_table_row_without_decision(line)
      ) {
      count += 1
      pending_source_heading = false
      continue
    }
    if pending_source_heading && decision_line_includes_source(line) {
      count += 1
      pending_source_heading = false
    }
  }
  count
}

///|
fn line_starts_included_sources_section(line : String) -> Bool {
  line.has_prefix("## included") || line.has_prefix("### included")
}

///|
fn line_starts_non_included_sources_section(line : String) -> Bool {
  line.contains("excluded") ||
  line.contains("rejected") ||
  line.contains("blocked") ||
  line.contains("discovery") ||
  line.contains("candidate")
}

///|
fn decision_line_includes_source(line : String) -> Bool {
  line.has_prefix("- decision:") &&
  line.contains("include") &&
  !line.contains("exclude") &&
  !line.contains("discovery_only")
}

///|
fn is_source_entry_heading(line : String) -> Bool {
  if !(line.has_prefix("### w") || line.has_prefix("### l")) {
    return false
  }
  !is_discovery_or_index_source_line(line)
}

///|
fn is_substantive_included_source_line(line : String) -> Bool {
  if !((line.has_prefix("| w") || line.has_prefix("| l")) &&
    line.contains("| include")) {
    return false
  }
  if is_discovery_or_index_source_line(line) {
    return false
  }
  true
}

///|
fn is_substantive_source_table_row_without_decision(line : String) -> Bool {
  if !((line.has_prefix("| w") || line.has_prefix("| l")) && line.contains("|")) {
    return false
  }
  if line.contains("---") || line.contains("source id") {
    return false
  }
  !is_discovery_or_index_source_line(line)
}

///|
fn is_discovery_or_index_source_line(line : String) -> Bool {
  line.contains("/search?") ||
  line.contains("search?") ||
  line.contains("web primary/index") ||
  line.contains("web research/index") ||
  line.contains("web market/index") ||
  line.contains("web independent/index") ||
  line.contains("index page") ||
  line.contains("search page") ||
  line.contains("hub/index") ||
  line.contains("discovery-oriented") ||
  line.contains("discovery-heavy") ||
  line.contains("discovery_only") ||
  line.contains("discovery only") ||
  line.contains("not claim evidence") ||
  line.contains("not evidence")
}
