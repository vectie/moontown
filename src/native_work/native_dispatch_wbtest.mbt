///|
async test "native owner sync executes injected configured route and reconciles exact receipt into Book" {
  let request = fixture_request()
  let path = request.owner_workspace + "/end-to-end.json"
  let queued = enqueue(request, path~)
  let submitted : Array[String] = []
  let native_events : Array[Json] = []
  let phase : Array[Int] = [0]
  let client = fixture_configured_client(request, async fn(
    method,
    route,
    body,
  ) {
    if route == "/v1/code/capabilities" {
      return Ok({ "model_workspace_contract": "mooncode.model-workspace.v1" })
    }
    if route == "/v1/moongate-route" {
      return Ok({
        "contract": "moonclaw.moongate-route.v1",
        "ready": true,
        "default_model": "moongate/exact",
        "models": [{ "name": "moongate/exact" }],
      })
    }
    if method == "POST" {
      submitted.push(body)
      let command = @json.parse(body)
      phase[0] = 1
      return Ok({
        "accepted": true,
        "session_id": text(command, "session_id"),
        "command_id": text(field(command, "packet"), "command_id"),
        "book_root": text(command, "book_root"),
      })
    }
    if phase[0] == 0 {
      return Err("native_not_found")
    }
    let command = @json.parse(submitted[0])
    let base : Json = {
      "protocol": "mooncode.v1",
      "owner": "moonclaw",
      "session_id": text(command, "session_id"),
      "book_root": request.execution_root,
    }
    guard base is Object(fields) else { abort("object") }
    if route.contains("runtime-claim") {
      fields["delivered_commands"] = [
        {
          "command_id": text(field(command, "packet"), "command_id"),
          "command": command,
          "receipt": {
            "protocol": "mooncode.v1",
            "journal_sequence": "100",
            "owner": "moonclaw",
            "session_id": text(command, "session_id"),
            "command_id": text(field(command, "packet"), "command_id"),
            "book_root": request.execution_root,
            "status": "runtime-completed",
            "command": command,
            "execution": {
              "tool_results": [
                {
                  "tool": "finish",
                  "accepted": true,
                  "result": {
                    "is_error": false,
                    "metadata": {
                      "answer": "repair_decision: accepted\nImplemented source repair",
                    },
                  },
                },
              ],
            },
          },
        },
      ]
    } else if route.contains("runtime-events") {
      fields["event_count"] = native_events.length().to_json()
      fields["events"] = native_events.to_json()
    }
    Ok(Json::object(fields))
  })
  let running = sync(queued.id, 2UL, path~, client~)
  assert_eq(running.state, "running")
  @support.write_text_file(request.execution_root + "/source.mbt", "after\n")
  native_events.push(
    fixture_event(running, "mutation", "write", {
      "path": "source.mbt",
      "before_fingerprint": native_fingerprint(b"before\n"),
      "after_fingerprint": native_fingerprint(b"after\n"),
      "changed": true,
    }),
  )
  native_events.push(fixture_validation(running, "validation"))
  let done = sync(queued.id, 40000UL, path~, client~)
  assert_eq(done.state, "completed")
  assert_eq(submitted.length(), 1)
  assert_true(text(done.receipt, "focused_diff").contains("+after"))
  assert_true(@fs.exists(request.result_path + ".native-receipt.json"))
  assert_true(accepted_repair(request.book_root, request.criterion_id, path~))
  // A crash between durable receipt and result application is repairable by
  // syncing that same completed work, without re-dispatch or new generations.
  @fs.remove(request.result_path)
  ignore(sync(queued.id, 80000UL, path~, client~))
  assert_true(@fs.exists(request.result_path))
  assert_eq(submitted.length(), 1)
  assert_eq(load(path~).work.length(), 1)
}

///|
async test "native dispatch rejects stale roots exact-body conflicts and missing continuity" {
  let request = fixture_request()
  let work = fixture_reserved(request)
  let reservation = work.reservation.unwrap()
  let body = @json.parse(reservation.request_body)
  let base : Json = {
    "protocol": "mooncode.v1",
    "owner": "moonclaw",
    "session_id": reservation.session_id,
    "book_root": reservation.execution_root,
  }
  let claim : Json = {
    "protocol": "mooncode.v1",
    "owner": "moonclaw",
    "session_id": reservation.session_id,
    "book_root": reservation.execution_root,
    "claimed_commands": [
      {
        "command_id": reservation.command_id,
        "command": { "model": "moongate/later" },
        "receipt": null,
      },
    ],
  }
  let conflict = observe(work, claim, base, base, "fixture-instance", 4UL)
  assert_eq(conflict.blocked_reason, "native_command_body_mismatch")
  let missing = observe(work, base, base, base, "new-instance", 4UL)
  assert_eq(missing.blocked_reason, "runtime_continuity_unverified")
  let wrong : Json = {
    "protocol": "mooncode.v1",
    "owner": "moonclaw",
    "session_id": reservation.session_id,
    "book_root": request.book_root,
  }
  assert_eq(
    observe(work, base, wrong, base, "fixture-instance", 4UL).blocked_reason,
    "native_observation_identity_mismatch",
  )
  let approval : Json = {
    "protocol": "mooncode.v1",
    "owner": "moonclaw",
    "session_id": reservation.session_id,
    "book_root": reservation.execution_root,
    "events": [
      {
        "session_id": reservation.session_id,
        "command_id": reservation.command_id,
        "state": "awaiting-approval",
      },
    ],
  }
  let correct : Json = {
    "protocol": "mooncode.v1",
    "owner": "moonclaw",
    "session_id": reservation.session_id,
    "book_root": reservation.execution_root,
    "claimed_commands": [
      { "command_id": reservation.command_id, "command": body, "receipt": null },
    ],
  }
  assert_eq(
    observe(work, correct, approval, base, "fixture-instance", 4UL).state,
    "awaiting_approval",
  )
  @support.write_text_file(
    request.execution_root + "/moon.mod",
    "name = \"another/project\"\n",
  )
  assert_false(source_still_bound(request.source_binding))
}

///|
async test "pending source correction uses explicit supersession and does not silently retarget" {
  let request = fixture_request()
  let path = request.owner_workspace + "/supersede.json"
  let missing = {
    ..request,
    execution_root: "",
    source_binding: Json::null(),
    input_blocker: "source_workspace_unconfigured",
  }
  let first = enqueue(missing, path~)
  let retried = enqueue(request, path~)
  assert_eq(retried.id, first.id)
  assert_eq(retried.request.execution_root, "")
  ignore(supersede(first.id, load(path~).revision, path~))
  let replacement = enqueue(request, path~)
  assert_true(replacement.id != first.id)
  assert_eq(replacement.request.generation, 2)
  assert_eq(replacement.request.execution_root, request.execution_root)
}
