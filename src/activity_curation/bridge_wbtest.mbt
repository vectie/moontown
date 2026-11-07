///|
fn fixture_preset() -> Preset {
  {
    template_id: "coffee-image-v1",
    template_version: "1",
    book_cli: "/not-configured/book",
    book_cli_sha256: "sha256:a",
    book_cli_cwd: "/not-configured/runtime",
    bundle_path: "/not-configured/bundle",
    bundle_file_sha256: "sha256:b",
    bundle_digest: "sha256:c",
    source_book_id: "banxing-coffee-curator",
    book_version: "1.2.0",
    curator_profile: "coffee_curator",
    workflow_id: "z-image-turbo",
    workflow_version: "1",
  }
}

///|
fn fixture_dossier() -> Json {
  {
    "schema": "moontown.activity-launch.v1",
    "activity_id": "activity-qualification",
    "application_id": "application-qualification",
    "approved_revision": 1,
    "approved_hash": "owner-reviewed-qualification-only",
    "organizer_id": "isolated-host",
    "template_id": "coffee-image-v1",
    "template_version": "1",
    "title": "策展桥接资格验证",
    "topic": "半醒咖啡",
    "scope": "仅验证真实导入；不发布比赛，不调用推理",
    "first_person_solution": "我检查落地书、来源和受限策展 profile",
    "prize_plan": "没有真实奖项或奖品",
    "opens_ms": "1",
    "deadline_ms": "2",
    "voting_opens_ms": "3",
    "voting_closes_ms": "4",
    "awards_ms": "5",
    "event_quota": 1,
    "participant_quota": 1,
    "model": "z-image-turbo",
    "book_id": "banxing-coffee-curator",
    "book_version": "1.2.0",
    "curator_profile": "coffee_curator",
    "workflow_id": "z-image-turbo",
    "workflow_version": "1",
  }
}

///|
test "canonical approved content binds meaning and rejects traversal identifiers" {
  assert_eq(
    json_digest({ "b": 2, "a": { "z": 1, "x": 2 } }),
    json_digest({ "a": { "x": 2, "z": 1 }, "b": 2 }),
  )
  assert_true(safe_id("activity-0123_ab"))
  for id in ["../x", "x/y", "/tmp", "x\\y", "", "x y"] {
    assert_false(safe_id(id))
  }
  for path in ["../x", "/tmp/x", "a/../x", "a//b", "a\\b", "C:/x"] {
    assert_false(relative_file(path))
  }
  assert_true(relative_file("portable/outputs/brand/半醒.png"))
}

///|
test "approved preset cannot silently switch workflow or source Book" {
  let dossier = fixture_dossier()
  validate_dossier("activity-qualification", dossier, fixture_preset())
  assert_true(
    try {
      validate_dossier("activity-qualification", dossier, {
        ..fixture_preset(),
        workflow_version: "other",
      })
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      validate_dossier("activity-qualification", dossier, {
        ..fixture_preset(),
        source_book_id: "other-book",
      })
      false
    } catch {
      _ => true
    },
  )
}

///|
test "curator is a bounded analysis profile without privileged tools or automatic execution" {
  let dossier = fixture_dossier()
  let profile = restricted_profile(
    { "role": "worker", "steps": [{ "kind": "job.delegate" }] },
    dossier,
    json_digest(dossier),
  )
  assert_true(
    profile
    is {
      "steps": [
        {
          "kind": String("job.analysis"),
          "metadata": {
            "enable_tools": False,
            "web_search": False,
            "max_total_tokens": Number(3000, ..),
            "timeout_ms": Number(120000, ..),
            ..
          },
          ..
        },
      ],
      "metadata": {
        "can_publish": False,
        "can_change_budget": False,
        "requires_review": True,
        ..
      },
      ..
    },
  )
  assert_false(profile.stringify().contains("job.delegate"))
  assert_true(object(profile).get("match") is None)
  assert_true(object(profile).get("execution_target") is None)
}

///|
async test "same approval intent resumes, changed content and tampered seed members fail closed" {
  let root = @fs.tmpdir(prefix="activity-curation-test-")
  defer @fs.rmdir(root, recursive=true)
  put_once(root + "/intent.json", "approved")
  put_once(root + "/intent.json", "approved")
  assert_true(
    try {
      put_once(root + "/intent.json", "different")
      false
    } catch {
      _ => true
    },
  )
  @fs.mkdir(root + "/skills")
  @fs.write_file(root + "/skills/example.md", "expected", create_mode=CreateNew)
  let bundle : Json = {
    "files": [
      {
        "path": "skills/example.md",
        "digest": digest(@utf8.encode("expected")),
      },
    ],
  }
  check_members(root, bundle)
  @fs.write_file(root + "/skills/example.md", "changed")
  assert_true(
    try {
      check_members(root, bundle)
      false
    } catch {
      _ => true
    },
  )
}

///|
/// Opt-in qualification with the actual Book CLI and real preset. No model runs.
async test "real MoonBook curation qualification when explicitly configured" {
  guard @env.get_env_var("MOONTOWN_CURATION_QUALIFY_PRESET") is Some(preset) &&
    @env.get_env_var("MOONTOWN_CURATION_QUALIFY_TEMPLATE") is Some(template) &&
    @env.get_env_var("MOONTOWN_CURATION_QUALIFY_ROOT") is Some(root) else {
    return
  }
  let dossier = fixture_dossier()
  let first = prepare_from_config(
    "activity-qualification", dossier, root, preset, template,
  )
  let second = prepare_from_config(
    "activity-qualification", dossier, root, preset, template,
  )
  assert_eq(first, second)
  assert_true(
    first
    is { "ready": True, "agent_state": String("configured-not-started"), .. },
  )
  @fs.write_file(
    root + "/qualification-result.json",
    first.stringify(indent=2),
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  guard dossier is Object(fields) else { fail("Invalid qualification dossier") }
  fields["title"] = Json::string("Changed approval")
  assert_true(
    try {
      ignore(
        prepare_from_config(
          "activity-qualification", dossier, root, preset, template,
        ),
      )
      false
    } catch {
      _ => true
    },
  )
}
