///|
async fn control_fixture_store(work : Work) -> String {
  let path = work.request.owner_workspace + "/control-state.json"
  save_unlocked(path, {
    schema: "moontown.native-work.v1",
    revision: 1,
    work: [work],
  })
  path
}

///|
fn control_fixture_pending(work : Work) -> Work {
  let reservation = work.reservation.unwrap()
  let body = cancel_body(work, reservation)
  {
    ..work,
    state: "cancel_pending",
    control: Some({
      command_id: work.id + "-cancel",
      target_command_id: reservation.command_id,
      request_body: body,
      body_digest: digest(body),
      status: "pending",
      last_attempt_at_ms: 0UL,
      evidence: Json::null(),
    }),
  }
}

///|
fn control_fixture_receipt(work : Work, status : String) -> Json {
  let value = no_change_fixture_binding(work)
  no_change_set(
    value,
    "command_id",
    work.reservation.unwrap().command_id.to_json(),
  )
  no_change_set(
    value,
    "command",
    @json.parse(work.reservation.unwrap().request_body) catch {
      _ => Json::null()
    },
  )
  no_change_set(value, "status", status.to_json())
  no_change_set(value, "control_command_id", (work.id + "-cancel").to_json())
  value
}

///|
fn control_fixture_claim(
  work : Work,
  receipt : Json,
  control_receipt : Json,
) -> Json {
  let result = no_change_fixture_binding(work)
  let body = @json.parse(work.reservation.unwrap().request_body) catch {
    _ => Json::null()
  }
  let commands : Array[Json] = [
    {
      "command_id": work.reservation.unwrap().command_id,
      "command": body,
      "receipt": receipt,
    },
  ]
  if work.control is Some(control) {
    if control_receipt != Json::null() {
      commands.push({
        "command_id": control.command_id,
        "command": @json.parse(control.request_body) catch {
          _ => Json::null()
        },
        "receipt": control_receipt,
      })
    }
  }
  no_change_set(result, "delivered_commands", commands.to_json())
  result
}

///|
fn control_fixture_delivered(work : Work) -> Json {
  let control = work.control.unwrap()
  let result = no_change_fixture_binding(work)
  no_change_set(result, "command_id", control.command_id.to_json())
  no_change_set(
    result,
    "command",
    @json.parse(control.request_body) catch {
      _ => Json::null()
    },
  )
  no_change_set(result, "status", "runtime-completed".to_json())
  no_change_set(result, "control", "cancel".to_json())
  no_change_set(
    result,
    "target_command_id",
    control.target_command_id.to_json(),
  )
  result
}

///|
async test "cancel persists separate exact control before POST and accepts only delivered target evidence" {
  let work = fixture_reserved(fixture_request())
  let path = control_fixture_store(work)
  let pending = control_fixture_pending(work)
  let posted : Array[String] = []
  let client = fixture_client(work.request, async fn(verb, route, body) {
    let base = no_change_fixture_binding(work)
    if verb == "POST" {
      assert_true(route.has_suffix("/turns"))
      let saved : State = @json.from_json(
        @json.parse(@fs.read_file(path).text()),
      )
      let control = saved.work[0].control.unwrap()
      assert_eq(control.request_body, body)
      assert_eq(control.command_id, work.id + "-cancel")
      assert_true(control.command_id != work.reservation.unwrap().command_id)
      assert_eq(control.target_command_id, work.reservation.unwrap().command_id)
      assert_eq(control.last_attempt_at_ms, 10UL)
      assert_eq(saved.work[0].reservation.to_json(), work.reservation.to_json())
      posted.push(body)
      no_change_set(base, "accepted", true.to_json())
      no_change_set(base, "command_id", control.command_id.to_json())
      return Ok(base)
    }
    assert_true(
      route.contains(
        "book_root=" +
        @native_code_control.url_component(work.request.execution_root),
      ),
    )
    if route.contains("runtime-claim") {
      return Ok(
        control_fixture_claim(
          pending,
          if posted.is_empty() {
            Json::null()
          } else {
            control_fixture_receipt(work, "runtime-cancelled")
          },
          if posted.is_empty() {
            Json::null()
          } else {
            control_fixture_delivered(pending)
          },
        ),
      )
    }
    Ok(base)
  })
  let done = cancel(work.id, 1, 10UL, path~, client~)
  assert_eq(done.state, "cancelled")
  assert_eq(done.control.unwrap().status, "cancelled")
  assert_eq(posted.length(), 1)
  assert_eq(done.reservation.to_json(), work.reservation.to_json())
  assert_eq(done.request_digest, work.request_digest)
  let repeated = cancel(work.id, load(path~).revision, 20UL, path~, client~)
  assert_eq(repeated.to_json(), done.to_json())
  assert_eq(posted.length(), 1)
  assert_false(@fs.exists(work.request.result_path))
}

