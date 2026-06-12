///|
fn detached_import_non_json_line_has_terminal_failure_signal(
  lowered : String,
) -> Bool {
  detached_import_text_has_terminal_failure_signal(lowered)
}

///|
fn detached_import_text_has_terminal_failure_signal(lowered : String) -> Bool {
  lowered.contains("failure(") ||
  lowered.contains(" failed:") ||
  lowered.contains("runtime error") ||
  lowered.contains("jsondecodeerror") ||
  lowered.contains("abort() called") ||
  lowered.contains("panic")
}
