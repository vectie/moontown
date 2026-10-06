///|
/// Pure source observations keep these regressions independent of Git history,
/// runtime sockets, configured providers, and user source checkouts.
fn wenyu_fixture_request(root? : String = "/synthetic-wenyu") -> Request {
  let prompt = "Implement the frozen Wenyu code patch"
  {
    kind: "wenyu_build",
    work_key: "wenyu:book:goal:task",
    generation: 0,
    owner_workspace: root + "/owner",
    book_id: "book",
    book_root: root + "/book",
    book_type: "wenyu",
    catalog_path: root + "/catalog.json",
    execution_root: root + "/source",
    source_binding: { "root": root + "/source" },
    criterion_id: "",
    model_request: "",
    prompt,
    input_blocker: "",
    input_digest: digest(prompt),
    output_contract: "wenyu.build.native-result.v1",
    result_path: root + "/book/build/CODE_PATCH.md",
    acceptance_policy: {
      "contract": "wenyu.build.native-policy.v1",
      "task_id": "task",
      "goal_id": "goal",
      "task_kind": "code-patch",
      "commit_requirement": "not_requested",
      "required_validation_commands": ["moon check --no-render"],
      "preserve_preexisting_unrelated_dirty_files": true,
      "push_requested": false,
    },
    created_at_ms: 1UL,
  }
}

///|
fn wenyu_fixture_snapshot(request : Request, after? : Bool = false) -> Json {
  {
    "root": request.execution_root,
    "head": "synthetic-base-head",
    "index_digest": "synthetic-unchanged-index",
    "source_digest": if after {
      "after-source"
    } else {
      "before-source"
    },
    "files": {
      "source.mbt": native_fingerprint(
        if after {
          b"after\n"
        } else {
          b"before\n"
        },
      ),
      "notes.txt": native_fingerprint(b"unrelated dirty note\n"),
    },
    "executable": { "source.mbt": false, "notes.txt": false },
    "dirty_paths": ["notes.txt"],
  }
}

///|
fn wenyu_fixture_queued(request : Request) -> Work {
  let request = { ..request, generation: 1, }
  let hash = digest(request.to_json().stringify())
  {
    id: "town-work-" + hash[:32].to_owned(),
    request,
    request_digest: hash,
    state: "queued",
    blocked_reason: "",
    reservation: None,
    control: None,
    baseline: Json::null(),
    observed_instances: [],
    last_attempt_at_ms: 0UL,
    retry_after_ms: 0UL,
    output: "",
    receipt: Json::null(),
  }
}

///|
fn wenyu_fixture_reserved(request : Request) -> Work {
  let queued = wenyu_fixture_queued(request)
  reserve(
    { ..queued, baseline: wenyu_fixture_snapshot(request), },
    fixture_client(request, async fn(_, _, _) { Err("must-not-call") }),
    "moongate/exact",
    2UL,
  )
}

///|
fn wenyu_fixture_answer(work : Work) -> Json {
  {
    "contract": "wenyu.build.native-result.v1",
    "work_id": work.id,
    "book_id": work.request.book_id,
    "task_id": text(work.request.acceptance_policy, "task_id"),
    "goal_id": text(work.request.acceptance_policy, "goal_id"),
    "outcome": "implemented",
    "summary": "Implemented the requested source change",
    "behavior": "The source now has the requested behavior",
    "residual_risks": ["Product acceptance remains pending"],
  }
}

///|
fn wenyu_fixture_events(work : Work) -> Json {
  {
    "event_count": 2,
    "events": [
      fixture_event(work, "mutation-1", "write", {
        "path": "source.mbt",
        "changed": true,
        "before_fingerprint": native_fingerprint(b"before\n"),
        "after_fingerprint": native_fingerprint(b"after\n"),
      }),
      fixture_validation(work, "check-2"),
    ],
  }
}

