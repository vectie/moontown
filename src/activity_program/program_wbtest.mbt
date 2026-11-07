///|
fn fixture_template() -> Json {
  {
    "brief": {
      "id": "legacy-coffee",
      "name": "Legacy",
      "topic": "Coffee",
      "scope": "Reference",
      "possibility_wiki": "moonbook:banxing-coffee-curator",
      "first_person_solution": "Draw",
      "deadline_ms": "200000",
      "benchmark_version": 1,
      "benchmark_materials": [],
      "evaluation_materials": [],
      "rubric": [],
      "published": true,
    },
    "opens_ms": "10000",
    "voting_opens_ms": "210000",
    "voting_closes_ms": "220000",
    "awards_ms": "230000",
    "event_quota": 100,
    "participant_quota": 10,
    "provider_origin": "http://qualified-provider.private:18991",
    "provider_key_file": "/private/provider-token",
    "manager_account_ids": ["legacy-operator"],
    "participant_account_ids": ["legacy-invite"],
    "model": "z-image-turbo",
    "program_template": {
      "template_id": "coffee-image-v1",
      "template_version": "1",
      "book_id": "banxing-coffee-curator",
      "book_version": "1.1.0",
      "curator_profile": "coffee_curator",
      "workflow_id": "z-image-turbo",
      "workflow_version": "1",
      "max_instances": 4,
      "max_total_quota": 12,
      "max_event_quota": 8,
      "max_participant_quota": 4,
      "max_cash_budget_cny": 500,
      "max_grants": 4,
    },
  }
}

///|
async fn fixture_root() -> (String, String) {
  let root = @fs.tmpdir(prefix="activity-program-")
  let template = root + "/template.json"
  @fs.write_file(
    template,
    fixture_template().stringify(),
    create_mode=CreateNew,
    permission=0o600,
  )
  (root, template)
}

///|
fn proposal(intent~ : String = "proposal-once") -> Json {
  {
    "application_id": "",
    "intent": intent,
    "expected_revision": 0,
    "title": "半醒咖啡",
    "topic": "清晨",
    "scope": "原创咖啡插画",
    "audience": "附近的朋友",
    "proposal": "每周收集一次轻松的清晨创作。",
    "prize_plan": "手办、帆布包和咖啡各一份",
    "contact": "private-applicant-contact",
    "cash_budget_cny": 300,
    "requested_instances": 2,
    "requested_total_quota": 10,
    "requested_participant_quota": 3,
  }
}

///|
fn approval(
  id : String,
  allow_publish~ : Bool = true,
  total~ : Int32 = 10,
  cash~ : Int32 = 300,
) -> Json {
  {
    "application_id": id,
    "expected_revision": 2,
    "decision": "approve",
    "note": "按批准额度举办",
    "starts_ms": "1",
    "ends_ms": "1000000",
    "max_instances": 2,
    "total_generation_quota": total,
    "per_event_quota": total.min(8),
    "participant_quota": total.min(3),
    "cash_budget_cny": cash,
    "allow_publish": allow_publish,
  }
}

///|
async fn approved(
  root : String,
  template : String,
  allow_publish~ : Bool = true,
) -> String {
  let saved = execute(
    "save-application",
    proposal(),
    1000UL,
    Some("alice"),
    false,
    root,
    template,
  )
  let id = text(saved, "application_id", 64)
  ignore(
    execute(
      "submit-application",
      { "application_id": id, "expected_revision": 1 },
      1000UL,
      Some("alice"),
      false,
      root,
      template,
    ),
  )
  ignore(
    execute(
      "review-application",
      approval(id, allow_publish~),
      1000UL,
      Some("council"),
      true,
      root,
      template,
    ),
  )
  id
}

///|
fn workbook(
  id : String,
  intent~ : String = "launch-once",
  quota~ : Int32 = 6,
  cash~ : Int32 = 150,
) -> Json {
  {
    "application_id": id,
    "intent": intent,
    "title": "半醒咖啡 · 第一期",
    "topic": "清晨",
    "scope": "围绕咖啡的原创插画",
    "first_person_solution": "我写提示词，生成图片并选一张投稿。",
    "prize_plan": "手办、帆布包、特调咖啡",
    "opens_ms": "10000",
    "deadline_ms": "200000",
    "voting_opens_ms": "210000",
    "voting_closes_ms": "220000",
    "awards_ms": "230000",
    "event_quota": quota,
    "participant_quota": quota.min(3),
    "cash_budget_cny": cash,
  }
}

