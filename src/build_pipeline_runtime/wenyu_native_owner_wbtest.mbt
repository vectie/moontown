///|
async fn wenyu_owner_fixture(
  label : String,
) -> (WenyuLaunch, @native_work.Work) {
  let root = "/tmp/town-wenyu-owner-" + label + "-" + @env.now().to_string()
  @fs.mkdir(root)
  let book = root + "/book"
  @fs.mkdir(book)
  let entry = @moonbook.BookCatalogEntry::new(
    id="book",
    name="Wenyu",
    purpose="Synthetic owner regression",
    workspace_root=book,
  )
  let task = @moonbook.BookTask::new(
    id="task",
    title="Patch",
    kind="code-patch",
    prompt="Implement the frozen task",
    priority=1,
    requires_review=true,
    target_pages=[
      "build/CODE_PATCH.md", "build/TEST_RESULTS.md", "repo:this-moontown-checkout",
    ],
  )
  let prompt = task.prompt
  let request : @native_work.Request = {
    kind: "wenyu_build",
    work_key: "wenyu:book:goal:task",
    generation: 0,
    owner_workspace: root + "/owner",
    book_id: "book",
    book_root: book,
    book_type: "wenyu",
    catalog_path: root + "/catalog.json",
    execution_root: root + "/source",
    source_binding: { "root": root + "/source" },
    criterion_id: task.id,
    model_request: "",
    prompt,
    input_blocker: "",
    input_digest: @native_work.digest(prompt),
    output_contract: "wenyu.build.native-result.v1",
    result_path: book + "/build/CODE_PATCH.md",
    acceptance_policy: {
      "contract": "wenyu.build.native-policy.v1",
      "goal_id": "goal",
      "task_id": task.id,
      "task_kind": "code-patch",
      "commit_requirement": "not_requested",
      "required_validation_commands": ["moon check --no-render"],
      "preserve_preexisting_unrelated_dirty_files": true,
      "push_requested": false,
    },
    created_at_ms: 1UL,
  }
  let before : Map[String, String] = Map([])
  for
    path in [
      "build/CODE_PATCH.md", "build/TEST_RESULTS.md", "build/CODE_BLOCKERS.md",
    ] {
    before[path] = "absent"
  }
  let launch : WenyuLaunch = {
    schema: "moontown.wenyu.launch.v1",
    execution: "native",
    native_path: root + "/native.json",
    entry,
    task,
    request,
    output_before: before,
  }
  let request = { ..request, generation: 1, }
  let request_digest = @native_work.digest(request.to_json().stringify())
  let id = "town-work-" + request_digest[:32].to_owned()
  let body = (
    {
      "protocol": "mooncode.v1",
      "session_id": id,
      "book_root": request.execution_root,
      "command": "prompt",
      "packet": { "command_id": id + "-build" },
    } : Json).stringify()
  let reservation : @native_work.Reservation = {
    session_id: id,
    command_id: id + "-build",
    model: "moongate/synthetic",
    model_workspace: request.owner_workspace,
    execution_root: request.execution_root,
    config_path: root + "/unused-config.json",
    request_body: body,
    body_digest: @native_work.digest(body),
    reserved_at_ms: 2UL,
  }
  let output = (
    {
      "contract": request.output_contract,
      "work_id": id,
      "book_id": "book",
      "task_id": task.id,
      "goal_id": "goal",
      "outcome": "implemented",
      "summary": "Implemented synthetic patch",
      "behavior": "Expected synthetic behavior",
      "residual_risks": [],
    } : Json).stringify()
  let baseline : Json = {
    "root": request.execution_root,
    "head": "head",
    "index_digest": "index",
    "source_digest": "before",
  }
  let receipt : Json = {
    "contract": "wenyu.build.native_patch_receipt.v1",
    "request_id": id,
    "request_digest": request_digest,
    "book_id": "book",
    "book_root": book,
    "task_id": task.id,
    "goal_id": "goal",
    "source_root": request.execution_root,
    "model_workspace": reservation.model_workspace,
    "model": reservation.model,
    "session_id": reservation.session_id,
    "command_id": reservation.command_id,
    "request_body_digest": reservation.body_digest,
    "output_digest": @native_work.digest(output),
    "engineering_status": "applied_and_validated",
    "commit_status": "not_requested",
    "push_status": "not_requested",
    "push_performed": null,
    "publication_verification": "not_verified",
    "checked_source_digest": "after",
    "baseline": baseline,
    "final_observation": {
      "root": request.execution_root,
      "head": "head",
      "index_digest": "index",
      "source_digest": "after",
    },
    "changed_files": [
      {
        "path": "source.mbt",
        "before_fingerprint": "before",
        "after_fingerprint": "after",
        "event_id": "write-1",
      },
    ],
    "validation_commands": [
      {
        "command": "moon check --no-render",
        "exit_code": 0,
        "event_id": "check-2",
      },
    ],
    "focused_diff": "+synthetic change",
    "original_task_acceptance": "unevaluated",
  }
  (
    launch,
    {
      id,
      request,
      request_digest,
      state: "completed",
      blocked_reason: "",
      reservation: Some(reservation),
      control: None,
      baseline,
      observed_instances: ["synthetic-instance"],
      last_attempt_at_ms: 3UL,
      retry_after_ms: 0UL,
      output,
      receipt,
    },
  )
}

