///|
test "marketplace completion preserves case-sensitive artifact references" {
  let (published, _, _, reader) = test_published_state()
  let requested = marketplace_request_listing_action(
    published,
    reader,
    AgentListing,
    "agent.robot-guide",
    "try",
    "Prepare a reviewable report.",
    now_ms=130UL,
  )
  let queued = {
    ..requested,
    action_requests: [
      {
        ..requested.action_requests[0],
        state: ActionHandoffQueued,
        execution_handoff_id: Some("handoff-case-sensitive-output"),
        runtime_status: "pending_transport",
      },
    ],
  }
  let local_ref = "books/a/artifacts/QuarterlyReport.PDF"
  let url_ref = "https://example.com/Reports/QuarterlyReport.PDF?revision=AbC123"
  let lower_ref = "books/a/artifacts/quarterlyreport.pdf"
  let completed = marketplace_reconcile_action_request_runtime(
    queued,
    {
      handoff_id: "handoff-case-sensitive-output",
      runtime_status: "succeeded",
      worker_run_id: "worker-case-sensitive-output",
      result_summary: "The report is ready.",
      result_evidence_refs: [
        "  " + local_ref + "\t",
        local_ref,
        "\n" + url_ref + "  ",
        url_ref,
        lower_ref,
        "",
        " \t\n",
      ],
    },
    now_ms=140UL,
  )
  let result = completed.action_requests[0]
  assert_eq(result.state, ActionSucceeded)
  assert_eq(result.result_evidence_refs.length(), 3)
  assert_eq(result.result_evidence_refs, [local_ref, lower_ref, url_ref])
  let visible = marketplace_visible_action_requests(completed, reader).stringify()
  assert_true(visible.contains(local_ref))
  assert_true(visible.contains(url_ref))
  // Search/category normalization remains deliberately case-insensitive.
  let tags = normalized_terms([" ROBOTICS ", "Robotics", "Education", " "])
  assert_eq(tags.length(), 2)
  assert_true(tags.contains("robotics"))
  assert_true(tags.contains("education"))
}
