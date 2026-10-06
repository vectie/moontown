///|
fn fixture_process(
  work : Work,
  command : String,
  changes : Array[Json],
  sequence : String,
  exit_code? : Int = 0,
  sandbox? : Json,
) -> Json {
  fixture_event(
    work,
    "process-" + sequence,
    "shell",
    {
      "cmd": command,
      "cwd": ".",
      "exit_code": exit_code,
      "run_id": "fort-" + sequence,
      "approval_id": "approval-" + sequence,
      "execution_sandbox_policy": "grant-bound",
      "sandbox_evidence": sandbox.unwrap_or({
        "command_digest": "digest-" + sequence,
        "cleanup_verified": true,
        "backend": "LocalOs",
        "enforcement": "Degraded",
        "unverified_limits": [
          "aggregate-cpu", "aggregate-memory", "hard-disk-quota", "filesystem-inode-quota",
          "hard-process-quota", "nested-user-namespaces",
        ],
        "requested_policy": {
          "backend": "LocalOs",
          "network": "Deny",
          "enforcement_requirement": "AllowDegraded",
        },
        "changes": changes,
      }),
    },
    ok=exit_code == 0,
    sequence~,
  )
}

///|
async test "native multi-file deletion and selected hunk proof use real file paths" {
  let request = fixture_request()
  let work = fixture_reserved(request)
  @support.write_text_file(request.execution_root + "/source.mbt", "after\n")
  @fs.remove(request.execution_root + "/notes.txt")
  let patch = fixture_event(work, "patchset", "apply_patch", {
    "path": "patchset",
    "changed": true,
    "files": [
      {
        "path": "source.mbt#hunk-2",
        "file_path": "source.mbt",
        "changed": true,
        "before_fingerprint": native_fingerprint(b"before\n"),
        "after_fingerprint": native_fingerprint(b"after\n"),
      },
      {
        "path": "notes.txt",
        "file_path": "notes.txt",
        "delete_file": true,
        "changed": true,
        "before_fingerprint": native_fingerprint(b"original notes\n"),
        "after_fingerprint": "absent",
      },
    ],
  })
  let evidence : Json = {
    "event_count": 2,
    "events": [patch, fixture_validation(work, "check-2")],
  }
  let result = reconcile_repair_evidence(
    work,
    fixture_receipt(work),
    evidence,
    source_snapshot(request.execution_root),
    0,
    4UL,
  )
  assert_eq(result.state, "completed")
  assert_eq(rows(result.receipt, "changed_files").length(), 2)
  assert_true(
    rows(result.receipt, "changed_files").all(file => {
      !text(file, "path").contains("#hunk")
    }),
  )
}

///|
async test "failed mutating formatter and generated interface changes require successful final-state checks" {
  let request = fixture_request()
  let request = {
    ..request,
    acceptance_policy: {
      "commit_requirement": "not_requested",
      "required_validation_commands": [
        "moon fmt", "moon info", "moon check --no-render",
      ],
    },
  }
  let work = fixture_reserved(request)
  @support.write_text_file(
    request.execution_root + "/source.mbt",
    "formatted\n",
  )
  @support.write_text_file(
    request.execution_root + "/generated.mbti",
    "interface\n",
  )
  let authored = fixture_event(work, "write", "write", {
    "path": "source.mbt",
    "changed": true,
    "before_fingerprint": native_fingerprint(b"before\n"),
    "after_fingerprint": native_fingerprint(b"unformatted\n"),
  })
  let fmt = fixture_process(
    work,
    "moon fmt",
    [
      {
        "relative_path": "source.mbt",
        "before": { "fingerprint": digest("unformatted\n") },
        "after": { "fingerprint": digest("formatted\n") },
      },
    ],
    "2",
    exit_code=1,
  )
  let info = fixture_process(
    work,
    "moon info",
    [
      {
        "relative_path": "generated.mbti",
        "before": null,
        "after": { "fingerprint": digest("interface\n") },
      },
    ],
    "3",
  )
  let events = [
    authored,
    fmt,
    info,
    fixture_process(work, "moon fmt", [], "4"),
    fixture_process(work, "moon info", [], "5"),
    fixture_process(work, "moon check --no-render", [], "6"),
  ]
  let result = reconcile_repair_evidence(
    work,
    fixture_receipt(work),
    { "event_count": events.length(), "events": events },
    source_snapshot(request.execution_root),
    0,
    5UL,
  )
  assert_eq(result.state, "completed")
  assert_eq(rows(result.receipt, "changed_files").length(), 2)
  assert_eq(rows(result.receipt, "validation_commands").length(), 3)
  let incomplete = [
    authored,
    fmt,
    info,
    fixture_process(work, "moon check --no-render", [], "6"),
  ]
  let failed = reconcile_repair_evidence(
    work,
    fixture_receipt(work),
    { "event_count": incomplete.length(), "events": incomplete },
    source_snapshot(request.execution_root),
    0,
    5UL,
  )
  assert_true(
    failed.blocked_reason.has_prefix(
      "native_required_validation_missing_or_failed",
    ),
  )
}

