///|
test "approved book review projects inactive acceptance pending with retained own run artifacts" {
  let task : Map[String, Json] = { "status": "Blocked" }
  let execution : Map[String, Json] = {
    "status": "AwaitingAcceptance",
    "result_decision": "human-review-approved",
    "summary": "Book review approved; goal acceptance remains unevaluated",
  }
  assert_eq(town_task_status(task, execution), "awaiting_acceptance")
  assert_false(active_status("awaiting_acceptance"))
  assert_eq(
    projected_task_activity({ "status": "awaiting_acceptance" }),
    ("idle", "Awaiting acceptance"),
  )
  assert_true(
    projected_task_can_link_results({
      "status": "awaiting_acceptance",
      "runId": "native-run",
    }),
  )
  assert_false(
    projected_task_can_link_results({ "status": "awaiting_acceptance" }),
  )
  assert_eq(
    town_task_status(task, { "status": "ReviewQueued" }),
    "waiting_review",
  )
  assert_eq(town_task_status(task, { "status": "Completed" }), "completed")
}
