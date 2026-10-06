///|
fn wenyu_no_change_commands() -> Array[String] {
  [
    "moon fmt", "moon info", "moon check --no-render", "moon test src/build_pipeline src/build_pipeline_runtime src/town_runtime --no-render",
    "moon -C src/ui/rabbita-town build --target js --release", "git diff --check",
  ]
}

///|
fn wenyu_no_change_request(
  root? : String = "/synthetic-wenyu-no-change",
) -> Request {
  let request = wenyu_fixture_request(root~)
  no_change_set(
    request.acceptance_policy,
    "required_validation_commands",
    wenyu_no_change_commands().to_json(),
  )
  no_change_set(
    request.acceptance_policy,
    "completion_policy",
    wenyu_completion_policy(wenyu_no_change_commands()),
  )
  request
}

///|
fn wenyu_no_change_proposal() -> Json {
  {
    "reason": "already_satisfied",
    "observation": "The inspected source already implements the requested behavior; product acceptance still needs human review",
    "evidence_refs": [
      "source-read", "check-1", "check-2", "check-3", "check-4", "check-5", "check-6",
    ],
  }
}

///|
fn wenyu_no_change_answer(work : Work) -> String {
  let answer = wenyu_fixture_answer(work)
  no_change_set(answer, "outcome", "no_change".to_json())
  no_change_set(
    answer,
    "summary",
    "No net source change; required checks passed".to_json(),
  )
  no_change_set(
    answer,
    "behavior",
    "The inspected source already has the requested behavior".to_json(),
  )
  answer.stringify()
}

///|
fn wenyu_no_change_events(work : Work) -> Json {
  let journal : Array[Json] = [
    fixture_event(work, "source-read", "read", { "path": "source.mbt" }),
  ]
  for index, command in wenyu_no_change_commands() {
    let event = fixture_validation(work, "check-" + (index + 1).to_string())
    no_change_set(event, "journal_sequence", (index + 2).to_string().to_json())
    let metadata = field(field(event, "tool_result"), "metadata")
    no_change_set(metadata, "cmd", command.to_json())
    no_change_set(
      field(metadata, "sandbox_evidence"),
      "fixture_injected",
      true.to_json(),
    )
    journal.push(event)
  }
  journal.push(
    fixture_event(
      work,
      "checkpoint-final",
      "checkpoint",
      {
        "all_done": true,
        "checkpoint": {
          "completion_outcome": "no_change",
          "no_change": wenyu_no_change_proposal(),
          "milestones": [
            { "id": "scope", "status": "done", "evidence_kind": "read" },
            {
              "id": "implementation",
              "status": "done",
              "evidence_kind": "mutation",
              "resolution": "already_satisfied",
            },
            { "id": "verification", "status": "done", "evidence_kind": "test" },
            { "id": "build", "status": "done", "evidence_kind": "build" },
          ],
        },
      },
      sequence="8",
    ),
  )
  journal.push(
    fixture_event(
      work,
      "finish-final",
      "finish",
      {
        "completion_outcome": "no_change",
        "no_change": wenyu_no_change_proposal(),
      },
      sequence="9",
    ),
  )
  { "event_count": journal.length(), "events": journal }
}

///|
fn wenyu_no_change_native_receipt(work : Work) -> Json {
  let receipt = fixture_receipt(work, answer=wenyu_no_change_answer(work))
  let claims : Array[Json] = []
  for index, _ in wenyu_no_change_commands() {
    let id = "check-" + (index + 1).to_string()
    claims.push({ "id": id, "event_id": id })
  }
  no_change_set(receipt, "execution", {
    "completion_verdict": {
      "kind": "mooncode-coding-completion-verdict",
      "accepted": true,
      "completion_contract": "mooncode.completion-outcome.v1",
      "completion_outcome": "no_change",
      "acceptance_scope": "engineering_only",
      "original_task_acceptance": "unevaluated",
      "no_change": wenyu_no_change_proposal(),
      "required_check_evidence": claims,
    },
    "tool_results": [
      {
        "tool": "finish",
        "accepted": true,
        "result": {
          "is_error": false,
          "metadata": {
            "answer": wenyu_no_change_answer(work),
            "completion_outcome": "no_change",
            "no_change": wenyu_no_change_proposal(),
          },
        },
      },
    ],
  })
  receipt
}

