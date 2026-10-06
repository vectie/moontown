///|
fn no_change_fixture_policy() -> Json {
  {
    "contract": "mooncode.completion-outcome.v1",
    "allowed_outcomes": ["mutation", "no_change"],
    "no_change_reason": "already_satisfied",
    "alternative_milestone_ids": ["implementation"],
    "required_checks": [
      {
        "id": "check-1",
        "tool": "shell",
        "command": "moon check --no-render",
        "cwd": ".",
        "exit_code": 0,
      },
    ],
    "evidence_scope": "native_tool_journal",
    "acceptance_scope": "engineering_only",
    "no_change_receipt_contract": "planbook.repair.native_no_change_receipt.v1",
  }
}

///|
async fn no_change_fixture_work() -> Work {
  let request = fixture_request()
  fixture_reserved(no_change_fixture_request(request))
}

///|
fn no_change_fixture_request(request : Request) -> Request {
  {
    ..request,
    acceptance_policy: {
      "commit_requirement": "not_requested",
      "required_validation_commands": ["moon check --no-render"],
      "completion_policy": no_change_fixture_policy(),
    },
  }
}

///|
fn no_change_fixture_proposal() -> Json {
  {
    "reason": "already_satisfied",
    "observation": "Worker found the requested behavior already present",
    "evidence_refs": ["check-2"],
  }
}

///|
fn no_change_fixture_receipt(work : Work) -> Json {
  let receipt = fixture_receipt(
    work,
    answer="No net source change; required checks passed",
  )
  if receipt is Object(fields) {
    fields["execution"] = {
      "completion_verdict": {
        "kind": "mooncode-coding-completion-verdict",
        "accepted": true,
        "reason": "validated",
        "completion_contract": "mooncode.completion-outcome.v1",
        "completion_outcome": "no_change",
        "no_change": no_change_fixture_proposal(),
        "acceptance_scope": "engineering_only",
        "original_task_acceptance": "unevaluated",
        "required_check_evidence": [{ "id": "check-1", "event_id": "check-2" }],
      },
      "tool_results": [
        {
          "tool": "finish",
          "accepted": true,
          "result": {
            "is_error": false,
            "metadata": {
              "answer": "No net source change; required checks passed",
              "completion_outcome": "no_change",
              "no_change": no_change_fixture_proposal(),
            },
          },
        },
      ],
    }
  }
  receipt
}

///|
fn no_change_fixture_events(work : Work) -> Json {
  {
    "event_count": 3,
    "events": [
      fixture_validation(work, "check-2"),
      fixture_event(
        work,
        "checkpoint-3",
        "checkpoint",
        {
          "all_done": true,
          "checkpoint": {
            "completion_outcome": "no_change",
            "no_change": no_change_fixture_proposal(),
            "milestones": [
              {
                "id": "implementation",
                "status": "done",
                "evidence_kind": "mutation",
                "resolution": "already_satisfied",
              },
            ],
          },
        },
        sequence="3",
      ),
      fixture_event(
        work,
        "finish-4",
        "finish",
        {
          "completion_outcome": "no_change",
          "no_change": no_change_fixture_proposal(),
        },
        sequence="4",
      ),
    ],
  }
}

///|
async test "native opted in no change settles engineering only with preserved native evidence" {
  let work = no_change_fixture_work()
  let result = reconcile_repair_evidence(
    work,
    no_change_fixture_receipt(work),
    no_change_fixture_events(work),
    work.baseline,
    0,
    5UL,
  )
  assert_eq(result.state, "completed")
  assert_eq(
    text(result.receipt, "contract"),
    "planbook.repair.native_no_change_receipt.v1",
  )
  assert_eq(text(result.receipt, "engineering_status"), "no_change")
  assert_eq(text(result.receipt, "result_decision"), "no_change")
  assert_eq(text(result.receipt, "original_task_acceptance"), "unevaluated")
  assert_eq(text(result.receipt, "commit_status"), "not_requested")
  assert_eq(field(result.receipt, "commit_sha"), Json::null())
  assert_true(rows(result.receipt, "changed_files").is_empty())
  assert_eq(field(result.receipt, "focused_diff"), Json::null())
  assert_eq(
    text(
      field(rows(result.receipt, "validation_commands")[0], "sandbox_evidence"),
      "enforcement",
    ),
    "Degraded",
  )
}

///|
fn no_change_set(value : Json, key : String, replacement : Json) -> Unit {
  if value is Object(fields) {
    fields[key] = replacement
  }
}

