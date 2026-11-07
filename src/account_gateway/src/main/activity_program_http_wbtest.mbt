///|
struct ProgramBodyReadObserver {
  reader : &@io.Reader
  buffer : @io.ReaderBuffer
  entered_ms : Array[UInt64]
}

///|
impl @io.Reader for ProgramBodyReadObserver with fn _get_internal_buffer(self) {
  self.buffer
}

///|
impl @io.Reader for ProgramBodyReadObserver with fn _direct_read(
  self,
  bytes,
  offset~,
  max_len~,
) {
  if self.entered_ms[0] == 0UL {
    self.entered_ms[0] = @async.now().reinterpret_as_uint64()
  }
  self.reader.read(bytes, offset~, max_len~)
}

///|
async test "program HTTP scopes approval and dynamic activities without platform escalation" {
  let identity_server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer identity_server.close()
  let app = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer app.close()
  let origin = "http://\{app.addr}"
  let identity_origin = "http://\{identity_server.addr}"
  let identity = @account_identity.Client::new(
    endpoint=identity_origin,
    host=identity_server.addr.to_string(),
    origin=identity_origin,
    prefix="/user",
  ).unwrap()
  let root = @fs.tmpdir(prefix="activity-http-")
  defer @fs.rmdir(root, recursive=true)
  let registry = root + "/program"
  let delayed_body_entered_ms = [0UL]
  let template_path = root + "/template.json"
  let now = @async.now().reinterpret_as_uint64()
  let template : Json = {
    "brief": {
      "id": "template",
      "name": "coffee",
      "topic": "coffee",
      "scope": "art",
      "possibility_wiki": "",
      "first_person_solution": "write",
      "deadline_ms": (now + 600000UL).to_string(),
      "benchmark_version": 1,
      "benchmark_materials": [],
      "evaluation_materials": [],
      "rubric": [],
      "published": true,
    },
    "opens_ms": (now - 60000UL).to_string(),
    "voting_opens_ms": (now + 700000UL).to_string(),
    "voting_closes_ms": (now + 800000UL).to_string(),
    "awards_ms": (now + 900000UL).to_string(),
    "participant_quota": 2,
    "event_quota": 4,
    "provider_origin": identity_origin,
    "provider_key_file": root + "/fixture.key",
    "model": "interface-fixture",
    "program_template": {
      "template_id": "coffee-image-v1",
      "template_version": "1",
      "book_id": "banxing-coffee-curator",
      "book_version": "1.2.0",
      "curator_profile": "coffee_curator",
      "workflow_id": "z-image-turbo",
      "workflow_version": "1",
      "max_instances": 2,
      "max_total_quota": 4,
      "max_event_quota": 2,
      "max_participant_quota": 2,
      "max_cash_budget_cny": 1000,
      "max_grants": 2,
    },
  }
  @fs.write_file(template_path, template.stringify(), permission=0o600)
  @fs.write_file(
    root + "/fixture.key",
    "fixture-only-not-a-real-key",
    permission=0o600,
  )
  let owner_id = "lunanexa:" +
    @account_system.account_token_digest(
      (["program-http-fixture", "owner"] : Array[String]).to_json().stringify(),
    )
  let platform : PublicPlatform = {
    identity: {
      flights: {},
      resolve: cookie => identity.resolve(identity_cookies(cookie)),
    },
    assets: root,
    controller: identity_origin,
    controller_ca: "",
    public_origin: origin,
    neighborhood_path: None,
    creative_path: None,
    creative_config: None,
    program_root: Some(registry),
    program_template_config: Some(template_path),
    program_approver_ids: [owner_id],
  }
  @async.with_task_group(group => {
    group.spawn_bg(no_wait=true, allow_failure=true, () => {
      identity_server.run_forever((request, _, conn) => {
        if request.path == "/v1/images/generations" {
          return reply_json(conn, 200, {
            "id": "fixture-output",
            "data": [
              {
                "b64_json": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aH2QAAAAASUVORK5CYII=",
              },
            ],
          })
        }
        let cookie = request.headers.get("cookie").unwrap_or("")
        let who = if cookie.contains("=a") {
          "a"
        } else if cookie.contains("=b") {
          "b"
        } else if cookie.contains("=owner") {
          "owner"
        } else {
          return reply_json(conn, 401, {})
        }
        match request.path {
          "/user/auth/session" =>
            reply_json(conn, 200, {
              "session_token": "lnxs_program_fixture_" + who,
            })
          "/user/v1/auth/self" =>
            reply_json(conn, 200, {
              "account_id": who,
              "subject_ref": who,
              "identity_issuer": "program-http-fixture",
              "display_name": who,
              "state": "Active",
              "roles": ["EnterpriseUser"],
            })
          _ => reply_json(conn, 404, {})
        }
      })
    })
    group.spawn_bg(no_wait=true, allow_failure=true, () => {
      app.run_forever((request, body, conn) => {
        if request.headers.get("x-program-expiry-fixture") == Some("1") {
          let observed : ProgramBodyReadObserver = {
            reader: body,
            buffer: @io.ReaderBuffer::new(),
            entered_ms: delayed_body_entered_ms,
          }
          return platform.handle(request, observed, conn)
        }
        platform.handle(request, body, conn)
      })
    })
    let get = async fn(who : String, path : String) {
      @http.get(origin + "/moontown/" + path, headers={
        "cookie": "lunanexa_http_enterprise_oidc_8443=" + who,
      })
    }
    let actor = async fn(who : String) {
      guard @json.parse(get(who, "api/program/mine").1.text())
        is { "viewer": { "account_id": String(id), .. }, .. } else {
        fail("Missing fixture actor")
      }
      id
    }
    let write = async fn(
      who : String,
      path : String,
      action : String,
      payload : Json,
    ) {
      let expected = actor(who)
      @http.post(
        origin + "/moontown/" + path,
        (
          {
            "expected_actor_id": expected,
            "action": action,
            "payload": payload,
          } : Json).stringify(),
        headers={
          "cookie": "lunanexa_http_enterprise_oidc_8443=" + who,
          "origin": origin,
          "content-type": "application/json",
        },
      )
    }
    assert_eq(get("", "api/program/public").0.code, 200)
    assert_eq(get("", "api/program/mine").0.code, 401)
    assert_eq(
      @http.post(origin + "/moontown/api/program/actions", "{}", headers={
        "origin": "https://attacker.invalid",
        "content-type": "application/json",
      }).0.code,
      403,
    )
    assert_eq(get("a", "api/activities/not-an-id/mine").0.code, 404)
    let saved = write("a", "api/program/actions", "save-application", {
      "application_id": "",
      "intent": "new-application",
      "expected_revision": 0,
      "title": "Coffee lab",
      "topic": "a morning",
      "scope": "original art",
      "audience": "neighbours",
      "proposal": "Private proposal, not public",
      "prize_plan": "three coffee surprises",
      "contact": "private-contact",
      "cash_budget_cny": 0,
      "requested_instances": 2,
      "requested_total_quota": 4,
      "requested_participant_quota": 2,
    })
    assert_eq(saved.0.code, 200)
    guard @json.parse(saved.1.text())
      is { "application_id": String(application), .. } else {
      fail("Missing application")
    }
    assert_false(
      get("b", "api/program/mine").1.text().contains("private-contact"),
    )
    assert_false(
      get("", "api/program/public").1.text().contains("private-contact"),
    )
    assert_eq(
      write("a", "api/program/actions", "submit-application", {
        "application_id": application,
        "expected_revision": 1,
      }).0.code,
      200,
    )
    let approval : Json = {
      "application_id": application,
      "expected_revision": 2,
      "decision": "approve",
      "note": "bounded",
      "starts_ms": (now - 60000UL).to_string(),
      "ends_ms": (now + 86400000UL).to_string(),
      "max_instances": 2,
      "total_generation_quota": 4,
      "per_event_quota": 2,
      "participant_quota": 2,
      "allow_publish": true,
    }
    assert_eq(
      write("b", "api/program/actions", "review-application", approval).0.code,
      403,
    )
    assert_eq(
      write("owner", "api/program/actions", "review-application", approval).0.code,
      200,
    )
    let workbook : Json = {
      "application_id": application,
      "intent": "launch-once",
      "title": "Activity One",
      "topic": "morning",
      "scope": "original coffee art",
      "first_person_solution": "I write then submit",
      "prize_plan": "approved three prizes",
      "opens_ms": (now - 1000UL).to_string(),
      "deadline_ms": (now + 600000UL).to_string(),
      "voting_opens_ms": (now + 700000UL).to_string(),
      "voting_closes_ms": (now + 800000UL).to_string(),
      "awards_ms": (now + 900000UL).to_string(),
      "event_quota": 2,
      "participant_quota": 2,
    }
    assert_eq(
      write("b", "api/program/actions", "create-activity", workbook).0.code,
      403,
    )
    let created = write("a", "api/program/actions", "create-activity", workbook)
    assert_eq(created.0.code, 200)
    guard @json.parse(created.1.text()) is { "activity_id": String(id), .. } else {
      fail("Missing activity")
    }
    guard @json.parse(
        write("a", "api/program/actions", "create-activity", workbook).1.text(),
      )
      is { "activity_id": String(replayed), .. } else {
      fail("Missing replayed activity")
    }
    assert_eq(replayed, id)
    // This explicit test callback is a fixture, not a claimed Book import.
    assert_true(
      @activity_program.process_next(registry, template_path, now, (_, _, _) => {
        "ready": true,
        "book_id": "fixture-book",
        "source_book_id": "banxing-coffee-curator",
        "book_version": "1.2.0",
        "curator_profile": "coffee_curator",
        "agent_state": "configured-not-started",
        "workflow_id": "z-image-turbo",
        "workflow_version": "1",
        "source_bundle_digest": "sha256:" + "a".repeat(64),
        "launch_digest": "sha256:" + "b".repeat(64),
        "profile_digest": "sha256:" + "c".repeat(64),
      }),
    )
    let base = "api/activities/" + id + "/"
    let a = @json.parse(get("a", base + "mine").1.text())
    assert_true(
      a
      is {
        "viewer": { "operator": True, .. },
        "event": { "prize_plan": "approved three prizes", .. },
        ..
      },
    )
    assert_true(
      @json.parse(get("b", base + "mine").1.text())
      is { "viewer": { "operator": False, .. }, .. },
    )
    assert_eq(
      write("b", base + "actions", "generate", {
        "prompt": "B private draft",
        "intent": "draft-b",
      }).0.code,
      200,
    )
    assert_true(
      @activity_program.with_activity(
        id,
        now,
        None,
        false,
        "worker",
        registry,
        binding => {
          @creative_contest.process_next(
            binding.state_path,
            binding.config_path,
          )
        },
      ),
    )
    guard @json.parse(get("b", base + "mine").1.text())
      is {
        "generations": [{ "id": String(image), "state": "completed", .. }],
        ..
      } else {
      fail("B fixture generation did not complete")
    }
    assert_eq(get("b", base + "images/" + image).0.code, 200)
    assert_eq(get("a", base + "images/" + image).0.code, 404)
    assert_eq(
      write("b", base + "actions", "submit", {
        "generation_id": image,
        "title": "B draft",
        "display_name": "B",
        "consent": true,
      }).0.code,
      200,
    )
    assert_eq(get("a", base + "images/" + image).0.code, 200)
    assert_eq(
      write("a", "api/program/actions", "pause-activity", { "activity_id": id }).0.code,
      200,
    )
    assert_eq(
      write("b", base + "actions", "generate", {
        "prompt": "paused",
        "intent": "paused",
      }).0.code,
      403,
    )
    assert_eq(
      write("a", "api/program/actions", "resume-activity", { "activity_id": id }).0.code,
      200,
    )
    // A real streaming request reaches the gateway's body read while its host
    // grant is valid, then withholds the remainder across grant expiry. The
    // event's own creative deadline is still ten minutes away. Reusing the
    // pre-body clock would incorrectly approve this pending submission.
    guard @json.parse(get("b", base + "mine").1.text())
      is { "entries": [{ "id": String(pending_entry), .. }], .. } else {
      fail("Missing pending entry for delayed-body expiry regression")
    }
    let expected_host = actor("a")
    let delayed_payload = (
      {
        "expected_actor_id": expected_host,
        "action": "approve",
        "payload": { "entry_id": pending_entry },
      } : Json).stringify()
    let delayed = @http.post_stream(origin + "/moontown/" + base + "actions", headers={
      "cookie": "lunanexa_http_enterprise_oidc_8443=a",
      "origin": origin,
      "content-type": "application/json",
      "x-program-expiry-fixture": "1",
    })
    defer delayed.close()
    delayed.write("{")
    delayed.flush()
    let wait_started = @async.now()
    while delayed_body_entered_ms[0] == 0UL {
      guard @async.now() - wait_started < 3000L else {
        fail("Streaming request never reached gateway body read")
      }
      @async.sleep(1)
    }
    let registry_file = registry + "/registry.json"
    let unexpired_registry = @fs.read_file(registry_file).text()
    let shortened = @json.parse(unexpired_registry)
    guard shortened is { "grants": [Object(grant)], .. } else {
      fail("Missing single fixture grant")
    }
    let ends_ms = delayed_body_entered_ms[0] + 250UL
    grant["ends_ms"] = Json::string(ends_ms.to_string())
    @fs.write_file(registry_file, shortened.stringify())
    while @async.now().reinterpret_as_uint64() <= ends_ms + 200UL {
      @async.sleep(10)
    }
    delayed.write(delayed_payload[1:].to_owned())
    assert_eq(delayed.end_request().code, 403)
    ignore(delayed.read_all())
    // Restore the fixture's approved grant for the independent revoke checks.
    @fs.write_file(registry_file, unexpired_registry)
    assert_false(get("", base + "public").1.text().contains("B draft"))
    assert_eq(
      write("owner", "api/program/actions", "revoke-grant", {
        "application_id": application,
        "reason": "QA revoke",
      }).0.code,
      200,
    )
    assert_true(
      @json.parse(get("a", base + "mine").1.text())
      is { "viewer": { "operator": False, .. }, "review_queue": [], .. },
    )
    assert_eq(get("a", base + "images/" + image).0.code, 404)
    assert_eq(get("b", base + "images/" + image).0.code, 200)
    assert_eq(
      write("a", base + "actions", "set-voting-url", { "url": "preview" }).0.code,
      403,
    )
    assert_eq(
      write("a", "api/program/actions", "resume-activity", { "activity_id": id }).0.code,
      403,
    )
  })
}
