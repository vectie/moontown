///|
// These tests exercise the actual producer, durable queue, public sync, fixed
// owner output application and public editor consumer. Native transport and
// validation journal are injected fixture evidence, never live execution proof.
async test "editor producer freezes source-only command and full checks then sync applies consumable proof" {
  let fixture = native_editor_fixture(
    existing_plan="Existing owner plan stays byte-identical\n",
  )
  let task = native_editor_materialize(fixture)
  let queued = native_editor_saved(fixture, task.id)
  let request = queued.request
  let path = @native_work.path_for_snapshot(fixture.snapshot_path)
  assert_eq(task.status, "queued")
  assert_eq(request.input_blocker, "")
  assert_eq(request.execution_root, fixture.source_root)
  assert_eq(request.book_root, fixture.book_root)
  assert_true(request.owner_workspace != fixture.source_root)
  assert_true(request.owner_workspace != fixture.book_root)
  assert_eq(request.output_contract, "planbook.editor.native-result.v1")
  assert_eq(request.input_digest, @native_work.digest(request.prompt))
  assert_eq(
    queued.request_digest,
    @native_work.digest(request.to_json().stringify()),
  )
  assert_eq(queued.id, "town-work-" + queued.request_digest[:32].to_owned())
  assert_eq(
    @json.parse(@fs.read_file(task.packet_path).text()),
    request.to_json(),
  )
  let spec = native_editor_spec(queued)
  assert_eq(spec.selection_content, native_editor_selection())
  assert_eq(
    spec.selection_digest,
    @native_work.digest(native_editor_selection()),
  )
  assert_true(
    request.work_key.has_suffix(":editor-owner-v1:" + spec.selection_digest),
  )
  assert_eq(spec.captured_inputs.length(), 4)
  for input in spec.captured_inputs {
    assert_eq(input.content_digest, @native_work.digest(input.content))
    assert_true(request.prompt.contains(input.content))
    assert_true(request.prompt.contains(input.content_digest))
  }
  assert_true(request.prompt.contains(native_editor_selection()))
  let commands = native_editor_rows(
    request.acceptance_policy,
    "required_validation_commands",
  )
  assert_eq(commands, [
    "moon fmt".to_json(),
    "moon info".to_json(),
    "moon check --no-render".to_json(),
    "moon test src/planbook_runtime/planbook_autonomy_wbtest.mbt src/live_autonomy_runtime/live_autonomy_wbtest.mbt --no-render".to_json(),
    "moon test src/editor_pipeline src/editor_runtime src/native_work --no-render".to_json(),
    "moon test --no-render".to_json(),
    "moon -C src/ui/rabbita-town build --target js --release".to_json(),
    "git diff --check".to_json(),
  ])
  let checks = native_editor_rows(
    native_editor_field(request.acceptance_policy, "completion_policy"),
    "required_checks",
  )
  assert_eq(checks.length(), commands.length())
  for index, check in checks {
    assert_eq(native_editor_field(check, "command"), commands[index])
    assert_eq(native_editor_text(check, "tool"), "shell")
    assert_eq(native_editor_text(check, "cwd"), ".")
  }
  let posted : Array[String] = []
  let journal : Array[Json] = []
  let receipts : Array[Json] = []
  let models = ["moongate/editor-fixture-one"]
  let calls : Array[String] = []
  let client = native_editor_client(
    request, posted, journal, receipts, models, calls,
  )
  let running = @native_work.sync(task.id, 1UL, path~, client~)
  assert_eq(running.state, "running")
  assert_eq(
    native_editor_text(running.baseline, "head"),
    "fdd650708bb049dd21f1b76725287dcbf9e42af4",
  )
  assert_eq(native_editor_rows(running.baseline, "dirty_paths"), [])
  assert_eq(posted.length(), 1)
  let reservation = running.reservation.unwrap()
  assert_eq(reservation.request_body, posted[0])
  assert_eq(reservation.body_digest, @native_work.digest(posted[0]))
  assert_eq(reservation.model, models[0])
  let body = @json.parse(posted[0])
  assert_eq(native_editor_text(body, "book_root"), fixture.source_root)
  assert_eq(
    native_editor_text(body, "model_workspace"),
    request.owner_workspace,
  )
  assert_eq(native_editor_text(body, "model"), reservation.model)
  let contract = native_editor_field(
    native_editor_field(body, "payload"),
    "task_contract",
  )
  assert_eq(native_editor_field(contract, "scope"), ["."].to_json())
  assert_eq(native_editor_text(contract, "owner_work_id"), task.id)
  assert_eq(native_editor_text(contract, "owner_book_id"), request.book_id)
  assert_eq(
    native_editor_text(contract, "output_contract"),
    request.output_contract,
  )
  let constraints = native_editor_field(contract, "constraints").stringify()
  assert_true(
    constraints.contains("Only the frozen source execution root is writable"),
  )
  assert_true(constraints.contains("Never write owner outputs, commit or push"))
  assert_true(constraints.contains(task.id))
  assert_true(constraints.contains(spec.selection_digest))
  assert_true(
    constraints.contains(
      "moon -C src/ui/rabbita-town build --target js --release",
    ),
  )
  assert_true(native_editor_text(body, "text").has_prefix(request.prompt))
  let before_index = @fs.read_file(fixture.source_root + "/.git/index").binary()
  let before_head = @fs.read_file(
    fixture.source_root + "/.git/refs/heads/master",
  ).binary()
  let answer = native_editor_finish_fixture(running, journal, receipts)
  let completed = @native_work.sync(task.id, 40000UL, path~, client~)
  assert_eq(completed.state, "completed")
  assert_eq(completed.blocked_reason, "")
  assert_eq(@native_work.owner_status(completed), "completed")
  assert_false(@native_work.editor_owner_pending(completed))
  assert_eq(completed.output, answer)
  assert_eq(
    native_editor_text(completed.receipt, "engineering_status"),
    "applied_and_validated",
  )
  assert_eq(
    native_editor_text(completed.receipt, "commit_status"),
    "not_requested",
  )
  assert_eq(native_editor_rows(completed.receipt, "changed_files").length(), 1)
  assert_eq(
    native_editor_text(
      native_editor_rows(completed.receipt, "changed_files")[0],
      "path",
    ),
    "source.mbt",
  )
  assert_eq(
    native_editor_rows(completed.receipt, "validation_commands").length(),
    commands.length(),
  )
  for check in native_editor_rows(completed.receipt, "validation_commands") {
    assert_eq(
      native_editor_field(
        native_editor_field(check, "sandbox_evidence"),
        "fixture_injected",
      ),
      true.to_json(),
    )
    assert_eq(
      native_editor_field(
        native_editor_field(check, "sandbox_evidence"),
        "actual_compiler_execution",
      ),
      false.to_json(),
    )
  }
  assert_true(
    native_editor_text(completed.receipt, "focused_diff").contains(
      "+pub fn editor_fixture_answer()",
    ),
  )
  assert_eq(
    @fs.read_file(fixture.source_root + "/.git/index").binary(),
    before_index,
  )
  assert_eq(
    @fs.read_file(fixture.source_root + "/.git/refs/heads/master").binary(),
    before_head,
  )
  assert_eq(
    @fs.read_file(fixture.source_root + "/notes.txt").text(),
    "original notes\n",
  )
  let result = @fs.read_file(request.result_path).text()
  let proof_path = fixture.book_root +
    "/raw/editor-pipeline/selected-feature-implementation.md"
  let proof = @fs.read_file(proof_path).text()
  let receipt_path = fixture.book_root +
    "/raw/editor-pipeline/native/" +
    task.id +
    "/application-receipt.json"
  let application = @json.parse(@fs.read_file(receipt_path).text())
  assert_true(result.contains("repair_decision: accepted"))
  assert_true(
    result.contains("native_owner_contract: planbook.editor.owner-output.v1"),
  )
  assert_true(proof.contains("selection_digest: " + spec.selection_digest))
  assert_true(proof.contains("original_task_acceptance: unevaluated"))
  assert_true(proof.contains("fixture evidence"))
  assert_eq(
    native_editor_text(application, "contract"),
    "planbook.editor.application-receipt.v1",
  )
  assert_eq(native_editor_text(application, "work_id"), task.id)
  assert_eq(
    native_editor_text(application, "request_digest"),
    queued.request_digest,
  )
  assert_eq(
    native_editor_text(application, "request_body_digest"),
    reservation.body_digest,
  )
  let document_digests = native_editor_field(application, "document_digests")
  assert_eq(
    native_editor_text(document_digests, "raw/repair/repair-result.md"),
    @native_work.digest(result),
  )
  assert_eq(
    native_editor_text(
      document_digests, "raw/editor-pipeline/selected-feature-implementation.md",
    ),
    @native_work.digest(proof),
  )
  assert_true(
    @editor_runtime.editor_selected_feature_implementation_ready(
      fixture.book_root,
    ),
  )
  assert_eq(
    @fs.read_file(
      fixture.book_root + "/" + @native_work.editor_owner_plan_relative(),
    ).text(),
    "Existing owner plan stays byte-identical\n",
  )

  // Durable replay is byte-stable even after a later model, course or source edit.
  let completed_request = completed.request.to_json()
  models[0] = "moongate/editor-fixture-later"
  @support.write_text_file(
    fixture.course_root + "/wiki/course/exercises.md",
    "Later course content\n",
  )
  @support.write_text_file(
    fixture.source_root + "/source.mbt",
    "Later source work must not rewrite saved command\n",
  )
  let replay_task = native_editor_materialize(fixture)
  assert_eq(replay_task.id, task.id)
  let replay = @native_work.sync(task.id, 80000UL, path~, client~)
  assert_eq(replay.request.to_json(), completed_request)
  assert_eq(replay.reservation.unwrap().request_body, posted[0])
  assert_eq(replay.reservation.unwrap().model, "moongate/editor-fixture-one")
  assert_eq(@fs.read_file(request.result_path).text(), result)
  assert_eq(@fs.read_file(proof_path).text(), proof)
  assert_eq(@json.parse(@fs.read_file(receipt_path).text()), application)
  assert_eq(posted.length(), 1)
  assert_eq(calls.filter(call => call.contains("moongate-route")).length(), 1)
  assert_eq(@native_work.load(path~).work.length(), 1)

  // A changed digest, even with the same feature ID, creates a new logical key
  // only after this old work has settled its owner outputs.
  let changed = native_editor_selection(
    acceptance="The same feature now has a different acceptance criterion",
  )
  @support.write_text_file(
    fixture.book_root + "/raw/editor-pipeline/next-feature.json",
    changed,
  )
  assert_false(
    @editor_runtime.editor_selected_feature_implementation_ready(
      fixture.book_root,
    ),
  )
  let next_task = native_editor_materialize(fixture)
  let next = native_editor_saved(fixture, next_task.id)
  assert_true(next.id != task.id)
  assert_true(next.request.work_key != request.work_key)
  assert_eq(
    native_editor_spec(next).selection_digest,
    @native_work.digest(changed),
  )
  assert_eq(@native_work.load(path~).work.length(), 2)
  assert_eq(posted.length(), 1)
}

