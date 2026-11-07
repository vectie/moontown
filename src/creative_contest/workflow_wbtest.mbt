///|
fn fixture_config() -> Config {
  {
    brief: {
      id: "coffee-01",
      name: "半醒咖啡",
      topic: "一杯想象",
      scope: "原创咖啡插画",
      possibility_wiki: "curator",
      first_person_solution: "改提示词，生成一张画",
      deadline_ms: 1000UL,
      benchmark_version: 1,
      benchmark_materials: [],
      evaluation_materials: [],
      rubric: [],
      published: true,
    },
    opens_ms: 100UL,
    voting_opens_ms: 1100UL,
    voting_closes_ms: 1200UL,
    awards_ms: 1300UL,
    participant_quota: 2,
    event_quota: 4,
    provider_origin: "http://127.0.0.1:9999",
    provider_key_file: "/unconfigured",
    model: "z-image-turbo",
    manager_account_ids: None,
    participant_account_ids: None,
  }
}

///|
fn fixture_config_json(config : Config) -> Json {
  {
    "brief": config.brief.to_json(),
    "opens_ms": config.opens_ms,
    "voting_opens_ms": config.voting_opens_ms,
    "voting_closes_ms": config.voting_closes_ms,
    "awards_ms": config.awards_ms,
    "participant_quota": config.participant_quota,
    "event_quota": config.event_quota,
    "provider_origin": config.provider_origin,
    "provider_key_file": config.provider_key_file,
    "model": config.model,
    "manager_account_ids": config.manager_account_ids.unwrap_or([]).to_json(),
  }
}

