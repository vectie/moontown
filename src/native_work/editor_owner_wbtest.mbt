///|
/// These owner application fixtures use real retained source/Book files and
/// production evidence reconciliation. Their check journals are injected, not
/// claims that a compiler or provider ran. Producer/full-policy coverage lives
/// in planbook_runtime/planbook_native_editor_wbtest.mbt.
async fn editor_owner_fixture(
  no_change? : Bool = false,
  real_pipeline? : Bool = false,
) -> (Work, String) {
  let root = @fsx.mkdtemp("/tmp/town-editor-owner-XXXXXX")
  let base = wenyu_fixture_request(root~)
  @fs.mkdir(base.owner_workspace)
  @fs.mkdir(base.book_root)
  wenyu_materialize_retained_fixture(base.execution_root)
  @moonbook.save_catalog_file(base.catalog_path, [
    @moonbook.BookCatalogEntry::new(
      id=base.book_id,
      name="PlanBook",
      purpose="Owner regression fixture",
      workspace_root=base.book_root,
    ),
  ])
  let selection = (
    {
      "contract": @editor_pipeline.feature_selection_result_contract(),
      "selected_feature": "road-editor",
      "title": "Road editor",
      "implementation_hint": "Implement bounded road editing",
      "acceptance": ["A road can be edited"],
    } : Json).stringify()
  @support.write_text_file(
    base.book_root + "/raw/editor-pipeline/next-feature.json",
    selection,
  )
  let before : Map[String, String] = {
    "raw/repair/repair-result.md": "absent",
    "raw/repair/repair-result.md.native-receipt.json": "absent",
  }
  if real_pipeline {
    before[editor_owner_plan_relative()] = "absent"
  } else {
    before["raw/editor-pipeline/selected-feature-implementation.md"] = "absent"
  }
  let criterion = if real_pipeline {
    "editor-mode-real-pipeline"
  } else {
    "editor-selected-feature-implementation"
  }
  let spec : EditorOwnerSpec = {
    contract: "planbook.editor.owner-output.v1",
    criterion_id: criterion,
    plan_id: "2026-05-31-editor-mode-real-pipeline",
    selection_content: if real_pipeline {
      ""
    } else {
      selection
    },
    selection_digest: if real_pipeline {
      ""
    } else {
      digest(selection)
    },
    selected_feature: if real_pipeline {
      ""
    } else {
      "road-editor"
    },
    title: if real_pipeline {
      ""
    } else {
      "Road editor"
    },
    implementation_hint: if real_pipeline {
      ""
    } else {
      "Implement bounded road editing"
    },
    acceptance: if real_pipeline {
      []
    } else {
      ["A road can be edited"]
    },
    captured_inputs: [
      {
        book_id: "course",
        root: root + "/course",
        relative: "wiki/course/beginner-course.md",
        content: "Captured course",
        content_digest: digest("Captured course"),
      },
    ],
    output_before: before,
    missing_plan_template: if real_pipeline {
      "# Frozen owner plan\n"
    } else {
      ""
    },
  }
  let request : Request = {
    ..base,
    kind: "planbook_repair",
    book_type: "planbook",
    criterion_id: criterion,
    work_key: "editor-fixture:" + spec.selection_digest,
    output_contract: "planbook.editor.native-result.v1",
    result_path: base.book_root + "/raw/repair/repair-result.md",
    source_binding: source_binding(Some(base.execution_root)).unwrap(),
    acceptance_policy: {
      "contract": "planbook.repair.native-policy.v1",
      "commit_requirement": "not_requested",
      "required_validation_commands": ["moon check --no-render"],
      "completion_policy": no_change_fixture_policy(),
      "editor_owner_output": spec,
    },
  }
  let path = root + "/state.json"
  let queued = enqueue(request, path~)
  let client = fixture_client(request, async fn(_, _, _) {
    Err("no-transport-permitted")
  })
  let running = reserve(
    { ..queued, baseline: source_snapshot(request.execution_root), },
    client,
    "moongate/fixture",
    2UL,
  )
  let answer = editor_finish_schema(running)
  no_change_set(
    answer,
    "summary",
    "Explicit synthetic owner replay fixture".to_json(),
  )
  let receipt = if no_change {
    no_change_set(answer, "outcome", "no_change".to_json())
    let receipt = no_change_fixture_receipt(running)
    let metadata = field(
      field(rows(field(receipt, "execution"), "tool_results")[0], "result"),
      "metadata",
    )
    no_change_set(metadata, "answer", answer.stringify().to_json())
    receipt
  } else {
    @support.write_text_file(request.execution_root + "/source.mbt", "after\n")
    fixture_receipt(running, answer=answer.stringify())
  }
  let events = if no_change {
    no_change_fixture_events(running)
  } else {
    wenyu_fixture_events(running)
  }
  let final_snapshot = source_snapshot(request.execution_root)
  let completed = reconcile_repair_evidence(
    running, receipt, events, final_snapshot, 0, 5UL,
  )
  assert_eq(completed.state, "completed", msg=completed.blocked_reason)
  let completed = attach_focused_diff(completed, 5UL)
  assert_eq(completed.state, "completed", msg=completed.blocked_reason)
  save_unlocked(path, {
    schema: "moontown.native-work.v1",
    revision: 1,
    work: [completed],
  })
  (completed, path)
}