///|
async test "same ID selection acceptance change blocks first owner apply and pending work wins before recapture" {
  let fixture = native_editor_fixture()
  let task = native_editor_materialize(fixture)
  let queued = native_editor_saved(fixture, task.id)
  let path = @native_work.path_for_snapshot(fixture.snapshot_path)
  let posted : Array[String] = []
  let journal : Array[Json] = []
  let receipts : Array[Json] = []
  let calls : Array[String] = []
  let client = native_editor_client(
    queued.request,
    posted,
    journal,
    receipts,
    ["moongate/editor-fixture"],
    calls,
  )
  let running = @native_work.sync(task.id, 1UL, path~, client~)
  assert_eq(running.state, "running")
  ignore(native_editor_finish_fixture(running, journal, receipts))
  let changed = native_editor_selection(
    acceptance="Changed acceptance with the same selected feature ID",
  )
  @support.write_text_file(
    fixture.book_root + "/raw/editor-pipeline/next-feature.json",
    changed,
  )
  let completed = @native_work.sync(task.id, 40000UL, path~, client~)
  assert_eq(completed.state, "completed")
  assert_true(completed.blocked_reason.contains("editor_selection_changed"))
  assert_true(@native_work.editor_owner_pending(completed))
  assert_eq(@native_work.owner_status(completed), "waiting_owner_output")
  assert_false(@fs.exists(queued.request.result_path))
  assert_false(
    @fs.exists(
      fixture.book_root +
      "/raw/editor-pipeline/selected-feature-implementation.md",
    ),
  )
  assert_false(
    @fs.exists(
      fixture.book_root +
      "/raw/editor-pipeline/native/" +
      task.id +
      "/application-receipt.json",
    ),
  )
  assert_false(
    @editor_runtime.editor_selected_feature_implementation_ready(
      fixture.book_root,
    ),
  )
  let saved_request = completed.request.to_json()
  let saved_body = completed.reservation.unwrap().request_body
  // These invalid current inputs must not be recaptured ahead of pending work.
  @support.write_text_file(
    fixture.course_root + "/wiki/course/beginner-course.md",
    "",
  )
  @support.write_text_file(
    fixture.book_root + "/raw/editor-pipeline/next-feature.json",
    "{malformed",
  )
  let pending = materialize_native_planbook_repair(
    fixture.criterion,
    fixture.snapshot_path,
    fixture.book_root,
    fixture.catalog_path,
    false,
    source_root_override=fixture.root + "/missing-source",
  )
  assert_eq(pending.id, task.id)
  assert_eq(pending.status, "waiting_owner_output")
  let retained = native_editor_saved(fixture, task.id)
  assert_eq(retained.request.to_json(), saved_request)
  assert_eq(retained.reservation.unwrap().request_body, saved_body)
  assert_eq(@native_work.load(path~).work.length(), 1)
  assert_eq(posted.length(), 1)

  // Explicit terminal supersession is required to abandon this blocked owner
  // package; a changed selection alone cannot silently rotate pending work.
  let state = @native_work.load(path~)
  let superseded = @native_work.supersede(task.id, state.revision, path~)
  assert_eq(superseded.state, "superseded")
  @support.write_text_file(
    fixture.course_root + "/wiki/course/beginner-course.md",
    "Corrected course input\n",
  )
  @support.write_text_file(
    fixture.book_root + "/raw/editor-pipeline/next-feature.json",
    changed,
  )
  let next_task = native_editor_materialize(fixture)
  let next = native_editor_saved(fixture, next_task.id)
  assert_true(next.id != task.id)
  assert_eq(next.request.input_blocker, "")
  assert_eq(
    native_editor_spec(next).selection_digest,
    @native_work.digest(changed),
  )
  assert_eq(@native_work.load(path~).work.length(), 2)
  assert_eq(posted.length(), 1)
}