///|
fn wenyu_owner_outcome(
  result : @moonbook.BookResult,
) -> @moonbook.PersistResultOutcome raise {
  @json.from_json({
    "log_path": "synthetic-log",
    "updated_pages": result.artifacts,
    "review_queued": true,
    "notify_town": true,
    "evidence_id": "synthetic-evidence",
    "executable_event_path": "synthetic-event",
    "latest_executable_event_path": "synthetic-latest-event",
    "executable_event": {
      "protocol": "moonbook.executable_event.v1",
      "id": "synthetic-event",
      "source": "moonbook",
      "book_id": "book",
      "result_id": result.result_id,
      "event_type": "review_required",
      "accepted": false,
      "requires_review": true,
      "notify_town": true,
      "summary": result.summary,
      "artifacts": result.artifacts,
      "evidence_id": "synthetic-evidence",
      "review_path": "synthetic-review",
    },
  })
}

///|
fn wenyu_owner_set(value : Json, key : String, replacement : Json) -> Unit {
  if value is Object(fields) {
    fields[key] = replacement
  }
}

///|
async test "wenyu owner import saves one immutable package and reuses application receipt" {
  let (launch, work) = wenyu_owner_fixture("replay")
  let calls = [0]
  let persist = async fn(result : @moonbook.BookResult) {
    calls[0] += 1
    assert_eq(result.result_id, launch.task.id)
    assert_true(result.requires_review)
    assert_true(result.notify_town)
    assert_true(result.artifacts.contains("build/CODE_PATCH.md"))
    assert_true(result.artifacts.contains("build/TEST_RESULTS.md"))
    wenyu_owner_outcome(result)
  }
  let first = import_wenyu_native_result(launch, work, persist~)
  let package_path = launch.entry.workspace_root +
    "/raw/build/native/" +
    work.id +
    "/output-package.json"
  let bytes = @fs.read_file(package_path).text()
  let second = import_wenyu_native_result(launch, work, persist~)
  assert_eq(first.to_json(), second.to_json())
  assert_eq(calls[0], 1)
  assert_eq(@fs.read_file(package_path).text(), bytes)
  assert_true(
    @fs.read_file(launch.entry.workspace_root + "/build/CODE_PATCH.md")
    .text()
    .contains(work.id),
  )
  assert_true(
    @fs.read_file(launch.entry.workspace_root + "/build/TEST_RESULTS.md")
    .text()
    .contains("moon check --no-render"),
  )
  assert_false(
    @fs.exists(launch.entry.workspace_root + "/build/CODE_BLOCKERS.md"),
  )
}

///|
async test "wenyu owner import rejects mismatched receipt request and nonterminal work before persistence" {
  let (launch, work) = wenyu_owner_fixture("binding")
  let calls = [0]
  let persist = async fn(result : @moonbook.BookResult) {
    calls[0] += 1
    wenyu_owner_outcome(result)
  }
  for
    key in [
      "contract", "request_id", "request_digest", "book_id", "book_root", "source_root",
      "task_id", "goal_id", "output_digest", "session_id", "command_id", "model",
      "model_workspace", "request_body_digest",
    ] {
    let receipt = @json.parse(work.receipt.stringify())
    wenyu_owner_set(receipt, key, "wrong".to_json())
    let error = try {
      ignore(import_wenyu_native_result(launch, { ..work, receipt, }, persist~))
      ""
    } catch {
      error => error.to_string()
    }
    assert_true(
      error.contains("wenyu_result_receipt_binding_mismatch"),
      msg=key,
    )
  }
  let changed_request = {
    ..work.request,
    prompt: "Changed task under the same key",
    input_digest: @native_work.digest("Changed task under the same key"),
  }
  let changed = {
    ..work,
    request: changed_request,
    request_digest: @native_work.digest(changed_request.to_json().stringify()),
  }
  let error = try {
    ignore(import_wenyu_native_result(launch, changed, persist~))
    ""
  } catch {
    error => error.to_string()
  }
  assert_true(error.contains("wenyu_result_binding_mismatch"))
  for
    state in [
      "running", "dispatch_uncertain", "awaiting_approval", "superseded",
    ] {
    let error = try {
      ignore(import_wenyu_native_result(launch, { ..work, state, }, persist~))
      ""
    } catch {
      error => error.to_string()
    }
    assert_true(error.contains("wenyu_result_binding_mismatch"), msg=state)
  }
  assert_eq(calls[0], 0)
  assert_false(@fs.exists(launch.entry.workspace_root + "/raw"))
  assert_false(@fs.exists(launch.entry.workspace_root + "/build"))
}

