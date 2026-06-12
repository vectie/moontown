///|
fn detached_import_failure_receipt(
  packet_id : String,
  packet_path : String,
  text : String,
) -> ProposalImportReceipt? {
  if detached_import_text_is_nonterminal_log_noise(text) {
    return None
  }
  let detail = compact_detached_import_failure_text(text)
  if detail.is_empty() {
    None
  } else {
    Some({
      packet_id,
      packet_path,
      proposal_id: "proposal-\{packet_id}",
      run_id: None,
      status: @core.TaskExecutionStatus::Failed,
      command: "detached MoonClaw import failure receipt \{detached_import_receipt_path(packet_path)}",
      summary: "Detached MoonClaw import failed for \{packet_id}: \{detail}",
    })
  }
}

///|
fn detached_import_text_is_nonterminal_log_noise(text : String) -> Bool {
  if detached_import_text_is_only_runtime_event_logs(text) {
    return true
  }
  let lowered = text.to_lower()
  let has_startup_log = lowered.contains("\"tag\":\"model\"") ||
    lowered.contains("\"tag\":\"job-analysis\"") ||
    lowered.contains("loading skills from directory") ||
    lowered.contains("loaded skill")
  let has_runtime_event = lowered.contains("\"msg\":\"received event\"") ||
    lowered.contains("\"msg\":\"tokencounted\"") ||
    lowered.contains("\"msg\":\"contextpruned\"")
  (has_startup_log || has_runtime_event) &&
  !detached_import_text_has_top_level_terminal_failure_signal(text)
}

///|
fn detached_import_text_has_top_level_terminal_failure_signal(
  text : String,
) -> Bool {
  for raw in text.split("\n") {
    let line = raw.trim()
    if line.is_empty() {
      continue
    }
    let parsed = @json.parse(line) catch {
      _ =>
        if detached_import_non_json_line_has_terminal_failure_signal(
            line.to_owned().to_lower(),
          ) {
          return true
        } else {
          continue
        }
    }
    if json_looks_like_moonclaw_runtime_log(parsed) {
      if json_runtime_log_has_terminal_failure_signal(parsed) {
        return true
      }
    } else if !json_looks_like_import_receipt(parsed) &&
      detached_import_non_json_line_has_terminal_failure_signal(
        line.to_owned().to_lower(),
      ) {
      return true
    }
  }
  false
}

///|
fn compact_detached_import_failure_text(text : String) -> String {
  let builder = StringBuilder::new()
  let mut count = 0
  for raw in text.split("\n") {
    if count >= 6 {
      break
    }
    let line = raw.trim()
    if line.is_empty() {
      continue
    }
    if count > 0 {
      builder.write_string(" | ")
    }
    builder.write_string(line.to_owned())
    count += 1
  }
  builder.to_string()
}
