///|
fn deep_report_word_count_gaps(
  topic : String,
  report : String,
  source_screen : String,
) -> Array[String] {
  let gaps : Array[String] = []
  let source_depth = inspect_external_source_depth_gate(topic, source_screen)
  if !source_depth.applies ||
    source_depth.included_sources < source_depth.minimum_sources {
    return gaps
  }
  let word_count = count_english_word_tokens(report)
  if word_count < 12000 {
    gaps.push(
      "deep report has \{word_count} English word tokens with \{source_depth.included_sources} included screened sources; complex external research should target 12k-15k English words or record a source-depth blocker",
    )
  }
  gaps
}

///|
fn source_depth_quality_gaps(
  topic : String,
  source_screen : String,
) -> Array[String] {
  let gaps : Array[String] = []
  let source_depth = inspect_external_source_depth_gate(topic, source_screen)
  if source_depth.applies &&
    source_depth.included_sources < source_depth.minimum_sources {
    gaps.push(
      "source screen has only \{source_depth.included_sources} included inspected sources; reference-grade external research needs at least \{reference_grade_source_threshold_label()} before a 12k-15k dossier can be considered clean",
    )
  }
  gaps
}

///|
fn source_discovery_fallback_gaps(
  topic : String,
  search_log : String,
  source_screen : String,
  tool_blockers : String,
) -> Array[String] {
  let gaps : Array[String] = []
  let source_depth = inspect_external_source_depth_gate(topic, source_screen)
  if !source_depth.applies ||
    source_depth.included_sources >= source_depth.minimum_sources {
    return gaps
  }
  let lower = "\{search_log}\n\{tool_blockers}".to_lower()
  let weak_native_search = lower.contains("weak_search_page") ||
    lower.contains("duckduckgo") ||
    lower.contains("search-engine result") ||
    lower.contains("search-engine page") ||
    lower.contains("native `web_search`")
  if !weak_native_search {
    return gaps
  }
  let command_fallback_recorded = lower.contains("execute_command") ||
    lower.contains("curl -l") ||
    lower.contains("curl --") ||
    lower.contains("fetched with curl") ||
    lower.contains("command fallback attempts") ||
    lower.contains("command-line attempts")
  if !command_fallback_recorded {
    gaps.push(
      "source screen is below six included sources after weak native search, but search-log/tool-blockers do not record actual execute_command/curl fallback attempts",
    )
  }
  gaps
}

///|
priv struct ExternalSourceDepthGate {
  applies : Bool
  included_sources : Int
  minimum_sources : Int
}

///|
fn inspect_external_source_depth_gate(
  topic : String,
  source_screen : String,
) -> ExternalSourceDepthGate {
  {
    applies: is_external_quality_topic(topic),
    included_sources: count_included_screened_sources(source_screen),
    minimum_sources: reference_grade_source_threshold(),
  }
}

///|
fn reference_grade_source_threshold() -> Int {
  6
}

///|
fn reference_grade_source_threshold_label() -> String {
  "six"
}