///|
async test "uncertain cancel survives restart and sync never posts a prompt or rechecks launch inputs" {
  let request = fixture_request()
  let request = {
    ..request,
    input_blocker: "launch_input_unavailable",
    acceptance_policy: { "commit_requirement": "required" },
  }
  let work = fixture_reserved(request)
  let path = control_fixture_store(work)
  @fs.remove(request.catalog_path)
  @support.write_text_file(
    request.execution_root + "/source.mbt",
    "later state\n",
  )
  let posted : Array[String] = []
  let client = fixture_client(request, async fn(verb, route, body) {
    assert_false(
      route.contains("capabilities") || route.contains("moongate-route"),
    )
    if verb == "POST" {
      posted.push(body)
      assert_eq(text(@json.parse(body), "command"), "cancel")
      return Err(
        if posted.length() == 1 {
          "native_conflict"
        } else {
          "runtime_unavailable"
        },
      )
    }
    Err("native_not_found")
  })
  let first = cancel(work.id, 1, 10UL, path~, client~)
  assert_eq(first.state, "cancel_pending")
  let reloaded = load(path~).work[0]
  assert_eq(reloaded.to_json(), first.to_json())
  let second = sync(work.id, 40000UL, path~, client~)
  let third = sync(work.id, 40001UL, path~, client~, force=true)
  assert_eq(second.state, "cancel_pending")
  assert_eq(third.state, "cancel_pending")
  assert_eq(posted.length(), 3)
  assert_eq(posted[0], posted[1])
  assert_eq(posted[1], posted[2])
  assert_eq(third.reservation.to_json(), work.reservation.to_json())
  assert_eq(
    third.control.unwrap().target_command_id,
    work.reservation.unwrap().command_id,
  )
  assert_false(@fs.exists(request.catalog_path))
  assert_false(@fs.exists(request.result_path))
  try supersede(work.id, load(path~).revision, path~) catch {
    _ => ()
  } noraise {
    _ => fail("expected supersession refusal")
  }
}

///|
async test "unfamiliar runtime absence never sends cancellation without original continuity" {
  let work = fixture_reserved(fixture_request())
  let path = control_fixture_store(work)
  let posts : Array[String] = []
  let client = @native_code_control.Client::new(
    owner_workspace=work.request.owner_workspace,
    instance_id="replacement-instance",
    config_path=work.reservation.unwrap().config_path,
    request=async fn(verb, _, body) {
      if verb == "POST" {
        posts.push(body)
      }
      Err("native_not_found")
    },
  )
  let pending = cancel(work.id, 1, 10UL, path~, client~)
  assert_eq(pending.state, "cancel_pending")
  assert_eq(pending.blocked_reason, "runtime_continuity_unverified")
  assert_eq(posts.length(), 0)
}

///|
async test "refresh observes exact completed work but never submits or applies Book output" {
  let work = no_change_fixture_work()
  let path = control_fixture_store(work)
  let calls : Array[String] = []
  let client = fixture_client(work.request, async fn(verb, route, _) {
    assert_eq(verb, "GET")
    calls.push(route)
    if route.contains("runtime-claim") {
      return Ok(no_change_fixture_claim(work, no_change_fixture_receipt(work)))
    }
    if route.contains("runtime-events") {
      return Ok(
        no_change_fixture_bound_events(work, no_change_fixture_events(work)),
      )
    }
    Ok(no_change_fixture_binding(work))
  })
  let done = refresh(work.id, 1, 10UL, path~, client~)
  assert_eq(done.state, "completed")
  assert_eq(text(done.receipt, "engineering_status"), "no_change")
  assert_eq(calls.length(), 3)
  assert_false(@fs.exists(work.request.result_path))
  assert_false(@fs.exists(work.request.result_path + ".native-receipt.json"))
  let revision = load(path~).revision
  assert_eq(
    refresh(work.id, revision, 20UL, path~, client~).to_json(),
    done.to_json(),
  )
  assert_eq(
    cancel(work.id, revision, 20UL, path~, client~).to_json(),
    done.to_json(),
  )
  assert_eq(load(path~).revision, revision)
  assert_eq(calls.length(), 3)
  ignore(sync(work.id, 30UL, path~, client~))
  assert_true(@fs.exists(work.request.result_path))
  assert_eq(calls.length(), 3)
}

