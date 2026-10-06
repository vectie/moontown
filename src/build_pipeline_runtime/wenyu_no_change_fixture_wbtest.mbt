///|
fn wenyu_test_field(value : Json, key : String) -> Json {
  match value {
    Object(fields) => fields.get(key).unwrap_or(Json::null())
    _ => Json::null()
  }
}

///|
fn wenyu_test_set(value : Json, key : String, replacement : Json) -> Unit {
  if value is Object(fields) {
    fields[key] = replacement
  }
}

///|
fn wenyu_test_rows(value : Json, key : String) -> Array[Json] {
  match wenyu_test_field(value, key) {
    Array(rows) => rows
    _ => []
  }
}

///|
fn wenyu_test_restore_env(key : String, old : String?) -> Unit {
  match old {
    Some(value) => @env.set_env_var(key, value)
    None => @env.unset_env_var(key)
  }
}

///|
// Only a disposable /tmp synthetic repository is initialized and committed.
// No remote is configured and no user source history is changed.
async fn wenyu_launch_fixture(
  allow_no_change? : Bool = true,
  execution? : String = "native",
  kind? : String = "code-patch",
) -> WenyuLaunch {
  let root = @fs.tmpdir(prefix="wenyu-no-change-launch-")
  let source = root + "/source"
  let book = root + "/suite/books/wenyu"
  @fs.mkdir(source)
  @fs.mkdir(book, recursive=true)
  @fs.mkdir(root + "/home")
  let home_before = @env.get_env_var("HOME")
  let source_before = @env.get_env_var("MOONTOWN_WORKSPACE_ROOT")
  let suite_before = @env.get_env_var("MOONTOWN_SUITE_ROOT")
  let common_before = @env.get_env_var("MOONSUITE_ROOT")
  defer wenyu_test_restore_env("HOME", home_before)
  defer wenyu_test_restore_env("MOONTOWN_WORKSPACE_ROOT", source_before)
  defer wenyu_test_restore_env("MOONTOWN_SUITE_ROOT", suite_before)
  defer wenyu_test_restore_env("MOONSUITE_ROOT", common_before)
  @env.set_env_var("HOME", root + "/home")
  @env.set_env_var("MOONTOWN_WORKSPACE_ROOT", source)
  @env.set_env_var("MOONTOWN_SUITE_ROOT", root + "/suite")
  @env.set_env_var("MOONSUITE_ROOT", root + "/suite")
  @support.write_text_file(source + "/moon.mod", "name = \"vectie/moontown\"\n")
  @support.write_text_file(
    source + "/source.mbt",
    "///|\npub fn existing_answer() -> Int { 42 }\n",
  )
  ignore(@integration.run_checked("git", ["-C", source, "init"]))
  ignore(
    @integration.run_checked("git", [
      "-C", source, "add", "moon.mod", "source.mbt",
    ]),
  )
  ignore(
    @integration.run_checked("git", [
      "-C", source, "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
      "commit", "-m", "Synthetic baseline",
    ]),
  )
  for
    relative in [
      "raw/bootstrap/WENYU_VALLEY_PRD.md", "raw/bootstrap/deep-report.md", "raw/bootstrap/evidence-matrix.md",
    ] {
    @support.write_text_file(
      book + "/" + relative,
      "Synthetic existing behavior context: " + relative + "\n",
    )
  }
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu",
    name="Wenyu fixture",
    purpose="Synthetic code validation",
    workspace_root=book,
  )
  let catalog = root + "/catalog.json"
  @moonbook.save_catalog_file(catalog, [entry])
  let task = @moonbook.BookTask::new(
    id="task",
    title="Validate existing answer",
    kind~,
    prompt="Build the requested behavior: existing_answer returns 42",
    priority=1,
    requires_review=true,
    target_pages=["build/CODE_PATCH.md", "build/TEST_RESULTS.md"],
  )
  freeze_wenyu_launch(
    entry,
    task,
    "goal",
    "Existing answer",
    execution~,
    allow_no_change~,
    native_path=root + "/native.json",
    catalog_path=catalog,
  )
}

