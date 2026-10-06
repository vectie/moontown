///|
struct WenyuOutputPackage {
  contract : String
  work_id : String
  request_digest : String
  result : @moonbook.BookResult
  receipt : Json
  pages : Map[String, String]
  before : Map[String, String]
} derive(ToJson, FromJson)

///|
fn wenyu_output_package(
  launch : WenyuLaunch,
  work : @native_work.Work,
) -> WenyuOutputPackage {
  let receipt = work.receipt.stringify(indent=2)
  let implemented = work.state == "completed" &&
    native_json_text(work.receipt, "engineering_status") ==
    "applied_and_validated"
  let no_change = work.state == "completed" &&
    native_json_text(work.receipt, "engineering_status") == "no_change"
  let pages : Map[String, String] = Map([])
  let identity = "- Task: `" +
    launch.task.id +
    "`\n- Work: `" +
    work.id +
    "`\n- Goal: `" +
    native_json_text(work.request.acceptance_policy, "goal_id") +
    "`\n"
  pages["build/CODE_PATCH.md"] = (if no_change {
      "# Wenyu Code Validation\n\n"
    } else {
      "# Wenyu Code Patch\n\n"
    }) +
    identity +
    "\nEngineering status: " +
    (if no_change {
      "No net source change; required checks passed; human review required; original-task acceptance unevaluated"
    } else if implemented {
      "applied and validated; uncommitted; human review required"
    } else {
      "not accepted; inspect partial changes and blocker"
    }) +
    "\n\n## Worker explanation\n\n" +
    work.output +
    "\n\n## Native source receipt\n\n```json\n" +
    receipt +
    "\n```\n"
  pages["build/TEST_RESULTS.md"] = "# Wenyu Test Results\n\n" +
    identity +
    "\nOnly the saved native evidence below establishes commands, status, final source digest and mutation attribution. Worker prose is not test proof.\n\n```json\n" +
    receipt +
    "\n```\n"
  if !implemented && !no_change {
    pages["build/CODE_BLOCKERS.md"] = "# Wenyu Code Blockers\n\n" +
      identity +
      "\n" +
      @native_work.summary(work) +
      "\n\nUse the saved native work status and exact-target controls. Source edits are not undone by cancellation. A replacement requires explicit supersession; no ACP fallback was dispatched.\n"
  }
  let artifact_root = "raw/build/native/" + work.id
  let result = @moonbook.BookResult::new(
    result_id=launch.task.id,
    summary=@native_work.summary(work) + "; human review required",
    artifacts=pages.keys().to_array() + [artifact_root + "/output-package.json"],
    requires_review=true,
    notify_town=true,
  )
  {
    contract: "moontown.wenyu.output-package.v1",
    work_id: work.id,
    request_digest: work.request_digest,
    result,
    receipt: work.receipt,
    pages,
    before: launch.output_before,
  }
}

///|
/// Immutable package first; exact before/after fingerprints make page replay safe.
/// MoonBook owns its separately idempotent result/evidence/review transaction.
pub async fn import_wenyu_native_result(
  launch : WenyuLaunch,
  work : @native_work.Work,
  persist? : async (@moonbook.BookResult) -> @moonbook.PersistResultOutcome,
  after_page? : async (String) -> Unit,
) -> @moonbook.PersistResultOutcome {
  validate_wenyu_result_binding(launch, work)
  persist_wenyu_output_package(launch, work, persist?, after_page?)
}

///|
// Shared by import and review readback: observing approval never weakens the
// frozen engineering receipt and Work/request identity checks.
fn validate_wenyu_result_binding(
  launch : WenyuLaunch,
  work : @native_work.Work,
) -> Unit raise {
  guard launch.execution == "native" &&
    @native_work.terminal(work.state) &&
    work.state != "superseded" &&
    work.request.work_key == launch.request.work_key &&
    work.request.book_id == launch.entry.id &&
    work.request.book_root == launch.entry.workspace_root &&
    work.request.criterion_id == launch.task.id &&
    work.request_digest ==
    @native_work.digest(work.request.to_json().stringify()) &&
    work.request.to_json() ==
    (
      { ..launch.request, generation: work.request.generation, } :
      @native_work.Request).to_json() else {
    fail("wenyu_result_binding_mismatch")
  }
  if work.state == "completed" {
    let no_change = native_json_text(work.receipt, "engineering_status") ==
      "no_change"
    guard @native_work.wenyu_result_satisfies_contract(
        work,
        work.output,
        no_change~,
      ) &&
      (if no_change {
        @native_work.wenyu_no_change_receipt_satisfies_contract(work)
      } else {
        @native_work.wenyu_mutation_receipt_satisfies_contract(work)
      }) else {
      fail("wenyu_result_evidence_invalid")
    }
    guard work.reservation is Some(reservation) &&
      native_json_text(work.receipt, "contract") ==
      (if no_change {
        "wenyu.build.native_no_change_receipt.v1"
      } else {
        "wenyu.build.native_patch_receipt.v1"
      }) &&
      native_json_text(work.receipt, "request_id") == work.id &&
      native_json_text(work.receipt, "request_digest") == work.request_digest &&
      native_json_text(work.receipt, "book_id") == work.request.book_id &&
      native_json_text(work.receipt, "book_root") == work.request.book_root &&
      native_json_text(work.receipt, "source_root") ==
      work.request.execution_root &&
      native_json_text(work.receipt, "task_id") == launch.task.id &&
      native_json_text(work.receipt, "goal_id") ==
      native_json_text(work.request.acceptance_policy, "goal_id") &&
      native_json_text(work.receipt, "output_digest") ==
      @native_work.digest(work.output) &&
      native_json_text(work.receipt, "session_id") == reservation.session_id &&
      native_json_text(work.receipt, "command_id") == reservation.command_id &&
      native_json_text(work.receipt, "model") == reservation.model &&
      native_json_text(work.receipt, "model_workspace") ==
      reservation.model_workspace &&
      native_json_text(work.receipt, "request_body_digest") ==
      reservation.body_digest &&
      reservation.body_digest == @native_work.digest(reservation.request_body) else {
      fail("wenyu_result_receipt_binding_mismatch")
    }
  }
}

