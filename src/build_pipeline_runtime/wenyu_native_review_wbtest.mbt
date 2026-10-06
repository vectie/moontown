///|
fn wenyu_review_test_resolution(
  launch : WenyuLaunch,
  work : @native_work.Work,
  status : String,
) -> @moonbook.NativeWenyuReviewResolution raise {
  let key = @native_work.digest(work.id)
  let value : Json = {
    "contract": "moonbook.native-wenyu-review.v1",
    "status": status,
    "root": launch.entry.workspace_root,
    "work_id": work.id,
    "request_digest": work.request_digest,
    "payload_digest": @native_work.digest(
      wenyu_output_package(launch, work).result.to_json().stringify(),
    ),
    "result_id": launch.task.id,
    "review_id": "result-review-native-wenyu-" + key,
    "evidence_id": "EV-native-wenyu-" + key,
    "original_task_acceptance": "unevaluated",
    "reason": "Synthetic Book review observation",
  }
  if status == "approved" || status == "rejected" {
    wenyu_owner_set(value, "resolution_timestamp", "-123".to_json())
  }
  @json.from_json(value)
}

///|
async fn wenyu_review_test_saved(
  label : String,
  failed? : Bool = false,
) -> (WenyuLaunch, @native_work.Work, @core.TaskExecutionRecord) {
  let (launch, completed) = wenyu_owner_fixture("human-review-" + label)
  let work = if failed {
    { ..completed, state: "failed", blocked_reason: "validation_failed", }
  } else {
    completed
  }
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
  ignore(
    import_wenyu_native_result(launch, work, persist=async fn(result) {
      let outcome = wenyu_owner_outcome(result).to_json()
      let evidence = "EV-native-wenyu-" + @native_work.digest(work.id)
      wenyu_owner_set(outcome, "evidence_id", evidence.to_json())
      guard outcome is Object(fields) else { fail("fixture outcome") }
      wenyu_owner_set(
        fields["executable_event"],
        "evidence_id",
        evidence.to_json(),
      )
      @json.from_json(outcome)
    }),
  )
  (launch, work, wenyu_native_execution_record(launch, work, 1, imported=true))
}

///|
async test "native Book review disposition clears only human review and preserves immutable engineering evidence" {
  let (launch, work, execution) = wenyu_review_test_saved("states")
  let native_before = @fs.read_file(launch.native_path).text()
  let directory = launch.entry.workspace_root + "/raw/build/native/" + work.id
  let package_before = @fs.read_file(directory + "/output-package.json").text()
  let receipt_before = @fs.read_file(directory + "/application-receipt.json").text()
  for status in ["pending", "unresolved", "approved", "rejected"] {
    let resolution = wenyu_review_test_resolution(launch, work, status)
    let projected = reconcile_wenyu_native_review_with_query(
      launch.entry,
      execution,
      9,
      query=async fn(_, _, _, _, _) { resolution },
    )
    assert_eq(projected.packet_id, work.id)
    assert_eq(projected.next_retry_tick, None)
    assert_true(projected.summary.contains("acceptance remain unevaluated"))
    if status == "approved" {
      assert_eq(projected.status, AwaitingAcceptance)
      assert_false(projected.requires_review)
      assert_eq(projected.result_decision, "native-book-review-approved")
      assert_eq(@core.town_task_status_for_execution(projected.status), Blocked)
      let replayed = reconcile_wenyu_native_review_with_query(
        launch.entry,
        projected,
        100,
        query=async fn(_, _, _, _, _) { resolution },
      )
      assert_eq(replayed, projected)
    } else if status == "rejected" {
      assert_eq(projected.status, Failed)
      assert_false(projected.requires_review)
      assert_eq(projected.result_decision, "native-book-review-rejected")
    } else {
      assert_eq(projected.status, ReviewQueued)
      assert_true(projected.requires_review)
    }
    assert_false(projected.status == Completed)
  }
  assert_eq(@fs.read_file(launch.native_path).text(), native_before)
  assert_false(@fs.exists(launch.native_path + ".lock"))
  assert_eq(
    @fs.read_file(directory + "/output-package.json").text(),
    package_before,
  )
  assert_eq(
    @fs.read_file(directory + "/application-receipt.json").text(),
    receipt_before,
  )
  let replayed = import_wenyu_native_result(launch, work, persist=async fn(_) {
    fail("committed replay must not persist again")
  })
  assert_true(replayed.review_queued)
  assert_false(replayed.executable_event.accepted)
}

