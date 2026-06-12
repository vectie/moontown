///|
async test "live autonomy surfaces book template request inbox" {
  let workspace = live_autonomy_test_workspace(
    "/tmp/moontown-live-autonomy-template-request-check",
  )
  let snapshot_path = workspace.snapshot_path
  ignore(
    @book_templates.save_request_ledger(
      @book_templates.request_path_for_snapshot(snapshot_path),
      {
        requests: [
          {
            id: "request-pdf-watch",
            template_id: "pdf-evidence-watch",
            config_path: "requests/pdf-watch.json",
            status: "pending",
            summary: "waiting for daemon",
            last_processed_tick: 0,
          },
          {
            id: "request-bad-config",
            template_id: "pdf-evidence-watch",
            config_path: "requests/missing.json",
            status: "failed",
            summary: "missing config",
            last_processed_tick: 4,
          },
        ],
      },
    ),
  )
  let state = @test_fixtures.visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    tick_summary="template inbox tick",
  )
  assert_eq(spine.book_template_request_count, 2)
  assert_eq(spine.pending_book_template_request_count, 1)
  assert_eq(spine.failed_book_template_request_count, 1)
  assert_eq(spine.enabled_standing_goal_count, 0)
  assert_eq(spine.disabled_standing_goal_count, 0)
  assert_eq(spine.book_template_latest_event_summary, "none")
  assert_true(spine.summary.contains("template_requests=2"))
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(status.contains("Book template requests: `2`"))
  assert_true(status.contains("Pending template requests: `1`"))
  assert_true(status.contains("Failed template requests: `1`"))
  assert_true(status.contains("Enabled standing goals: `0`"))
  assert_true(status.contains("Disabled standing goals: `0`"))
  assert_true(status.contains("Latest book-template event: none"))
  assert_true(status.contains("Inspect failed book-template request configs"))
  let digest_text = @support.read_text_or_empty(
    default_live_digest_path(snapshot_path~),
  )
  assert_true(digest_text.contains("book_template_requests: `2`"))
  assert_true(digest_text.contains("enabled_standing_goals: `0`"))
  assert_true(digest_text.contains("disabled_standing_goals: `0`"))
  assert_true(digest_text.contains("failed_book_template_requests: `1`"))
  assert_true(digest_text.contains("book_template_latest_event: none"))
}
