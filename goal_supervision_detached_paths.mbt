///|
fn detached_import_packet_id_for_execution(
  execution : @core.TaskExecutionRecord,
) -> String {
  if execution.packet_id.trim().is_empty() ||
    execution.packet_id.has_prefix("pending-") {
    @roles.keeper_packet_id(execution.book_id, execution.task_id)
  } else {
    execution.packet_id
  }
}

///|
fn detached_import_packet_path_for_execution(
  execution : @core.TaskExecutionRecord,
) -> String {
  if !execution.packet_path.trim().is_empty() {
    return execution.packet_path
  }
  let packet_id = detached_import_packet_id_for_execution(execution)
  if packet_id.trim().is_empty() {
    ""
  } else {
    @moonclaw.packet_file_path(@moonclaw.default_packet_directory(), packet_id)
  }
}

///|
async fn detached_import_stderr_summary(packet_path : String) -> String {
  if packet_path.trim().is_empty() {
    return ""
  }
  let stderr_path = @moonclaw.detached_import_receipt_path(packet_path) + ".err"
  let text = read_text_or_empty(stderr_path).trim().to_owned()
  if text.is_empty() {
    return ""
  }
  let compact = compact_detached_import_stderr(text)
  if compact.is_empty() {
    ""
  } else {
    " Detached import stderr: \{compact}"
  }
}

///|
fn compact_detached_import_stderr(text : String) -> String {
  let builder = StringBuilder::new()
  let mut count = 0
  for line in text.split("\n") {
    if count >= 8 {
      break
    }
    let trimmed = line.trim()
    if trimmed.is_empty() {
      continue
    }
    if count > 0 {
      builder.write_string(" | ")
    }
    builder.write_string(trimmed.to_owned())
    count += 1
  }
  builder.to_string()
}