///|
async test "completion during cancel wins with full result and receipt without implicit Book output" {
  let work = no_change_fixture_work()
  let path = control_fixture_store(work)
  let posted : Array[String] = []
  let client = fixture_client(work.request, async fn(verb, route, body) {
    if verb == "POST" {
      posted.push(body)
      return Err("native_conflict")
    }
    if route.contains("runtime-claim") {
      return Ok(
        if posted.is_empty() {
          control_fixture_claim(work, Json::null(), Json::null())
        } else {
          no_change_fixture_claim(work, no_change_fixture_receipt(work))
        },
      )
    }
    if route.contains("runtime-events") {
      return Ok(
        no_change_fixture_bound_events(work, no_change_fixture_events(work)),
      )
    }
    Ok(no_change_fixture_binding(work))
  })
  let done = cancel(work.id, 1, 10UL, path~, client~)
  assert_eq(done.state, "completed")
  assert_eq(done.control.unwrap().status, "already_terminal")
  assert_eq(text(done.receipt, "engineering_status"), "no_change")
  assert_true(done.output.contains("No net source change"))
  assert_eq(posted.length(), 1)
  assert_false(@fs.exists(work.request.result_path))
}

///|
async test "unreserved cancellation and passive projection need no native access and stale revisions fail" {
  let request = fixture_request()
  let path = request.owner_workspace + "/queued.json"
  let work = enqueue(request, path~)
  let calls : Array[String] = []
  let client = fixture_client(request, async fn(verb, _, _) {
    calls.push(verb)
    Err("must-not-call")
  })
  try cancel(work.id, 0, 10UL, path~, client~) catch {
    _ => ()
  } noraise {
    _ => fail("expected revision conflict")
  }
  try refresh(work.id, 0, 10UL, path~, client~) catch {
    _ => ()
  } noraise {
    _ => fail("expected revision conflict")
  }
  assert_eq(load(path~).revision, 1)
  assert_eq(refresh(work.id, 1, 10UL, path~, client~).to_json(), work.to_json())
  let projection = status(work).to_json().stringify()
  assert_false(projection.contains(request.prompt))
  assert_false(projection.contains(request.owner_workspace))
  assert_false(
    projection.contains("request_body") || projection.contains("baseline"),
  )
  assert_true(render_status(path~).contains(work.id))
  assert_eq(load(path~).revision, 1)
  let done = cancel(work.id, 1, 20UL, path~, client~)
  assert_eq(done.state, "cancelled")
  assert_true(done.reservation is None)
  assert_true(done.control is None)
  assert_eq(calls.length(), 0)
}

///|
async test "legacy v1 work missing optional control still loads with immutable reservation" {
  let work = fixture_reserved(fixture_request())
  let json = work.to_json()
  if json is Object(fields) {
    fields.remove("control")
  }
  let path = work.request.owner_workspace + "/legacy.json"
  @support.write_text_file(
    path,
    (
      { "schema": "moontown.native-work.v1", "revision": 7, "work": [json] } :
      Json).stringify(),
  )
  let legacy = load(path~)
  assert_eq(legacy.revision, 7)
  assert_true(legacy.work[0].control is None)
  assert_eq(legacy.work[0].reservation.to_json(), work.reservation.to_json())
}

