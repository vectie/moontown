///|
fn resident_explorer_test_projection_text(observed_at : String) -> String {
  let template =
    #|{
    #|  "schema": "moontown.energy-valley.runtime.v1",
    #|  "mode": "live",
    #|  "observedAt": "__OBSERVED_AT__",
    #|  "knowledgeCatalogDigest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    #|  "tick": 42,
    #|  "tasks": [{
    #|    "id": "research-task",
    #|    "title": "协作研究能源谷居民体验",
    #|    "status": "running",
    #|    "buildingModuleKey": "energy-lab",
    #|    "agentId": "agent-moon",
    #|    "agentName": "月灯",
    #|    "role": "worker",
    #|    "runId": "run-parent",
    #|    "bookId": "research-ai-agents",
    #|    "summary": "command failed at /Users/example/private/report.md",
    #|    "updatedAt": "1970-01-01T00:01:40.000Z",
    #|    "artifacts": ["/Users/example/private/report.md"],
    #|    "resultLinks": [{"label":"研究报告","url":"/book-output/research-ai-agents/report.html","kind":"report"}],
    #|    "collaboration": {
    #|      "mode": "parallel",
    #|      "participants": [{"runId":"run-child","family":"source-review","status":"completed","artifacts":["sources.json"]}]
    #|    },
    #|    "activityKind": "researching",
    #|    "activityLabel": "核验居民交互证据",
    #|    "originBuildingModuleKey": "policy-hall",
    #|    "destinationBuildingModuleKey": "energy-lab",
    #|    "source": "operator-request"
    #|  }],
    #|  "agents": [{
    #|    "id": "agent-moon",
    #|    "name": "月灯",
    #|    "role": "worker",
    #|    "avatarRef": "avatar://moon-lantern",
    #|    "status": "running",
    #|    "buildingModuleKey": "energy-lab",
    #|    "workItemId": "research-task",
    #|    "runId": "run-parent",
    #|    "bookId": "research-ai-agents",
    #|    "activityKind": "researching",
    #|    "activityLabel": "核验居民交互证据",
    #|    "originBuildingModuleKey": "policy-hall",
    #|    "destinationBuildingModuleKey": "energy-lab"
    #|  }]
    #|}
  template.replace(old="__OBSERVED_AT__", new=observed_at)
}

///|
fn resident_explorer_test_model() -> Model {
  {
    ..init_model(),
    energy_valley_runtime: energy_valley_runtime_state_from_text(
      resident_explorer_test_projection_text("1970-01-01T00:01:40.000Z"),
      1,
      110000.0,
    ),
    resident_explorer_open: true,
  }
}

///|
test "resident task lookup, search, and generic lab routing stay evidence-backed" {
  let model = resident_explorer_test_model()
  let projection = model.energy_valley_runtime.projection.unwrap()
  let agent = projection.agents[0]
  let task = resident_runtime_task_for_agent_in_projection(projection, agent).unwrap()
  assert_eq(task.id, "research-task")
  assert_eq(
    resident_workplace_identity(agent, Some(task)),
    "research-ai-agents",
  )
  assert_true(
    resident_matches_query(agent, Some(task), "AI智能体实验室", "月灯"),
  )
  assert_true(
    resident_matches_query(
      agent,
      Some(task),
      "AI智能体实验室",
      "run-parent",
    ),
  )
  assert_true(
    resident_matches_query(
      agent,
      Some(task),
      "AI智能体实验室",
      "AI智能体实验室",
    ),
  )
  assert_false(
    resident_matches_query(
      agent,
      Some(task),
      "AI智能体实验室",
      "不存在",
    ),
  )
}

///|
test "stale resident copy never claims current work" {
  let (status, tone) = resident_status_copy(Stale, "running")
  assert_eq(status, "最近记录 · 执行中")
  assert_eq(tone, "is-stale")
  let model = resident_explorer_test_model()
  let projection = model.energy_valley_runtime.projection.unwrap()
  assert_eq(
    resident_activity_copy(
      Stale,
      projection.agents[0],
      Some(projection.tasks[0]),
    ),
    "最近记录：核验居民交互证据",
  )
}