///|
async test "native stable source identity allows attributed manifest bytes but detects unrelated modes and broken links" {
  let request = fixture_request()
  let old_manifest = @fs.read_file(request.execution_root + "/moon.mod").text()
  let manifest = old_manifest + "version = \"0.2.0\"\n"
  @fs.symlink(target="missing-a", request.execution_root + "/broken-link")
  let work = fixture_reserved(request)
  @support.write_text_file(request.execution_root + "/moon.mod", manifest)
  assert_false(source_still_bound(request.source_binding))
  assert_true(source_still_bound(request.source_binding, strict_digest=false))
  let mutation = fixture_event(work, "manifest", "write", {
    "path": "moon.mod",
    "changed": true,
    "before_fingerprint": native_fingerprint(@utf8.encode(old_manifest)),
    "after_fingerprint": native_fingerprint(@utf8.encode(manifest)),
  })
  let events : Json = {
    "event_count": 2,
    "events": [mutation, fixture_validation(work, "check-2")],
  }
  assert_eq(
    reconcile_repair_evidence(
      work,
      fixture_receipt(work),
      events,
      source_snapshot(request.execution_root),
      0,
      4UL,
    ).state,
    "completed",
  )
  @fs.chmod(request.execution_root + "/notes.txt", 0o755)
  assert_true(
    reconcile_repair_evidence(
      work,
      fixture_receipt(work),
      events,
      source_snapshot(request.execution_root),
      0,
      4UL,
    ).blocked_reason.contains("executable_mode_change"),
  )
  @fs.chmod(request.execution_root + "/notes.txt", 0o644)
  @fs.remove(request.execution_root + "/broken-link")
  @fs.symlink(target="missing-b", request.execution_root + "/broken-link")
  assert_true(
    reconcile_repair_evidence(
      work,
      fixture_receipt(work),
      events,
      source_snapshot(request.execution_root),
      0,
      4UL,
    ).blocked_reason.contains("mismatch"),
  )
}