///|
async test "cancelled original needs exact separate delivered control body target owner and identity" {
  let work = control_fixture_pending(fixture_reserved(fixture_request()))
  for
    key in [
      "command", "target_command_id", "owner", "session_id", "command_id", "book_root",
      "control", "status",
    ] {
    let receipt = control_fixture_delivered(work)
    no_change_set(receipt, key, "wrong".to_json())
    let client = fixture_client(work.request, async fn(_, route, _) {
      Ok(
        if route.contains("runtime-claim") {
          control_fixture_claim(
            work,
            control_fixture_receipt(work, "runtime-cancelled"),
            receipt,
          )
        } else {
          no_change_fixture_binding(work)
        },
      )
    })
    let result = observe_with_client(work, client, 10UL)
    assert_eq(result.state, "cancel_pending")
    assert_eq(
      result.blocked_reason,
      "native_cancel_control_evidence_unverified",
    )
  }
  let target = control_fixture_receipt(work, "runtime-cancelled")
  no_change_set(target, "control_command_id", "other-cancel".to_json())
  let client = fixture_client(work.request, async fn(_, route, _) {
    Ok(
      if route.contains("runtime-claim") {
        control_fixture_claim(work, target, control_fixture_delivered(work))
      } else {
        no_change_fixture_binding(work)
      },
    )
  })
  assert_eq(
    observe_with_client(work, client, 10UL).blocked_reason,
    "native_cancel_target_control_mismatch",
  )
}

///|
async test "cancellation never posts against contradictory original command or terminal receipt identity" {
  let work = fixture_reserved(fixture_request())
  for key in ["command", "owner", "session_id", "command_id", "book_root"] {
    let path = control_fixture_store(work)
    let receipt = control_fixture_receipt(work, "runtime-cancelled")
    no_change_set(receipt, key, "wrong".to_json())
    let posts : Array[String] = []
    let client = fixture_client(work.request, async fn(verb, route, body) {
      if verb == "POST" {
        posts.push(body)
      }
      Ok(
        if route.contains("runtime-claim") {
          control_fixture_claim(work, receipt, Json::null())
        } else {
          no_change_fixture_binding(work)
        },
      )
    })
    let pending = cancel(work.id, 1, 10UL, path~, client~)
    assert_eq(pending.state, "cancel_pending")
    assert_eq(posts.length(), 0)
  }
}

///|
async test "native completion before cancellation is a no-op even while owner result reconciliation is blocked" {
  let work = fixture_reserved(fixture_request())
  let path = control_fixture_store(work)
  // Removing only this disposable synthetic fixture's module blocks the
  // final source observation, but cannot make a completed native turn active.
  @fs.remove(work.request.execution_root + "/moon.mod")
  let posts : Array[String] = []
  let receipt = control_fixture_receipt(work, "runtime-completed")
  let client = fixture_client(work.request, async fn(verb, route, body) {
    if verb == "POST" {
      posts.push(body)
    }
    Ok(
      if route.contains("runtime-claim") {
        control_fixture_claim(work, receipt, Json::null())
      } else {
        no_change_fixture_binding(work)
      },
    )
  })
  let result = cancel(work.id, 1, 10UL, path~, client~)
  assert_eq(result.control.unwrap().status, "already_terminal")
  assert_true(result.state != "cancel_pending" && result.state != "cancelled")
  assert_eq(posts.length(), 0)
  ignore(sync(work.id, 40000UL, path~, client~))
  assert_eq(posts.length(), 0)
  assert_false(@fs.exists(work.request.result_path))
}

///|
async test "refresh with pending cancellation observes only and retains exact control under absence" {
  let work = control_fixture_pending(fixture_reserved(fixture_request()))
  let path = control_fixture_store(work)
  let client = fixture_client(work.request, async fn(verb, _, _) {
    assert_eq(verb, "GET")
    Err("native_not_found")
  })
  let result = refresh(work.id, 1, 10UL, path~, client~)
  assert_eq(result.state, "cancel_pending")
  assert_eq(result.control.to_json(), work.control.to_json())
  assert_eq(result.reservation.to_json(), work.reservation.to_json())
  assert_false(@fs.exists(work.request.result_path))
}