///|
async fn persist_wenyu_output_package(
  launch : WenyuLaunch,
  work : @native_work.Work,
  persist? : async (@moonbook.BookResult) -> @moonbook.PersistResultOutcome,
  after_page? : async (String) -> Unit,
) -> @moonbook.PersistResultOutcome {
  let root = launch.entry.workspace_root
  let directory = "raw/build/native/" + work.id
  let package_path = native_book_file(root, directory + "/output-package.json")
  let outcome_path = native_book_file(
    root,
    directory + "/application-receipt.json",
  )
  let lock_path = native_book_file(root, "raw/build/native/import.lock")
  @support.ensure_parent_directory(lock_path)
  let lock = @fs.open(
    lock_path,
    mode=ReadWrite,
    create_mode=OpenOrCreate,
    permission=0o600,
  )
  defer lock.close()
  lock.lock(Exclusive)
  defer lock.unlock()
  let expected = wenyu_output_package(launch, work)
  let package = if @fs.exists(package_path) {
    let saved : WenyuOutputPackage = @json.from_json(
      @json.parse(@fs.read_file(package_path).text()),
    )
    guard saved.to_json() == expected.to_json() else {
      fail("wenyu_output_package_conflict")
    }
    saved
  } else {
    @support.ensure_parent_directory(package_path)
    @fs.write_file(
      package_path,
      expected.to_json().stringify(indent=2),
      create_mode=CreateNew,
      permission=0o600,
      sync=Full,
    )
    wenyu_sync_ancestors(package_path)
    expected
  }
  if @fs.exists(outcome_path) {
    let saved = @json.parse(@fs.read_file(outcome_path).text())
    guard saved is { "package_digest": String(digest), "outcome": outcome, .. } &&
      digest == @native_work.digest(package.to_json().stringify()) else {
      fail("wenyu_application_receipt_invalid")
    }
    return @json.from_json(outcome)
  }
  // Validate all destinations before updating any one page.
  for relative, content in package.pages {
    guard [
      "build/CODE_PATCH.md", "build/TEST_RESULTS.md", "build/CODE_BLOCKERS.md",
    ].contains(relative) else {
      fail("wenyu_output_path_not_allowed")
    }
    let actual = native_output_fingerprint(root, relative)
    guard Some(actual) == package.before.get(relative) ||
      actual == @native_work.digest(content) else {
      fail("wenyu_output_changed_by_human_or_newer_work: " + relative)
    }
  }
  for
    relative in [
      "build/CODE_PATCH.md", "build/TEST_RESULTS.md", "build/CODE_BLOCKERS.md",
    ] {
    let content = match package.pages.get(relative) {
      Some(content) => content
      None => continue
    }
    let path = native_book_file(root, relative)
    let desired = @native_work.digest(content)
    let current = native_output_fingerprint(root, relative)
    if current == desired {
      continue
    }
    guard Some(current) == package.before.get(relative) else {
      fail("wenyu_output_changed_by_human_or_newer_work: " + relative)
    }
    let next = native_book_file(root, relative + "." + work.id + ".next")
    @support.ensure_parent_directory(path)
    @fs.write_file(next, content, create_mode=CreateOrTruncate, sync=Full)
    let before_replace = native_output_fingerprint(root, relative)
    if before_replace == desired {
      continue
    }
    guard Some(before_replace) == package.before.get(relative) else {
      fail("wenyu_output_changed_by_human_or_newer_work: " + relative)
    }
    @fs.rename(next, path, replace=true)
    wenyu_sync_ancestors(path)
    if after_page is Some(after_page) {
      after_page(relative)
    }
  }
  let outcome = match persist {
    Some(persist) => persist(package.result)
    None =>
      @moonbook.persist_native_wenyu_result(
        launch.entry,
        package.result,
        work.id,
        work.request_digest,
      )
  }
  @fs.write_file(
    outcome_path,
    (
      {
        "contract": "moontown.wenyu.application-receipt.v1",
        "work_id": work.id,
        "package_digest": @native_work.digest(package.to_json().stringify()),
        "outcome": outcome,
      } : Json).stringify(indent=2),
    create_mode=CreateNew,
    permission=0o600,
    sync=Full,
  )
  wenyu_sync_ancestors(outcome_path)
  outcome
}