///|
async test "wenyu owner recovers a Book committed Town unacknowledged crash without duplicate Book effects" {
  let (launch, work) = wenyu_owner_fixture("crash")
  let durable = launch.entry.workspace_root + "/synthetic-book-outcome.json"
  let attempts = [0]
  let effects = [0]
  let persist = async fn(
    result : @moonbook.BookResult,
  ) -> @moonbook.PersistResultOutcome {
    attempts[0] += 1
    if @fs.exists(durable) {
      return @json.from_json(@json.parse(@fs.read_file(durable).text()))
    }
    let outcome = wenyu_owner_outcome(result)
    @fs.write_file(
      durable,
      outcome.to_json().stringify(),
      create_mode=CreateNew,
      sync=Full,
    )
    effects[0] += 1
    fail("simulated_crash_after_book_commit")
  }
  let error = try {
    ignore(import_wenyu_native_result(launch, work, persist~))
    ""
  } catch {
    error => error.to_string()
  }
  assert_true(error.contains("simulated_crash_after_book_commit"))
  let directory = launch.entry.workspace_root + "/raw/build/native/" + work.id
  assert_false(@fs.exists(directory + "/application-receipt.json"))
  let package = @fs.read_file(directory + "/output-package.json").text()
  let page = @fs.read_file(launch.entry.workspace_root + "/build/CODE_PATCH.md").text()
  let result = import_wenyu_native_result(launch, work, persist~)
  assert_true(result.review_queued)
  ignore(import_wenyu_native_result(launch, work, persist~))
  assert_eq(attempts[0], 2)
  assert_eq(effects[0], 1)
  assert_eq(@fs.read_file(directory + "/output-package.json").text(), package)
  assert_eq(
    @fs.read_file(launch.entry.workspace_root + "/build/CODE_PATCH.md").text(),
    page,
  )
  assert_true(@fs.exists(directory + "/application-receipt.json"))
}

///|
async test "wenyu owner retains human edits and the immutable failed import package" {
  let (launch, work) = wenyu_owner_fixture("human")
  let page = launch.entry.workspace_root + "/build/CODE_PATCH.md"
  @support.write_text_file(page, "Human work must remain\n")
  let calls = [0]
  let error = try {
    ignore(
      import_wenyu_native_result(launch, work, persist=async fn(
        result : @moonbook.BookResult,
      ) {
        calls[0] += 1
        wenyu_owner_outcome(result)
      }),
    )
    ""
  } catch {
    error => error.to_string()
  }
  assert_true(error.contains("wenyu_output_changed_by_human_or_newer_work"))
  assert_eq(@fs.read_file(page).text(), "Human work must remain\n")
  assert_false(
    @fs.exists(launch.entry.workspace_root + "/build/TEST_RESULTS.md"),
  )
  assert_true(
    @fs.exists(
      launch.entry.workspace_root +
      "/raw/build/native/" +
      work.id +
      "/output-package.json",
    ),
  )
  assert_eq(calls[0], 0)
}

///|
async test "wenyu owner rejects dangling output symlinks without following or replacing them" {
  let (launch, work) = wenyu_owner_fixture("symlink")
  @fs.mkdir(launch.entry.workspace_root + "/build")
  let outside = launch.entry.workspace_root + "/missing/outside.md"
  let page = launch.entry.workspace_root + "/build/CODE_PATCH.md"
  @fs.symlink(target=outside, page)
  let calls = [0]
  let error = try {
    ignore(
      import_wenyu_native_result(launch, work, persist=async fn(
        result : @moonbook.BookResult,
      ) {
        calls[0] += 1
        wenyu_owner_outcome(result)
      }),
    )
    ""
  } catch {
    error => error.to_string()
  }
  assert_true(error.contains("wenyu_book_path_not_canonical"))
  assert_true(@fs.kind(page, follow_symlink=false) is SymLink)
  assert_false(@fs.exists(outside))
  assert_false(
    @fs.exists(launch.entry.workspace_root + "/build/TEST_RESULTS.md"),
  )
  assert_eq(calls[0], 0)
}