///|
async test "native no change rejects synthetic verdicts mismatched proposals incomplete or invalid evidence" {
  let work = no_change_fixture_work()
  for
    boundary in [
      "no-verdict", "rejected-verdict", "wrong-kind", "wrong-contract", "wrong-outcome",
      "wrong-scope", "claimed-acceptance", "empty-observation", "wrong-reason", "missing-reference",
      "duplicate-reference", "unknown-reference", "missing-events", "incomplete-events",
      "duplicate-event", "out-of-order", "checkpoint-mismatch", "not-all-done", "finish-mismatch",
      "projection-mismatch", "unpermitted-milestone", "missing-check-id", "wrong-check-event",
      "wrong-command", "wrong-cwd", "wrong-tool", "failed-check", "no-cleanup", "ambiguous-process",
    ] {
    let receipt = no_change_fixture_receipt(work)
    let events = no_change_fixture_events(work)
    let execution = field(receipt, "execution")
    let verdict = field(execution, "completion_verdict")
    let proposal = field(verdict, "no_change")
    let journal = rows(events, "events")
    let check = field(field(journal[0], "tool_result"), "metadata")
    let checkpoint = field(field(journal[1], "tool_result"), "metadata")
    let finish = field(field(journal[2], "tool_result"), "metadata")
    match boundary {
      "no-verdict" =>
        no_change_set(execution, "completion_verdict", Json::null())
      "rejected-verdict" => no_change_set(verdict, "accepted", false.to_json())
      "wrong-kind" => no_change_set(verdict, "kind", "forged".to_json())
      "wrong-contract" =>
        no_change_set(verdict, "completion_contract", "unknown".to_json())
      "wrong-outcome" =>
        no_change_set(verdict, "completion_outcome", "mutation".to_json())
      "wrong-scope" =>
        no_change_set(verdict, "acceptance_scope", "customer".to_json())
      "claimed-acceptance" =>
        no_change_set(verdict, "original_task_acceptance", "accepted".to_json())
      "empty-observation" =>
        no_change_set(proposal, "observation", " ".to_json())
      "wrong-reason" =>
        no_change_set(proposal, "reason", "nothing-to-do".to_json())
      "missing-reference" =>
        no_change_set(proposal, "evidence_refs", [].to_json())
      "duplicate-reference" =>
        no_change_set(
          proposal,
          "evidence_refs",
          ["check-2", "check-2"].to_json(),
        )
      "unknown-reference" =>
        no_change_set(proposal, "evidence_refs", ["missing"].to_json())
      "missing-events" => {
        no_change_set(events, "events", [].to_json())
        no_change_set(events, "event_count", (0).to_json())
      }
      "incomplete-events" => no_change_set(events, "event_count", (4).to_json())
      "duplicate-event" => no_change_set(journal[1], "id", "check-2".to_json())
      "out-of-order" =>
        no_change_set(journal[1], "journal_sequence", "1".to_json())
      "checkpoint-mismatch" =>
        no_change_set(
          field(checkpoint, "checkpoint"),
          "no_change",
          Json::null(),
        )
      "not-all-done" => no_change_set(checkpoint, "all_done", false.to_json())
      "finish-mismatch" =>
        no_change_set(finish, "completion_outcome", "mutation".to_json())
      "projection-mismatch" =>
        no_change_set(
          field(field(rows(execution, "tool_results")[0], "result"), "metadata"),
          "no_change",
          Json::null(),
        )
      "unpermitted-milestone" =>
        no_change_set(
          rows(field(checkpoint, "checkpoint"), "milestones")[0],
          "id",
          "other".to_json(),
        )
      "missing-check-id" =>
        no_change_set(
          verdict,
          "required_check_evidence",
          [{ "id": "other", "event_id": "check-2" }].to_json(),
        )
      "wrong-check-event" =>
        no_change_set(
          verdict,
          "required_check_evidence",
          [{ "id": "check-1", "event_id": "checkpoint-3" }].to_json(),
        )
      "wrong-command" => no_change_set(check, "cmd", "moon check".to_json())
      "wrong-cwd" => no_change_set(check, "cwd", "/other".to_json())
      "wrong-tool" => {
        no_change_set(journal[0], "tool", "moon_cmd".to_json())
        no_change_set(check, "command", "moon check --no-render".to_json())
      }
      "failed-check" => no_change_set(check, "exit_code", (1).to_json())
      "no-cleanup" =>
        no_change_set(
          field(check, "sandbox_evidence"),
          "cleanup_verified",
          false.to_json(),
        )
      _ => no_change_set(check, "pipeline_exit_ambiguous", true.to_json())
    }
    let result = reconcile_repair_evidence(
      work,
      receipt,
      events,
      work.baseline,
      0,
      5UL,
    )
    assert_true(result.state != "completed", msg=boundary)
  }
  let missing_policy = fixture_reserved(fixture_request())
  assert_eq(
    reconcile_repair_evidence(
      missing_policy,
      no_change_fixture_receipt(missing_policy),
      no_change_fixture_events(missing_policy),
      missing_policy.baseline,
      0,
      5UL,
    ).blocked_reason,
    "native_no_change_settlement_unsupported",
  )
}