///|
test "wenyu mutation receipt binds exact owner output and source validation evidence" {
  let work = wenyu_fixture_reserved(wenyu_fixture_request())
  let answer = wenyu_fixture_answer(work).stringify()
  let events = wenyu_fixture_events(work)
  let result = reconcile_repair_evidence(
    work,
    fixture_receipt(work, answer~),
    events,
    wenyu_fixture_snapshot(work.request, after=true),
    0,
    5UL,
  )
  assert_eq(result.state, "completed")
  assert_eq(result.output, answer)
  assert_eq(
    text(result.receipt, "contract"),
    "wenyu.build.native_patch_receipt.v1",
  )
  assert_eq(text(result.receipt, "task_id"), "task")
  assert_eq(text(result.receipt, "goal_id"), "goal")
  assert_eq(text(result.receipt, "book_id"), "book")
  assert_eq(text(result.receipt, "request_id"), work.id)
  assert_eq(text(result.receipt, "output_digest"), digest(answer))
  assert_eq(
    text(result.receipt, "native_evidence_digest"),
    digest(events.stringify()),
  )
  assert_eq(text(result.receipt, "engineering_status"), "applied_and_validated")
  assert_eq(text(result.receipt, "result_decision"), "implemented")
  assert_eq(text(result.receipt, "original_task_acceptance"), "unevaluated")
  assert_eq(text(result.receipt, "commit_status"), "not_requested")
  assert_eq(rows(result.receipt, "changed_files").length(), 1)
  assert_eq(rows(result.receipt, "validation_commands").length(), 1)
  assert_eq(field(result.receipt, "baseline"), work.baseline)
  assert_eq(
    field(result.receipt, "final_observation"),
    wenyu_fixture_snapshot(work.request, after=true),
  )
}

///|
test "wenyu reserved body keeps original task and pins generated work identity" {
  let work = wenyu_fixture_reserved(wenyu_fixture_request())
  let reservation = work.reservation.unwrap()
  let body = @json.parse(reservation.request_body)
  assert_eq(reservation.command_id, work.id + "-build")
  assert_eq(text(body, "book_root"), work.request.execution_root)
  assert_eq(text(body, "model_workspace"), work.request.owner_workspace)
  assert_true(text(body, "text").has_prefix(work.request.prompt))
  assert_true(text(body, "text").contains(work.id))
  assert_true(text(body, "text").contains("wenyu.build.native-result.v1"))
  let payload = field(body, "payload")
  assert_eq(text(payload, "task_intent"), "workspace_change")
  let contract = field(payload, "task_contract")
  assert_eq(text(contract, "owner_work_id"), work.id)
  assert_eq(text(contract, "owner_task_id"), "task")
  assert_eq(text(contract, "owner_goal_id"), "goal")
  assert_true(field(contract, "constraints").stringify().contains(work.id))
  assert_eq(rows(contract, "scope"), ["source.mbt".to_json()])
  assert_eq(field(contract, "completion_policy"), Json::null())
  assert_true(
    rows(payload, "planner_allowed_tools").contains("checkpoint".to_json()),
  )
  assert_true(
    rows(payload, "planner_allowed_tools").contains("apply_patch".to_json()),
  )
}

///|
async test "wenyu uncertain dispatch replays saved model and exact bytes without fresh selection" {
  let request = wenyu_fixture_request()
  let work = wenyu_fixture_reserved(request)
  let calls : Array[String] = []
  let bodies : Array[String] = []
  let client = fixture_client(request, async fn(method, route, body) {
    calls.push(method + " " + route)
    if method == "GET" {
      return Err("native_not_found")
    }
    bodies.push(body)
    Err("lost-response")
  })
  let state : State = {
    schema: "moontown.native-work.v1",
    revision: 1,
    work: [work],
  }
  let first = sync_with_client(work, client, 3UL, "/unused-state.json", state)
  let retried = sync_with_client(
    first, client, 40000UL, "/unused-state.json", state,
  )
  assert_eq(first.state, "dispatch_uncertain")
  assert_eq(retried.state, "dispatch_uncertain")
  assert_eq(bodies.length(), 2)
  assert_eq(bodies[0], work.reservation.unwrap().request_body)
  assert_eq(bodies[1], bodies[0])
  assert_eq(retried.reservation.unwrap().model, "moongate/exact")
  assert_false(
    calls.any(call => {
      call.contains("moongate-route") || call.contains("capabilities")
    }),
  )
}

