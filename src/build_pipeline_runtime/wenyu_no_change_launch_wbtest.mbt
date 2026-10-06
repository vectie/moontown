///|
async test "Wenyu launch opt in freezes exact existing commands and saved launches win" {
  let launch = wenyu_launch_fixture()
  assert_eq(launch.request.input_blocker, "")
  let policy = launch.request.acceptance_policy
  assert_eq(
    wenyu_test_field(policy, "required_validation_commands"),
    wenyu_validation_commands().to_json(),
  )
  let completion = wenyu_test_field(policy, "completion_policy")
  assert_eq(
    completion,
    @native_work.wenyu_completion_policy(wenyu_validation_commands()),
  )
  assert_eq(wenyu_test_rows(completion, "required_checks").length(), 6)
  assert_eq(wenyu_test_rows(completion, "alternative_milestone_ids"), [
    "implementation".to_json(),
  ])
  assert_true(launch.request.prompt.contains("Never create a fake edit"))
  assert_true(
    launch.request.prompt.contains(
      "original-task acceptance remains unevaluated",
    ),
  )
  assert_true(launch.request.execution_root != launch.entry.workspace_root)
  let saved_bytes = @fs.read_file(
    wenyu_launch_path(launch.native_path, launch.task.id),
  ).text()
  let saved = freeze_wenyu_launch(
    launch.entry,
    launch.task,
    "changed-goal",
    "changed-objective",
    execution="acp",
    model="later-model",
    allow_no_change=false,
    native_path=launch.native_path,
    catalog_path="/unused-catalog",
  )
  assert_eq(saved.to_json(), launch.to_json())
  assert_eq(
    @fs.read_file(wenyu_launch_path(launch.native_path, launch.task.id)).text(),
    saved_bytes,
  )
  let legacy = wenyu_launch_fixture(allow_no_change=false)
  assert_eq(
    wenyu_test_field(legacy.request.acceptance_policy, "completion_policy"),
    Json::null(),
  )
  assert_true(legacy.request.prompt.contains("No-change is not enabled"))
  let replay = freeze_wenyu_launch(
    legacy.entry,
    legacy.task,
    "goal",
    "Existing answer",
    allow_no_change=true,
    native_path=legacy.native_path,
  )
  assert_eq(replay.to_json(), legacy.to_json())
  let acp = wenyu_launch_fixture(allow_no_change=false, execution="acp")
  assert_eq(
    wenyu_test_field(acp.request.acceptance_policy, "completion_policy"),
    Json::null(),
  )
  let extension = wenyu_launch_fixture(kind="projection-schema")
  assert_eq(
    wenyu_test_field(extension.request.acceptance_policy, "completion_policy"),
    Json::null(),
  )
  assert_true(
    extension.request.input_blocker.contains(
      "wenyu_task_output_contract_not_supported",
    ),
  )
  try {
    ignore(wenyu_launch_fixture(execution="acp"))
    fail("expected native-only flag rejection")
  } catch {
    error =>
      assert_true(error.to_string().contains("wenyu_no_change_requires_native"))
  }
}

///|
async test "Wenyu opted launch negotiates capability before reservation and retries exact bytes" {
  let launch = wenyu_launch_fixture()
  let queued = @native_work.enqueue(launch.request, path=launch.native_path)
  let calls : Array[String] = []
  let missing = @native_code_control.Client::new(
    owner_workspace=launch.request.owner_workspace,
    instance_id="fixture",
    config_path="/synthetic/unused.json",
    request=async fn(method, route, _) {
      calls.push(method + " " + route)
      Ok({ "model_workspace_contract": "mooncode.model-workspace.v1" })
    },
  )
  let blocked = @native_work.sync(
    queued.id,
    2UL,
    path=launch.native_path,
    client=missing,
  )
  assert_eq(blocked.blocked_reason, "completion_outcome_unavailable")
  assert_true(blocked.reservation is None)
  assert_eq(calls, ["GET /v1/code/capabilities"])
  let posted : Array[String] = []
  let capable = @native_code_control.Client::new(
    owner_workspace=launch.request.owner_workspace,
    instance_id="fixture",
    config_path="/synthetic/unused.json",
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
          "default_model": "moongate/frozen",
          "models": [{ "name": "moongate/frozen" }],
        })
      }
      if method == "GET" {
        return Err("native_not_found")
      }
      posted.push(body)
      Err("lost-response")
    },
  )
  let first = @native_work.sync(
    queued.id,
    40000UL,
    path=launch.native_path,
    client=capable,
  )
  let second = @native_work.sync(
    queued.id,
    80000UL,
    path=launch.native_path,
    client=capable,
  )
  assert_eq(first.state, "dispatch_uncertain")
  assert_eq(posted.length(), 2)
  assert_eq(posted[0], posted[1])
  assert_eq(first.reservation.to_json(), second.reservation.to_json())
  assert_eq(first.request_digest, second.request_digest)
  assert_eq(
    @native_work.load(path=launch.native_path).work[0].to_json(),
    second.to_json(),
  )
  let changed = @native_work.enqueue(
    {
      ..launch.request,
      model_request: "moongate/new",
      acceptance_policy: Json::null(),
    },
    path=launch.native_path,
  )
  assert_eq(changed.request.to_json(), second.request.to_json())
  assert_eq(changed.reservation.to_json(), second.reservation.to_json())
}