///|
async test "editor producer missing and malformed required inputs block before native transport" {
  let cases = [
    ("", "", "editor_selection_missing"),
    ("{malformed", "", "editor_selection_invalid"),
    ("{}", "", "editor_selection_invalid"),
    (
      "{\"contract\":\"moontown.editor_feature_selection.v1\",\"selected_feature\":\"fixture-editor\",\"title\":\"Fixture\",\"implementation_hint\":\"Implement it\",\"acceptance\":[]}",
      "", "editor_selection_invalid",
    ),
    (
      native_editor_selection(),
      "wiki/course/exercises.md",
      "editor_course_input_missing",
    ),
    (
      native_editor_selection(),
      "wiki/course/beginner-course.md",
      "editor_course_input_missing",
    ),
  ]
  for (selection, omit_course_page, expected) in cases {
    let fixture = native_editor_fixture(selection~, omit_course_page~)
    let task = native_editor_materialize(fixture)
    let queued = native_editor_saved(fixture, task.id)
    assert_true(queued.request.input_blocker.contains(expected))
    let calls : Array[String] = []
    let client = native_editor_client(
      queued.request,
      [],
      [],
      [],
      ["moongate/unused"],
      calls,
    )
    let blocked = @native_work.sync(
      task.id,
      1UL,
      path=@native_work.path_for_snapshot(fixture.snapshot_path),
      client~,
    )
    assert_eq(blocked.state, "waiting_input")
    assert_true(blocked.reservation is None)
    assert_eq(calls.length(), 0)
    assert_false(@fs.exists(queued.request.result_path))
    assert_false(
      @editor_runtime.editor_selected_feature_implementation_ready(
        fixture.book_root,
      ),
    )
  }
  for missing_binding in [true, false] {
    let fixture = native_editor_fixture()
    if missing_binding {
      @moonbook.save_catalog_file(fixture.catalog_path, [
        @moonbook.BookCatalogEntry::new(
          id=default_planbook_book_id(),
          name="Plan",
          purpose="Fixture",
          workspace_root=fixture.book_root,
        ),
      ])
    } else {
      @support.write_text_file(
        fixture.course_root + "/wiki/course/progress-rubric.md",
        " \n\t",
      )
    }
    let task = native_editor_materialize(fixture)
    let queued = native_editor_saved(fixture, task.id)
    assert_true(
      queued.request.input_blocker.contains(
        if missing_binding {
          "editor_course_binding_missing"
        } else {
          "editor_course_input_empty"
        },
      ),
    )
    let calls : Array[String] = []
    let client = native_editor_client(
      queued.request,
      [],
      [],
      [],
      ["moongate/unused"],
      calls,
    )
    let blocked = @native_work.sync(
      task.id,
      1UL,
      path=@native_work.path_for_snapshot(fixture.snapshot_path),
      client~,
    )
    assert_eq(blocked.state, "waiting_input")
    assert_eq(calls.length(), 0)
  }
}

