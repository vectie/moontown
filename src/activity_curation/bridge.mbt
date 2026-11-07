///|
async fn command(
  cli : String,
  args : Array[String],
  cwd : String,
  stage : String,
) -> String {
  let result = @async.with_timeout(60000, () => {
    @integration.run(cli, args, cwd=Some(cwd))
  })
  guard result.status == 0 else {
    // Upstream output can contain private host paths. Keep it out of API errors.
    fail("MoonBook " + stage + " did not complete")
  }
  result.stdout
}

///|
async fn fixed_file(path : String, expected : String) -> Unit {
  guard path.has_prefix("/") &&
    expected.has_prefix("sha256:") &&
    expected.length() == 71 &&
    digest(@fs.read_file(path).binary()) == expected else {
    fail("The deployed curation preset failed its immutable file check")
  }
}

///|
async fn require_regular(path : String) -> Unit {
  guard @fs.kind(path, follow_symlink=false) == Regular else {
    fail("The activity curation destination is not a regular file")
  }
}

///|
async fn ensure_directories(base : String, relative : String) -> Unit {
  let mut current = base
  for part in relative.split("/") {
    current += "/" + part.to_owned()
    if @fs.exists(current) {
      guard @fs.kind(current, follow_symlink=false) == Directory else {
        fail("The activity curation directory has been replaced")
      }
    } else {
      @fs.mkdir(current, permission=0o700)
    }
  }
}

///|
async fn put_once(path : String, value : String) -> Unit {
  if @fs.exists(path) {
    require_regular(path)
    guard @fs.read_file(path).text() == value else {
      fail(
        "Existing activity curation content differs from the approved launch",
      )
    }
  } else {
    @fs.write_file(
      path,
      value,
      create_mode=CreateNew,
      permission=0o600,
      sync=Full,
    )
  }
}

///|
async fn check_bundle(preset : Preset) -> Json {
  fixed_file(preset.bundle_path, preset.bundle_file_sha256)
  let bundle = @json.parse(@fs.read_file(preset.bundle_path).text())
  guard bundle
    is {
      "agent_id": String(agent_id),
      "version": String(version),
      "bundle_digest": String(bundle_digest),
      "files": Array(files),
      ..
    } &&
    agent_id == preset.source_book_id &&
    version == preset.book_version &&
    bundle_digest == preset.bundle_digest &&
    files.length() > 0 &&
    files.length() <= 256 else {
    fail("The installed MoonBook bundle identity does not match the preset")
  }
  for item in files {
    let path = string_field(item, "path")
    guard relative_file(path) &&
      ![
        "moonclaw.jobs.json", "wiki/index.md", "wiki/log.md", "wiki/planning/activity-launch.md",
        "plans/activity-launch/approved-workbook.json",
      ].contains(path) else {
      fail("The preset overlaps activity-owned curation files")
    }
  }
  bundle
}

///|
async fn check_members(book : String, bundle : Json) -> Unit {
  guard object(bundle).get("files") is Some(Array(files)) else {
    fail("Missing bundle members")
  }
  for item in files {
    let relative = string_field(item, "path")
    guard relative_file(relative) else { fail("Unsafe preset member") }
    let segments = relative.split("/").to_array()
    let mut current = book
    for index, part in segments {
      current += "/" + part.to_owned()
      guard @fs.kind(current, follow_symlink=false) ==
        (if index + 1 == segments.length() { Regular } else { Directory }) else {
        fail("An imported Book member has been replaced or is incomplete")
      }
    }
    guard digest(@fs.read_file(current).binary()) ==
      string_field(item, "digest") else {
      fail("An imported Book member no longer matches the approved preset")
    }
  }
}

///|
async fn append_if_missing(
  path : String,
  marker : String,
  content : String,
) -> Unit {
  let current = if @fs.exists(path) {
    require_regular(path)
    @fs.read_file(path).text()
  } else {
    ""
  }
  if !current.contains(marker) {
    @fs.write_file(
      path,
      current + "\n" + content + "\n",
      create_mode=CreateOrTruncate,
      permission=0o600,
      sync=Full,
    )
  }
}

