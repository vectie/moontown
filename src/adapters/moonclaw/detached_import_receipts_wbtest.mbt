///|
test "pending and running MoonClaw runs are orphan detectable" {
  assert_true(orphan_detectable_run_status(RunConfirmed))
  assert_true(orphan_detectable_run_status(Running))
  assert_true(!orphan_detectable_run_status(Completed))
}

///|
test "detached import receipt parser tolerates compiler noise before json" {
  let parsed = parse_json_from_command_text(
    "Warning: generated before receipt\n{\"proposal_id\":\"proposal-1\",\"run_id\":\"run-1\"}",
  )
  assert_true(parsed.stringify().contains("\"run_id\":\"run-1\""))
}

///|
test "detached import receipt parser skips moonclaw json startup logs" {
  let parsed = parse_json_from_command_text(
    (
      $|{"level":"Info","pid":1,"msg":"No model specified, auto-detecting...","tag":"Model"}
      $|{"level":"Info","pid":1,"msg":"Loaded skill 'moonbit-agent-guide'.","tag":"job-analysis"}
      $|{"proposal_id":"proposal-1","run_id":"run-1"}
    ),
  )
  assert_true(parsed.stringify().contains("\"proposal_id\":\"proposal-1\""))
  assert_true(parsed.stringify().contains("\"run_id\":\"run-1\""))
}

///|
async test "detached import oversized receipt is failed without parsing" {
  let root = "/tmp/moontown-oversized-receipt-test"
  let packet_path = "\{root}/packet.json"
  let receipt_path = detached_import_receipt_path(packet_path)
  let builder = StringBuilder::new()
  for _ in 0..<1_010 {
    builder.write_string("0123456789".repeat(100))
    builder.write_char('\n')
  }
  moonclaw_write_text_file(receipt_path, builder.to_string())
  let receipt = detached_import_receipt("packet", packet_path)
  assert_true(receipt is Some(_))
  let loaded = receipt.unwrap()
  assert_eq(loaded.status, Failed)
  assert_true(loaded.summary.contains("oversized receipt"))
}

///|
test "detached import startup logs are not terminal failure receipts" {
  let receipt = detached_import_failure_receipt(
    "packet",
    "/tmp/packet.json",
    (
      $|{"level":"Info","pid":12722,"msg":"No model specified, auto-detecting...","tag":"Model"}
      $|{"level":"Warn","pid":12722,"msg":"Directory '/Users/kq/.moonsuite/products/moonclaw/rules' does not exist, skipping.","tag":"job-analysis"}
      $|{"level":"Info","pid":12722,"msg":"Loading skills from directory '/Users/kq/.moonsuite/products/moonclaw/skills/.system'...","tag":"job-analysis"}
    ),
  )
  assert_true(receipt is None)
}

///|
test "detached import event logs ignore nested failure words in prompts" {
  let receipt = detached_import_failure_receipt(
    "packet",
    "/tmp/packet.json",
    (
      $|{"level":"Info","pid":12722,"msg":"Received event","tag":"job-analysis","event":{"desc":{"msg":"SystemPromptSet","prompt":"If the step failed: explain the missing inputs."}}}
      $|{"level":"Info","pid":12722,"msg":"Received event","tag":"job-analysis","event":{"desc":{"msg":"ToolAdded","tool":{"schema":{"properties":{"status":{"type":"string"}}}}}}}
    ),
  )
  assert_true(receipt is None)
}

///|
test "detached import startup stream ignores nested failed prompt and lock line" {
  let receipt = detached_import_failure_receipt(
    "packet",
    "/tmp/packet.json",
    (
      $|Blocking waiting for file lock /workspace/moontown/_build/.moon-lock ...
      $|{"level":"Info","pid":10357,"msg":"No model specified, auto-detecting...","tag":"Model"}
      $|{"level":"Info","pid":10357,"msg":"Received event","tag":"job-analysis","event":{"desc":{"msg":"SystemPromptSet","prompt":"If the step failed: explain missing inputs without inventing facts."}}}
      $|{"level":"Info","pid":10357,"msg":"Received event","tag":"job-analysis","event":{"desc":{"msg":"PostToolCall","result":{"status":127,"stderr":"sh: rg: command not found"}}}}
    ),
  )
  assert_true(receipt is None)
}

///|
test "inline detached import receipt status maps succeeded to completed" {
  assert_eq(import_receipt_status(Some("run-1"), Some("Succeeded")), Completed)
  assert_eq(import_receipt_status(Some("run-1"), Some("Pending")), RunConfirmed)
}

///|
test "detached import receipt surfaces plain text moonclaw failure" {
  let receipt = detached_import_failure_receipt(
    "packet", "/tmp/packet.json", "Failure(job/system_storage.mbt:284:14-284:42@vectie/moonclaw FAILED: Failed to load job definitions: JsonDecodeError((, Missing field workflows)))",
  )
  assert_true(receipt is Some(_))
  let loaded = receipt.unwrap()
  assert_eq(loaded.status, Failed)
  assert_true(loaded.summary.contains("Missing field workflows"))
}