///|
async test "real pipeline producer creates frozen missing plan and preserves existing plan through sync" {
  for existing in [false, true] {
    let fixture = if existing {
      native_editor_fixture(
        criterion_id="editor-mode-real-pipeline",
        selection="",
        existing_plan="Human-owned existing editor plan\n",
      )
    } else {
      native_editor_fixture(
        criterion_id="editor-mode-real-pipeline",
        selection="",
      )
    }
    let task = native_editor_materialize(fixture)
    let queued = native_editor_saved(fixture, task.id)
    assert_eq(queued.request.input_blocker, "")
    let spec = native_editor_spec(queued)
    assert_eq(spec.selection_digest, "")
    assert_eq(spec.captured_inputs.length(), if existing { 2 } else { 1 })
    assert_eq(
      spec.missing_plan_template,
      if existing {
        ""
      } else {
        @planbook.editor_pipeline_plan_markdown()
      },
    )
    let posted : Array[String] = []
    let journal : Array[Json] = []
    let receipts : Array[Json] = []
    let calls : Array[String] = []
    let client = native_editor_client(
      queued.request,
      posted,
      journal,
      receipts,
      ["moongate/editor-fixture"],
      calls,
    )
    let path = @native_work.path_for_snapshot(fixture.snapshot_path)
    let running = @native_work.sync(task.id, 1UL, path~, client~)
    assert_eq(running.state, "running")
    ignore(native_editor_finish_fixture(running, journal, receipts))
    let completed = @native_work.sync(task.id, 40000UL, path~, client~)
    assert_eq(completed.state, "completed")
    assert_eq(completed.blocked_reason, "")
    assert_false(@native_work.editor_owner_pending(completed))
    let plan = @fs.read_file(
      fixture.book_root + "/" + @native_work.editor_owner_plan_relative(),
    ).text()
    assert_eq(
      plan,
      if existing {
        "Human-owned existing editor plan\n"
      } else {
        spec.missing_plan_template
      },
    )
    assert_true(
      @fs.read_file(queued.request.result_path)
      .text()
      .contains("repair_decision: accepted"),
    )
    assert_false(
      @fs.exists(
        fixture.book_root +
        "/raw/editor-pipeline/selected-feature-implementation.md",
      ),
    )
    let application = @json.parse(
      @fs.read_file(
        fixture.book_root +
        "/raw/editor-pipeline/native/" +
        task.id +
        "/application-receipt.json",
      ).text(),
    )
    assert_eq(native_editor_text(application, "status"), "applied")
    let hashes = native_editor_field(application, "document_digests")
    assert_eq(
      native_editor_text(hashes, @native_work.editor_owner_plan_relative()),
      if existing {
        ""
      } else {
        @native_work.digest(plan)
      },
    )
    assert_eq(
      @native_work.sync(task.id, 80000UL, path~, client~).receipt,
      completed.receipt,
    )
    assert_eq(posted.length(), 1)
  }
}

