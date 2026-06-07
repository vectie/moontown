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