///|
/// Import an actual MoonBook, verify its baseline bytes, and prepare its bounded
/// MoonClaw profile. The activity root and preset are server-owned arguments.
/// A successful result never means that an agent job or model has been run.
pub async fn prepare_from_config(
  activity_id : String,
  dossier : Json,
  activity_root : String,
  preset_path : String,
  template_path : String,
) -> Json {
  guard activity_root.has_prefix("/") &&
    preset_path.has_prefix("/") &&
    @fs.kind(activity_root, follow_symlink=false) == Directory else {
    fail("The activity workspace must be a deployment-owned directory")
  }
  let preset : Preset = @json.from_json(
    @json.parse(@fs.read_file(preset_path).text()),
  )
  validate_dossier(activity_id, dossier, preset)
  guard preset.book_cli_cwd.has_prefix("/") &&
    @fs.kind(preset.book_cli_cwd, follow_symlink=false) == Directory else {
    fail("The deployed MoonBook seed runtime is missing")
  }
  provider_ready(template_path, dossier)
  fixed_file(preset.book_cli, preset.book_cli_sha256)
  let lock_path = activity_root + "/.curation.lock"
  if @fs.exists(lock_path) {
    require_regular(lock_path)
  }
  let lock = @fs.open(
    lock_path,
    mode=ReadWrite,
    create_mode=OpenOrCreate,
    permission=0o600,
  )
  lock.lock(Exclusive)
  defer lock.close()
  defer lock.unlock()
  let launch_digest = json_digest(dossier)
  let identity : Json = {
    "schema": "moontown.activity-curation.intent.v1",
    "activity_id": activity_id,
    "launch_digest": launch_digest,
    "source_bundle_digest": preset.bundle_digest,
    "bundle_file_sha256": preset.bundle_file_sha256,
  }
  put_once(
    activity_root + "/curation-intent.json",
    canonical(identity).stringify(),
  )
  // Do not retain the 68 MiB parsed package while the Book child imports it.
  fixed_file(preset.bundle_path, preset.bundle_file_sha256)
  let book_id = "moonbook-" + activity_id
  let book = activity_root + "/" + book_id
  let ready_path = activity_root + "/curation-ready.json"
  if !@fs.exists(book) {
    let verified = @json.parse(
      command(
        preset.book_cli,
        ["agent", "verify", preset.bundle_path],
        preset.book_cli_cwd,
        "preset verification",
      ),
    )
    guard verified
      is {
        "ok": True,
        "agent_id": String(agent_id),
        "version": String(version),
        "bundle_digest": String(bundle_digest),
        ..
      } &&
      agent_id == preset.source_book_id &&
      version == preset.book_version &&
      bundle_digest == preset.bundle_digest else {
      fail("MoonBook rejected the installed preset")
    }
    ignore(
      command(
        preset.book_cli,
        ["agent", "import", preset.bundle_path, book],
        preset.book_cli_cwd,
        "import",
      ),
    )
  } else {
    guard @fs.kind(book, follow_symlink=false) == Directory &&
      @fs.kind(book + "/book.toml", follow_symlink=false) == Regular &&
      @fs.kind(book + "/wiki.toml", follow_symlink=false) == Regular else {
      fail("An incomplete curation import needs operator inspection")
    }
    // Only the same unexposed, intent-owned partial import may be resumed.
    if !@fs.exists(ready_path) {
      let complete = try {
        check_members(book, check_bundle(preset))
        true
      } catch {
        _ => false
      }
      if !complete {
        ignore(
          command(
            preset.book_cli,
            ["agent", "upgrade", preset.bundle_path, book],
            preset.book_cli_cwd,
            "partial import recovery",
          ),
        )
      }
    }
  }
  check_members(book, check_bundle(preset))
  let installation = @json.parse(
    @fs.read_file(book + "/state/agent-installation.json").text(),
  )
  guard installation
    is {
      "agent_id": String(agent),
      "version": String(version),
      "bundle_digest": String(installed_digest),
      ..
    } &&
    agent == preset.source_book_id &&
    version == preset.book_version &&
    installed_digest == preset.bundle_digest else {
    fail("MoonBook installation receipt is missing or does not match")
  }
  ensure_directories(book, "plans/activity-launch")
  ensure_directories(book, "wiki/planning")
  put_once(
    book + "/plans/activity-launch/approved-workbook.json",
    canonical(dossier).stringify(indent=2) + "\n",
  )
  put_once(
    book + "/wiki/planning/activity-launch.md",
    "# 已批准活动落地书\n\n活动：" +
    string_field(dossier, "title") +
    "\n\n本页是当前活动的权威上下文；种子书的旧赛程只是历史参考。\n\n批准内容摘要：`" +
    launch_digest +
    "`。策展助手只生成草案，不能批准、发布、加预算或采购。\n\n```json\n" +
    canonical(dossier).stringify(indent=2) +
    "\n```\n",
  )
  append_if_missing(
    book + "/wiki/index.md",
    "planning/activity-launch.md",
    "- [本活动已批准落地书](planning/activity-launch.md)",
  )
  append_if_missing(
    book + "/wiki/log.md",
    launch_digest,
    "活动落地书已建立：" +
    activity_id +
    " · " +
    launch_digest +
    "。完成原生 MoonBook 导入与成员校验；配置受限 profile，未启动模型任务。",
  )
  let source = @json.parse(
    @fs.read_file(book + "/skills/coffee-curator/references/moonclaw.jobs.json").text(),
  )
  guard source is { "jobs": { "profiles": Object(profiles), .. }, .. } &&
    profiles.get(preset.curator_profile) is Some(seed) else {
    fail("The preset curator profile is missing")
  }
  let profile = restricted_profile(seed, dossier, launch_digest)
  let host_path = book + "/moonclaw.jobs.json"
  let host = if @fs.exists(host_path) {
    require_regular(host_path)
    @json.parse(@fs.read_file(host_path).text())
  } else {
    Json::object({})
  }
  let host_fields = object(host)
  let jobs = object(host_fields.get("jobs").unwrap_or(Json::object({})))
  let host_profiles = object(jobs.get("profiles").unwrap_or(Json::object({})))
  if host_profiles.get(preset.curator_profile) is Some(existing) {
    guard canonical(existing) == canonical(profile) else {
      fail("The installed curator profile has changed")
    }
  } else {
    host_profiles[preset.curator_profile] = profile
    jobs["profiles"] = Json::object(host_profiles)
    host_fields["jobs"] = Json::object(jobs)
    @fs.write_file(
      host_path,
      Json::object(host_fields).stringify(indent=2),
      create_mode=CreateOrTruncate,
      permission=0o600,
      sync=Full,
    )
  }
  let result : Json = {
    "ready": true,
    "book_id": book_id,
    "book_version": preset.book_version,
    "source_book_id": preset.source_book_id,
    "source_bundle_digest": preset.bundle_digest,
    "launch_digest": launch_digest,
    "curator_profile": preset.curator_profile,
    "profile_digest": json_digest(profile),
    "agent_state": "configured-not-started",
    "workflow_id": preset.workflow_id,
    "workflow_version": preset.workflow_version,
  }
  put_once(ready_path, canonical(result).stringify())
  provider_ready(template_path, dossier)
  result
}

