///|
#warnings("-reserved_keyword-unused_async")
async test "native no change negotiates before reservation and preserves exact bytes through retry and restart" {
  let request = no_change_fixture_request(fixture_request())
  let path = request.owner_workspace + "/retry.json"
  let queued = enqueue(request, path~)
  let calls : Array[String] = []
  let missing = fixture_client(request, async fn(method_val, route, _) {
    calls.push(method_val + " " + route)
    Ok({ "model_workspace_contract": "mooncode.model-workspace.v1" })
  })
  let blocked = sync(queued.id, 2UL, path~, client=missing)
  assert_eq(blocked.blocked_reason, "completion_outcome_unavailable")
  assert_true(blocked.reservation is None)
  assert_eq(calls.length(), 1)
  let submitted : Array[String] = []
  let capability_calls : Array[String] = []
  let capable = fixture_client(request, async fn(method_val, route, body) {
    if route == "/v1/code/capabilities" {
      capability_calls.push(route)
      return Ok({
        "model_workspace_contract": "mooncode.model-workspace.v1",
        "completion_outcome_contract": "mooncode.completion-outcome.v1",
      })
    }
    if route == "/v1/moongate-route" {
      return Ok({
        "contract": "moonclaw.moongate-route.v1",
        "ready": true,
        "default_model": "moongate/one",
        "models": [{ "name": "moongate/one" }],
      })
    }
    if method_val == "GET" {
      return Err("native_not_found")
    }
    submitted.push(body)
    Err("runtime_unavailable")
  })
  let first = sync(queued.id, 40000UL, path~, client=capable)
  let second = sync(queued.id, 80000UL, path~, client=capable)
  assert_eq(first.state, "dispatch_uncertain")
  assert_eq(
    second.reservation.unwrap().request_body,
    first.reservation.unwrap().request_body,
  )
  assert_eq(submitted.length(), 2)
  assert_eq(submitted[0], submitted[1])
  assert_eq(capability_calls.length(), 1)
  assert_eq(
    field(
      field(field(@json.parse(submitted[0]), "payload"), "task_contract"),
      "completion_policy",
    ),
    field(request.acceptance_policy, "completion_policy"),
  )
  let reloaded = load(path~).work[0]
  assert_eq(ToJson::to_json(reloaded), ToJson::to_json(second))
  assert_eq(
    enqueue(
      {
        ..request,
        acceptance_policy: Json::null(),
        model_request: "different",
      },
      path~,
    ).id,
    queued.id,
  )
  let old = fixture_reserved(fixture_request())
  let old_body = old.reservation.unwrap().request_body
  assert_false(old_body.contains("completion_policy"))
  let old_roundtrip : Work = @json.from_json(
    @json.parse(ToJson::to_json(old).stringify()),
  )
  assert_eq(old_roundtrip.reservation.unwrap().request_body, old_body)
  assert_eq(ToJson::to_json(old_roundtrip), ToJson::to_json(old))
}

///|
fn no_change_fixture_binding(work : Work) -> Json {
  {
    "protocol": "mooncode.v1",
    "owner": "moonclaw",
    "session_id": work.reservation.unwrap().session_id,
    "book_root": work.request.execution_root,
  }
}

///|
fn no_change_fixture_claim(work : Work, receipt : Json) -> Json {
  let command = @json.parse(work.reservation.unwrap().request_body) catch {
    _ => Json::null()
  }
  no_change_set(receipt, "protocol", ToJson::to_json("mooncode.v1"))
  no_change_set(receipt, "command", command)
  let claim = no_change_fixture_binding(work)
  no_change_set(
    claim,
    "delivered_commands",
    Json::array([
      {
        "command_id": work.reservation.unwrap().command_id,
        "command": command,
        "receipt": receipt,
      },
    ]),
  )
  claim
}

