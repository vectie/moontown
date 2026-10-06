///|
// The audit supplies a freshly built verification-only bridge. Ordinary package
// runs still cover the injected binding tests; this explicit mode proves the
// actual Book import/manual-review/query APIs and Town read-only adapter together.
async test "native actual Book manual review readback keeps original goal acceptance unevaluated" {
  guard @env.get_env_var("WENYU_TEST_BOOK_REVIEW_BIN") is Some(binary) else {
    return
  }
  for action in ["approve", "reject"] {
    let (launch, work) = wenyu_owner_fixture("book-journey-" + action)
    let keys = [
      "HOME", "MOONTOWN_SUITE_ROOT", "MOONSUITE_ROOT", "MOONTOWN_MOONBOOK_ROOT",
      "MOONTOWN_MOONBOOK_BIN",
    ]
    let old = keys.map(key => @env.get_env_var(key))
    defer wenyu_test_restore_envs(keys, old)
    let cli_root = launch.entry.workspace_root + "/cli-home"
    @fs.mkdir(cli_root)
    @env.set_env_var("HOME", cli_root)
    @env.set_env_var("MOONTOWN_SUITE_ROOT", cli_root)
    @env.set_env_var("MOONSUITE_ROOT", cli_root)
    @env.set_env_var("MOONTOWN_MOONBOOK_ROOT", cli_root)
    @env.set_env_var("MOONTOWN_MOONBOOK_BIN", binary)
    let result = wenyu_output_package(launch, work).result
    let payload_digest = @native_work.digest(result.to_json().stringify())
    let empty_files = @fs.readdir(launch.entry.workspace_root)
    let missing = @moonbook.read_native_wenyu_review(
      launch.entry,
      work.id,
      work.request_digest,
      payload_digest,
      launch.task.id,
    )
    assert_eq(missing.status, "unresolved")
    assert_eq(@fs.readdir(launch.entry.workspace_root), empty_files)
    @support.write_text_file(
      wenyu_launch_path(launch.native_path, launch.task.id),
      launch.to_json().stringify(),
    )
    @support.write_text_file(
      launch.native_path,
      (
        {
          "schema": "moontown.native-work.v1",
          "revision": 1,
          "work": [work.to_json()],
        } : Json).stringify(),
    )
    let payload_path = cli_root + "/import.json"
    @support.write_text_file(
      payload_path,
      (
        {
          "book_result": result.to_json(),
          "native_import": {
            "contract": "moontown.wenyu.import.v1",
            "work_id": work.id,
            "request_digest": work.request_digest,
            "payload_digest": payload_digest,
          },
        } : Json).stringify(),
    )
    ignore(
      import_wenyu_native_result(launch, work, persist=async fn(_) {
        @json.from_json(
          @integration.run_json(binary, [
            "wiki",
            "extension",
            "persist",
            launch.entry.workspace_root,
            payload_path,
          ]),
        )
      }),
    )
    let execution = wenyu_native_execution_record(
      launch,
      work,
      1,
      imported=true,
    )
    let pending = reconcile_wenyu_native_review(launch.entry, execution, 2)
    assert_eq(pending.status, ReviewQueued)
    assert_true(pending.requires_review)
    let review_id = "result-review-native-wenyu-" + @native_work.digest(work.id)
    ignore(
      @integration.run_checked(binary, [
        "wiki",
        "review",
        action,
        launch.entry.workspace_root,
        review_id,
      ]),
    )
    let readback = reconcile_wenyu_native_review(launch.entry, pending, 3)
    assert_eq(
      readback.status,
      if action == "approve" {
        AwaitingAcceptance
      } else {
        Failed
      },
    )
    assert_false(readback.requires_review)
    assert_eq(readback.next_retry_tick, None)
    assert_true(
      readback.summary.contains(
        "original-task and goal acceptance remain unevaluated",
      ),
    )
    let native_before = @fs.read_file(launch.native_path).text()
    let approved_before = @fs.read_file(
      launch.entry.workspace_root + "/wiki/reviews/approved.md",
    ).text()
    ignore(import_wenyu_native_result(launch, work))
    let reload : @core.TaskExecutionRecord = @json.from_json(
      @json.parse(readback.to_json().stringify()),
    )
    let again = reconcile_wenyu_native_review(launch.entry, reload, 100)
    assert_eq(again, readback)
    assert_eq(@fs.read_file(launch.native_path).text(), native_before)
    assert_eq(
      @fs.read_file(launch.entry.workspace_root + "/wiki/reviews/approved.md").text(),
      approved_before,
    )
    assert_false(
      @fs.exists(launch.entry.workspace_root + "/moonclaw.jobs.json"),
    )
    println("WENYU_REAL_REVIEW_PROOF " + action + " " + work.id)
  }
}