///|
async test "historical approvals resolve and terminal completion outranks old checkpoints" {
  let request = fixture_request()
  let work = fixture_reserved(request)
  let reservation = work.reservation.unwrap()
  let checkpoint : Json = {
    "session_id": reservation.session_id,
    "command_id": reservation.command_id,
    "kind": "runtime.turn_checkpointed",
    "state": "awaiting-approval",
    "approval_id": "approval",
  }
  let approved : Json = {
    "session_id": reservation.session_id,
    "command_id": reservation.command_id,
    "kind": "tool.approval_approved",
    "state": "approved",
    "approval_id": "approval",
  }
  assert_true(unresolved_approval([checkpoint], reservation))
  assert_false(unresolved_approval([checkpoint, approved], reservation))
  let resumed : Json = {
    "session_id": reservation.session_id,
    "command_id": reservation.command_id,
    "kind": "runtime.turn_checkpointed",
    "state": "planner-quantum-paused",
  }
  assert_false(unresolved_approval([checkpoint, resumed], reservation))
  @support.write_text_file(request.execution_root + "/source.mbt", "after\n")
  let command = @json.parse(reservation.request_body)
  let base : Json = {
    "protocol": "mooncode.v1",
    "owner": "moonclaw",
    "session_id": reservation.session_id,
    "book_root": reservation.execution_root,
  }
  let receipt = fixture_receipt(work)
  guard receipt is Object(receipt_fields) else { abort("receipt") }
  receipt_fields["protocol"] = "mooncode.v1".to_json()
  receipt_fields["command"] = command
  let claim : Json = {
    "protocol": "mooncode.v1",
    "owner": "moonclaw",
    "session_id": reservation.session_id,
    "book_root": reservation.execution_root,
    "delivered_commands": [
      {
        "command_id": reservation.command_id,
        "command": command,
        "receipt": Json::object(receipt_fields),
      },
    ],
  }
  let mutation = fixture_event(work, "write", "write", {
    "path": "source.mbt",
    "changed": true,
    "before_fingerprint": native_fingerprint(b"before\n"),
    "after_fingerprint": native_fingerprint(b"after\n"),
  })
  guard base is Object(fields) else { abort("base") }
  fields["events"] = [
    checkpoint,
    approved,
    mutation,
    fixture_validation(work, "check-2"),
  ].to_json()
  fields["event_count"] = (4).to_json()
  let result = observe(
    work,
    claim,
    Json::object(fields),
    base,
    "fixture-instance",
    5UL,
  )
  assert_eq(result.state, "completed")
}

///|
test "observed Git mutation is separate from unverified process behavior" {
  assert_false(observed_forbidden_git_operation("git --no-pager diff --check"))
  assert_false(observed_forbidden_git_operation("git -C . status --short"))
  assert_true(observed_forbidden_git_operation("git -C . push"))
  assert_true(observed_forbidden_git_operation("git --no-pager push"))
  assert_true(observed_forbidden_git_operation("git -C . commit -m repair"))
  assert_true(
    observed_forbidden_git_operation(
      "/usr/bin/git -c advice.detachedHead=false -C . add source.mbt",
    ),
  )
  assert_true(observed_forbidden_git_operation("moon test; git push"))
  assert_false(observed_forbidden_git_operation("sh scripts/unknown.sh"))
  assert_false(observed_forbidden_git_operation("moon info && moon check"))
  assert_false(observed_forbidden_git_operation("printf 'example; git push'"))
  assert_false(observed_forbidden_git_operation("git restore source.mbt"))
  assert_false(observed_forbidden_git_operation("git checkout -- source.mbt"))
  assert_false(observed_forbidden_git_operation("git apply repair.patch"))
}