///|
async test "native no change rejects net source mode symlink head index and root changes" {
  let work = no_change_fixture_work()
  for key in ["root", "head", "index_digest", "source_digest"] {
    let snapshot = source_snapshot(work.request.execution_root)
    no_change_set(snapshot, key, "different".to_json())
    assert_true(
      reconcile_repair_evidence(
        work,
        no_change_fixture_receipt(work),
        no_change_fixture_events(work),
        snapshot,
        0,
        5UL,
      ).state !=
      "completed",
      msg=key,
    )
  }
  let snapshot = source_snapshot(work.request.execution_root)
  no_change_set(field(snapshot, "executable"), "source.mbt", true.to_json())
  assert_true(
    reconcile_repair_evidence(
      work,
      no_change_fixture_receipt(work),
      no_change_fixture_events(work),
      snapshot,
      0,
      5UL,
    ).state !=
    "completed",
  )
  let snapshot = source_snapshot(work.request.execution_root)
  no_change_set(
    field(snapshot, "files"),
    "source.mbt",
    "symlink:other".to_json(),
  )
  assert_true(
    reconcile_repair_evidence(
      work,
      no_change_fixture_receipt(work),
      no_change_fixture_events(work),
      snapshot,
      0,
      5UL,
    ).state !=
    "completed",
  )
  @support.write_text_file(
    work.request.execution_root + "/source.mbt",
    "after\n",
  )
  let events = no_change_fixture_events(work)
  let journal = rows(events, "events")
  journal.insert(
    0,
    fixture_event(work, "write-1", "write", {
      "path": "source.mbt",
      "changed": true,
      "before_fingerprint": native_fingerprint(b"before\n"),
      "after_fingerprint": native_fingerprint(b"after\n"),
    }),
  )
  no_change_set(events, "event_count", journal.length().to_json())
  assert_eq(
    reconcile_repair_evidence(
      work,
      no_change_fixture_receipt(work),
      events,
      source_snapshot(work.request.execution_root),
      0,
      5UL,
    ).blocked_reason,
    "native_no_change_source_changed",
  )
}

///|
async test "native no change attested edit restore requires final checks and never touches existing dirty work" {
  let request = no_change_fixture_request(fixture_request())
  @support.write_text_file(request.execution_root + "/notes.txt", "staged\n")
  ignore(
    @integration.run_checked("git", [
      "-C",
      request.execution_root,
      "add",
      "notes.txt",
    ]),
  )
  @support.write_text_file(
    request.execution_root + "/private.txt",
    "untracked\n",
  )
  let work = fixture_reserved(request)
  let events = no_change_fixture_events(work)
  let journal = rows(events, "events")
  for offset, event in journal {
    no_change_set(event, "journal_sequence", (offset + 3).to_string().to_json())
  }
  journal.insert(
    0,
    fixture_event(
      work,
      "write-1",
      "write",
      {
        "path": "source.mbt",
        "changed": true,
        "before_fingerprint": native_fingerprint(b"before\n"),
        "after_fingerprint": native_fingerprint(b"temporary\n"),
      },
      sequence="1",
    ),
  )
  journal.insert(
    1,
    fixture_event(
      work,
      "restore-2",
      "write",
      {
        "path": "source.mbt",
        "changed": true,
        "before_fingerprint": native_fingerprint(b"temporary\n"),
        "after_fingerprint": native_fingerprint(b"before\n"),
      },
      sequence="2",
    ),
  )
  no_change_set(events, "event_count", journal.length().to_json())
  let result = reconcile_repair_evidence(
    work,
    no_change_fixture_receipt(work),
    events,
    work.baseline,
    0,
    6UL,
  )
  assert_eq(result.state, "completed")
  assert_eq(text(result.receipt, "engineering_status"), "no_change")
  assert_eq(
    @fs.read_file(request.execution_root + "/private.txt").text(),
    "untracked\n",
  )
  assert_eq(
    text(source_snapshot(request.execution_root), "index_digest"),
    text(work.baseline, "index_digest"),
  )
  let stale = no_change_fixture_events(work)
  let stale_events = rows(stale, "events")
  stale_events.insert(1, journal[0])
  stale_events.insert(2, journal[1])
  for offset, event in stale_events {
    no_change_set(event, "journal_sequence", (offset + 1).to_string().to_json())
  }
  no_change_set(stale, "event_count", stale_events.length().to_json())
  assert_true(
    reconcile_repair_evidence(
      work,
      no_change_fixture_receipt(work),
      stale,
      work.baseline,
      0,
      6UL,
    ).state !=
    "completed",
  )
  for event in journal[:2] {
    no_change_set(
      field(field(event, "tool_result"), "metadata"),
      "path",
      "notes.txt".to_json(),
    )
  }
  assert_true(
    reconcile_repair_evidence(
      work,
      no_change_fixture_receipt(work),
      events,
      work.baseline,
      0,
      6UL,
    ).blocked_reason.has_prefix("native_preexisting_dirty_path_touched"),
  )
}