///|
test "wenyu opted in no change requires exact frozen checks and preserves mutation only defaults" {
  let request = wenyu_no_change_request()
  assert_true(wenyu_policy_valid(request))
  let work = wenyu_fixture_reserved(request)
  let policy = field(request.acceptance_policy, "completion_policy")
  assert_eq(rows(policy, "required_checks").length(), 6)
  assert_eq(rows(policy, "alternative_milestone_ids"), [
    "implementation".to_json(),
  ])
  assert_eq(
    field(
      field(
        field(@json.parse(work.reservation.unwrap().request_body), "payload"),
        "task_contract",
      ),
      "completion_policy",
    ),
    policy,
  )
  assert_true(
    work.reservation.unwrap().request_body.contains("Never create a fake edit"),
  )
  assert_false(
    work.reservation.unwrap().request_body.contains("no no-change completion"),
  )
  assert_false(
    wenyu_result_satisfies_contract(work, wenyu_no_change_answer(work)),
  )
  assert_true(
    wenyu_result_satisfies_contract(
      work,
      wenyu_no_change_answer(work),
      no_change=true,
    ),
  )
  let legacy = wenyu_fixture_reserved(wenyu_fixture_request())
  assert_false(
    wenyu_result_satisfies_contract(
      legacy,
      wenyu_no_change_answer(legacy),
      no_change=true,
    ),
  )
  for
    boundary in [
      "missing", "extra", "command", "tool", "cwd", "exit", "id", "milestone", "receipt",
      "scope", "outcomes", "extra-key",
    ] {
    let request = wenyu_no_change_request()
    let completion = field(request.acceptance_policy, "completion_policy")
    let checks = rows(completion, "required_checks")
    match boundary {
      "missing" => ignore(checks.pop())
      "extra" => checks.push(checks[0])
      "command" => no_change_set(checks[0], "command", "moon check".to_json())
      "tool" => no_change_set(checks[0], "tool", "moon_cmd".to_json())
      "cwd" => no_change_set(checks[0], "cwd", "/elsewhere".to_json())
      "exit" => no_change_set(checks[0], "exit_code", (1).to_json())
      "id" => no_change_set(checks[1], "id", "check-1".to_json())
      "milestone" =>
        no_change_set(
          completion,
          "alternative_milestone_ids",
          ["implementation", "build"].to_json(),
        )
      "receipt" =>
        no_change_set(
          completion,
          "no_change_receipt_contract",
          "planbook.repair.native_no_change_receipt.v1".to_json(),
        )
      "scope" =>
        no_change_set(completion, "acceptance_scope", "product".to_json())
      "outcomes" =>
        no_change_set(completion, "allowed_outcomes", ["no_change"].to_json())
      _ => no_change_set(completion, "accept_anything", true.to_json())
    }
    assert_false(wenyu_policy_valid(request), msg=boundary)
  }
}

