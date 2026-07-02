///|
async test "poll run prefers terminal meta over stale running index" {
  let root = "/tmp/moontown-moonclaw-poll-meta-wbtest-\{@async.now().to_int()}"
  test_ignore_checked_command("rm", ["-rf", root])
  let home = root + "/books/research-town"
  test_write_text_file(
    @moonsuite.product_artifact_for_workspace_root(
      home, "moonclaw", "jobs/index/runs.json",
    ),
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
    @moonsuite.product_artifact_for_workspace_root(
      home, "moonclaw", "jobs/runs/run-meta-wins/meta.json",
    ),
    (
      $|{
      $|  "id": "run-meta-wins",
      $|  "workspace_dir": "\{root}/workspace",
      $|  "status": "Succeeded",
      $|  "summary": "Workflow completed"
      $|}
    ),
  )
  assert_false(run_store_root(home).contains("/books/research-town/.moonsuite"))
  let response = poll_run(
    "task-meta-wins",
    "run-meta-wins",
    home~,
    cwd=root,
    detect_orphan=false,
  )
  assert_eq(response.status, Completed)
  assert_true(response.summary.contains("Workflow completed"))
}

///|
async test "poll run forces review when succeeded result text says fail" {
  let root = "/tmp/moontown-moonclaw-poll-review-fail-wbtest-\{@async.now().to_int()}"
  test_ignore_checked_command("rm", ["-rf", root])
  let home = root
  test_write_text_file(
    @moonsuite.product_artifact(
      home, "moonclaw", "jobs/runs/run-review-fail/meta.json",
    ),
    (
      $|{
      $|  "id": "run-review-fail",
      $|  "workspace_dir": "\{root}/workspace",
      $|  "status": "Succeeded",
      $|  "summary": "Review step completed"
      $|}
    ),
  )
  test_write_text_file(
    "\{root}/workspace/result.json",
    (
      $|{
      $|  "result_decision": "accepted",
      $|  "requires_review": false,
      $|  "content": "- **Pass/Fail:** FAIL. Blockers: Missing changed_pages. The result should be rejected because it treats incomplete progress as complete."
      $|}
    ),
  )
  let response = poll_run(
    "task-review-fail",
    "run-review-fail",
    home~,
    cwd=root,
    detect_orphan=false,
  )
  assert_eq(response.status, Completed)
  assert_eq(response.result_decision, "needs_review")
  assert_true(response.requires_review)
}

///|
test "moonclaw review text detector does not flag pass labels" {
  assert_false(
    moonclaw_result_text_requires_review(
      "- **Pass/Fail:** PASS\nAll checks passed.",
    ),
  )
  assert_true(
    moonclaw_result_text_requires_review(
      "- **Pass/Fail:** FAIL\nMissing fields.",
    ),
  )
}

///|
test "moonclaw process liveness only accepts proposal run argv sequence" {
  assert_true(
    moonclaw_process_line_is_proposal_run(
      "501 123 1 0 ?? moon -C /opt/moonclaw run cmd/main -- proposal run run-1 --cwd /tmp",
      "run-1",
    ),
  )
  assert_false(
    moonclaw_process_line_is_proposal_run(
      "501 123 1 0 ?? codex prompt mentions proposal run run-1 in source text", "run-1",
    ),
  )
  assert_false(
    moonclaw_process_line_is_proposal_run(
      "501 123 1 0 ?? moon -C /opt/moonclaw run cmd/main -- proposal run run-1,",
      "run-1",
    ),
  )
}