///|
async fn provider_ready(template_path : String, dossier : Json) -> Unit {
  guard template_path.has_prefix("/") else {
    fail("The approved activity model is not configured")
  }
  let config = @creative_contest.load_config(template_path)
  guard !config.provider_origin.is_empty() &&
    config.model == string_field(dossier, "model") else {
    fail("The approved model route does not match this activity")
  }
  @async.with_timeout(5000, () => {
    let (response, body) = @http.get(config.provider_origin + "/health")
    guard response.code == 200 &&
      @json.parse(body.text())
      is {
        "status": String("ok"),
        "component": String("qualified-image-adapter"),
        ..
      } else {
      fail("The qualified image adapter is not ready")
    }
  })
}

///|
/// Only deployment configuration selects the preset, model endpoint and paths.
pub async fn prepare(
  activity_id : String,
  dossier : Json,
  activity_root : String,
) -> Json {
  guard @env.get_env_var("MOONTOWN_ACTIVITY_CURATION_PRESET_FILE")
    is Some(preset) &&
    @env.get_env_var("MOONTOWN_ACTIVITY_TEMPLATE_CONFIG_FILE") is Some(template) else {
    fail("Activity curation is not configured by the platform")
  }
  prepare_from_config(activity_id, dossier, activity_root, preset, template)
}