///|
test "wenyu policy rejects permissive malformed or unsupported completion requirements" {
  for
    boundary in [
      "contract", "goal_id", "task_id", "task_kind", "commit_requirement", "preserve_preexisting_unrelated_dirty_files",
      "push_requested", "required_validation_commands",
    ] {
    let request = wenyu_fixture_request()
    no_change_set(request.acceptance_policy, boundary, Json::null())
    assert_false(wenyu_policy_valid(request), msg=boundary)
  }
  for
    commands in [
      [].to_json(),
      [" "].to_json(),
      ["moon check --no-render", "moon check --no-render"].to_json(),
      ["git push"].to_json(),
      [true].to_json(),
    ] {
    let request = wenyu_fixture_request()
    no_change_set(
      request.acceptance_policy,
      "required_validation_commands",
      commands,
    )
    assert_false(wenyu_policy_valid(request))
  }
}

///|
test "wenyu invalid output never grants a successful mutation receipt" {
  let work = wenyu_fixture_reserved(wenyu_fixture_request())
  for
    boundary in [
      "contract", "work_id", "book_id", "task_id", "goal_id", "outcome", "summary",
      "behavior", "residual_risks", "unexpected",
    ] {
    let output = wenyu_fixture_answer(work)
    no_change_set(
      output,
      boundary,
      if boundary == "behavior" {
        true.to_json()
      } else {
        "".to_json()
      },
    )
    let result = reconcile_repair_evidence(
      work,
      fixture_receipt(work, answer=output.stringify()),
      wenyu_fixture_events(work),
      wenyu_fixture_snapshot(work.request, after=true),
      0,
      5UL,
    )
    assert_eq(
      result.blocked_reason,
      "wenyu_native_output_contract_invalid",
      msg=boundary,
    )
    assert_eq(result.state, "waiting_result", msg=boundary)
    assert_eq(result.output, "", msg=boundary)
  }
  let planbook_answer = "repair_decision: accepted\nA prose success claim"
  assert_false(wenyu_result_satisfies_contract(work, planbook_answer))
}

///|
test "wenyu rejects absent failed stale or unattributed evidence and all no change claims" {
  let work = wenyu_fixture_reserved(wenyu_fixture_request())
  let receipt = fixture_receipt(
    work,
    answer=wenyu_fixture_answer(work).stringify(),
  )
  for
    boundary in [
      "missing-check", "failed-check", "stale-check", "unattributed", "head", "index",
      "dirty", "diff", "no-change",
    ] {
    let events = wenyu_fixture_events(work)
    let snapshot = wenyu_fixture_snapshot(work.request, after=true)
    let journal = rows(events, "events")
    match boundary {
      "missing-check" => {
        journal.pop() |> ignore
        no_change_set(events, "event_count", (1).to_json())
      }
      "failed-check" =>
        journal[1] = fixture_validation(work, "check-2", ok=false)
      "stale-check" => {
        let mutation = journal[0]
        let check = journal[1]
        journal[0] = check
        journal[1] = mutation
        no_change_set(check, "journal_sequence", "1".to_json())
        no_change_set(mutation, "journal_sequence", "2".to_json())
      }
      "unattributed" => {
        journal.remove(0) |> ignore
        no_change_set(events, "event_count", (1).to_json())
      }
      "head" => no_change_set(snapshot, "head", "changed-head".to_json())
      "index" =>
        no_change_set(snapshot, "index_digest", "changed-index".to_json())
      "dirty" =>
        no_change_set(
          field(snapshot, "files"),
          "notes.txt",
          native_fingerprint(b"touched").to_json(),
        )
      "no-change" => {
        no_change_set(snapshot, "files", field(work.baseline, "files"))
        no_change_set(
          snapshot,
          "source_digest",
          field(work.baseline, "source_digest"),
        )
        journal.remove(0) |> ignore
        no_change_set(events, "event_count", (1).to_json())
      }
      _ => ()
    }
    let result = reconcile_repair_evidence(
      work,
      receipt,
      events,
      snapshot,
      if boundary == "diff" {
        1
      } else {
        0
      },
      5UL,
    )
    assert_true(result.state != "completed", msg=boundary)
    assert_eq(result.output, "", msg=boundary)
  }
  let opted_in = wenyu_fixture_request()
  no_change_set(
    opted_in.acceptance_policy,
    "completion_policy",
    no_change_fixture_policy(),
  )
  assert_false(wenyu_policy_valid(opted_in))
}

