///|
fn wenyu_review_summary(
  work : @native_work.Work,
  resolution : @moonbook.NativeWenyuReviewResolution,
) -> String {
  @native_work.summary(work) +
  "; Book review " +
  resolution.status +
  "; review_id=" +
  resolution.review_id +
  "; work_id=" +
  work.id +
  "; request_digest=" +
  work.request_digest +
  "; payload_digest=" +
  resolution.payload_digest +
  "; resolution_timestamp=" +
  resolution.resolution_timestamp.unwrap_or("") +
  "; original-task and goal acceptance remain unevaluated" +
  (if resolution.status == "rejected" {
    "; rework requires an explicit operator decision"
  } else {
    "; awaiting acceptance"
  })
}

///|
fn project_wenyu_review_resolution(
  execution : @core.TaskExecutionRecord,
  work : @native_work.Work,
  resolution : @moonbook.NativeWenyuReviewResolution,
  tick : Int,
) -> @core.TaskExecutionRecord {
  if resolution.status != "approved" && resolution.status != "rejected" {
    // If the Book evidence was removed or became inconsistent, do not preserve
    // a resolved badge from an earlier observation.
    return copy_execution_with(
      execution,
      status=if work.state == "completed" { ReviewQueued } else { Failed },
      summary=@native_work.summary(work) +
        "; Book review " +
        resolution.status +
        "; " +
        resolution.reason +
        "; original-task and goal acceptance remain unevaluated",
      next_retry_tick=None,
      result_decision=if work.state == "completed" {
        "native-persisted-review"
      } else {
        "native-blocked-review"
      },
      requires_review=true,
    )
  }
  let status : @core.TaskExecutionStatus = if resolution.status == "approved" &&
    work.state == "completed" {
    AwaitingAcceptance
  } else {
    Failed
  }
  let decision = if resolution.status == "approved" {
    "native-book-review-approved"
  } else {
    "native-book-review-rejected"
  }
  let summary = wenyu_review_summary(work, resolution)
  if execution.status == status &&
    execution.result_decision == decision &&
    execution.summary == summary &&
    !execution.requires_review &&
    execution.next_retry_tick is None {
    return execution
  }
  copy_execution_with(
    execution,
    status~,
    summary~,
    heartbeat_tick=tick,
    next_retry_tick=None,
    result_decision=decision,
    requires_review=false,
  )
}

///|
async fn read_wenyu_imported_review(
  launch : WenyuLaunch,
  work : @native_work.Work,
  execution : @core.TaskExecutionRecord,
  tick : Int,
  query? : async (@moonbook.BookCatalogEntry, String, String, String, String) -> @moonbook.NativeWenyuReviewResolution,
) -> @core.TaskExecutionRecord {
  validate_wenyu_result_binding(launch, work)
  guard execution.task_id == launch.task.id &&
    execution.book_id == launch.entry.id &&
    execution.packet_id == work.id &&
    execution.packet_path ==
    wenyu_launch_path(launch.native_path, launch.task.id) &&
    is_wenyu_native_execution(execution) else {
    fail("wenyu_review_execution_binding_mismatch")
  }
  let directory = "raw/build/native/" + work.id
  let package_path = native_book_file(
    launch.entry.workspace_root,
    directory + "/output-package.json",
  )
  let receipt_path = native_book_file(
    launch.entry.workspace_root,
    directory + "/application-receipt.json",
  )
  guard @fs.kind(package_path, follow_symlink=false) is Regular &&
    @fs.kind(receipt_path, follow_symlink=false) is Regular else {
    fail("wenyu_review_committed_package_missing")
  }
  let package_bytes = @fs.read_file(package_path).text()
  let receipt_bytes = @fs.read_file(receipt_path).text()
  let package : WenyuOutputPackage = @json.from_json(@json.parse(package_bytes))
  guard package.to_json() == wenyu_output_package(launch, work).to_json() else {
    fail("wenyu_review_output_package_mismatch")
  }
  let receipt = @json.parse(receipt_bytes)
  guard receipt
    is {
      "contract": "moontown.wenyu.application-receipt.v1",
      "work_id": String(work_id),
      "package_digest": String(package_digest),
      "outcome": outcome,
      ..
    } &&
    work_id == work.id &&
    package_digest == @native_work.digest(package.to_json().stringify()) else {
    fail("wenyu_review_application_receipt_mismatch")
  }
  let imported : @moonbook.PersistResultOutcome = @json.from_json(outcome)
  let key = @native_work.digest(work.id)
  guard imported.review_queued &&
    imported.evidence_id == "EV-native-wenyu-" + key &&
    imported.executable_event.result_id == launch.task.id &&
    imported.executable_event.evidence_id == Some(imported.evidence_id) &&
    imported.executable_event.requires_review &&
    !imported.executable_event.accepted else {
    fail("wenyu_review_original_outcome_mismatch")
  }
  let payload_digest = @native_work.digest(package.result.to_json().stringify())
  let resolution = match query {
    Some(query) =>
      query(
        launch.entry,
        work.id,
        work.request_digest,
        payload_digest,
        launch.task.id,
      )
    None =>
      @moonbook.read_native_wenyu_review(
        launch.entry,
        work.id,
        work.request_digest,
        payload_digest,
        launch.task.id,
      )
  }
  @moonbook.validate_native_wenyu_review_resolution(
    resolution,
    launch.entry,
    work.id,
    work.request_digest,
    payload_digest,
    launch.task.id,
  )
  guard @fs.read_file(package_path).text() == package_bytes &&
    @fs.read_file(receipt_path).text() == receipt_bytes else {
    fail("wenyu_review_package_changed_during_readback")
  }
  project_wenyu_review_resolution(execution, work, resolution, tick)
}

///|
/// Observe a saved, imported native Work's exact Book review. This never syncs
/// a native command, reapplies an output package, or accepts the original goal.
///
/// ```mbt check
/// test {
///   let observe = async fn(
///     entry : @moonbook.BookCatalogEntry,
///     execution : @core.TaskExecutionRecord,
///   ) {
///     @build_pipeline_runtime.reconcile_wenyu_native_review(entry, execution, 0)
///   }
///   ignore(observe)
/// }
/// ```
pub async fn reconcile_wenyu_native_review(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
  tick : Int,
) -> @core.TaskExecutionRecord {
  reconcile_wenyu_native_review_with_query(entry, execution, tick)
}

///|
async fn reconcile_wenyu_native_review_with_query(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
  tick : Int,
  query? : async (@moonbook.BookCatalogEntry, String, String, String, String) -> @moonbook.NativeWenyuReviewResolution,
) -> @core.TaskExecutionRecord {
  let launch = load_wenyu_launch(execution.packet_path)
  guard launch.execution == "native" &&
    launch.entry.id == entry.id &&
    launch.entry.workspace_root == entry.workspace_root &&
    launch.task.id == execution.task_id &&
    entry.id == execution.book_id &&
    @fs.exists(launch.native_path) else {
    fail("wenyu_review_launch_binding_mismatch")
  }
  let state_bytes = @fs.read_file(launch.native_path).text()
  let saved = @native_work.read_saved(path=launch.native_path)
  let work = match
    saved.work.iter().find_first(work => work.id == execution.packet_id) {
    Some(work) => work
    None => fail("wenyu_review_work_missing")
  }
  let projected = read_wenyu_imported_review(
    launch,
    work,
    execution,
    tick,
    query?,
  )
  guard @fs.read_file(launch.native_path).text() == state_bytes else {
    fail("wenyu_review_native_state_changed_during_readback")
  }
  projected
}
