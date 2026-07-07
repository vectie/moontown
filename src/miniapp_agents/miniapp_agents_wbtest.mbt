///|
test "agent runtime creates and attaches user scoped agents" {
  let snapshot = @miniapp_projection.miniapp_projection_fixture_mixed_snapshot()
  let viewer = miniapp_agent_test_viewer()
  let created = miniapp_create_agent(
    snapshot,
    viewer,
    {
      id: "agent-private-builder",
      display_name: "Private Builder",
      owner_kind: @miniapp_contracts.UserOwner,
      owner_id: "user-a",
      building_id: None,
      capabilities: ["answer", "create-building"],
    },
    now_ms=4000UL,
  )
  assert_eq(created.ok, true)
  assert_true(created.agent_id == Some("agent-private-builder"))
  assert_eq(created.snapshot.agents.length(), snapshot.agents.length() + 1)
  assert_true(
    miniapp_agent_test_agent_building(created.snapshot, "agent-private-builder") ==
    None,
  )
  let attached = miniapp_attach_agent_to_building(
    created.snapshot,
    viewer,
    { agent_id: "agent-private-builder", building_id: "private-lab" },
    now_ms=4100UL,
  )
  assert_eq(attached.ok, true)
  assert_true(
    miniapp_agent_test_agent_building(
      attached.snapshot,
      "agent-private-builder",
    ) ==
    Some("private-lab"),
  )
  assert_true(miniapp_agent_test_has_audit(attached.snapshot, "agent.attached"))
}

///|
test "agent runtime rejects cross user agent ownership and hidden building chat" {
  let snapshot = @miniapp_projection.miniapp_projection_fixture_mixed_snapshot()
  let viewer = miniapp_agent_test_viewer()
  let rejected = miniapp_create_agent(
    snapshot,
    viewer,
    {
      id: "agent-user-b",
      display_name: "Other User Agent",
      owner_kind: @miniapp_contracts.UserOwner,
      owner_id: "user-b",
      building_id: None,
      capabilities: ["answer"],
    },
    now_ms=4000UL,
  )
  assert_eq(rejected.ok, false)
  assert_eq(rejected.message, "viewer cannot own agent")
  let hidden = miniapp_send_agent_message(
    snapshot,
    viewer,
    {
      message_id: "msg-hidden",
      run_id: "run-hidden",
      thread_id: "thread-hidden",
      building_id: "other-private-lab",
      agent_id: None,
      body: "Can I see this?",
      answer_summary: "Hidden building should reject chat.",
    },
    now_ms=4200UL,
  )
  assert_eq(hidden.ok, false)
  assert_eq(hidden.message, "viewer cannot chat with building")
}

///|
test "chat send records message run thread and audit without making agent truth durable" {
  let snapshot = @miniapp_projection.miniapp_projection_fixture_mixed_snapshot()
  let viewer = miniapp_agent_test_viewer()
  let sent = miniapp_send_agent_message(
    snapshot,
    viewer,
    {
      message_id: "msg-private-lab-question",
      run_id: "run-private-lab-question",
      thread_id: "thread-private-lab",
      building_id: "private-lab",
      agent_id: None,
      body: "Create a draft agent lab checklist.",
      answer_summary: "Draft answer waiting for book review.",
    },
    now_ms=4300UL,
  )
  assert_eq(sent.ok, true)
  assert_true(sent.thread_id == Some("thread-private-lab"))
  assert_true(sent.run_id == Some("run-private-lab-question"))
  assert_eq(sent.snapshot.messages.length(), snapshot.messages.length() + 1)
  assert_eq(sent.snapshot.runs.length(), snapshot.runs.length() + 1)
  assert_true(
    miniapp_agent_test_run_status(sent.snapshot, "run-private-lab-question") ==
    @miniapp_contracts.RunWaitingReview,
  )
  assert_true(miniapp_agent_test_has_audit(sent.snapshot, "chat.sent"))
  let projected = @miniapp_projection.miniapp_filter_snapshot_for_viewer(
    sent.snapshot,
    viewer,
  )
  let summary = @miniapp_projection.miniapp_projection_summary(
    sent.snapshot,
    projected,
  )
  assert_true(summary.visible_messages >= 2)
  assert_true(summary.visible_audit_events >= 2)
}

///|
test "run status controls cover cancel retry and review acceptance" {
  let snapshot = @miniapp_projection.miniapp_projection_fixture_mixed_snapshot()
  let viewer = miniapp_agent_test_viewer()
  let cancelled = miniapp_cancel_run(
    snapshot,
    viewer,
    {
      run_id: "run-policy-hall-1",
      summary: "User cancelled the pending query.",
    },
    now_ms=4400UL,
  )
  assert_eq(cancelled.ok, true)
  assert_true(
    miniapp_agent_test_run_status(cancelled.snapshot, "run-policy-hall-1") ==
    @miniapp_contracts.RunCancelled,
  )
  let retried = miniapp_retry_run(
    cancelled.snapshot,
    viewer,
    { run_id: "run-policy-hall-1", summary: "User retried the query." },
    now_ms=4500UL,
  )
  assert_true(
    miniapp_agent_test_run_status(retried.snapshot, "run-policy-hall-1") ==
    @miniapp_contracts.RunPending,
  )
  let accepted = miniapp_accept_run_for_review(
    retried.snapshot,
    viewer,
    {
      run_id: "run-policy-hall-1",
      summary: "Accepted answer becomes book memory.",
    },
    now_ms=4600UL,
  )
  assert_true(
    miniapp_agent_test_run_status(accepted.snapshot, "run-policy-hall-1") ==
    @miniapp_contracts.RunDone,
  )
  assert_true(
    miniapp_agent_test_has_audit(accepted.snapshot, "review.accepted"),
  )
}

///|
fn miniapp_agent_test_viewer() -> @miniapp_projection.MiniappViewerContext {
  @miniapp_projection.miniapp_viewer_context(
    user_id="user-a",
    organization_ids=["org-a"],
    workspace_ids=["workspace-user-a", "workspace-org-a"],
    roles=[
      @miniapp_contracts.OwnerRole,
      @miniapp_contracts.EditorRole,
      @miniapp_contracts.PublisherRole,
    ],
  )
}

///|
fn miniapp_agent_test_agent_building(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  agent_id : String,
) -> String? {
  for agent in snapshot.agents {
    if agent.id == agent_id {
      return agent.building_id
    }
  }
  None
}

///|
fn miniapp_agent_test_run_status(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  run_id : String,
) -> @miniapp_contracts.MiniappRunStatus {
  for run in snapshot.runs {
    if run.id == run_id {
      return run.status
    }
  }
  @miniapp_contracts.RunFailed
}

///|
fn miniapp_agent_test_has_audit(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  action : String,
) -> Bool {
  for event in snapshot.audit_events {
    if event.action == action {
      return true
    }
  }
  false
}