///|
test "wenyu six command no change evidence settles honest owner bound receipt" {
  let work = wenyu_fixture_reserved(wenyu_no_change_request())
  let completed = reconcile_repair_evidence(
    work,
    wenyu_no_change_native_receipt(work),
    wenyu_no_change_events(work),
    work.baseline,
    0,
    5UL,
  )
  assert_eq(completed.state, "completed")
  assert_eq(
    text(completed.receipt, "contract"),
    "wenyu.build.native_no_change_receipt.v1",
  )
  assert_eq(text(completed.receipt, "engineering_status"), "no_change")
  assert_eq(text(completed.receipt, "result_decision"), "no_change")
  assert_eq(rows(completed.receipt, "validation_commands").length(), 6)
  assert_eq(rows(completed.receipt, "changed_files"), [])
  assert_eq(field(completed.receipt, "focused_diff"), Json::null())
  assert_eq(text(completed.receipt, "original_task_acceptance"), "unevaluated")
  assert_true(wenyu_no_change_receipt_satisfies_contract(completed))
  assert_true(summary(completed).contains("No net source change"))
  let restored : Work = @json.from_json(
    @json.parse(completed.to_json().stringify()),
  )
  assert_eq(restored.to_json(), completed.to_json())
  assert_true(wenyu_no_change_receipt_satisfies_contract(restored))
  for
    key in [
      "completion_outcome", "result_decision", "acceptance_scope", "original_task_acceptance",
      "native_completion_verdict", "required_check_evidence", "changed_files", "baseline",
      "final_observation",
    ] {
    let tampered : Work = @json.from_json(
      @json.parse(completed.to_json().stringify()),
    )
    no_change_set(tampered.receipt, key, Json::null())
    assert_false(wenyu_no_change_receipt_satisfies_contract(tampered), msg=key)
  }
}