///|
fn wenyu_journey_event(
  work : @native_work.Work,
  id : String,
  tool : String,
  metadata : Json,
  sequence : Int,
) -> Json {
  let reservation = work.reservation.unwrap()
  {
    "id": id,
    "journal_sequence": sequence.to_string(),
    "source": "moonclaw-native-tool-exec",
    "protocol": "mooncode.v1",
    "session_id": reservation.session_id,
    "command_id": reservation.command_id,
    "book_root": reservation.execution_root,
    "tool": tool,
    "tool_result": {
      "tool": tool,
      "ok": true,
      "is_error": false,
      "metadata": metadata,
    },
  }
}

///|
fn wenyu_journey_evidence(
  work : @native_work.Work,
  journal : Array[Json],
) -> Json {
  let refs : Array[String] = ["source-read"]
  let claims : Array[Json] = []
  journal.push(
    wenyu_journey_event(
      work,
      "source-read",
      "read",
      { "path": "source.mbt" },
      1,
    ),
  )
  for index, command in wenyu_validation_commands() {
    let id = "check-" + (index + 1).to_string()
    refs.push(id)
    claims.push({ "id": id, "event_id": id })
    journal.push(
      wenyu_journey_event(
        work,
        id,
        "shell",
        {
          "cmd": command,
          "cwd": ".",
          "exit_code": 0,
          "run_id": "injected-run-" + id,
          "approval_id": "injected-approval-" + id,
          "execution_sandbox_policy": "grant-bound",
          "sandbox_evidence": {
            "command_digest": @native_work.digest(command),
            "cleanup_verified": true,
            "fixture_injected": true,
            "enforcement": "Degraded",
            "requested_policy": { "enforcement_requirement": "AllowDegraded" },
          },
        },
        index + 2,
      ),
    )
  }
  let proposal : Json = {
    "reason": "already_satisfied",
    "observation": "Inspection found existing_answer already returns 42; human product review remains required",
    "evidence_refs": refs,
  }
  journal.push(
    wenyu_journey_event(
      work,
      "checkpoint",
      "checkpoint",
      {
        "all_done": true,
        "checkpoint": {
          "completion_outcome": "no_change",
          "no_change": proposal,
          "milestones": [
            { "id": "scope", "status": "done", "evidence_kind": "read" },
            {
              "id": "implementation",
              "status": "done",
              "evidence_kind": "mutation",
              "resolution": "already_satisfied",
            },
            { "id": "verification", "status": "done", "evidence_kind": "test" },
            { "id": "build", "status": "done", "evidence_kind": "build" },
          ],
        },
      },
      8,
    ),
  )
  let answer = (
    {
      "contract": work.request.output_contract,
      "work_id": work.id,
      "book_id": work.request.book_id,
      "task_id": "task",
      "goal_id": "goal",
      "outcome": "no_change",
      "summary": "No net source change; required checks passed",
      "behavior": "existing_answer already returns 42",
      "residual_risks": ["Original-task acceptance remains unevaluated"],
    } : Json).stringify()
  let finish : Json = {
    "answer": answer,
    "completion_outcome": "no_change",
    "no_change": proposal,
  }
  journal.push(wenyu_journey_event(work, "finish", "finish", finish, 9))
  let reservation = work.reservation.unwrap()
  {
    "protocol": "mooncode.v1",
    "status": "runtime-completed",
    "journal_sequence": "100",
    "owner": "moonclaw",
    "session_id": reservation.session_id,
    "command_id": reservation.command_id,
    "book_root": reservation.execution_root,
    "command": @json.parse(reservation.request_body) catch {
      _ => Json::null()
    },
    "execution": {
      "completion_verdict": {
        "kind": "mooncode-coding-completion-verdict",
        "accepted": true,
        "completion_contract": "mooncode.completion-outcome.v1",
        "completion_outcome": "no_change",
        "acceptance_scope": "engineering_only",
        "original_task_acceptance": "unevaluated",
        "no_change": proposal,
        "required_check_evidence": claims,
      },
      "tool_results": [
        {
          "tool": "finish",
          "accepted": true,
          "result": { "is_error": false, "metadata": finish },
        },
      ],
    },
  }
}

