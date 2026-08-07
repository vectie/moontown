///|
fn town_chronicle_test_runtime(now_ms : Double) -> EnergyValleyRuntimeState {
  energy_valley_runtime_state_from_text(
    energy_valley_runtime_test_projection_text(
      "1970-01-01T00:01:40.000Z", "live",
    ),
    1,
    now_ms,
  )
}

///|
test "town today derives live stories and evidence from the runtime ledger" {
  let state = town_chronicle_test_runtime(110000.0)
  let entries = town_chronicle_runtime_entries(state)
  assert_eq(entries.length(), 1)
  assert_true(entries[0].title.contains("正在推进"))
  assert_eq(entries[0].agent_id, Some("agent-1"))
  assert_eq(entries[0].building_id, "policy-hall")
  assert_eq(entries[0].evidence_count, 1)
  assert_eq(entries[0].participant_count, 1)
  assert_eq(entries[0].tone, "active")
}

///|
test "town today never describes a stale running snapshot as current work" {
  let stale = energy_valley_runtime_state_at(
    town_chronicle_test_runtime(110000.0),
    175000.0,
  )
  assert_true(stale.phase is Stale)
  let entries = town_chronicle_runtime_entries(stale)
  assert_eq(entries.length(), 1)
  assert_true(entries[0].title.contains("最近记录"))
  assert_false(entries[0].title.contains("正在推进"))
  assert_true(entries[0].detail.contains("不代表 Agent 现在仍在执行"))
  assert_eq(entries[0].tone, "history")
  assert_true(town_chronicle_phase_copy(stale).contains("不代表 Agent"))
}

///|
test "town today prefers the authored activity label over verbose summaries" {
  let state = town_chronicle_test_runtime(110000.0)
  let task = {
    ..state.projection.unwrap().tasks[0],
    summary: Some(
      "command failed while reading /Users/example/private/workspace/output.log",
    ),
    activityLabel: Some("正在核对来源"),
  }
  let detail = town_chronicle_task_detail(state, task)
  assert_eq(detail, "正在核对来源")
  assert_false(detail.contains("/Users/"))
}

///|
test "town today redacts path-bearing summaries, activity, titles, and errors" {
  let state = town_chronicle_test_runtime(110000.0)
  let base_task = state.projection.unwrap().tasks[0]
  let summary_task = {
    ..base_task,
    activityLabel: None,
    summary: Some("command failed at /Users/example/private/report.md"),
  }
  let summary_detail = town_chronicle_task_detail(state, summary_task)
  assert_true(summary_detail.contains("已隐藏"))
  assert_false(summary_detail.contains("/Users/"))
  let activity_task = {
    ..base_task,
    activityLabel: Some("核验 /home/example/private/source.json"),
  }
  let activity_detail = town_chronicle_task_detail(state, activity_task)
  assert_true(activity_detail.contains("已隐藏"))
  assert_false(activity_detail.contains("/home/"))
  let title_task = { ..base_task, title: "审阅 /private/example/runtime.log" }
  let title = town_chronicle_task_title(state, title_task)
  assert_true(title.contains("任务标题包含本地路径"))
  assert_false(title.contains("/private/"))
  let error_state = {
    ..state,
    phase: Error,
    error: "failed to read /Users/example/private/runtime.json",
  }
  let error_copy = town_chronicle_phase_copy(error_state)
  assert_true(error_copy.contains("请检查本机服务日志"))
  assert_false(error_copy.contains("/Users/"))
  assert_false(error_copy.contains("failed to read"))
}

///|
test "town today only offers resident navigation for projected Agents" {
  let state = town_chronicle_test_runtime(110000.0)
  let projection = state.projection.unwrap()
  let missing_agent_state = {
    ..state,
    projection: Some({ ..projection, agents: [] }),
  }
  let entries = town_chronicle_runtime_entries(missing_agent_state)
  assert_eq(entries.length(), 1)
  assert_eq(entries[0].agent_id, None)
  assert_false(entries[0].title.contains("Scout正在推进"))
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_town_chronicle(dashboard_test_dispatch(), {
        ..init_model(),
        town_chronicle_open: true,
        energy_valley_runtime: missing_agent_state,
      }),
    ),
  )
  assert_false(html.contains("查看居民"))
}

///|
test "town today header counts evidence across the full ledger" {
  let state = town_chronicle_test_runtime(110000.0)
  let projection = state.projection.unwrap()
  let base_task = projection.tasks[0]
  let tasks : Array[EnergyValleyRuntimeWorkItem] = []
  for index in 0..<8 {
    tasks.push({
      ..base_task,
      id: "research-task-\{index}",
      updatedAt: Some("1970-01-01T00:01:\{40 + index}.000Z"),
    })
  }
  let expanded = { ..state, projection: Some({ ..projection, tasks, }) }
  assert_eq(
    town_chronicle_runtime_entries(expanded).length(),
    town_chronicle_runtime_limit,
  )
  assert_eq(town_chronicle_runtime_evidence_count(expanded), 8)
}