///|
async test "replacement runtime with exact original continuity can settle the same saved control" {
  let work = fixture_reserved(fixture_request())
  let path = control_fixture_store(work)
  let pending = control_fixture_pending(work)
  let posts : Array[String] = []
  let client = @native_code_control.Client::new(
    owner_workspace=work.request.owner_workspace,
    instance_id="replacement-instance",
    config_path=work.reservation.unwrap().config_path,
    request=async fn(verb, route, body) {
      let base = no_change_fixture_binding(work)
      if verb == "POST" {
        posts.push(body)
        assert_eq(body, pending.control.unwrap().request_body)
        no_change_set(base, "accepted", true.to_json())
        no_change_set(
          base,
          "command_id",
          pending.control.unwrap().command_id.to_json(),
        )
        return Ok(base)
      }
      Ok(
        if route.contains("runtime-claim") {
          control_fixture_claim(
            pending,
            if posts.is_empty() {
              Json::null()
            } else {
              control_fixture_receipt(work, "runtime-cancelled")
            },
            if posts.is_empty() {
              Json::null()
            } else {
              control_fixture_delivered(pending)
            },
          )
        } else {
          base
        },
      )
    },
  )
  let result = cancel(work.id, 1, 10UL, path~, client~)
  assert_eq(result.state, "cancelled")
  assert_eq(result.control.unwrap().status, "cancelled")
  assert_true(result.observed_instances.contains("replacement-instance"))
  assert_eq(posts.length(), 1)
}

///|
async test "safe saved status redacts path bearing blockers without changing private recovery state" {
  let work = fixture_reserved(fixture_request())
  let blocked = {
    ..work,
    state: "waiting_control",
    blocked_reason: "control_unavailable: " +
    work.reservation.unwrap().config_path,
  }
  let path = control_fixture_store(blocked)
  assert_eq(status(blocked).blocked_reason, "control_unavailable")
  assert_true(
    status(blocked).blocker_help.contains("MOONTOWN_MOONCODE_CONTROL_CONFIG"),
  )
  assert_true(
    status(blocked).blocker_help.contains("does not rebind reserved work"),
  )
  assert_true(
    status({ ..blocked, reservation: None, }).blocker_help.contains(
      "default Desk application-support",
    ),
  )
  assert_false(
    render_status(path~).contains(work.reservation.unwrap().config_path),
  )
  assert_false(
    status(blocked)
    .to_json()
    .stringify()
    .contains(work.reservation.unwrap().config_path),
  )
  assert_eq(load(path~).work[0].blocked_reason, blocked.blocked_reason)
  assert_true(
    render_status(path~).contains("control/execution-sandbox/moonclaw.json"),
  )
  let source_reason = "source_binding_stale_or_unavailable: " +
    work.request.execution_root
  assert_eq(
    status({ ..work, blocked_reason: source_reason, }).blocked_reason,
    source_reason,
  )
}

///|
async test "completion during cancel preserves unreconciled owner blocker rather than cancel pending" {
  let work = fixture_reserved(fixture_request())
  let path = control_fixture_store(work)
  let posted : Array[String] = []
  let receipt = control_fixture_receipt(work, "runtime-completed")
  let client = fixture_client(work.request, async fn(verb, route, body) {
    if verb == "POST" {
      posted.push(body)
      @fs.rename(
        work.request.execution_root,
        work.request.execution_root + "-offline",
      )
      return Err("native_conflict")
    }
    Ok(
      if route.contains("runtime-claim") {
        control_fixture_claim(
          work,
          if posted.is_empty() {
            Json::null()
          } else {
            receipt
          },
          Json::null(),
        )
      } else {
        no_change_fixture_binding(work)
      },
    )
  })
  let result = cancel(work.id, 1, 10UL, path~, client~)
  assert_eq(result.state, "waiting_source_binding")
  assert_eq(result.blocked_reason, "source_final_observation_unavailable")
  assert_eq(result.control.unwrap().status, "already_terminal")
  assert_eq(result.control.unwrap().evidence, receipt)
  assert_eq(posted.length(), 1)
}

///|
async test "late original acceptance settles persisted cancellation without resubmitting original" {
  let work = fixture_reserved(fixture_request())
  let path = control_fixture_store(work)
  let pending = control_fixture_pending(work)
  let phase = [0]
  let posted : Array[String] = []
  let client = fixture_client(work.request, async fn(verb, route, body) {
    if verb == "POST" {
      posted.push(body)
      assert_eq(text(@json.parse(body), "command"), "cancel")
      if phase[0] == 1 {
        phase[0] = 2
      }
      return Err("runtime_unavailable")
    }
    if phase[0] == 0 {
      return Err("native_not_found")
    }
    Ok(
      if route.contains("runtime-claim") {
        control_fixture_claim(
          pending,
          if phase[0] == 2 {
            control_fixture_receipt(work, "runtime-cancelled")
          } else {
            Json::null()
          },
          if phase[0] == 2 {
            control_fixture_delivered(pending)
          } else {
            Json::null()
          },
        )
      } else {
        no_change_fixture_binding(work)
      },
    )
  })
  let uncertain = cancel(work.id, 1, 10UL, path~, client~)
  assert_eq(uncertain.state, "cancel_pending")
  let saved = load(path~).work[0].control.unwrap()
  phase[0] = 1
  let done = sync(work.id, 40000UL, path~, client~)
  assert_eq(done.state, "cancelled")
  assert_eq(posted.length(), 2)
  assert_eq(posted[0], posted[1])
  assert_eq(done.control.unwrap().request_body, saved.request_body)
  assert_eq(done.control.unwrap().command_id, saved.command_id)
}

