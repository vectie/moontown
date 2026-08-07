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
test "detached import command publishes stdout only after the child exits" {
  let command = build_detached_shell_command_with_output(
    "/opt/moonclaw",
    ["proposal", "import", "/tmp/packet.json", "--json"],
    "/tmp/packet.import.json",
    "/tmp/packet.import.json.err",
  )
  assert_true(command.contains("receipt_tmp="))
  assert_true(command.contains("/tmp/packet.import.json.partial."))
  assert_true(command.contains("stderr_tmp="))
  assert_true(command.contains("/tmp/packet.import.json.err.partial."))
  assert_true(command.contains("mv -f \"$stderr_tmp\""))
  assert_true(command.contains("mv -f \"$receipt_tmp\""))
  assert_true(command.contains("moontown_child_status=$?"))
  assert_true(command.contains("else exit 74"))
  assert_true(!command.contains(" >'/tmp/packet.import.json' 2>"))
}

///|
async test "detached relaunch clears published output but preserves live partials" {
  let root = @fs.tmpdir(prefix="moontown-clear-receipt-test-")
  let receipt_path = root + "/packet.json.import.json"
  let stderr_path = receipt_path + ".err"
  let partial_path = receipt_path + ".partial.123"
  moonclaw_write_text_file(receipt_path, "stale receipt")
  moonclaw_write_text_file(stderr_path, "stale stderr")
  moonclaw_write_text_file(partial_path, "live child output")
  clear_detached_import_output(receipt_path, stderr_path)
  assert_true(!@fs.exists(receipt_path))
  assert_true(!@fs.exists(stderr_path))
  assert_true(@fs.exists(partial_path))
}

///|
async fn wait_for_detached_test_file(path : String) -> Bool {
  for _ in 0..<500 {
    if @fs.exists(path) {
      return true
    }
    @async.sleep(10)
  }
  false
}

///|
async test "large detached output is invisible until atomic publication" {
  let root = @fs.tmpdir(prefix="moontown-atomic-receipt-test-")
  let packet_path = "\{root}/packet.json"
  let receipt_path = detached_import_receipt_path(packet_path)
  let ready_path = root + "/child-ready"
  let release_path = root + "/release-child"
  ensure_parent_directory(receipt_path)
  let child_script = "yes x | head -c 65536; : > \{ready_path}; while [ ! -e \{release_path} ]; do sleep 0.01; done; printf \"\\n%s\\n\" \"{\\\"proposal_id\\\":\\\"proposal-1\\\",\\\"run_id\\\":\\\"run-1\\\",\\\"status\\\":\\\"Pending\\\"}\""
  let command = build_detached_shell_command_with_output(
    "/bin/zsh",
    ["-lc", child_script],
    receipt_path,
    receipt_path + ".err",
  )
  ignore(@integration.run_checked("/bin/zsh", ["-lc", command]))
  let child_ready = wait_for_detached_test_file(ready_path)
  let final_visible_while_running = @fs.exists(receipt_path)
  let early_receipt = detached_import_receipt("packet", packet_path)
  moonclaw_write_text_file(release_path, "release")
  let final_published = wait_for_detached_test_file(receipt_path)
  assert_true(child_ready)
  assert_true(!final_visible_while_running)
  assert_eq(early_receipt, None)
  assert_true(final_published)
  guard detached_import_receipt("packet", packet_path) is Some(receipt) else {
    fail("published receipt should become visible")
  }
  assert_eq(receipt.status, RunConfirmed)
  assert_eq(receipt.run_id, Some("run-1"))
}

///|
async test "detached import oversized receipt is failed without parsing" {
  let root = @fs.tmpdir(prefix="moontown-oversized-receipt-test-")
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
async test "detached import surfaces compiler failure written only to stderr" {
  let root = @fs.tmpdir(prefix="moontown-detached-stderr-test-")
  let packet_path = "\{root}/packet.json"
  let receipt_path = detached_import_receipt_path(packet_path)
  moonclaw_write_text_file(receipt_path, "")
  moonclaw_write_text_file(
    receipt_path + ".err",
    "Error: [4032]\nThe type IterResult is undefined.\n",
  )
  guard detached_import_receipt("packet", packet_path) is Some(receipt) else {
    fail("compiler stderr should become a terminal import receipt")
  }
  assert_eq(receipt.status, Failed)
  assert_true(receipt.summary.contains("IterResult"))
}

///|
async test "detached import reports failed run receipts as failures" {
  let root = @fs.tmpdir(prefix="moontown-detached-failed-run-test-")
  let packet_path = "\{root}/packet.json"
  moonclaw_write_text_file(
    detached_import_receipt_path(packet_path),
    "{\"proposal_id\":\"proposal-1\",\"run_id\":\"run-1\",\"status\":\"Failed\"}",
  )
  guard detached_import_receipt("packet", packet_path) is Some(receipt) else {
    fail("failed run receipt should be terminal")
  }
  assert_eq(receipt.status, Failed)
  assert_true(receipt.summary.contains("reported failure"))
  assert_true(receipt.summary.contains("run-1"))
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
