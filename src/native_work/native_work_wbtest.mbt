///|
async fn fixture_request() -> Request {
  let root = @fsx.mkdtemp("/tmp/town-native-work-XXXXXX")
  let owner = root + "/owner"
  let book = root + "/imported-book"
  let source = root + "/repository"
  for dir in [owner, book, source] {
    @fs.mkdir(dir)
  }
  @support.write_text_file(source + "/moon.mod", "name = \"vectie/moontown\"\n")
  @support.write_text_file(source + "/source.mbt", "before\n")
  @support.write_text_file(source + "/notes.txt", "original notes\n")
  ignore(@integration.run_checked("git", ["-C", source, "init", "-q"]))
  ignore(@integration.run_checked("git", ["-C", source, "add", "."]))
  ignore(
    @integration.run_checked("git", [
      "-C", source, "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
      "commit", "-qm", "baseline",
    ]),
  )
  let catalog = root + "/catalog.json"
  @moonbook.save_catalog_file(catalog, [
    @moonbook.BookCatalogEntry::new(
      id="plan",
      name="Plan",
      purpose="plan",
      workspace_root=book,
      tags=["planbook"],
    ),
  ])
  let binding = source_binding(Some(source)).unwrap()
  let prompt = "Implement one repair, no commit or push"
  {
    kind: "planbook_repair",
    work_key: "planbook_repair:plan:test",
    generation: 0,
    owner_workspace: owner,
    book_id: "plan",
    book_root: book,
    book_type: "planbook",
    catalog_path: catalog,
    execution_root: source,
    source_binding: binding,
    criterion_id: "test",
    model_request: "",
    prompt,
    input_blocker: "",
    input_digest: digest(prompt),
    output_contract: "planbook.repair.native_patch_receipt.v1",
    result_path: book + "/raw/repair/repair-result.md",
    acceptance_policy: {
      "commit_requirement": "not_requested",
      "required_validation_commands": ["moon check --no-render"],
    },
    created_at_ms: 1UL,
  }
}

///|
fn fixture_client(
  request : Request,
  handler : async (String, String, String) -> Result[Json, String],
) -> @native_code_control.Client {
  @native_code_control.Client::new(
    owner_workspace=request.owner_workspace,
    instance_id="fixture-instance",
    config_path="/fixture/control/execution-sandbox/moonclaw.json",
    request=handler,
  )
}

///|
async fn fixture_configured_client(
  request : Request,
  handler : async (String, String, String) -> Result[Json, String],
) -> @native_code_control.Client {
  let path = request.owner_workspace +
    "/app/control/execution-sandbox/moonclaw.json"
  let instance = "0123456789abcdef0123456789abcdef"
  let token = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  @support.write_text_file(
    path,
    (
      {
        "protocol_version": 1,
        "instance_id": instance,
        "auth_token": token,
        "workspace_id": "fixture",
        "workspace_root": request.owner_workspace,
      } : Json).stringify(),
  )
  @support.write_text_file(
    @moonsuite.product_artifact_for_workspace_root(
      request.owner_workspace,
      "moonclaw",
      "daemon.json",
    ),
    "{\"port\":43123}",
  )
  @native_code_control.load(path~, owner_workspace=request.owner_workspace, exchange=async fn(
    method,
    uri,
    body,
    headers,
  ) {
    assert_true(uri.has_prefix("http://127.0.0.1:43123/v1/"))
    assert_eq(headers["X-MoonClaw-Execution-Token"], token)
    let route = uri["http://127.0.0.1:43123".length():].to_owned()
    match handler(method, route, body) {
      Ok(result) =>
        (if method == "POST" { 202 } else { 200 }, instance, result.stringify())
      Err(reason) if reason == "native_not_found" => (404, instance, "{}")
      Err(reason) => fail(reason)
    }
  }).unwrap()
}

///|
fn fixture_event(
  work : Work,
  id : String,
  tool : String,
  metadata : Json,
  ok? : Bool = true,
  sequence? : String = "1",
) -> Json {
  let reservation = work.reservation.unwrap()
  {
    "id": id,
    "journal_sequence": sequence,
    "source": "moonclaw-native-tool-exec",
    "protocol": "mooncode.v1",
    "session_id": reservation.session_id,
    "command_id": reservation.command_id,
    "book_root": reservation.execution_root,
    "tool": tool,
    "tool_result": {
      "tool": tool,
      "ok": ok,
      "is_error": !ok,
      "metadata": metadata,
    },
  }
}