///|
async test "approving a failed native work note never converts engineering failure into success" {
  let (launch, work, execution) = wenyu_review_test_saved("failed", failed=true)
  let resolution = wenyu_review_test_resolution(launch, work, "approved")
  let projected = reconcile_wenyu_native_review_with_query(
    launch.entry,
    execution,
    10,
    query=async fn(_, _, _, _, _) { resolution },
  )
  assert_eq(projected.status, Failed)
  assert_false(projected.requires_review)
  assert_eq(projected.next_retry_tick, None)
  assert_true(projected.summary.contains("failed"))
}

///|
async test "native review rejects wrong work root request result and package before projecting approval" {
  let (launch, work, execution) = wenyu_review_test_saved("binding")
  let valid = wenyu_review_test_resolution(launch, work, "approved")
  for
    key in [
      "root", "work_id", "request_digest", "payload_digest", "result_id", "review_id",
      "evidence_id", "original_task_acceptance",
    ] {
    let raw = valid.to_json()
    wenyu_owner_set(raw, key, "wrong-binding".to_json())
    let wrong : @moonbook.NativeWenyuReviewResolution = @json.from_json(raw)
    try
      reconcile_wenyu_native_review_with_query(launch.entry, execution, 2, query=async fn(
        _,
        _,
        _,
        _,
        _,
      ) {
        wrong
      })
    catch {
      error =>
        assert_true(error.to_string().contains("binding_mismatch"), msg=key)
    } noraise {
      _ => fail("approved mismatched " + key)
    }
  }
  let wrong = copy_execution_with(execution, packet_id="other-work")
  try
    reconcile_wenyu_native_review_with_query(launch.entry, wrong, 2, query=async fn(
      _,
      _,
      _,
      _,
      _,
    ) {
      fail("query must not run")
    })
  catch {
    error => assert_true(error.to_string().contains("work_missing"))
  } noraise {
    _ => fail("accepted wrong work")
  }
  let path = launch.entry.workspace_root +
    "/raw/build/native/" +
    work.id +
    "/application-receipt.json"
  @support.write_text_file(path, "{}")
  try
    reconcile_wenyu_native_review_with_query(launch.entry, execution, 2, query=async fn(
      _,
      _,
      _,
      _,
      _,
    ) {
      fail("query must not run")
    })
  catch {
    error =>
      assert_true(error.to_string().contains("application_receipt_mismatch"))
  } noraise {
    _ => fail("accepted partial receipt")
  }
}

///|
async test "native readback recovers after import replay without requeuing approved Book review" {
  let (launch, work, original) = wenyu_review_test_saved("replay")
  let resolution = wenyu_review_test_resolution(launch, work, "approved")
  let approved = reconcile_wenyu_native_review_with_query(
    launch.entry,
    original,
    4,
    query=async fn(_, _, _, _, _) { resolution },
  )
  ignore(import_wenyu_native_result(launch, work))
  let reconstructed = wenyu_native_execution_record(
    launch,
    work,
    5,
    imported=true,
  )
  let restored = read_wenyu_imported_review(launch, work, reconstructed, 6, query=async fn(
    _,
    _,
    _,
    _,
    _,
  ) {
    resolution
  })
  assert_eq(restored.status, AwaitingAcceptance)
  assert_eq(restored.summary, approved.summary)
  assert_false(restored.requires_review)
  let pending = wenyu_review_test_resolution(launch, work, "unresolved")
  let conflicted = reconcile_wenyu_native_review_with_query(
    launch.entry,
    approved,
    9,
    query=async fn(_, _, _, _, _) { pending },
  )
  assert_eq(conflicted.status, ReviewQueued)
  assert_true(conflicted.requires_review)
}