///|
test "town today separates terminal retry history from current blockers" {
  let state = town_chronicle_test_runtime(110000.0)
  let projection = state.projection.unwrap()
  let base = projection.tasks[0]
  let current_blocker = {
    ..base,
    id: "current-policy-blocker",
    title: "Resolve current policy review",
    status: "blocked",
    buildingModuleKey: "policy-hall",
    agentId: None,
    agentName: None,
    runId: None,
    bookId: Some("wenyu-policy-hall"),
    resultLinks: None,
    collaboration: None,
    source: "town-runtime",
  }
  let coding_review = {
    ..current_blocker,
    id: "legacy-coding-review",
    title: "Review pending book updates",
    buildingModuleKey: "ai-garden",
    bookId: Some("coding"),
  }
  let coding_ingest = {
    ..coding_review,
    id: "legacy-coding-ingest",
    title: "Bootstrap ingest and population",
  }
  let finance_review = {
    ..coding_review,
    id: "legacy-finance-review",
    title: "Review pending book updates",
    buildingModuleKey: "valley-market",
    bookId: Some("finance"),
  }
  let finance_ingest = {
    ..finance_review,
    id: "legacy-finance-ingest",
    title: "Bootstrap ingest and population",
  }
  let separated = {
    ..state,
    projection: Some({
      ..projection,
      tasks: [current_blocker],
      history: Some([
        coding_review, coding_ingest, finance_review, finance_ingest,
      ]),
      agents: [],
    }),
  }
  let entries = town_chronicle_runtime_entries(separated)
  assert_eq(entries.length(), 1)
  assert_true(entries[0].title.contains("政策大厅"))
  assert_true(entries[0].title.contains("Resolve current policy review"))
  assert_false(entries[0].title.contains("一项真实任务"))
  let groups = town_chronicle_history_groups(separated)
  assert_eq(groups.length(), 2)
  assert_eq(town_chronicle_history_count(groups), 4)
  assert_true(groups.any(group => group.label == "AI科学花园"))
  assert_true(groups.any(group => group.label == "山谷市集"))

  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_town_chronicle(dashboard_test_dispatch(), {
        ..init_model(),
        town_chronicle_open: true,
        energy_valley_runtime: separated,
      }),
    ),
  )
  assert_true(html.contains("当前账本任务 1"))
  assert_true(html.contains("历史重试 4"))
  assert_true(html.contains("历史重试债务 · 4 项"))
  assert_true(html.contains("legacy-coding-review"))
  assert_true(html.contains("legacy-finance-ingest"))
  assert_true(html.contains("不计入当前 blocked/failed"))
  assert_true(html.contains("不构成完成证据"))
}

///|
test "town today local history rejects malformed and unknown activity" {
  let model = {
    ..init_model(),
    analytics: [
      "1|walk_step|政策大厅", "broken", "1|invented_event|不应出现", "1|knowledge_publish|研究塔 1",
    ],
  }
  let entries = town_chronicle_recent_local_entries(model, 4)
  assert_eq(entries.length(), 2)
  assert_eq(entries[0].label, "发布本地知识条目")
  assert_eq(entries[0].detail, "研究塔 1")
  assert_eq(entries[1].label, "角色移动")
}

///|
test "town today renders navigation, evidence, and explicit truth boundaries" {
  let state = town_chronicle_test_runtime(110000.0)
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_town_chronicle(dashboard_test_dispatch(), {
        ..init_model(),
        town_chronicle_open: true,
        energy_valley_runtime: state,
        analytics: ["1|building_visit|政策大厅"],
      }),
    ),
  )
  assert_true(html.contains("role=\"dialog\""))
  assert_true(html.contains("当前运行时账本"))
  assert_true(html.contains("查看居民"))
  assert_true(html.contains("定位建筑"))
  assert_true(html.contains("打开证据"))
  assert_true(html.contains("/book-output/policy-hall/report.html"))
  assert_true(html.contains("仅来自当前浏览器"))
  assert_true(html.contains("演示居民不进入此处"))
}

///|
test "closed town today drawer renders nothing" {
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_town_chronicle(dashboard_test_dispatch(), {
        ..init_model(),
        town_chronicle_open: false,
      }),
    ),
  )
  assert_false(html.contains("town-chronicle-panel"))
}
