///|
fn runtime_resolution_test_task(
  id : String,
  status : String,
  agent_id : String?,
  run_id : String?,
  updated_at : String?,
  collaboration : EnergyValleyRuntimeCollaboration?,
) -> EnergyValleyRuntimeWorkItem {
  {
    id,
    title: "Task \{id}",
    status,
    buildingModuleKey: "policy-hall",
    agentId: agent_id,
    agentName: Some("Resolver"),
    role: Some("worker"),
    runId: run_id,
    bookId: Some("policy-hall"),
    summary: None,
    updatedAt: updated_at,
    requestId: None,
    standingGoalId: None,
    correlationId: None,
    artifacts: [],
    resultLinks: None,
    collaboration,
    progress: None,
    activityKind: None,
    activityLabel: None,
    originBuildingModuleKey: None,
    destinationBuildingModuleKey: None,
    source: "town-runtime",
  }
}

///|
fn runtime_resolution_test_agent(
  work_item_id : String?,
  run_id : String?,
) -> EnergyValleyRuntimeAgent {
  {
    id: "agent-resolver",
    name: "Resolver",
    role: "worker",
    avatarRef: None,
    status: "running",
    buildingModuleKey: Some("policy-hall"),
    workItemId: work_item_id,
    runId: run_id,
    bookId: Some("policy-hall"),
    activityKind: None,
    activityLabel: None,
    originBuildingModuleKey: None,
    destinationBuildingModuleKey: None,
  }
}

///|
fn runtime_resolution_test_projection(
  tasks : Array[EnergyValleyRuntimeWorkItem],
) -> EnergyValleyRuntimeProjection {
  {
    schema: energy_valley_runtime_schema(),
    mode: "live",
    observedAt: "2026-08-06T12:00:00.000Z",
    knowledgeCatalogDigest: None,
    tick: Some(1),
    tasks,
    history: None,
    agents: [],
    message: None,
  }
}

///|
fn runtime_resolution_child_collaboration(
  run_id : String,
) -> EnergyValleyRuntimeCollaboration {
  {
    mode: "parallel",
    participants: [
      {
        runId: run_id,
        parentRunId: Some("run-parent"),
        family: "source-review",
        status: "running",
        artifacts: [],
      },
    ],
  }
}

///|
test "runtime work resolver gives explicit work item precedence over run links" {
  let tasks = [
    runtime_resolution_test_task(
      "fallback-active",
      "running",
      Some("agent-resolver"),
      Some("run-fallback"),
      Some("2026-08-06T12:04:00.000Z"),
      None,
    ),
    runtime_resolution_test_task(
      "collaboration-match",
      "running",
      None,
      Some("run-parent"),
      Some("2026-08-06T12:03:00.000Z"),
      Some(runtime_resolution_child_collaboration("run-agent")),
    ),
    runtime_resolution_test_task(
      "exact-run",
      "running",
      None,
      Some("run-agent"),
      Some("2026-08-06T12:02:00.000Z"),
      None,
    ),
    runtime_resolution_test_task(
      "explicit-work",
      "completed",
      None,
      Some("run-old"),
      Some("2026-08-06T12:01:00.000Z"),
      None,
    ),
  ]
  let selected = energy_valley_runtime_task_for_agent_in_projection(
    runtime_resolution_test_projection(tasks),
    runtime_resolution_test_agent(Some("explicit-work"), Some("run-agent")),
  ).unwrap()
  assert_eq(selected.id, "explicit-work")
}

///|
test "runtime work resolver uses exact run before collaboration child run" {
  let tasks = [
    runtime_resolution_test_task(
      "collaboration-match",
      "running",
      None,
      Some("run-parent"),
      Some("2026-08-06T12:03:00.000Z"),
      Some(runtime_resolution_child_collaboration("run-agent")),
    ),
    runtime_resolution_test_task(
      "exact-run",
      "completed",
      None,
      Some("run-agent"),
      Some("2026-08-06T12:01:00.000Z"),
      None,
    ),
  ]
  let selected = energy_valley_runtime_task_for_agent_in_projection(
    runtime_resolution_test_projection(tasks),
    // A missing legacy workItemId must not prevent the next canonical link.
    runtime_resolution_test_agent(Some("missing-work"), Some("run-agent")),
  ).unwrap()
  assert_eq(selected.id, "exact-run")
}

///|
test "map Agent work status uses the canonical legacy Run ID resolver" {
  let projection = runtime_resolution_test_projection([
    runtime_resolution_test_task(
      "exact-run",
      "waiting_review",
      None,
      Some("run-agent"),
      Some("2026-08-06T12:01:00.000Z"),
      None,
    ),
  ])
  let state : EnergyValleyRuntimeState = {
    phase: Live,
    projection: Some(projection),
    version: 1,
    fresh_at_ms: 1.0,
    presence_started_at_tick: 0,
    presence_clocks: [],
    error: "",
  }
  assert_eq(
    golden_valley_runtime_agent_work_status(
      state,
      runtime_resolution_test_agent(None, Some("run-agent")),
    ),
    "waiting_review",
  )
}

///|
test "runtime work resolver uses collaboration child run before agent history" {
  let tasks = [
    runtime_resolution_test_task(
      "agent-history",
      "running",
      Some("agent-resolver"),
      Some("run-history"),
      Some("2026-08-06T12:05:00.000Z"),
      None,
    ),
    runtime_resolution_test_task(
      "collaboration-match",
      "completed",
      None,
      Some("run-parent"),
      Some("2026-08-06T12:01:00.000Z"),
      Some(runtime_resolution_child_collaboration("run-agent")),
    ),
  ]
  let selected = energy_valley_runtime_task_for_agent_in_projection(
    runtime_resolution_test_projection(tasks),
    runtime_resolution_test_agent(None, Some("run-agent")),
  ).unwrap()
  assert_eq(selected.id, "collaboration-match")
}

///|
test "runtime work resolver fallback is status ranked, newest, and stable" {
  let completed_newer = runtime_resolution_test_task(
    "z-completed-newer",
    "completed",
    Some("agent-resolver"),
    None,
    Some("2026-08-06T12:09:00.000Z"),
    None,
  )
  let active_older = runtime_resolution_test_task(
    "a-active-older",
    "running",
    Some("agent-resolver"),
    None,
    Some("2026-08-06T12:01:00.000Z"),
    None,
  )
  let active_newer_a = runtime_resolution_test_task(
    "a-active-newer",
    "running",
    Some("agent-resolver"),
    None,
    Some("2026-08-06T12:05:00.000Z"),
    None,
  )
  let active_newer_z = runtime_resolution_test_task(
    "z-active-newer",
    "running",
    Some("agent-resolver"),
    None,
    Some("2026-08-06T12:05:00.000Z"),
    None,
  )
  let agent = runtime_resolution_test_agent(None, None)
  let first_order = energy_valley_runtime_task_for_agent_in_projection(
    runtime_resolution_test_projection([
      completed_newer, active_newer_a, active_older, active_newer_z,
    ]),
    agent,
  ).unwrap()
  let reversed_order = energy_valley_runtime_task_for_agent_in_projection(
    runtime_resolution_test_projection([
      active_newer_z, active_older, active_newer_a, completed_newer,
    ]),
    agent,
  ).unwrap()
  assert_eq(first_order.id, "z-active-newer")
  assert_eq(reversed_order.id, "z-active-newer")
}