///|
async test "wenyu queue deduplicates exact key and preserves separate goals tasks and generations" {
  let root = @fs.realpath(@fsx.mkdtemp("/tmp/town-wenyu-queue-XXXXXX"))
  let request = wenyu_fixture_request(root~)
  let path = root + "/state.json"
  let first = enqueue(request, path~)
  let retry = enqueue({ ..request, model_request: "moongate/later", }, path~)
  assert_eq(first.id, retry.id)
  let second = enqueue(
    { ..request, work_key: "wenyu:book:goal:other-task", },
    path~,
  )
  let next_goal = enqueue(
    { ..request, work_key: "wenyu:book:new-goal:task", },
    path~,
  )
  assert_true(first.id != second.id)
  assert_true(first.id != next_goal.id)
  assert_eq(load(path~).work.length(), 3)
  assert_eq(second.state, "queued")
  assert_true(second.reservation is None)
  ignore(supersede(first.id, load(path~).revision, path~))
  let replacement = enqueue(request, path~)
  assert_eq(replacement.request.generation, 2)
  assert_true(replacement.id != first.id)
  assert_eq(enqueue(request, path~).id, replacement.id)
  assert_eq(load(path~).work.length(), 4)
  assert_eq(enqueue({ ..request, generation: 1, }, path~).id, first.id)
  assert_eq(enqueue({ ..request, generation: 2, }, path~).id, replacement.id)
  assert_eq(load(path~).work.length(), 4)
}

///|
async test "wenyu unreserved cancellation records no native execution and never imports a Book" {
  let root = @fs.realpath(@fsx.mkdtemp("/tmp/town-wenyu-cancel-XXXXXX"))
  let request = wenyu_fixture_request(root~)
  let path = root + "/state.json"
  let queued = enqueue(request, path~)
  let cancelled = cancel(queued.id, load(path~).revision, 3UL, path~)
  assert_eq(cancelled.state, "cancelled")
  assert_eq(text(cancelled.receipt, "engineering_status"), "not_started")
  assert_eq(text(cancelled.receipt, "reservation_status"), "not_reserved")
  assert_eq(text(cancelled.receipt, "task_id"), "task")
  assert_eq(field(cancelled.receipt, "native_receipt"), Json::null())
  assert_false(@fs.exists(request.book_root))
}

///|
async test "wenyu and PlanBook reserve one shared source at a time even when dispatch is uncertain" {
  let request = wenyu_fixture_request()
  let pending = wenyu_fixture_queued(request)
  let calls : Array[String] = []
  let client = fixture_client(request, async fn(method, route, _) {
    calls.push(method + " " + route)
    Err("must-not-call")
  })
  for kind in ["wenyu_build", "planbook_repair"] {
    let active = wenyu_fixture_reserved({ ..request, kind, work_key: "active", })
    for
      status in [
        "queued", "running", "awaiting_approval", "dispatch_uncertain", "waiting_result",
        "cancelling",
      ] {
      let state : State = {
        schema: "moontown.native-work.v1",
        revision: 2,
        work: [pending, { ..active, state: status, }],
      }
      let result = sync_with_client(
        pending, client, 3UL, "/unused-state.json", state,
      )
      assert_eq(result.state, "queued", msg=kind + ":" + status)
      assert_eq(result.blocked_reason, "source_workspace_busy: " + active.id)
      assert_true(result.reservation is None)
      assert_eq(result.baseline, Json::null())
      assert_eq(calls.length(), 0)
    }
    for status in ["completed", "failed", "cancelled", "superseded"] {
      assert_eq(
        workspace_reservation_blocker(
          {
            schema: "moontown.native-work.v1",
            revision: 2,
            work: [pending, { ..active, state: status, }],
          },
          pending,
        ),
        "",
      )
    }
    let different = {
      ..active,
      request: { ..active.request, execution_root: "/different-source", },
    }
    assert_eq(
      workspace_reservation_blocker(
        { schema: "moontown.native-work.v1", revision: 2, work: [different], },
        pending,
      ),
      "",
    )
  }
}