///|
async test "concurrent cancel and forced sync preserve one durable control and reject stale revision" {
  let work = control_fixture_pending(fixture_reserved(fixture_request()))
  let path = control_fixture_store(work)
  let posted : Array[String] = []
  let client = fixture_client(work.request, async fn(verb, route, body) {
    if verb == "POST" {
      posted.push(body)
      assert_eq(body, work.control.unwrap().request_body)
      return Err("runtime_unavailable")
    }
    Ok(
      if route.contains("runtime-claim") {
        control_fixture_claim(
          work,
          if posted.is_empty() {
            Json::null()
          } else {
            control_fixture_receipt(work, "runtime-cancelled")
          },
          if posted.is_empty() {
            Json::null()
          } else {
            control_fixture_delivered(work)
          },
        )
      } else {
        no_change_fixture_binding(work)
      },
    )
  })
  let results = @async.with_task_group(group => {
    let first = group.spawn(() => {
      try {
        ignore(cancel(work.id, 1, 10UL, path~, client~))
        true
      } catch {
        _ => false
      }
    })
    let second = group.spawn(() => {
      try {
        ignore(cancel(work.id, 1, 11UL, path~, client~))
        true
      } catch {
        _ => false
      }
    })
    let syncer = group.spawn(() => {
      sync(work.id, 12UL, path~, client~, force=true)
    })
    (first.wait(), second.wait(), syncer.wait())
  })
  assert_false(results.0 && results.1)
  assert_eq(results.2.state, "cancelled")
  assert_eq(posted.length(), 1)
  let saved = load(path~)
  assert_eq(saved.work.length(), 1)
  assert_eq(
    saved.work[0].control.unwrap().command_id,
    work.control.unwrap().command_id,
  )
  assert_eq(saved.work[0].reservation.to_json(), work.reservation.to_json())
}

///|
async test "completed applied repair during cancellation retains engineering receipt focused diff and output" {
  let work = fixture_reserved(fixture_request())
  let path = control_fixture_store(work)
  let posted : Array[String] = []
  let events : Array[Json] = []
  let client = fixture_client(work.request, async fn(verb, route, body) {
    if verb == "POST" {
      posted.push(body)
      @support.write_text_file(
        work.request.execution_root + "/source.mbt",
        "after\n",
      )
      events.push(
        fixture_event(work, "mutation", "write", {
          "path": "source.mbt",
          "before_fingerprint": native_fingerprint(b"before\n"),
          "after_fingerprint": native_fingerprint(b"after\n"),
          "changed": true,
        }),
      )
      events.push(fixture_validation(work, "validation"))
      return Err("native_conflict")
    }
    if route.contains("runtime-claim") {
      return Ok(
        if posted.is_empty() {
          control_fixture_claim(work, Json::null(), Json::null())
        } else {
          no_change_fixture_claim(work, fixture_receipt(work))
        },
      )
    }
    if route.contains("runtime-events") {
      return Ok(
        no_change_fixture_bound_events(work, {
          "event_count": events.length(),
          "events": events,
        }),
      )
    }
    Ok(no_change_fixture_binding(work))
  })
  let done = cancel(work.id, 1, 10UL, path~, client~)
  assert_eq(done.state, "completed")
  assert_eq(done.control.unwrap().status, "already_terminal")
  assert_eq(text(done.receipt, "engineering_status"), "applied_and_validated")
  assert_true(text(done.receipt, "focused_diff").contains("+after"))
  assert_eq(done.output, "repair_decision: accepted\nApplied source fix")
  assert_false(@fs.exists(work.request.result_path))
  assert_eq(posted.length(), 1)
}