///|
// Explicit test double. Production must use the real Book import/provider bridge.
async fn fixture_prepare(
  id : String,
  dossier : Json,
  _directory : String,
) -> Json {
  {
    "ready": true,
    "book_id": "moonbook-" + id,
    "book_version": "1.1.0",
    "source_book_id": "banxing-coffee-curator",
    "source_bundle_digest": "sha256:" + hash("fixture-bundle"),
    "launch_digest": "sha256:" + hash(dossier.stringify()),
    "curator_profile": "coffee_curator",
    "profile_digest": "sha256:" + hash("fixture-profile"),
    "agent_state": "configured-not-started",
    "workflow_id": "z-image-turbo",
    "workflow_version": "1",
    "private_path": "/private/book",
    "provider_key": "never-project-this",
  }
}

///|
async test "qualified native MoonBook 1.2 receipt passes full launch validation" {
  let (root, template) = fixture_root()
  defer @fs.rmdir(root, recursive=true)
  let trusted = fixture_template()
  let metadata = fields(fields(trusted).get("program_template").unwrap())
  metadata["book_version"] = Json::string("1.2.0")
  @fs.write_file(template, trusted.stringify(), create_mode=CreateOrTruncate)
  let application = approved(root, template)
  let created = execute(
    "create-activity",
    workbook(application),
    1000UL,
    Some("alice"),
    false,
    root,
    template,
  )
  let id = text(created, "activity_id", 64)
  assert_true(
    process_next(root, template, 1000UL, async fn(_id, _dossier, _path) {
      // Receipt from the real, verified native thin-bundle qualification. It is
      // evidence of configured resources, never evidence of an agent execution.
      {
        "ready": true,
        "book_id": "moonbook-activity-qualification",
        "book_version": "1.2.0",
        "source_book_id": "banxing-coffee-curator",
        "source_bundle_digest": "sha256:0569dd437ba243510127cec012e929b086934a8560dac3c42b6aad890999983f",
        "launch_digest": "sha256:a4e8ac721fe3e455c2efa54e0ea8add26b16c221aa9cc9ae8e08fe60de12f84c",
        "curator_profile": "coffee_curator",
        "profile_digest": "sha256:5d323411560ba5277052dbbcadac3c9f269f96807a0b47371344aaee1269c453",
        "agent_state": "configured-not-started",
        "workflow_id": "z-image-turbo",
        "workflow_version": "1",
      }
    }),
  )
  let activity = find_activity(read_registry(root), id)
  assert_eq(activity.status, "published")
  assert_true(
    clean_binding(activity.binding_json)
    is { "book_version": "1.2.0", "ready": True, .. },
  )
}