///|
async test "editor sync refuses missing frozen UI check without writing any owner proof" {
  let fixture = native_editor_fixture()
  let task = native_editor_materialize(fixture)
  let queued = native_editor_saved(fixture, task.id)
  let path = @native_work.path_for_snapshot(fixture.snapshot_path)
  let posted : Array[String] = []
  let journal : Array[Json] = []
  let receipts : Array[Json] = []
  let calls : Array[String] = []
  let client = native_editor_client(
    queued.request,
    posted,
    journal,
    receipts,
    ["moongate/editor-fixture"],
    calls,
  )
  let running = @native_work.sync(task.id, 1UL, path~, client~)
  ignore(
    native_editor_finish_fixture(
      running,
      journal,
      receipts,
      omit_command="moon -C src/ui/rabbita-town build --target js --release",
    ),
  )
  let failed = @native_work.sync(task.id, 40000UL, path~, client~)
  assert_eq(failed.state, "failed")
  assert_true(
    failed.blocked_reason.contains(
      "native_required_validation_missing_or_failed",
    ),
  )
  assert_true(failed.blocked_reason.contains("rabbita-town"))
  assert_eq(
    native_editor_rows(
      failed.request.acceptance_policy,
      "required_validation_commands",
    ).length(),
    8,
  )
  assert_false(@fs.exists(queued.request.result_path))
  assert_false(
    @fs.exists(
      fixture.book_root +
      "/raw/editor-pipeline/selected-feature-implementation.md",
    ),
  )
  assert_false(
    @fs.exists(
      fixture.book_root +
      "/raw/editor-pipeline/native/" +
      task.id +
      "/application-receipt.json",
    ),
  )
  assert_false(
    @editor_runtime.editor_selected_feature_implementation_ready(
      fixture.book_root,
    ),
  )
  assert_eq(posted.length(), 1)
}