///|
async test "revision checked sync rejects stale dispatch before any native access or durable change" {
  let work = fixture_reserved(fixture_request())
  let path = control_fixture_store(work)
  let before = @fs.read_file(path).text()
  let calls : Array[String] = []
  let client = fixture_client(work.request, async fn(verb, _, _) {
    calls.push(verb)
    Err("must-not-call")
  })
  try
    sync(work.id, 10UL, path~, client~, force=true, expected_revision=0)
  catch {
    error =>
      assert_true(error.to_string().contains("native_work_revision_conflict"))
  } noraise {
    _ => fail("expected revision conflict")
  }
  assert_eq(calls.length(), 0)
  assert_eq(@fs.read_file(path).text(), before)
  assert_false(@fs.exists(work.request.result_path))
}

///|
async test "revision checked sync rejects stale terminal result application but preserves omitted callers" {
  let work = no_change_fixture_work()
  let done = observe(
    work,
    no_change_fixture_claim(work, no_change_fixture_receipt(work)),
    no_change_fixture_bound_events(work, no_change_fixture_events(work)),
    no_change_fixture_binding(work),
    "fixture-instance",
    5UL,
  )
  assert_eq(done.state, "completed")
  let path = control_fixture_store(done)
  let before = @fs.read_file(path).text()
  let calls : Array[String] = []
  let client = fixture_client(work.request, async fn(verb, _, _) {
    calls.push(verb)
    Err("must-not-call")
  })
  try sync(done.id, 10UL, path~, client~, expected_revision=0) catch {
    error =>
      assert_true(error.to_string().contains("native_work_revision_conflict"))
  } noraise {
    _ => fail("expected revision conflict")
  }
  assert_false(@fs.exists(work.request.result_path))
  assert_false(@fs.exists(work.request.result_path + ".native-receipt.json"))
  assert_eq(@fs.read_file(path).text(), before)
  assert_eq(
    sync(done.id, 11UL, path~, client~, expected_revision=1).to_json(),
    done.to_json(),
  )
  assert_true(@fs.exists(work.request.result_path))
  @fs.remove(work.request.result_path)
  assert_eq(sync(done.id, 12UL, path~, client~).to_json(), done.to_json())
  assert_true(@fs.exists(work.request.result_path))
  assert_eq(calls.length(), 0)
}

///|
async test "concurrent revision checked sync allows one control attempt and rejects the stale contender" {
  let work = control_fixture_pending(fixture_reserved(fixture_request()))
  let path = control_fixture_store(work)
  let posted : Array[String] = []
  let client = fixture_client(work.request, async fn(verb, route, body) {
    if verb == "POST" {
      posted.push(body)
      assert_eq(body, work.control.unwrap().request_body)
      return Err("runtime_unavailable")
    }
    Ok(
      if route.contains("runtime-claim") {
        control_fixture_claim(
          work,
          if posted.is_empty() {
            Json::null()
          } else {
            control_fixture_receipt(work, "runtime-cancelled")
          },
          if posted.is_empty() {
            Json::null()
          } else {
            control_fixture_delivered(work)
          },
        )
      } else {
        no_change_fixture_binding(work)
      },
    )
  })
  let results = @async.with_task_group(group => {
    let first = group.spawn(() => {
      try {
        ignore(
          sync(work.id, 10UL, path~, client~, force=true, expected_revision=1),
        )
        true
      } catch {
        error => {
          assert_true(
            error.to_string().contains("native_work_revision_conflict"),
          )
          false
        }
      }
    })
    let second = group.spawn(() => {
      try {
        ignore(
          sync(work.id, 11UL, path~, client~, force=true, expected_revision=1),
        )
        true
      } catch {
        error => {
          assert_true(
            error.to_string().contains("native_work_revision_conflict"),
          )
          false
        }
      }
    })
    (first.wait(), second.wait())
  })
  assert_true(results.0 != results.1)
  assert_eq(posted.length(), 1)
  let saved = load(path~)
  assert_eq(saved.work.length(), 1)
  assert_eq(saved.work[0].state, "cancelled")
  assert_eq(
    saved.work[0].control.unwrap().command_id,
    work.control.unwrap().command_id,
  )
}