///|
async test "wenyu owner projection distinguishes native running persistence review and failure" {
  let (launch, work) = wenyu_owner_fixture("projection")
  for
    state in [
      "queued", "running", "dispatch_uncertain", "waiting_model", "awaiting_approval",
    ] {
    let record = wenyu_native_execution_record(launch, { ..work, state, }, 10)
    assert_eq(record.status, Running, msg=state)
    assert_true(record.run_id is None)
    assert_eq(record.packet_id, work.id)
    assert_true(is_wenyu_native_execution(record))
  }
  assert_eq(
    wenyu_native_execution_record(launch, work, 10).status,
    AwaitingPersistence,
  )
  let imported = wenyu_native_execution_record(launch, work, 10, imported=true)
  assert_eq(imported.status, ReviewQueued)
  assert_eq(imported.result_decision, "native-persisted-review")
  assert_true(imported.requires_review)
  let failed = {
    ..work,
    state: "failed",
    blocked_reason: "native_required_validation_missing_or_failed",
    output: "",
  }
  assert_eq(wenyu_native_execution_record(launch, failed, 10).status, Failed)
  assert_eq(
    wenyu_native_execution_record(
      launch,
      failed,
      10,
      import_blocker="Book temporarily unavailable",
    ).status,
    AwaitingPersistence,
  )
  assert_eq(
    wenyu_native_execution_record(launch, failed, 10, imported=true).result_decision,
    "native-blocked-review",
  )
}

///|
async test "wenyu explicit supersession advances only the task manifest and preserves saved inputs" {
  let (launch, _) = wenyu_owner_fixture("supersession")
  let path = wenyu_launch_path(launch.native_path, launch.task.id)
  let saved = launch.to_json().stringify(indent=2)
  @support.write_text_file(path, saved)
  let queued = @native_work.enqueue(launch.request, path=launch.native_path)
  assert_eq(
    wenyu_task_after_explicit_supersession(launch.task, launch.native_path).id,
    launch.task.id,
  )
  ignore(
    @native_work.supersede(
      queued.id,
      @native_work.load(path=launch.native_path).revision,
      path=launch.native_path,
    ),
  )
  let corrected = wenyu_task_after_explicit_supersession(
    launch.task,
    launch.native_path,
  )
  assert_eq(corrected.id, launch.task.id + "-generation-2")
  assert_eq(corrected.prompt, launch.task.prompt)
  assert_eq(corrected.target_pages, launch.task.target_pages)
  assert_eq(@fs.read_file(path).text(), saved)
  assert_false(@fs.exists(wenyu_launch_path(launch.native_path, corrected.id)))
}

///|
async test "wenyu owner detects a human output race after the first page write" {
  let (launch, work) = wenyu_owner_fixture("page-race")
  let calls = [0]
  let raced = [false]
  let human = "Human TEST_RESULTS edit during import must remain\n"
  let error = try {
    ignore(
      import_wenyu_native_result(
        launch,
        work,
        persist=async fn(result : @moonbook.BookResult) {
          calls[0] += 1
          wenyu_owner_outcome(result)
        },
        after_page=async fn(relative) {
          if relative == "build/CODE_PATCH.md" {
            raced[0] = true
            @support.write_text_file(
              launch.entry.workspace_root + "/build/TEST_RESULTS.md",
              human,
            )
          }
        },
      ),
    )
    ""
  } catch {
    error => error.to_string()
  }
  assert_true(raced[0])
  assert_true(error.contains("wenyu_output_changed_by_human_or_newer_work"))
  assert_eq(
    @fs.read_file(launch.entry.workspace_root + "/build/TEST_RESULTS.md").text(),
    human,
  )
  assert_eq(calls[0], 0)
  assert_false(
    @fs.exists(
      launch.entry.workspace_root +
      "/raw/build/native/" +
      work.id +
      "/application-receipt.json",
    ),
  )
  assert_true(
    @fs.exists(
      launch.entry.workspace_root +
      "/raw/build/native/" +
      work.id +
      "/output-package.json",
    ),
  )
}
