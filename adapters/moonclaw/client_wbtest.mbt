///|
test "proposal packet pins provider task spec for bootstrap ingest" {
  let task = @moonbook.BookTask::new(
    id="task-bootstrap",
    title="Bootstrap verified research coverage",
    kind="ingest",
    prompt="Bootstrap this book before answering the research question.",
    priority=100,
    requires_review=true,
    target_pages=["raw/bootstrap/research-question.md"],
  )
  let metadata = packet_step_metadata(Some(task)).stringify()
  assert_true(metadata.contains("\"extension_task_id\":\"task-bootstrap\""))
  assert_true(metadata.contains("\"bookapi_task_id\":\"task-bootstrap\""))
  assert_true(metadata.contains("\"kind\":\"bootstrap_gather\""))
  assert_true(metadata.contains("\"extension_task_kind\":\"bootstrap_gather\""))
}

///|
async fn test_ignore_checked_command(
  command : String,
  args : Array[String],
) -> Unit {
  let completed = @integration.run_checked(command, args) catch { _ => return }
  ignore(completed)
}

///|
async fn test_write_text_file(path : String, content : String) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(content),
    create=0o644,
    truncate=true,
  )
}

///|
test "research bootstrap packet leaves web tools to the selected profile" {
  let task = @moonbook.BookTask::new(
    id="goal-research-opc-research-bootstrap-ingest",
    title="Bootstrap verified research coverage",
    kind="ingest",
    prompt="Bootstrap this book before answering the research question.",
    priority=100,
    requires_review=true,
    target_pages=["raw/bootstrap/research-question.md"],
  )
  let metadata = packet_step_metadata(Some(task)).stringify()
  assert_true(metadata.contains("MoonClaw raw research bootstrap artifacts"))
  assert_true(metadata.contains("raw/bootstrap/deep-report.md"))
  assert_true(!metadata.contains("\"tool_contract\""))
  assert_true(!metadata.contains("\"web_search\":false"))
  assert_true(!metadata.contains("wiki/sources"))
}

///|
test "civic repair prompt mentioning course negatively is not rewritten as course task" {
  let task = @moonbook.BookTask::new(
    id="standing-book-quality-repair-wenyu-resident-twins-tick-17941",
    title="Standing watch: Repair book quality: wenyu-resident-twins",
    kind="standing-watch",
    prompt="Follow the book's own contract and SKILL.md; do not force a research genre onto civic, course, planbook, cookbook, or operational books. Resolve the import-authority blocker, then run one module-native resident-memory packet.",
    priority=95,
    requires_review=false,
    target_pages=[
      "wiki/history/journey.md", "wiki/sources/", "wiki/synthesis/overview.md", "raw/bootstrap/",
    ],
  )
  let metadata = packet_step_metadata(Some(task)).stringify()
  assert_true(metadata.contains("module-native resident-memory packet"))
  assert_true(!metadata.contains("Produce MoonClaw beginner-course artifacts"))
  assert_true(!metadata.contains("wiki/synthesis/beginner-course.md"))
}

///|
test "explicit course task still receives course artifact routing" {
  let task = @moonbook.BookTask::new(
    id="standing-book-quality-repair-course-wenyu-game-design-tick-17941",
    title="Standing watch: Repair book quality: course-wenyu-game-design",
    kind="standing-watch",
    prompt="Run course projection repair: enforce course identity, lesson progression, exercises, checkpoints, and beginner usability.",
    priority=95,
    requires_review=false,
    target_pages=["wiki/course/beginner-course.md"],
  )
  let metadata = packet_step_metadata(Some(task)).stringify()
  assert_true(metadata.contains("Produce MoonClaw beginner-course artifacts"))
  assert_true(metadata.contains("wiki/synthesis/beginner-course.md"))
}

///|
test "pending and running MoonClaw runs are orphan detectable" {
  assert_true(
    orphan_detectable_run_status(@core.TaskExecutionStatus::RunConfirmed),
  )
  assert_true(orphan_detectable_run_status(@core.TaskExecutionStatus::Running))
  assert_true(
    !orphan_detectable_run_status(@core.TaskExecutionStatus::Completed),
  )
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
test "detached import startup logs are not terminal failure receipts" {
  let receipt = detached_import_failure_receipt(
    "packet",
    "/tmp/packet.json",
    (
      $|{"level":"Info","pid":12722,"msg":"No model specified, auto-detecting...","tag":"Model"}
      $|{"level":"Warn","pid":12722,"msg":"Directory '/Users/kq/.moonclaw/rules' does not exist, skipping.","tag":"job-analysis"}
      $|{"level":"Info","pid":12722,"msg":"Loading skills from directory '/Users/kq/.moonclaw/skills/.system'...","tag":"job-analysis"}
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
      $|Blocking waiting for file lock /Users/kq/Workspace/moontown/_build/.moon-lock ...
      $|{"level":"Info","pid":10357,"msg":"No model specified, auto-detecting...","tag":"Model"}
      $|{"level":"Info","pid":10357,"msg":"Received event","tag":"job-analysis","event":{"desc":{"msg":"SystemPromptSet","prompt":"If the step failed: explain missing inputs without inventing facts."}}}
      $|{"level":"Info","pid":10357,"msg":"Received event","tag":"job-analysis","event":{"desc":{"msg":"PostToolCall","result":{"status":127,"stderr":"sh: rg: command not found"}}}}
    ),
  )
  assert_true(receipt is None)
}

///|
test "inline detached import receipt status maps succeeded to completed" {
  assert_eq(
    import_receipt_status(Some("run-1"), Some("Succeeded")),
    @core.TaskExecutionStatus::Completed,
  )
  assert_eq(
    import_receipt_status(Some("run-1"), Some("Pending")),
    @core.TaskExecutionStatus::RunConfirmed,
  )
}

///|
test "detached import receipt surfaces plain text moonclaw failure" {
  let receipt = detached_import_failure_receipt(
    "packet", "/tmp/packet.json", "Failure(job/system_storage.mbt:284:14-284:42@vectie/moonclaw FAILED: Failed to load job definitions: JsonDecodeError((, Missing field workflows)))",
  )
  assert_true(receipt is Some(_))
  let loaded = receipt.unwrap()
  assert_eq(loaded.status, @core.TaskExecutionStatus::Failed)
  assert_true(loaded.summary.contains("Missing field workflows"))
}

///|
async test "poll run prefers terminal meta over stale running index" {
  let root = "/tmp/moontown-moonclaw-poll-meta-wbtest-\{@async.now().to_int()}"
  test_ignore_checked_command("rm", ["-rf", root])
  test_write_text_file(
    "\{root}/.moonclaw/jobs/index/runs.json",
    (
      $|{
      $|  "runs": [
      $|    {
      $|      "id": "run-meta-wins",
      $|      "workspace_dir": "\{root}/workspace",
      $|      "status": "Running",
      $|      "summary": "stale index"
      $|    }
      $|  ]
      $|}
    ),
  )
  test_write_text_file(
    "\{root}/.moonclaw/jobs/runs/run-meta-wins/meta.json",
    (
      $|{
      $|  "id": "run-meta-wins",
      $|  "workspace_dir": "\{root}/workspace",
      $|  "status": "Succeeded",
      $|  "summary": "Workflow completed"
      $|}
    ),
  )
  let response = poll_run(
    "task-meta-wins",
    "run-meta-wins",
    home=".moonclaw",
    cwd=root,
    detect_orphan=false,
  )
  assert_eq(response.status, @core.TaskExecutionStatus::Completed)
  assert_true(response.summary.contains("Workflow completed"))
}