///|
async test "operator-authorized local AllowDegraded validation preserves assurance without publication claims" {
  let request = fixture_request()
  let commands = [
    "moon fmt", "moon info", "moon check --no-render", "moon test --no-render",
  ]
  let request = {
    ..request,
    acceptance_policy: {
      "commit_requirement": "not_requested",
      "required_validation_commands": commands,
    },
  }
  let work = fixture_reserved(request)
  @support.write_text_file(request.execution_root + "/source.mbt", "after\n")
  let events = [
    fixture_event(work, "write", "write", {
      "path": "source.mbt",
      "changed": true,
      "before_fingerprint": native_fingerprint(b"before\n"),
      "after_fingerprint": native_fingerprint(b"after\n"),
    }),
  ]
  for index, command in commands {
    events.push(fixture_process(work, command, [], (index + 2).to_string()))
  }
  let unknown = fixture_process(
    work,
    "sh scripts/inspect.sh && printf done",
    [],
    "6",
    sandbox={
      "command_digest": "approved-other-process",
      "cleanup_verified": true,
      "backend": "LocalOs",
      "enforcement": "Degraded",
      "unverified_limits": ["shared-kernel"],
      "requested_policy": {
        "backend": "LocalOs",
        "network": "Deny",
        "enforcement_requirement": "AllowDegraded",
      },
    },
  )
  events.push(unknown)
  let accepted = reconcile_repair_evidence(
    work,
    fixture_receipt(work),
    { "event_count": events.length(), "events": events },
    source_snapshot(request.execution_root),
    0,
    5UL,
  )
  assert_eq(accepted.state, "completed")
  assert_eq(
    text(accepted.receipt, "engineering_status"),
    "applied_and_validated",
  )
  assert_eq(field(accepted.receipt, "push_performed"), Json::null())
  assert_eq(text(accepted.receipt, "publication_verification"), "not_verified")
  let checks = rows(accepted.receipt, "validation_commands")
  assert_eq(checks.length(), 4)
  for index, check in checks {
    assert_eq(
      field(check, "sandbox_evidence"),
      field(
        field(field(events[index + 1], "tool_result"), "metadata"),
        "sandbox_evidence",
      ),
    )
    assert_eq(text(field(check, "sandbox_evidence"), "enforcement"), "Degraded")
  }
  assert_eq(rows(accepted.receipt, "process_evidence").length(), 5)
  for prose in ["push_performed: false", "push_performed: true"] {
    let prose_result = reconcile_repair_evidence(
      work,
      fixture_receipt(work, answer="repair_decision: accepted\n" + prose),
      { "event_count": events.length(), "events": events },
      source_snapshot(request.execution_root),
      0,
      5UL,
    )
    assert_eq(prose_result.state, "completed")
    assert_eq(field(prose_result.receipt, "push_performed"), Json::null())
    assert_eq(
      text(prose_result.receipt, "publication_verification"),
      "not_verified",
    )
  }
  ignore(apply_owner_result(accepted))
  assert_true(
    @fs.read_file(request.result_path)
    .text()
    .contains("publication_verification: not_verified"),
  )
  for
    command in [
      "git -C . push", "git --no-pager commit -m repair", "git -C . add source.mbt",
      "moon test; git push",
    ] {
    let forbidden = events.copy()
    forbidden.push(fixture_process(work, command, [], "7"))
    let rejected = reconcile_repair_evidence(
      work,
      fixture_receipt(work),
      { "event_count": forbidden.length(), "events": forbidden },
      source_snapshot(request.execution_root),
      0,
      6UL,
    )
    assert_eq(rejected.blocked_reason, "native_forbidden_git_operation")
  }
}

///|
async test "authorized assurance does not weaken required command identity or terminal evidence" {
  let request = fixture_request()
  let work = fixture_reserved(request)
  @support.write_text_file(request.execution_root + "/source.mbt", "after\n")
  let mutation = fixture_event(work, "write", "write", {
    "path": "source.mbt",
    "changed": true,
    "before_fingerprint": native_fingerprint(b"before\n"),
    "after_fingerprint": native_fingerprint(b"after\n"),
  })
  for
    (key, value) in [
      ("cmd", "moon check".to_json()),
      ("cwd", "/unrelated".to_json()),
      ("approval_id", "".to_json()),
      ("run_id", "".to_json()),
      ("execution_sandbox_policy", "missing".to_json()),
      ("exit_code", (1).to_json()),
      ("sandbox_evidence", ({ "cleanup_verified": false } : Json)),
    ] {
    let validation = fixture_validation(work, "check-2")
    guard field(field(validation, "tool_result"), "metadata")
      is Object(metadata) else {
      abort("fixture")
    }
    metadata[key] = value
    let result = reconcile_repair_evidence(
      work,
      fixture_receipt(work),
      { "event_count": 2, "events": [mutation, validation] },
      source_snapshot(request.execution_root),
      0,
      5UL,
    )
    assert_true(
      result.blocked_reason.has_prefix(
        "native_required_validation_missing_or_failed",
      ),
    )
  }
}