///|
test "wenyu no change rejects invalid six check proof and contradictory answer branches" {
  let work = wenyu_fixture_reserved(wenyu_no_change_request())
  for
    boundary in [
      "missing-ui", "failed-ui", "stale-ui", "wrong-command", "wrong-tool", "wrong-cwd",
      "no-run", "no-approval", "no-digest", "no-cleanup", "duplicate-ref", "unknown-ref",
      "event-count", "duplicate-event", "out-of-order", "checkpoint", "finish", "empty-observation",
      "wrong-milestone", "implemented-answer", "source", "head", "index", "mode",
    ] {
    let receipt = wenyu_no_change_native_receipt(work)
    let events = wenyu_no_change_events(work)
    let journal = rows(events, "events")
    let ui = field(field(journal[5], "tool_result"), "metadata")
    let verdict = field(field(receipt, "execution"), "completion_verdict")
    let proposal = field(verdict, "no_change")
    let snapshot = wenyu_fixture_snapshot(work.request)
    match boundary {
      "missing-ui" => ignore(journal.remove(5))
      "failed-ui" => no_change_set(ui, "exit_code", (1).to_json())
      "stale-ui" =>
        journal.insert(
          7,
          fixture_event(
            work,
            "failed-later",
            "read",
            {},
            ok=false,
            sequence="7",
          ),
        )
      "wrong-command" =>
        no_change_set(ui, "cmd", "moon check --no-render".to_json())
      "wrong-tool" => no_change_set(journal[5], "tool", "moon_cmd".to_json())
      "wrong-cwd" => no_change_set(ui, "cwd", "/other".to_json())
      "no-run" => no_change_set(ui, "run_id", "".to_json())
      "no-approval" => no_change_set(ui, "approval_id", "".to_json())
      "no-digest" =>
        no_change_set(
          field(ui, "sandbox_evidence"),
          "command_digest",
          "".to_json(),
        )
      "no-cleanup" =>
        no_change_set(
          field(ui, "sandbox_evidence"),
          "cleanup_verified",
          false.to_json(),
        )
      "duplicate-ref" =>
        rows(proposal, "evidence_refs").push("check-5".to_json())
      "unknown-ref" => rows(proposal, "evidence_refs").push("unknown".to_json())
      "event-count" => no_change_set(events, "event_count", (20).to_json())
      "duplicate-event" => no_change_set(journal[5], "id", "check-4".to_json())
      "out-of-order" =>
        no_change_set(journal[5], "journal_sequence", "1".to_json())
      "checkpoint" =>
        no_change_set(
          field(field(journal[7], "tool_result"), "metadata"),
          "all_done",
          false.to_json(),
        )
      "finish" =>
        no_change_set(
          field(field(journal[8], "tool_result"), "metadata"),
          "completion_outcome",
          "mutation".to_json(),
        )
      "empty-observation" =>
        no_change_set(proposal, "observation", " ".to_json())
      "wrong-milestone" =>
        no_change_set(
          rows(
            field(
              field(field(journal[7], "tool_result"), "metadata"),
              "checkpoint",
            ),
            "milestones",
          )[1],
          "id",
          "build".to_json(),
        )
      "implemented-answer" =>
        no_change_set(
          field(
            field(
              rows(field(receipt, "execution"), "tool_results")[0],
              "result",
            ),
            "metadata",
          ),
          "answer",
          wenyu_fixture_answer(work).stringify().to_json(),
        )
      "source" =>
        no_change_set(snapshot, "source_digest", "different".to_json())
      "head" => no_change_set(snapshot, "head", "different".to_json())
      "index" => no_change_set(snapshot, "index_digest", "different".to_json())
      _ =>
        no_change_set(
          field(snapshot, "executable"),
          "source.mbt",
          true.to_json(),
        )
    }
    if ["missing-ui", "stale-ui"].contains(boundary) {
      no_change_set(events, "event_count", journal.length().to_json())
      for index, event in journal {
        no_change_set(
          event,
          "journal_sequence",
          (index + 1).to_string().to_json(),
        )
      }
    }
    assert_true(
      reconcile_repair_evidence(work, receipt, events, snapshot, 0, 5UL).state !=
      "completed",
      msg=boundary,
    )
  }
  let mutated_events = wenyu_no_change_events(work)
  let journal = rows(mutated_events, "events")
  journal.insert(
    0,
    fixture_event(work, "write-before", "write", {
      "path": "source.mbt",
      "changed": true,
      "before_fingerprint": native_fingerprint(b"before\n"),
      "after_fingerprint": native_fingerprint(b"after\n"),
    }),
  )
  for index, event in journal {
    no_change_set(event, "journal_sequence", (index + 1).to_string().to_json())
  }
  no_change_set(mutated_events, "event_count", journal.length().to_json())
  let mutated = reconcile_repair_evidence(
    work,
    wenyu_no_change_native_receipt(work),
    mutated_events,
    wenyu_fixture_snapshot(work.request, after=true),
    0,
    5UL,
  )
  assert_eq(mutated.blocked_reason, "native_no_change_source_changed")
  let ordinary = fixture_receipt(
    work,
    answer=wenyu_fixture_answer(work).stringify(),
  )
  let checks = rows(mutated_events, "events")[:7].to_array()
  let mutation = reconcile_repair_evidence(
    work,
    ordinary,
    { "event_count": checks.length(), "events": checks },
    wenyu_fixture_snapshot(work.request, after=true),
    0,
    5UL,
  )
  // The prefix above intentionally omits the final diff check: opt-in cannot
  // weaken the ordinary mutation branch either.
  assert_true(mutation.state != "completed")
  let full = rows(mutated_events, "events")[:8].to_array()
  let mutation = reconcile_repair_evidence(
    work,
    ordinary,
    { "event_count": full.length(), "events": full },
    wenyu_fixture_snapshot(work.request, after=true),
    0,
    5UL,
  )
  assert_eq(mutation.state, "completed")
  assert_eq(
    text(mutation.receipt, "contract"),
    "wenyu.build.native_patch_receipt.v1",
  )
  assert_eq(text(mutation.receipt, "result_decision"), "implemented")
  assert_true(wenyu_mutation_receipt_satisfies_contract(mutation))
  let attempts = rows(
    field(field(mutation.receipt, "native_receipt"), "execution"),
    "tool_results",
  )
  attempts.insert(0, {
    "tool": "finish",
    "accepted": false,
    "result": {
      "is_error": true,
      "metadata": {
        "completion_outcome": "no_change",
        "no_change": wenyu_no_change_proposal(),
      },
    },
  })
  attempts.insert(0, {
    "tool": "finish",
    "accepted": true,
    "result": {
      "is_error": false,
      "metadata": {
        "answer": "Earlier horizon-rejected proposal",
        "completion_outcome": "no_change",
        "no_change": wenyu_no_change_proposal(),
      },
    },
  })
  assert_true(wenyu_mutation_receipt_satisfies_contract(mutation))
  no_change_set(mutation.receipt, "result_decision", "no_change".to_json())
  assert_false(wenyu_mutation_receipt_satisfies_contract(mutation))
}