///|
test "an invitation-only rehearsal rejects strangers before spending its budget" {
  let config = { ..fixture_config(), participant_account_ids: Some(["alice"]), }
  let state = empty(config)
  assert_true(
    try {
      ignore(
        transition(
          state,
          config,
          "generate",
          { "prompt": "coffee", "intent": "outsider" },
          500UL,
          "bob",
          false,
        ),
      )
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  let accepted = transition(
    state,
    config,
    "generate",
    { "prompt": "coffee", "intent": "member" },
    500UL,
    "alice",
    false,
  )
  assert_eq(accepted.generations.length(), 1)
}

///|
test "failed attempts refund the person but never reset the event spend cap" {
  let config = { ..fixture_config(), event_quota: 1, }
  let queued = transition(
    empty(config),
    config,
    "generate",
    { "prompt": "一杯咖啡", "intent": "once" },
    500UL,
    "alice",
    false,
  )
  let failed = {
    ..queued,
    generations: queued.generations.map(job => { ..job, state: "failed", }),
  }
  assert_true(
    snapshot(failed, config, 500UL, Some("alice"), false)
    is { "remaining": Number(2, ..), "event_remaining": Number(0, ..), .. },
  )
  assert_true(
    try {
      ignore(
        transition(
          failed,
          config,
          "generate",
          { "prompt": "再来一杯", "intent": "twice" },
          500UL,
          "alice",
          false,
        ),
      )
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
}

///|
test "preview voting is explicit and has no counting projection" {
  let state = apply(
    empty(fixture_config()),
    "set-voting-url",
    { "url": "preview" },
    operator=true,
  )
  assert_true(
    snapshot(state, fixture_config(), 1101UL, None, false)
    is {
      "voting_url": String("./coffee-vote-preview.html"),
      "voting_preview": True,
      ..
    },
  )
  assert_true(
    snapshot(state, fixture_config(), 1201UL, None, false)
    is { "voting_url": String(""), .. },
  )
}

///|
async test "ambiguous generation recovers by GET only and expired queued work never spends" {
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer server.close()
  let root = @fs.tmpdir(prefix="creative-recovery-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  let config_path = root + "/config.json"
  let config = {
    ..fixture_config(),
    provider_origin: "http://\{server.addr}",
    provider_key_file: root + "/key",
  }
  @fs.write_file(
    root + "/key",
    "local-interface-fixture-not-a-production-key",
    create_mode=CreateNew,
  )
  @fs.write_file(
    config_path,
    fixture_config_json(config).stringify(),
    create_mode=CreateNew,
  )
  let original = submitted()
  let pending = {
    ..original,
    generations: original.generations.map(job => {
      ..job,
      state: "needs_reconcile",
      finished_ms: 0UL,
    }),
  }
  save(path, pending)
  let failed = Ref(false)
  let calls = Ref(0)
  @async.with_task_group(group => {
    group.spawn_bg(no_wait=true, allow_failure=true, () => {
      server.run_forever((request, _, conn) => {
        assert_true(request.meth is Get)
        calls.val += 1
        assert_eq(
          request.path,
          "/v1/images/generations/" + original.generations[0].id,
        )
        conn.send_response(if failed.val { 202 } else { 200 }, "OK", extra_headers={
          "content-type": "application/json",
        })
        let result : Json = if failed.val {
          { "status": "failed" }
        } else {
          {
            "id": original.generations[0].id,
            "data": [
              {
                "b64_json": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aH2QAAAAASUVORK5CYII=",
              },
            ],
          }
        }
        conn.write(result.stringify())
        conn.end_response()
      })
    })
    ignore(process_next(path, config_path))
    assert_eq(read(path, config).generations[0].state, "completed")
    assert_eq(calls.val, 1)
    failed.val = true
    save(path, pending)
    ignore(process_next(path, config_path))
    assert_eq(read(path, config).generations[0].state, "failed")
    assert_eq(calls.val, 2)
    assert_true(
      snapshot(read(path, config), config, 500UL, Some("alice"), false)
      is { "remaining": Number(2), .. },
    )
    save(path, {
      ..original,
      generations: original.generations.map(job => { ..job, state: "queued", }),
    })
    assert_true(process_next(path, config_path))
    assert_eq(read(path, config).generations[0].state, "failed")
    assert_eq(calls.val, 2)
  })
}

///|
fn apply(
  state : State,
  action : String,
  payload : Json,
  actor~ : String = "alice",
  operator~ : Bool = false,
  now~ : UInt64 = 500UL,
) -> State raise {
  transition(state, fixture_config(), action, payload, now, actor, operator)
}

///|
fn completed(state : State) -> State {
  {
    ..state,
    generations: state.generations.map(job => {
      ..job,
      state: "completed",
      sha256: hash("fixture"),
    }),
  }
}

///|
fn submitted() -> State raise {
  let state = completed(
    apply(empty(fixture_config()), "generate", {
      "prompt": "private prompt",
      "intent": "a",
    }),
  )
  apply(state, "submit", {
    "generation_id": state.generations[0].id,
    "title": "一杯小城",
    "display_name": "阿树",
    "consent": true,
  })
}

///|
test "durable intent is idempotent and conflicting reuse cannot spend again" {
  let state = apply(empty(fixture_config()), "generate", {
    "prompt": "hello",
    "intent": "a",
  })
  assert_eq(
    apply(state, "generate", { "prompt": "hello", "intent": "a" }).to_json(),
    state.to_json(),
  )
  assert_true(
    try {
      ignore(apply(state, "generate", { "prompt": "changed", "intent": "a" }))
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  assert_true(
    try {
      ignore(apply(state, "generate", { "prompt": "next", "intent": "b" }))
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  assert_true(
    try {
      ignore(
        apply(state, "generate", { "prompt": "next", "intent": "b" }, actor=""),
      )
      false
    } catch {
      Denied => true
      _ => false
    },
  )
}

///|
test "pending versions and prompts stay private across two users" {
  let state = submitted()
  let bob = snapshot(state, fixture_config(), 500UL, Some("bob"), false).stringify()
  assert_false(bob.contains("private prompt"))
  assert_false(bob.contains("阿树"))
  assert_false(bob.contains("alice"))
  let public = snapshot(state, fixture_config(), 500UL, None, false)
  assert_true(
    public
    is {
      "gallery": Array([]),
      "generations": Array([]),
      "review_queue": Array([]),
      ..
    },
  )
  assert_true(
    try {
      ignore(
        apply(
          state,
          "submit",
          {
            "generation_id": state.generations[0].id,
            "title": "stolen",
            "display_name": "bob",
            "consent": true,
          },
          actor="bob",
        ),
      )
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  assert_true(
    try {
      ignore(
        apply(
          state,
          "approve",
          { "entry_id": state.entries[0].id },
          actor="bob",
        ),
      )
      false
    } catch {
      Denied => true
      _ => false
    },
  )
}

///|
test "approval binds the submitted version and a different host" {
  let state = submitted()
  let entry = state.entries[0]
  assert_true(
    try {
      ignore(apply(state, "approve", { "entry_id": entry.id }, operator=true))
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  let approved = apply(
    state,
    "approve",
    { "entry_id": entry.id },
    actor="mayor",
    operator=true,
  )
  let public = snapshot(approved, fixture_config(), 500UL, None, false).stringify()
  assert_true(public.contains("一杯小城"))
  assert_false(public.contains("private prompt"))
  assert_false(public.contains("alice"))
  assert_false(public.contains("mayor"))
  let second = completed(
    apply(approved, "generate", { "prompt": "second private", "intent": "b" }),
  )
  let replaced = apply(second, "submit", {
    "generation_id": second.generations[1].id,
    "title": "新版",
    "display_name": "阿树",
    "consent": true,
  })
  assert_eq(replaced.entries[0].state, "superseded")
  assert_eq(replaced.entries[1].state, "pending")
  assert_true(
    snapshot(replaced, fixture_config(), 500UL, None, false)
    is { "gallery": Array([]), .. },
  )
  assert_true(
    try {
      ignore(
        apply(
          replaced,
          "approve",
          { "entry_id": entry.id },
          actor="mayor",
          operator=true,
        ),
      )
      false
    } catch {
      Denied => true
      _ => false
    },
  )
}

///|
test "calendar closes submissions and freezes admission before voting" {
  let state = submitted()
  assert_true(
    try {
      ignore(
        apply(
          state,
          "generate",
          { "prompt": "late", "intent": "late" },
          now=1000UL,
        ),
      )
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  assert_true(
    try {
      ignore(
        apply(
          state,
          "submit",
          {
            "generation_id": state.generations[0].id,
            "title": "late",
            "display_name": "alice",
            "consent": true,
          },
          now=1000UL,
        ),
      )
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  assert_true(
    try {
      ignore(
        apply(
          state,
          "approve",
          { "entry_id": state.entries[0].id },
          actor="mayor",
          operator=true,
          now=1100UL,
        ),
      )
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  assert_true(
    try {
      ignore(
        apply(
          state,
          "set-voting-url",
          { "url": "https://docs.qq.com.evil.example/a" },
          actor="mayor",
          operator=true,
        ),
      )
      false
    } catch {
      Invalid(_) => true
      _ => false
    },
  )
  let linked = apply(
    state,
    "set-voting-url",
    { "url": "https://docs.qq.com/form/a" },
    actor="mayor",
    operator=true,
  )
  assert_true(
    snapshot(linked, fixture_config(), 500UL, None, false)
    is { "voting_url": String(""), .. },
  )
  assert_true(
    snapshot(linked, fixture_config(), 1150UL, None, false)
    is { "voting_url": String("https://docs.qq.com/form/a"), .. },
  )
}

///|
async test "private image access follows approval and withdrawal on disk" {
  let root = @fs.tmpdir(prefix="creative-access-")
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/state.json"
  let config_path = root + "/event.json"
  let config = fixture_config()
  @fs.write_file(
    config_path,
    (
      {
        "brief": config.brief.to_json(),
        "opens_ms": "100",
        "voting_opens_ms": "1100",
        "voting_closes_ms": "1200",
        "awards_ms": "1300",
        "participant_quota": 2,
        "event_quota": 4,
        "provider_origin": config.provider_origin,
        "provider_key_file": config.provider_key_file,
        "model": config.model,
      } : Json).stringify(),
    create_mode=CreateNew,
  )
  let state = submitted()
  let id = state.generations[0].id
  save(path, state)
  @fs.mkdir(path + ".images", permission=0o700)
  @fs.write_file(
    path + ".images/" + id + ".png",
    b"private pixels",
    create_mode=CreateNew,
  )
  assert_eq(image(id, Some("alice"), path, config_path), b"private pixels")
  assert_true(
    try {
      ignore(image(id, Some("bob"), path, config_path))
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  assert_true(
    try {
      ignore(image(id, None, path, config_path))
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  let approved = apply(
    state,
    "approve",
    { "entry_id": state.entries[0].id },
    actor="mayor",
    operator=true,
  )
  save(path, approved)
  assert_eq(image(id, None, path, config_path), b"private pixels")
  save(path, apply(approved, "withdraw", { "entry_id": state.entries[0].id }))
  assert_true(
    try {
      ignore(image(id, None, path, config_path))
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  assert_true(
    try {
      ignore(image("../event.json", Some("alice"), path, config_path))
      false
    } catch {
      Denied => true
      _ => false
    },
  )
}

///|
test "PNG preserves pixels, removes private workflow and adds AI provenance" {
  let png = @base64.decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aH2QAAAAASUVORK5CYII=",
  )
  let injected = png[:png.length() - 12].to_owned() +
    png_chunk(b"tEXt", b"prompt\x00very private workflow") +
    png[png.length() - 12:].to_owned()
  let cleaned = private_metadata_removed(injected)
  assert_false(@utf8.decode_lossy(cleaned).contains("private workflow"))
  assert_true(@utf8.decode_lossy(cleaned).contains("AIGC"))
  assert_true(cleaned[12:16].to_owned() == b"IHDR")
  assert_true(
    try {
      ignore(private_metadata_removed(b"not a PNG"))
      false
    } catch {
      Unavailable => true
      _ => false
    },
  )
}
