///|
fn runtime_result_running_request() -> (MarketplaceState, MarketplacePrincipal) raise {
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
  (
    {
      ..requested,
      action_requests: [
        {
          ..requested.action_requests[0],
          state: ActionRunning,
          execution_handoff_id: Some("supervisor-execution-summary-test"),
          worker_run_id: Some("worker-summary-test"),
          runtime_status: "running",
        },
      ],
    },
    reader,
  )
}

///|
fn runtime_result_draft(
  summary : String,
  status : String,
) -> ActionRequestRuntimeDraft {
  {
    handoff_id: "supervisor-execution-summary-test",
    runtime_status: status,
    worker_run_id: "worker-summary-test",
    result_summary: summary,
    result_evidence_refs: ["books/coding/artifacts/QuarterlyReport.PDF"],
  }
}

///|
test "oversized Unicode result settles success without exposing private output" {
  let (running, reader) = runtime_result_running_request()
  let content = StringBuilder()
  for _ in 0..<900 {
    content.write_string("结论🙂")
  }
  let private_output : Json = {
    "summary": content.to_string(),
    "artifact_evidence": [
      {
        "artifact_ref": "books/coding/artifacts/QuarterlyReport.PDF",
        "digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      },
    ],
  }
  let private_output = private_output.stringify()
  assert_true(private_output.length() > 2000)
  let draft = runtime_result_draft(private_output, "succeeded")
  let completed = marketplace_reconcile_action_request_runtime(
    running,
    draft,
    now_ms=140UL,
  )
  let request = completed.action_requests[0]
  assert_eq(request.state, ActionSucceeded)
  assert_eq(request.runtime_status, "succeeded")
  assert_true(
    request.result_summary.contains(
      "Detailed output remains with the publisher",
    ),
  )
  assert_false(request.result_summary.contains("结论"))
  assert_true(request.result_summary.length() <= 2000)
  assert_eq(request.worker_run_id, Some("worker-summary-test"))
  assert_eq(
    request.execution_handoff_id,
    Some("supervisor-execution-summary-test"),
  )
  assert_eq(request.result_evidence_refs, [
    "books/coding/artifacts/QuarterlyReport.PDF",
  ])
  assert_eq(draft.result_summary, private_output)
  let visible = marketplace_visible_action_requests(completed, reader).stringify()
  assert_false(visible.contains("结论"))
  assert_false(completed.notifications.to_json().stringify().contains("结论"))
  assert_true(visible.contains("worker-summary-test"))
  assert_true(visible.contains("QuarterlyReport.PDF"))
}

///|
test "private-looking result prose cannot strand successful work or leak to projection" {
  for
    raw in [
      "The authorization checks passed.", "Verified /home/private/report.md with internal notes.",
      "The workspace_root field points to the private source.", "OAuth integration result is ready.",
      "\"api_key\": \"synthetic-do-not-share\"",
    ] {
    let (running, reader) = runtime_result_running_request()
    let completed = marketplace_reconcile_action_request_runtime(
      running,
      runtime_result_draft(raw, "succeeded"),
      now_ms=140UL,
    )
    let request = completed.action_requests[0]
    assert_eq(request.state, ActionSucceeded)
    assert_eq(request.result_evidence_refs, [
      "books/coding/artifacts/QuarterlyReport.PDF",
    ])
    assert_false(request.result_summary.contains(raw))
    assert_false(
      marketplace_visible_action_requests(completed, reader)
      .stringify()
      .contains(raw),
    )
    assert_false(
      completed.notifications
      .to_json()
      .stringify()
      .contains("synthetic-do-not-share"),
    )
    // The existing publication validator stays strict even though runtime
    // settlement now has a safe, fixed fallback.
    try validate_public_text("fixture", raw, 2000) catch {
      _ => ()
    } noraise {
      _ => fail("privacy validator must continue rejecting this raw detail")
    }
  }
}

///|
test "ordinary public result summary and exact references remain unchanged" {
  let (running, reader) = runtime_result_running_request()
  let completed = marketplace_reconcile_action_request_runtime(
    running,
    runtime_result_draft("  The report is ready.  ", "succeeded"),
    now_ms=140UL,
  )
  let request = completed.action_requests[0]
  assert_eq(request.result_summary, "The report is ready.")
  assert_eq(request.state, ActionSucceeded)
  assert_eq(request.worker_run_id, Some("worker-summary-test"))
  assert_true(
    marketplace_visible_action_requests(completed, reader)
    .stringify()
    .contains("The report is ready."),
  )
}

///|
test "unshareable failure and cancellation detail preserve their actual terminal state" {
  for status in ["failed", "runtime_failed", "cancelled"] {
    let (running, _) = runtime_result_running_request()
    let completed = marketplace_reconcile_action_request_runtime(
      running,
      runtime_result_draft("Private error at /home/private/source", status),
      now_ms=140UL,
    )
    let request = completed.action_requests[0]
    assert_eq(request.state, ActionFailed)
    assert_eq(request.runtime_status, status)
    assert_false(request.result_summary.contains("/home/private"))
    assert_false(request.result_summary.contains("completed"))
    assert_true(
      request.result_summary.contains(
        if status == "cancelled" {
          "cancelled"
        } else {
          "failed"
        },
      ),
    )
    assert_eq(request.worker_run_id, Some("worker-summary-test"))
    assert_eq(request.result_evidence_refs, [
      "books/coding/artifacts/QuarterlyReport.PDF",
    ])
  }
}

///|
test "terminal replay keeps the original exact result without duplicate notifications" {
  let (running, _) = runtime_result_running_request()
  let first = marketplace_reconcile_action_request_runtime(
    running,
    runtime_result_draft("Authorization checks completed", "succeeded"),
    now_ms=140UL,
  )
  let replayed = marketplace_reconcile_action_request_runtime(
    first,
    runtime_result_draft("/home/private/new-content", "succeeded"),
    now_ms=150UL,
  )
  assert_eq(replayed, first)
  let reloaded : MarketplaceState = @json.from_json(
    @json.parse(replayed.to_json().stringify()),
  )
  assert_eq(reloaded, first)
  assert_eq(
    reloaded.action_requests[0].worker_run_id,
    Some("worker-summary-test"),
  )
  try
    marketplace_reconcile_action_request_runtime(
      reloaded,
      runtime_result_draft("Late failure", "failed"),
      now_ms=160UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("terminal state changes remain a separate unsupported operation")
  }
}

///|
test "empty and whitespace-only result detail cannot block terminal settlement" {
  for detail in ["", " \t\n"] {
    let (running, _) = runtime_result_running_request()
    let completed = marketplace_reconcile_action_request_runtime(
      running,
      runtime_result_draft(detail, "succeeded"),
      now_ms=140UL,
    )
    assert_eq(completed.action_requests[0].state, ActionSucceeded)
  }
}

///|
async test "real marketplace store persists safe terminal result across restart" {
  let (running, reader) = runtime_result_running_request()
  let path = "/tmp/moontown-result-summary-" +
    @env.now().to_string() +
    "/state.json"
  let owner = test_principal("publisher-a", ["publisher"])
  let app = marketplace_application(
    path, owner, "summary-session", "synthetic-summary-token",
  )
  app.save_state(running)
  let output : Json = {
    "summary": "The authorization checks passed; private source /home/private/project remains unchanged.",
    "artifact_evidence": [],
  }
  let draft = runtime_result_draft(output.stringify(), "succeeded")
  let response = app.reconcile_runtime_handoff(draft, now_ms=140UL)
  assert_true(response.stringify().contains("succeeded"))
  let restarted = marketplace_application(
    path, owner, "summary-session", "synthetic-summary-token",
  )
  let saved = restarted.load_state()
  assert_eq(saved.action_requests[0].state, ActionSucceeded)
  assert_eq(saved.action_requests[0].worker_run_id, Some("worker-summary-test"))
  assert_eq(saved.action_requests[0].result_evidence_refs, [
    "books/coding/artifacts/QuarterlyReport.PDF",
  ])
  assert_false(@fs.read_file(path).text().contains("/home/private/project"))
  assert_false(
    marketplace_visible_action_requests(saved, reader)
    .stringify()
    .contains("authorization"),
  )
  let replay = restarted.reconcile_runtime_handoff(draft, now_ms=150UL)
  assert_true(replay.stringify().contains("succeeded"))
  assert_eq(restarted.load_state(), saved)
}

///|
test "summary fallback cannot accept unknown status or rewrite a failed request" {
  let (running, _) = runtime_result_running_request()
  try
    marketplace_reconcile_action_request_runtime(
      running,
      runtime_result_draft(
        "Private result /home/private/source", "unknown-status",
      ),
      now_ms=140UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("unknown runtime status must remain rejected")
  }
  let failed = marketplace_reconcile_action_request_runtime(
    running,
    runtime_result_draft("Private failure /home/private/source", "failed"),
    now_ms=140UL,
  )
  try
    marketplace_reconcile_action_request_runtime(
      failed,
      runtime_result_draft(
        "Private later success /home/private/source", "succeeded",
      ),
      now_ms=150UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("failed request may not be rewritten by the summary fallback")
  }
  assert_eq(failed.action_requests[0].state, ActionFailed)
  assert_eq(failed.action_requests[0].runtime_status, "failed")
}