///|
async test "partial drafts are private and submission freezes a reviewed revision" {
  let (root, template) = fixture_root()
  defer @fs.rmdir(root, recursive=true)
  let saved = execute(
    "save-application",
    {
      "application_id": "",
      "intent": "draft",
      "expected_revision": 0,
      "title": "First draft",
    },
    1000UL,
    Some("alice"),
    false,
    root,
    template,
  )
  let id = text(saved, "application_id", 64)
  assert_true(
    execute("snapshot", {}, 1000UL, Some("council"), true, root, template)
    is { "applications": [], .. },
  )
  assert_true(
    try {
      ignore(
        execute(
          "submit-application",
          { "application_id": id, "expected_revision": 1 },
          1000UL,
          Some("alice"),
          false,
          root,
          template,
        ),
      )
      false
    } catch {
      Invalid(_) => true
      _ => false
    },
  )
  let changed = fields(proposal())
  changed["application_id"] = Json::string(id)
  changed["expected_revision"] = Json::number(1)
  assert_true(
    try {
      ignore(
        execute(
          "save-application",
          Json::object(changed),
          1000UL,
          Some("bob"),
          false,
          root,
          template,
        ),
      )
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  ignore(
    execute(
      "save-application",
      Json::object(changed),
      1000UL,
      Some("alice"),
      false,
      root,
      template,
    ),
  )
  ignore(
    execute(
      "submit-application",
      { "application_id": id, "expected_revision": 2 },
      1000UL,
      Some("alice"),
      false,
      root,
      template,
    ),
  )
  let review = fields(approval(id))
  review["expected_revision"] = Json::number(3)
  assert_true(
    try {
      ignore(
        execute(
          "review-application",
          Json::object(review),
          1000UL,
          Some("alice"),
          false,
          root,
          template,
        ),
      )
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  ignore(
    execute(
      "review-application",
      Json::object(review),
      1000UL,
      Some("council"),
      true,
      root,
      template,
    ),
  )
  let state = read_registry(root)
  assert_eq(state.grants[0].approved_revision, 3)
  assert_eq(state.grants[0].approved_hash, state.applications[0].submitted_hash)
  assert_true(
    try {
      ignore(
        execute(
          "save-application",
          Json::object(changed),
          1000UL,
          Some("alice"),
          false,
          root,
          template,
        ),
      )
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  assert_true(
    execute("snapshot", {}, 1000UL, Some("bob"), false, root, template)
    is { "applications": [], .. },
  )
}

///|
async test "creation requires approval and reserves aggregate image and cash budgets exactly once" {
  let (root, template) = fixture_root()
  defer @fs.rmdir(root, recursive=true)
  let application = approved(root, template)
  let first = execute(
    "create-activity",
    workbook(application),
    1000UL,
    Some("alice"),
    false,
    root,
    template,
  )
  let id = text(first, "activity_id", 64)
  let repeated = execute(
    "create-activity",
    workbook(application),
    1000UL,
    Some("alice"),
    false,
    root,
    template,
  )
  assert_eq(text(repeated, "activity_id", 64), id)
  assert_eq(read_registry(root).activities.length(), 1)
  assert_eq(fields(first).get("revision"), fields(repeated).get("revision"))
  assert_true(
    try {
      ignore(
        execute(
          "create-activity",
          workbook(application),
          1000UL,
          Some("bob"),
          false,
          root,
          template,
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
        execute(
          "create-activity",
          workbook(application, quota=5),
          1000UL,
          Some("alice"),
          false,
          root,
          template,
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
        execute(
          "create-activity",
          workbook(application, intent="too-many-images"),
          1000UL,
          Some("alice"),
          false,
          root,
          template,
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
        execute(
          "create-activity",
          workbook(application, intent="too-much-cash", quota=4, cash=200),
          1000UL,
          Some("alice"),
          false,
          root,
          template,
        ),
      )
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  ignore(
    execute(
      "create-activity",
      workbook(application, intent="second-week", quota=4),
      1000UL,
      Some("alice"),
      false,
      root,
      template,
    ),
  )
  assert_eq(read_registry(root).activities.length(), 2)
  assert_true(
    execute("snapshot", {}, 1000UL, Some("alice"), false, root, template)
    is {
      "applications": [
        {
          "grant": {
            "remaining_generation_quota": Number(0, ..),
            "remaining_cash_budget_cny": Number(0, ..),
            ..
          },
          ..
        },
      ],
      ..
    },
  )
}

///|
async test "bridge failures remain private and retry resumes the same reservation" {
  let (root, template) = fixture_root()
  defer @fs.rmdir(root, recursive=true)
  let app = approved(root, template)
  let id = text(
    execute(
      "create-activity",
      workbook(app),
      1000UL,
      Some("alice"),
      false,
      root,
      template,
    ),
    "activity_id",
    64,
  )
  assert_true(
    process_next(root, template, 1000UL, (_id, _dossier, _path) => {
      "ready": false,
    }),
  )
  assert_eq(read_registry(root).activities[0].status, "failed")
  assert_true(
    execute("snapshot", {}, 1000UL, None, false, root, template)
    is { "activities": [], "applications": [], .. },
  )
  assert_true(
    try {
      ignore(
        execute(
          "retry-activity",
          { "activity_id": id },
          1000UL,
          Some("bob"),
          false,
          root,
          template,
        ),
      )
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  ignore(
    execute(
      "retry-activity",
      { "activity_id": id },
      1000UL,
      Some("alice"),
      false,
      root,
      template,
    ),
  )
  assert_true(
    process_next(root, template, 1000UL, (_id, _dossier, _path) => {
      "ready": true,
    }),
  )
  assert_eq(read_registry(root).activities[0].status, "failed")
  ignore(
    execute(
      "retry-activity",
      { "activity_id": id },
      1000UL,
      Some("alice"),
      false,
      root,
      template,
    ),
  )
  assert_true(process_next(root, template, 1000UL, fixture_prepare))
  let state = read_registry(root)
  assert_eq(state.activities.length(), 1)
  assert_eq(state.activities[0].status, "published")
  assert_eq(state.activities[0].prepare_attempts, 3)
  let public = execute("snapshot", {}, 1000UL, None, false, root, template).stringify()
  for
    forbidden in [
      "private-applicant-contact", "provider_origin", "provider_key_file", "never-project-this",
      "/private/book", "template_json",
    ] {
    assert_false(public.contains(forbidden))
  }
  let config = @json.parse(
    @fs.read_file(root + "/activities/" + id + "/config.json").text(),
  )
  assert_true(
    config is { "manager_account_ids": [], "voting_mode": "builtin", .. },
  )
  assert_false(fields(config).contains("participant_account_ids"))
}

///|
async test "fresh runtime gates stop old organizer sessions and preserve read and withdrawal access" {
  let (root, template) = fixture_root()
  defer @fs.rmdir(root, recursive=true)
  let app = approved(root, template)
  let id = text(
    execute(
      "create-activity",
      workbook(app),
      1000UL,
      Some("alice"),
      false,
      root,
      template,
    ),
    "activity_id",
    64,
  )
  assert_true(process_next(root, template, 1000UL, fixture_prepare))
  with_activity(id, 1000UL, Some("alice"), false, "approve", root, binding => {
    assert_true(binding.may_manage)
    assert_true(binding.allow_generation)
  })
  with_activity(id, 1000001UL, None, false, "snapshot", root, binding => {
    assert_false(binding.may_manage)
    assert_false(binding.allow_generation)
  })
  for mode in ["generate", "submit", "approve"] {
    assert_true(
      try {
        with_activity(id, 1000001UL, Some("alice"), false, mode, root, _ => ())
        false
      } catch {
        Denied => true
        _ => false
      },
    )
  }
  with_activity(id, 1000001UL, Some("council"), true, "approve", root, binding => {
    assert_true(binding.may_manage)
    assert_false(binding.allow_generation)
  })
  assert_true(
    try {
      with_activity(id, 1000UL, Some("bob"), false, "approve", root, _ => ())
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  ignore(
    execute(
      "pause-activity",
      { "activity_id": id },
      1000UL,
      Some("alice"),
      false,
      root,
      template,
    ),
  )
  with_activity(id, 1000UL, None, false, "public", root, binding => {
    assert_false(binding.allow_generation)
  })
  with_activity(id, 1000UL, None, false, "worker", root, binding => {
    assert_false(binding.allow_generation)
  })
  assert_true(
    try {
      with_activity(id, 1000UL, Some("bob"), false, "generate", root, _ => ())
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  ignore(
    execute(
      "resume-activity",
      { "activity_id": id },
      1000UL,
      Some("alice"),
      false,
      root,
      template,
    ),
  )
  assert_true(
    try {
      ignore(
        execute(
          "revoke-grant",
          { "application_id": app, "reason": "撤销" },
          1000UL,
          Some("alice"),
          false,
          root,
          template,
        ),
      )
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  ignore(
    execute(
      "revoke-grant",
      { "application_id": app, "reason": "额度复核" },
      1000UL,
      Some("council"),
      true,
      root,
      template,
    ),
  )
  assert_true(
    try {
      with_activity(id, 1000UL, Some("alice"), false, "approve", root, _ => ())
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  with_activity(id, 1000UL, Some("alice"), false, "snapshot", root, binding => {
    assert_false(binding.may_manage)
  })
  with_activity(id, 1000UL, Some("alice"), false, "withdraw", root, _ => ())
  with_activity(id, 1000UL, Some("council"), true, "disqualify", root, binding => {
    assert_true(binding.may_manage)
  })
  assert_true(
    try {
      with_activity(id, 1000UL, Some("council"), true, "generate", root, _ => ())
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  assert_true(
    try {
      ignore(
        execute(
          "resume-activity",
          { "activity_id": id },
          1000UL,
          Some("council"),
          true,
          root,
          template,
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
async test "ready previews require owner publication and revoked unpublished drafts do not become public" {
  let (root, template) = fixture_root()
  defer @fs.rmdir(root, recursive=true)
  let app = approved(root, template, allow_publish=false)
  let id = text(
    execute(
      "create-activity",
      workbook(app),
      1000UL,
      Some("alice"),
      false,
      root,
      template,
    ),
    "activity_id",
    64,
  )
  assert_true(process_next(root, template, 1000UL, fixture_prepare))
  assert_eq(read_registry(root).activities[0].status, "ready")
  assert_true(
    execute("snapshot", {}, 1000UL, None, false, root, template)
    is { "activities": [], .. },
  )
  assert_true(
    try {
      ignore(
        execute(
          "publish-activity",
          { "activity_id": id },
          1000UL,
          Some("alice"),
          false,
          root,
          template,
        ),
      )
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  ignore(
    execute(
      "revoke-grant",
      { "application_id": app, "reason": "取消发布" },
      1000UL,
      Some("council"),
      true,
      root,
      template,
    ),
  )
  assert_true(
    execute("snapshot", {}, 1000UL, None, false, root, template)
    is { "activities": [], .. },
  )
}

///|
async test "global approval pool and expiry cannot be reset by revocation or retries" {
  let (root, template) = fixture_root()
  defer @fs.rmdir(root, recursive=true)
  let app = approved(root, template)
  let bob = text(
    execute(
      "save-application",
      proposal(intent="bob-proposal"),
      1000UL,
      Some("bob"),
      false,
      root,
      template,
    ),
    "application_id",
    64,
  )
  ignore(
    execute(
      "submit-application",
      { "application_id": bob, "expected_revision": 1 },
      1000UL,
      Some("bob"),
      false,
      root,
      template,
    ),
  )
  assert_true(
    try {
      ignore(
        execute(
          "review-application",
          approval(bob, total=3, cash=100),
          1000UL,
          Some("council"),
          true,
          root,
          template,
        ),
      )
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  ignore(
    execute(
      "revoke-grant",
      { "application_id": app, "reason": "更换方案" },
      1000UL,
      Some("council"),
      true,
      root,
      template,
    ),
  )
  assert_true(
    try {
      ignore(
        execute(
          "review-application",
          approval(bob, total=3, cash=100),
          1000UL,
          Some("council"),
          true,
          root,
          template,
        ),
      )
      false
    } catch {
      Conflict(_) => true
      _ => false
    },
  )
  ignore(
    execute(
      "review-application",
      approval(bob, total=2, cash=100),
      1000UL,
      Some("council"),
      true,
      root,
      template,
    ),
  )
  assert_true(
    try {
      ignore(
        execute(
          "create-activity",
          workbook(bob, quota=2, cash=0),
          1000001UL,
          Some("bob"),
          false,
          root,
          template,
        ),
      )
      false
    } catch {
      Denied => true
      _ => false
    },
  )
  assert_eq(read_registry(root).grants.length(), 2)
}

///|
async test "an owner can publish a resource-ready preview without delegating self-publication" {
  let (root, template) = fixture_root()
  defer @fs.rmdir(root, recursive=true)
  let app = approved(root, template, allow_publish=false)
  let id = text(
    execute(
      "create-activity",
      workbook(app),
      1000UL,
      Some("alice"),
      false,
      root,
      template,
    ),
    "activity_id",
    64,
  )
  assert_true(process_next(root, template, 1000UL, fixture_prepare))
  assert_true(
    execute("snapshot", {}, 1000UL, Some("alice"), false, root, template)
    is { "activities": [{ "may_publish": False, .. }], .. },
  )
  assert_true(
    execute("snapshot", {}, 1000UL, Some("council"), true, root, template)
    is { "activities": [{ "may_publish": True, .. }], .. },
  )
  ignore(
    execute(
      "publish-activity",
      { "activity_id": id },
      1000UL,
      Some("council"),
      true,
      root,
      template,
    ),
  )
  assert_true(
    execute("snapshot", {}, 1000UL, None, false, root, template)
    is { "activities": [{ "id": String(public_id), .. }], .. } &&
    public_id == id,
  )
  let revision = read_registry(root).revision
  assert_eq(
    text(
      execute(
        "create-activity",
        workbook(app),
        1000001UL,
        Some("alice"),
        false,
        root,
        template,
      ),
      "activity_id",
      64,
    ),
    id,
  )
  assert_eq(read_registry(root).revision, revision)
}

///|
async test "control gates linearize revocation without blocking independent snapshot reads" {
  let (root, template) = fixture_root()
  defer @fs.rmdir(root, recursive=true)
  let app = approved(root, template)
  let gate = gate_lock(root, app)
  defer gate.close()
  let complete = Ref(false)
  @async.with_task_group(group => {
    let revoke = group.spawn(() => {
      ignore(
        execute(
          "revoke-grant",
          { "application_id": app, "reason": "并发撤销" },
          1000UL,
          Some("council"),
          true,
          root,
          template,
        ),
      )
      complete.val = true
    })
    @async.sleep(10)
    assert_false(complete.val)
    ignore(
      @async.with_timeout(1000, () => {
        execute("snapshot", {}, 1000UL, Some("alice"), false, root, template)
      }),
    )
    gate.unlock()
    revoke.wait()
    assert_true(complete.val)
  })
}