///|
test "wenyu failure receipt preserves partial source and raw failed evidence without success" {
  let work = wenyu_fixture_reserved(wenyu_fixture_request())
  let native = fixture_receipt(work, answer="not valid output")
  let events = wenyu_fixture_events(work)
  let snapshot = wenyu_fixture_snapshot(work.request, after=true)
  let receipt = wenyu_failure_receipt(
    work, native, events, snapshot, "wenyu_native_output_contract_invalid",
  )
  assert_eq(text(receipt, "contract"), "wenyu.build.native_patch_receipt.v1")
  assert_eq(text(receipt, "task_id"), "task")
  assert_eq(text(receipt, "goal_id"), "goal")
  assert_eq(text(receipt, "engineering_status"), "applied_validation_failed")
  assert_eq(field(receipt, "native_receipt"), native)
  assert_eq(field(receipt, "native_events"), events)
  assert_eq(field(receipt, "final_observation"), snapshot)
  assert_eq(field(receipt, "validation_commands"), Json::null())
  assert_eq(
    text(
      wenyu_failure_receipt(work, native, events, Json::null(), "unavailable"),
      "engineering_status",
    ),
    "source_unverified",
  )
}

///|
async test "wenyu completed result cannot write a PlanBook owner result" {
  let root = @fs.realpath(@fsx.mkdtemp("/tmp/town-wenyu-owner-result-XXXXXX"))
  let work = wenyu_fixture_reserved(wenyu_fixture_request(root~))
  let completed = reconcile_repair_evidence(
    work,
    fixture_receipt(work, answer=wenyu_fixture_answer(work).stringify()),
    wenyu_fixture_events(work),
    wenyu_fixture_snapshot(work.request, after=true),
    0,
    5UL,
  )
  ignore(apply_owner_result(completed))
  assert_false(@fs.exists(work.request.result_path))
  assert_false(@fs.exists(work.request.book_root))
  assert_eq(
    verify_final_source_freshness(completed, 6UL).blocked_reason,
    "native_source_changed_during_reconciliation",
  )
}

///|
test "wenyu extension keeps legacy PlanBook mutation and no change semantics" {
  let base = wenyu_fixture_request()
  let request = {
    ..base,
    kind: "planbook_repair",
    output_contract: "planbook.repair.native_patch_receipt.v1",
    acceptance_policy: {
      "commit_requirement": "not_requested",
      "required_validation_commands": ["moon check --no-render"],
    },
  }
  let work = wenyu_fixture_reserved(request)
  let body = @json.parse(work.reservation.unwrap().request_body)
  assert_eq(text(body, "text"), request.prompt)
  assert_eq(
    field(field(field(body, "payload"), "task_contract"), "owner_work_id"),
    Json::null(),
  )
  let mutation = reconcile_repair_evidence(
    work,
    fixture_receipt(work),
    wenyu_fixture_events(work),
    wenyu_fixture_snapshot(request, after=true),
    0,
    5UL,
  )
  assert_eq(mutation.state, "completed")
  assert_eq(
    text(mutation.receipt, "contract"),
    "planbook.repair.native_patch_receipt.v1",
  )
  assert_eq(field(mutation.receipt, "task_id"), Json::null())
  let no_change = wenyu_fixture_reserved(no_change_fixture_request(request))
  let result = reconcile_repair_evidence(
    no_change,
    no_change_fixture_receipt(no_change),
    no_change_fixture_events(no_change),
    no_change.baseline,
    0,
    5UL,
  )
  assert_eq(result.state, "completed")
  assert_eq(
    text(result.receipt, "contract"),
    "planbook.repair.native_no_change_receipt.v1",
  )
  assert_eq(text(result.receipt, "engineering_status"), "no_change")
  assert_false(is_workspace_change("book_quality_review"))
}