///|
test "live resident status tones preserve operational meaning" {
  assert_eq(resident_status_copy(Live, "running"), ("执行中", "is-active"))
  assert_eq(resident_status_copy(Live, "assigned"), ("已分派", "is-active"))
  assert_eq(resident_status_copy(Live, "reviewing"), ("审阅中", "is-active"))
  assert_eq(resident_status_copy(Live, "waiting"), ("等待中", "is-waiting"))
  assert_eq(resident_status_copy(Live, "queued"), ("等待中", "is-waiting"))
  assert_eq(
    resident_status_copy(Live, "waiting_review"),
    ("等待审阅", "is-waiting"),
  )
  assert_eq(resident_status_copy(Live, "blocked"), ("受阻", "is-alert"))
  assert_eq(resident_status_copy(Live, "failed"), ("失败", "is-alert"))
  assert_eq(
    resident_status_copy(Live, "completed"),
    ("已完成", "is-complete"),
  )
  assert_eq(resident_status_copy(Live, "idle"), ("待命", "is-idle"))
  assert_eq(resident_status_copy(Live, "offline"), ("离线", "is-idle"))
}

///|
test "resident activity fallbacks never expose local paths" {
  let model = resident_explorer_test_model()
  let projection = model.energy_valley_runtime.projection.unwrap()
  let base_agent = projection.agents[0]
  let base_task = projection.tasks[0]
  let agent_activity = resident_activity_copy(
    Live,
    {
      ..base_agent,
      activityLabel: Some("正在读取 /Users/example/private/source.json"),
    },
    Some(base_task),
  )
  assert_true(agent_activity.contains("已隐藏"))
  assert_false(agent_activity.contains("/Users/"))
  let task_fallback = resident_activity_copy(
    Live,
    { ..base_agent, activityLabel: None },
    Some({
      ..base_task,
      activityLabel: None,
      summary: Some("command failed at /home/example/private/report.md"),
    }),
  )
  assert_true(task_fallback.contains("已隐藏"))
  assert_false(task_fallback.contains("/home/"))
}

///|
test "resident rendering exposes actions and safe evidence without path leaks" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let base = resident_explorer_test_model()
  let directory_html = @rabbita.render_to_string(
    @rabbita.static_cell(render_resident_explorer(dispatch, base)),
  )
  assert_true(directory_html.contains("月灯"))
  assert_true(directory_html.contains("AI智能体实验室"))
  assert_false(directory_html.contains("{agent.name}"))
  let selected = { ..base, selection: Agent("agent-moon") }
  let profile_html = @rabbita.render_to_string(
    @rabbita.static_cell(render_selected_resident_profile(dispatch, selected)),
  )
  assert_true(profile_html.contains("定位工作建筑"))
  assert_true(profile_html.contains("用此上下文创建工作请求"))
  assert_true(profile_html.contains("research-ai-agents"))
  assert_true(profile_html.contains("研究报告"))
  assert_true(
    profile_html.contains("/book-output/research-ai-agents/report.html"),
  )
  assert_true(profile_html.contains("只显示数量"))
  assert_true(profile_html.contains("已在居民资料中隐藏"))
  assert_false(profile_html.contains("/Users/example/private/report.md"))
  assert_false(profile_html.contains("{workplace_label}"))
}

///|
test "resident work receipt redacts a path-bearing task title" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let base = resident_explorer_test_model()
  let projection = base.energy_valley_runtime.projection.unwrap()
  let unsafe_task = {
    ..projection.tasks[0],
    title: "审阅 /private/example/runtime.log",
  }
  let model = {
    ..base,
    selection: Agent("agent-moon"),
    energy_valley_runtime: {
      ..base.energy_valley_runtime,
      projection: Some({ ..projection, tasks: [unsafe_task] }),
    },
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_selected_resident_profile(dispatch, model)),
  )
  assert_true(html.contains("任务标题包含本地路径"))
  assert_false(html.contains("/private/example/runtime.log"))
}