///|
fn fixture_validation(work : Work, id : String, ok? : Bool = true) -> Json {
  fixture_event(
    work,
    id,
    "shell",
    {
      "cmd": "moon check --no-render",
      "cwd": ".",
      "exit_code": if ok {
        0
      } else {
        1
      },
      "run_id": "fort-run",
      "approval_id": "fort-approval",
      "execution_sandbox_policy": "grant-bound",
      "sandbox_evidence": {
        "command_digest": "command-hash",
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
    },
    ok~,
    sequence=if id.has_suffix("3") { "3" } else { "2" },
  )
}

///|
fn fixture_receipt(
  work : Work,
  answer? : String = "repair_decision: accepted\nApplied source fix",
) -> Json {
  let reservation = work.reservation.unwrap()
  {
    "status": "runtime-completed",
    "journal_sequence": "100",
    "owner": "moonclaw",
    "session_id": reservation.session_id,
    "command_id": reservation.command_id,
    "book_root": reservation.execution_root,
    "execution": {
      "tool_results": [
        {
          "tool": "finish",
          "accepted": true,
          "result": { "is_error": false, "metadata": { "answer": answer } },
        },
      ],
    },
  }
}

///|
async fn fixture_reserved(request : Request) -> Work {
  let work = enqueue(request, path=request.owner_workspace + "/work.json")
  let client = fixture_client(request, async fn(_, _, _) { Err("not-used") })
  reserve(
    { ..work, baseline: source_snapshot(request.execution_root), },
    client,
    "moongate/one",
    2UL,
  )
}

///|
async test "native queue is durable and freezes three roots model and exact retry bytes" {
  let request = fixture_request()
  let path = request.owner_workspace + "/state.json"
  let work = enqueue(request, path~)
  let same = enqueue(
    { ..request, model_request: "moongate/later", execution_root: "/later", },
    path~,
  )
  assert_eq(work.id, same.id)
  assert_eq(load(path~).work.length(), 1)
  let calls : Array[String] = []
  let posted : Array[String] = []
  let client = fixture_client(request, async fn(method, route, body) {
    calls.push(method + " " + route)
    if route == "/v1/code/capabilities" {
      return Ok({ "model_workspace_contract": "mooncode.model-workspace.v1" })
    }
    if route == "/v1/moongate-route" {
      return Ok({
        "contract": "moonclaw.moongate-route.v1",
        "ready": true,
        "default_model": "moongate/one",
        "models": [{ "name": "moongate/one" }],
      })
    }
    if method == "GET" {
      return Err("native_not_found")
    }
    posted.push(body)
    Err("runtime_unavailable")
  })
  let first = sync(work.id, 3UL, path~, client~)
  assert_eq(first.state, "dispatch_uncertain")
  assert_true(first.reservation is Some(_))
  let second = sync(work.id, 40000UL, path~, client~)
  assert_eq(second.reservation.unwrap().model, "moongate/one")
  assert_eq(posted.length(), 2)
  assert_eq(posted[0], posted[1])
  assert_eq(calls.filter(call => call.contains("moongate-route")).length(), 1)
  let body = @json.parse(posted[0])
  assert_eq(text(body, "book_root"), request.execution_root)
  assert_eq(text(body, "model_workspace"), request.owner_workspace)
  assert_true(
    request.book_root != request.execution_root &&
    request.book_root != request.owner_workspace,
  )
  assert_eq(text(field(body, "payload"), "task_intent"), "workspace_change")
  assert_true(
    rows(field(body, "payload"), "planner_allowed_tools").contains(
      "checkpoint".to_json(),
    ),
  )
  assert_false(posted[0].contains("codex"))
}

///|
async test "native pending capability and explicit source absence never choose ACP or cwd" {
  assert_true(
    source_binding(None) is Err(reason) &&
    reason.has_prefix("source_workspace_unconfigured"),
  )
  let request = fixture_request()
  let request = {
    ..request,
    kind: "book_quality_review",
    execution_root: request.book_root,
  }
  let path = request.owner_workspace + "/pending.json"
  let work = enqueue(request, path~)
  let calls : Array[String] = []
  let client = fixture_client(request, async fn(method, path, _) {
    calls.push(method + " " + path)
    Ok({ "model_workspace_contract": "mooncode.model-workspace.v1" })
  })
  let pending = sync(work.id, 2UL, path~, client~)
  assert_eq(pending.blocked_reason, "read_only_execution_unavailable")
  assert_true(pending.reservation is None)
  ignore(sync(work.id, 3UL, path~, client~))
  assert_eq(calls.length(), 1)
  assert_eq(load(path~).work.length(), 1)
  assert_false(@fs.exists(request.book_root + "/moonclaw.jobs.json"))
}

///|
async test "native repair accepts real final files and event proof without commit preserving unrelated index" {
  let request = fixture_request()
  @support.write_text_file(
    request.execution_root + "/notes.txt",
    "preexisting staged note\n",
  )
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
    "preexisting untracked\n",
  )
  let work = fixture_reserved(request)
  let scopes = clean_source_scopes(work.baseline)
  assert_false(scopes.contains("notes.txt"))
  assert_false(scopes.contains("private.txt"))
  assert_true(scopes.contains("source.mbt"))
  @support.write_text_file(request.execution_root + "/source.mbt", "after\n")
  let mutation = fixture_event(work, "write-1", "write", {
    "path": "source.mbt",
    "changed": true,
    "before_fingerprint": native_fingerprint(b"before\n"),
    "after_fingerprint": native_fingerprint(b"after\n"),
  })
  let events : Json = {
    "event_count": 2,
    "events": [mutation, fixture_validation(work, "check-2")],
  }
  let final_snapshot = source_snapshot(request.execution_root)
  let accepted = reconcile_repair_evidence(
    work,
    fixture_receipt(work),
    events,
    final_snapshot,
    0,
    5UL,
  )
  assert_eq(accepted.state, "completed")
  assert_eq(
    text(accepted.receipt, "engineering_status"),
    "applied_and_validated",
  )
  assert_eq(text(accepted.receipt, "commit_status"), "not_requested")
  assert_eq(field(accepted.receipt, "commit_sha"), Json::null())
  assert_eq(rows(accepted.receipt, "changed_files").length(), 1)
  assert_eq(
    text(work.baseline, "index_digest"),
    text(final_snapshot, "index_digest"),
  )
  assert_eq(
    @fs.read_file(request.execution_root + "/notes.txt").text(),
    "preexisting staged note\n",
  )
  ignore(apply_owner_result(accepted))
  assert_true(
    @fs.read_file(request.result_path)
    .text()
    .contains("Applied and validated; uncommitted"),
  )
  let missing = reconcile_repair_evidence(
    work,
    fixture_receipt(work),
    { "event_count": 1, "events": [mutation] },
    final_snapshot,
    0,
    5UL,
  )
  assert_true(
    missing.blocked_reason.has_prefix(
      "native_required_validation_missing_or_failed",
    ),
  )
  let failed = reconcile_repair_evidence(
    work,
    fixture_receipt(work),
    {
      "event_count": 3,
      "events": [
        mutation,
        fixture_validation(work, "check-2"),
        fixture_validation(work, "check-3", ok=false),
      ],
    },
    final_snapshot,
    0,
    5UL,
  )
  assert_true(
    failed.blocked_reason.has_prefix(
      "native_required_validation_missing_or_failed",
    ),
  )
  @support.write_text_file(
    request.execution_root + "/source.mbt",
    "unexpected after receipt\n",
  )
  let mismatch = reconcile_repair_evidence(
    work,
    fixture_receipt(work),
    events,
    source_snapshot(request.execution_root),
    0,
    6UL,
  )
  assert_true(mismatch.blocked_reason.contains("mismatch"))
}

///|
async test "native repair no change is honest and prior commit requirement remains blocked" {
  let request = fixture_request()
  let work = fixture_reserved(request)
  let result = reconcile_repair_evidence(
    work,
    fixture_receipt(
      work,
      answer="repair_decision: no_change\nAlready satisfied",
    ),
    { "event_count": 0, "events": [] },
    work.baseline,
    0,
    4UL,
  )
  assert_eq(result.state, "waiting_result")
  assert_eq(result.blocked_reason, "native_no_change_settlement_unsupported")
  let committed = {
    ..request,
    work_key: "required-commit",
    acceptance_policy: {
      "commit_requirement": "required",
      "required_validation_commands": ["moon check --no-render"],
    },
  }
  let path = request.owner_workspace + "/commit.json"
  let work = enqueue(committed, path~)
  let calls : Array[String] = []
  let client = fixture_client(request, async fn(method, _, _) {
    calls.push(method)
    Err("must-not-call")
  })
  let pending = sync(work.id, 2UL, path~, client~)
  assert_eq(pending.state, "blocked_commit_capability")
  assert_eq(calls.length(), 0)
  assert_eq(
    text(pending.request.acceptance_policy, "commit_requirement"),
    "required",
  )
}