///|
async test "editor owner interrupted package pages and receipt resume through terminal sync without transport" {
  for
    stop in [
      "package", "raw/repair/repair-result.md.native-receipt.json", "raw/repair/repair-result.md",
      "raw/editor-pipeline/selected-feature-implementation.md", "before_receipt",
      "receipt",
    ] {
    let (work, path) = editor_owner_fixture()
    let stopped = apply_editor_owner_result(work, after_step=async fn(step) {
      if step == stop {
        fail("injected_owner_interruption")
      }
    })
    assert_eq(owner_status(stopped), "waiting_owner_output")
    assert_eq(status(stopped).state, "waiting_owner_output")
    assert_true(stopped.blocked_reason.contains("injected_owner_interruption"))
    if stop != "receipt" {
      assert_eq(editor_applied_feature(work.request.book_root), None)
    }
    save_unlocked(path, {
      schema: "moontown.native-work.v1",
      revision: 2,
      work: [stopped],
    })
    let calls : Array[String] = []
    let client = fixture_client(work.request, async fn(method, route, _) {
      calls.push(method + route)
      Err("must-not-call")
    })
    let observed = refresh(work.id, 2, 6UL, path~, client~)
    assert_eq(observed.to_json(), stopped.to_json())
    let applied = sync(work.id, 7UL, path~, client~)
    assert_eq(owner_status(applied), "completed", msg=applied.blocked_reason)
    assert_eq(
      text(field(applied.receipt, "owner_application"), "status"),
      "applied",
    )
    assert_eq(
      editor_applied_feature(work.request.book_root),
      Some("road-editor"),
    )
    let again = sync(work.id, 8UL, path~, client~)
    assert_eq(again.to_json(), applied.to_json())
    assert_eq(calls.length(), 0)
    assert_eq(applied.request.to_json(), work.request.to_json())
    assert_eq(
      applied.reservation.unwrap().request_body,
      work.reservation.unwrap().request_body,
    )
  }
}

///|
async test "editor owner selection drift retains package and exact retry never accepts same ID changed acceptance" {
  let (work, path) = editor_owner_fixture()
  let selection_path = work.request.book_root +
    "/raw/editor-pipeline/next-feature.json"
  let original_selection = @fs.read_file(selection_path).text()
  let changed = @json.parse(original_selection)
  no_change_set(
    changed,
    "acceptance",
    ["A different acceptance requirement"].to_json(),
  )
  @support.write_text_file(selection_path, changed.stringify())
  let blocked = sync(work.id, 6UL, path~)
  assert_true(blocked.blocked_reason.contains("editor_selection_changed"))
  assert_eq(owner_status(blocked), "waiting_owner_output")
  let package_path = work.request.book_root +
    "/" +
    editor_owner_directory(work.id) +
    "/output-package.json"
  assert_true(@fs.exists(package_path))
  let package = @fs.read_file(package_path).text()
  assert_false(@fs.exists(work.request.result_path))
  assert_eq(editor_applied_feature(work.request.book_root), None)
  @support.write_text_file(selection_path, original_selection)
  let applied = sync(work.id, 7UL, path~)
  assert_eq(owner_status(applied), "completed", msg=applied.blocked_reason)
  assert_eq(@fs.read_file(package_path).text(), package)
  assert_eq(editor_applied_feature(work.request.book_root), Some("road-editor"))
  @support.write_text_file(selection_path, changed.stringify())
  assert_eq(editor_applied_feature(work.request.book_root), None)
  let replay = sync(work.id, 8UL, path~)
  assert_eq(replay.to_json(), applied.to_json())
}