///|
async test "native no change requires all checks after a later failed tool and final freshness" {
  let work = no_change_fixture_work()
  let events = no_change_fixture_events(work)
  let journal = rows(events, "events")
  journal.insert(
    1,
    fixture_event(work, "failed-read", "read", {}, ok=false, sequence="3"),
  )
  for offset, event in journal {
    no_change_set(event, "journal_sequence", (offset + 1).to_string().to_json())
  }
  no_change_set(events, "event_count", journal.length().to_json())
  assert_true(
    reconcile_repair_evidence(
      work,
      no_change_fixture_receipt(work),
      events,
      work.baseline,
      0,
      5UL,
    ).state !=
    "completed",
  )
  let result = reconcile_repair_evidence(
    work,
    no_change_fixture_receipt(work),
    no_change_fixture_events(work),
    work.baseline,
    0,
    5UL,
  )
  assert_eq(verify_final_source_freshness(result, 6UL).state, "completed")
  @support.write_text_file(
    work.request.execution_root + "/source.mbt",
    "drift\n",
  )
  assert_eq(
    verify_final_source_freshness(result, 7UL).blocked_reason,
    "native_source_changed_during_reconciliation",
  )
}

///|
async test "native no change permits an attested new file created and removed before final checks" {
  let work = no_change_fixture_work()
  let events = no_change_fixture_events(work)
  let journal = rows(events, "events")
  for offset, event in journal {
    no_change_set(event, "journal_sequence", (offset + 3).to_string().to_json())
  }
  journal.insert(
    0,
    fixture_event(
      work,
      "write-1",
      "write",
      {
        "path": "temporary.mbt",
        "changed": true,
        "before_fingerprint": "absent",
        "after_fingerprint": native_fingerprint(b"temporary\n"),
      },
      sequence="1",
    ),
  )
  journal.insert(
    1,
    fixture_event(
      work,
      "remove-2",
      "apply_patch",
      {
        "path": "temporary.mbt",
        "changed": true,
        "before_fingerprint": native_fingerprint(b"temporary\n"),
        "after_fingerprint": "absent",
      },
      sequence="2",
    ),
  )
  no_change_set(events, "event_count", journal.length().to_json())
  assert_eq(
    reconcile_repair_evidence(
      work,
      no_change_fixture_receipt(work),
      events,
      work.baseline,
      0,
      6UL,
    ).state,
    "completed",
  )
}

///|
async test "native no change generic checks cannot replace a frozen task specific check" {
  let request = no_change_fixture_request(fixture_request())
  let policy = field(request.acceptance_policy, "completion_policy")
  rows(policy, "required_checks").push({
    "id": "task-specific",
    "tool": "shell",
    "command": "test -f required-feature",
    "cwd": ".",
    "exit_code": 0,
  })
  let work = fixture_reserved(request)
  let receipt = no_change_fixture_receipt(work)
  let verdict = field(field(receipt, "execution"), "completion_verdict")
  rows(verdict, "required_check_evidence").push({
    "id": "task-specific",
    "event_id": "missing-task-check",
  })
  assert_true(
    reconcile_repair_evidence(
      work,
      receipt,
      no_change_fixture_events(work),
      work.baseline,
      0,
      5UL,
    ).state !=
    "completed",
  )
  let changed = no_change_fixture_work()
  no_change_set(
    field(changed.request.acceptance_policy, "completion_policy"),
    "acceptance_scope",
    "customer".to_json(),
  )
  assert_eq(
    reconcile_repair_evidence(
      changed,
      no_change_fixture_receipt(changed),
      no_change_fixture_events(changed),
      changed.baseline,
      0,
      5UL,
    ).blocked_reason,
    "native_no_change_policy_binding_invalid",
  )
}