///|
async fn wenyu_journey_completed(launch : WenyuLaunch) -> @native_work.Work {
  let path = launch.native_path
  let queued = @native_work.enqueue(launch.request, path~)
  let posted : Array[String] = []
  let journal : Array[Json] = []
  let receipts : Array[Json] = []
  let client = @native_code_control.Client::new(
    owner_workspace=launch.request.owner_workspace,
    instance_id="synthetic-wenyu-instance",
    config_path="/synthetic/unused-control.json",
    request=async fn(method, route, body) {
      if route == "/v1/code/capabilities" {
        return Ok({
          "model_workspace_contract": "mooncode.model-workspace.v1",
          "completion_outcome_contract": "mooncode.completion-outcome.v1",
        })
      }
      if route == "/v1/moongate-route" {
        return Ok({
          "contract": "moonclaw.moongate-route.v1",
          "ready": true,
          "default_model": "moongate/fixture",
          "models": [{ "name": "moongate/fixture" }],
        })
      }
      if method == "POST" {
        posted.push(body)
        let command = @json.parse(body)
        return Ok({
          "accepted": true,
          "session_id": native_json_text(command, "session_id"),
          "command_id": native_json_text(
            wenyu_test_field(command, "packet"),
            "command_id",
          ),
          "book_root": launch.request.execution_root,
        })
      }
      if posted.is_empty() {
        return Err("native_not_found")
      }
      let command = @json.parse(posted[0])
      let projection : Json = {
        "protocol": "mooncode.v1",
        "owner": "moonclaw",
        "session_id": native_json_text(command, "session_id"),
        "book_root": launch.request.execution_root,
      }
      if route.contains("runtime-claim") {
        let delivered : Json = [
          {
            "command_id": native_json_text(
              wenyu_test_field(command, "packet"),
              "command_id",
            ),
            "command": command,
            "receipt": receipts[0],
          },
        ]
        wenyu_test_set(projection, "delivered_commands", delivered)
      } else if route.contains("runtime-events") {
        wenyu_test_set(projection, "events", journal.to_json())
        wenyu_test_set(projection, "event_count", journal.length().to_json())
      }
      Ok(projection)
    },
  )
  let running = @native_work.sync(queued.id, 2UL, path~, client~)
  assert_eq(running.state, "running")
  let source = @fs.read_file(launch.request.execution_root + "/source.mbt").binary()
  let index = @fs.read_file(launch.request.execution_root + "/.git/index").binary()
  let head = @integration.run_checked("git", [
      "-C",
      launch.request.execution_root,
      "rev-parse",
      "HEAD",
    ]).stdout
  receipts.push(wenyu_journey_evidence(running, journal))
  let completed = @native_work.sync(queued.id, 40000UL, path~, client~)
  assert_eq(completed.state, "completed", msg=completed.blocked_reason)
  assert_true(
    @native_work.wenyu_no_change_receipt_satisfies_contract(completed),
  )
  assert_eq(
    @fs.read_file(launch.request.execution_root + "/source.mbt").binary(),
    source,
  )
  assert_eq(
    @fs.read_file(launch.request.execution_root + "/.git/index").binary(),
    index,
  )
  assert_eq(
    @integration.run_checked("git", [
      "-C",
      launch.request.execution_root,
      "rev-parse",
      "HEAD",
    ]).stdout,
    head,
  )
  assert_eq(@native_work.load(path~).work[0].to_json(), completed.to_json())
  assert_eq(
    @native_work.sync(queued.id, 80000UL, path~, client~).to_json(),
    completed.to_json(),
  )
  assert_eq(posted.length(), 1)
  completed
}