///|
fn no_change_fixture_bound_events(work : Work, evidence : Json) -> Json {
  let binding = no_change_fixture_binding(work)
  no_change_set(binding, "events", field(evidence, "events"))
  no_change_set(binding, "event_count", field(evidence, "event_count"))
  binding
}

///|
#warnings("-reserved_keyword-unused_async")
async test "native no change full observation survives durable settlement without redispatch patch acceptance or backlog records" {
  let work = no_change_fixture_work()
  let path = work.request.owner_workspace + "/work.json"
  let done = observe(
    work,
    no_change_fixture_claim(work, no_change_fixture_receipt(work)),
    no_change_fixture_bound_events(work, no_change_fixture_events(work)),
    no_change_fixture_binding(work),
    "fixture-instance",
    5UL,
  )
  assert_eq(done.state, "completed")
  assert_eq(field(done.receipt, "focused_diff"), Json::null())
  save_unlocked(path, replace_work(load(path~), done))
  ignore(apply_owner_result(done))
  let output = @fs.read_file(work.request.result_path).text()
  assert_true(output.contains("No net source change; required checks passed"))
  assert_true(output.contains("original_task_acceptance: unevaluated"))
  assert_false(output.contains("repair_decision: accepted"))
  assert_false(
    accepted_repair(work.request.book_root, work.request.criterion_id, path~),
  )
  let calls : Array[String] = []
  let client = fixture_client(work.request, async fn(method_val, _, _) {
    calls.push(method_val)
    Err("must-not-call")
  })
  @fs.remove(work.request.result_path)
  let repeated = sync(work.id, 40000UL, path~, client~)
  assert_eq(ToJson::to_json(repeated), ToJson::to_json(done))
  assert_true(@fs.exists(work.request.result_path))
  assert_eq(calls.length(), 0)
  let same = enqueue({ ..work.request, model_request: "later", }, path~)
  assert_eq(same.id, done.id)
  assert_eq(load(path~).work.length(), 1)
  assert_eq(@fs.readdir(work.request.book_root + "/raw", include_hidden=true), [
    "repair",
  ])
  @support.write_text_file(
    work.request.execution_root + "/source.mbt",
    "later source drift\n",
  )
  assert_false(
    accepted_repair(work.request.book_root, work.request.criterion_id, path~),
  )
  assert_eq(enqueue(work.request, path~).id, done.id)
  assert_eq(load(path~).work[0].receipt, done.receipt)
}

///|
async test "native no change failed Town validation retains worker evidence and cannot create owner success" {
  let work = no_change_fixture_work()
  let native = no_change_fixture_receipt(work)
  let events = no_change_fixture_events(work)
  no_change_set(
    field(field(rows(events, "events")[0], "tool_result"), "metadata"),
    "exit_code",
    ToJson::to_json(1),
  )
  let failed = observe(
    work,
    no_change_fixture_claim(work, native),
    no_change_fixture_bound_events(work, events),
    no_change_fixture_binding(work),
    "fixture-instance",
    5UL,
  )
  assert_eq(failed.state, "failed")
  assert_eq(text(failed.receipt, "engineering_status"), "blocked")
  assert_eq(field(failed.receipt, "native_receipt"), native)
  assert_eq(
    text(
      field(
        field(field(failed.receipt, "native_receipt"), "execution"),
        "completion_verdict",
      ),
      "completion_outcome",
    ),
    "no_change",
  )
  ignore(apply_owner_result(failed))
  assert_false(@fs.exists(work.request.result_path))
  let wrong = no_change_fixture_claim(work, no_change_fixture_receipt(work))
  no_change_set(wrong, "session_id", ToJson::to_json("other"))
  assert_eq(
    observe(
      work,
      wrong,
      no_change_fixture_bound_events(work, no_change_fixture_events(work)),
      no_change_fixture_binding(work),
      "fixture-instance",
      6UL,
    ).blocked_reason,
    "native_observation_identity_mismatch",
  )
}
