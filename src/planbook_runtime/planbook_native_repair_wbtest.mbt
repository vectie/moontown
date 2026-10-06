///|
async test "PlanBook default is durable native queue without generated ACP target or profile" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-native-planbook-default-wbtest",
  )
  let criterion : PlanbookCriterionStatus = {
    id: "native-fixture",
    plan_id: "fixture",
    title: "Source fix",
    owner: "moontown",
    satisfied: false,
    evidence: "Fixture gap",
    next_action: "Fix source",
  }
  let task = materialize_native_planbook_repair(
    criterion,
    workspace.snapshot_path,
    workspace.workspace_root,
    workspace.catalog_path,
    false,
  )
  assert_eq(task.status, "queued")
  assert_true(task.id.has_prefix("town-work-"))
  let packet = @support.read_text_or_empty(task.packet_path)
  assert_true(packet.contains("planbook.repair.native_patch_receipt.v1"))
  assert_false(packet.contains("\"execution_mode\":\"acp\""))
  assert_false(packet.contains("codex-main"))
  let state = @native_work.load(
    path=@native_work.path_for_snapshot(workspace.snapshot_path),
  )
  assert_eq(state.work.length(), 1)
  assert_true(
    state.work[0].request.acceptance_policy
    is { "commit_requirement": "not_requested", .. },
  )
  let second = materialize_native_planbook_repair(
    criterion,
    workspace.snapshot_path,
    workspace.workspace_root,
    workspace.catalog_path,
    false,
  )
  assert_eq(task.id, second.id)
  assert_eq(
    state.work[0].request.prompt,
    @native_work.load(
      path=@native_work.path_for_snapshot(workspace.snapshot_path),
    ).work[0].request.prompt,
  )
  // A settled engineering-only attempt leaves the criterion open, but must
  // not rotate its logical work identity when materialized again.
  let completed : @native_work.Work = {
    ..state.work[0],
    state: "completed",
    receipt: {
      "engineering_status": "no_change",
      "original_task_acceptance": "unevaluated",
    },
  }
  let terminal_state : @native_work.State = { ..state, work: [completed], }
  @support.write_text_file(
    @native_work.path_for_snapshot(workspace.snapshot_path),
    terminal_state.to_json().stringify(),
  )
  let repeated = materialize_native_planbook_repair(
    criterion,
    workspace.snapshot_path,
    workspace.workspace_root,
    workspace.catalog_path,
    false,
  )
  assert_eq(repeated.id, task.id)
  assert_eq(repeated.status, "completed")
  let retained = @native_work.load(
    path=@native_work.path_for_snapshot(workspace.snapshot_path),
  )
  assert_eq(retained.work.length(), 1)
  assert_eq(retained.work[0].request.to_json(), state.work[0].request.to_json())
}

///|
test "native repair policy preserves saved commit requirement without making all new work require a commit" {
  assert_true(
    native_repair_policy(false) is { "commit_requirement": "not_requested", .. },
  )
  assert_true(
    native_repair_policy(true)
    is {
      "commit_requirement": "required",
      "commit_provenance": "saved_legacy_packet",
      ..
    },
  )
  let policy = native_repair_policy(false)
  guard policy
    is {
      "completion_policy": completion,
      "required_validation_commands": Array(commands),
      ..
    } else {
    fail("missing new opt-in")
  }
  guard completion
    is {
      "contract": "mooncode.completion-outcome.v1",
      "allowed_outcomes": ["mutation", "no_change"],
      "acceptance_scope": "engineering_only",
      "no_change_receipt_contract": "planbook.repair.native_no_change_receipt.v1",
      "required_checks": Array(checks),
      ..
    } else {
    fail("invalid completion contract")
  }
  assert_eq(commands, [
    "moon fmt".to_json(),
    "moon info".to_json(),
    "moon check --no-render".to_json(),
    "moon test src/planbook_runtime/planbook_autonomy_wbtest.mbt src/live_autonomy_runtime/live_autonomy_wbtest.mbt --no-render".to_json(),
    "moon test --no-render".to_json(),
    "git diff --check".to_json(),
  ])
  assert_eq(checks.length(), commands.length())
  for index, check in checks {
    assert_eq(check, {
      "id": "check-" + (index + 1).to_string(),
      "tool": "shell",
      "command": commands[index],
      "cwd": ".",
      "exit_code": 0,
    })
  }
  assert_true(native_repair_policy(true) is { "completion_policy"? : None, .. })
}

///|
test "native no change result is not source patch loop proof" {
  assert_false(
    planbook_repair_source_patch_receipt_text_ready(
      "contract: planbook.repair.result.v1\ncriterion_id: planbook-source-patch-loop\nrepair_decision: no_change\nengineering_status: no_change\nnative_receipt_contract: planbook.repair.native_no_change_receipt.v1\noriginal_task_acceptance: unevaluated\nNo net source change; required checks passed.\n",
    ),
  )
}