///|
async test "editor owner preserves human or newer pages before first application and after completed replay" {
  for
    relative in [
      "raw/repair/repair-result.md", "raw/repair/repair-result.md.native-receipt.json",
      "raw/editor-pipeline/selected-feature-implementation.md",
    ] {
    let (work, path) = editor_owner_fixture()
    let human_path = work.request.book_root + "/" + relative
    @support.write_text_file(human_path, "Human or newer work\n")
    let blocked = sync(work.id, 6UL, path~)
    assert_true(
      blocked.blocked_reason.contains(
        "editor_owner_output_changed_by_human_or_newer_work",
      ),
    )
    assert_eq(@fs.read_file(human_path).text(), "Human or newer work\n")
    assert_eq(editor_applied_feature(work.request.book_root), None)
  }
  let (work, path) = editor_owner_fixture()
  let applied = sync(work.id, 6UL, path~)
  assert_eq(editor_applied_feature(work.request.book_root), Some("road-editor"))
  let proof_path = work.request.book_root +
    "/raw/editor-pipeline/selected-feature-implementation.md"
  let proof = @fs.read_file(proof_path).text()
  @support.write_text_file(
    proof_path,
    proof + "\nHuman edit after acceptance\n",
  )
  assert_eq(sync(work.id, 7UL, path~).to_json(), applied.to_json())
  assert_eq(
    @fs.read_file(proof_path).text(),
    proof + "\nHuman edit after acceptance\n",
  )
  assert_eq(editor_applied_feature(work.request.book_root), None)
}

///|
async test "editor owner no change remains engineering only and may create only missing real pipeline template" {
  let (selected, selected_path) = editor_owner_fixture(no_change=true)
  let selected = sync(selected.id, 6UL, path=selected_path)
  assert_eq(owner_status(selected), "completed", msg=selected.blocked_reason)
  assert_eq(text(selected.receipt, "engineering_status"), "no_change")
  assert_eq(editor_applied_feature(selected.request.book_root), None)
  assert_false(
    @fs.exists(
      selected.request.book_root +
      "/raw/editor-pipeline/selected-feature-implementation.md",
    ),
  )
  assert_true(
    @fs.read_file(selected.request.result_path)
    .text()
    .contains("original_task_acceptance: unevaluated"),
  )
  let (pipeline, pipeline_path) = editor_owner_fixture(
    no_change=true,
    real_pipeline=true,
  )
  let pipeline = sync(pipeline.id, 6UL, path=pipeline_path)
  assert_eq(owner_status(pipeline), "completed", msg=pipeline.blocked_reason)
  assert_eq(
    @fs.read_file(
      pipeline.request.book_root + "/" + editor_owner_plan_relative(),
    ).text(),
    "# Frozen owner plan\n",
  )
  assert_eq(editor_applied_feature(pipeline.request.book_root), None)
}

///|
async test "editor owner refuses stale source altered receipt and partial unsupported identity" {
  let (stale, path) = editor_owner_fixture()
  @support.write_text_file(
    stale.request.execution_root + "/source.mbt",
    "later human source\n",
  )
  let blocked = sync(stale.id, 6UL, path~)
  assert_true(blocked.blocked_reason.contains("editor_owner_source_changed"))
  assert_false(@fs.exists(stale.request.result_path))
  let (work, path) = editor_owner_fixture()
  let applied = sync(work.id, 6UL, path~)
  assert_eq(owner_status(applied), "completed")
  let receipt_path = work.request.book_root +
    "/" +
    editor_owner_directory(work.id) +
    "/application-receipt.json"
  @support.write_text_file(receipt_path, "{}")
  assert_eq(editor_applied_feature(work.request.book_root), None)
  assert_true(
    sync(work.id, 7UL, path~).blocked_reason.contains(
      "editor_application_receipt_invalid",
    ),
  )
}
