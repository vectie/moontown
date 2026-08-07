///|
fn ecosystem_test_signal(
  id : String,
  provenance : EcosystemProvenance,
  urgency : Int,
  happened_tick : Int,
) -> EcosystemAttentionSignal {
  {
    id,
    subject_id: id,
    place_id: "social-square",
    behavior: Exchange,
    headline: "A deliberately long attention headline for disclosure testing",
    detail: "Evidence-bearing detail stays behind the inspector disclosure.",
    interaction_label: "Inspect",
    interaction_target: id,
    urgency,
    novelty: 50,
    proximity: 50,
    affinity: 50,
    happened_tick,
    decay_per_tick: 2,
    expires_after_ticks: 40,
    cooldown_key: id,
    cooldown_ticks: 12,
    provenance,
  }
}

///|
fn ecosystem_attention_fixture_runtime_task(
  status : String,
) -> EnergyValleyRuntimeWorkItem {
  {
    id: "task-attention",
    title: "Compare evidence for the valley report",
    status,
    buildingModuleKey: "policy-hall",
    agentId: Some("agent-attention"),
    agentName: Some("Evidence Scout"),
    role: Some("worker"),
    runId: Some("run-attention"),
    bookId: Some("wenyu-policy-hall"),
    summary: Some("Reviewing three public sources before a cited handoff."),
    updatedAt: Some("2026-08-07T00:00:00Z"),
    requestId: Some("request-attention"),
    standingGoalId: None,
    correlationId: Some("correlation-attention"),
    artifacts: [],
    resultLinks: None,
    collaboration: None,
    progress: None,
    activityKind: Some("reviewing"),
    activityLabel: Some("Checking citations at the policy desk"),
    originBuildingModuleKey: Some("town-shell"),
    destinationBuildingModuleKey: Some("policy-hall"),
    source: "operator-request",
  }
}

///|
fn ecosystem_attention_fixture_runtime_agent(
  status : String,
) -> EnergyValleyRuntimeAgent {
  {
    id: "agent-attention",
    name: "Evidence Scout",
    role: "worker",
    avatarRef: None,
    status,
    buildingModuleKey: Some("policy-hall"),
    workItemId: Some("task-attention"),
    runId: Some("run-attention"),
    bookId: Some("wenyu-policy-hall"),
    activityKind: Some("reviewing"),
    activityLabel: Some("Checking citations at the policy desk"),
    originBuildingModuleKey: Some("town-shell"),
    destinationBuildingModuleKey: Some("policy-hall"),
  }
}

///|
fn ecosystem_attention_fixture_runtime_state(
  phase : EnergyValleyRuntimePhase,
  status : String,
) -> EnergyValleyRuntimeState {
  {
    phase,
    projection: Some({
      schema: "moontown.energy-valley-runtime.v1",
      mode: "live",
      observedAt: "2026-08-07T00:00:00Z",
      knowledgeCatalogDigest: None,
      tick: Some(10),
      tasks: [ecosystem_attention_fixture_runtime_task(status)],
      history: None,
      agents: [ecosystem_attention_fixture_runtime_agent(status)],
      message: None,
    }),
    version: 1,
    fresh_at_ms: 0.0,
    presence_started_at_tick: 0,
    presence_clocks: [],
    error: "",
  }
}

///|
test "ecosystem profiles cover every civic module with a unique character" {
  let profiles = ecosystem_civic_place_profiles()
  assert_eq(profiles.length(), 16)
  let ids : Array[String] = []
  let characteristics : Array[String] = []
  for profile in profiles {
    assert_true(!profile.id.is_empty())
    assert_true(!profile.characteristic.is_empty())
    assert_true(!profile.living_detail.is_empty())
    assert_true(!profile.interaction_label.is_empty())
    assert_true(!ids.contains(profile.id))
    assert_true(!characteristics.contains(profile.characteristic))
    assert_true(profile.provenance is AuthoredPlace)
    ids.push(profile.id)
    characteristics.push(profile.characteristic)
  }
  assert_true(ids.contains("town-shell"))
  assert_true(ids.contains("research-embodied-robotics"))
  assert_true(ids.contains("research-ai-hardware"))
  let social = profiles.filter(profile => profile.id == "social-square")[0]
  assert_eq(social.characteristic, "弱连接会客场")
  assert_true(social.social_bias > social.focus_bias)
}

///|
test "custom buildings receive honest style-specific place fallbacks" {
  let laboratory : GoldenValleyBuilding = {
    authored_id: None,
    module_key: None,
    name: "River Test Bench",
    style: "custom-lab",
    x: 30,
    y: 40,
    width: 5,
    depth: 4,
    entrance_x: None,
    entrance_y: None,
    floors: 2,
  }
  let profile = ecosystem_place_profile_for_building(laboratory)
  assert_true(profile.provenance is LocalPlace)
  assert_eq(profile.id, "local-place-30-40")
  assert_eq(profile.characteristic, "开放试验间")
  assert_eq(profile.entrance_x, 32)
  assert_eq(profile.entrance_y, 44)
  assert_true(profile.living_detail.contains("本地试验"))
}

///|
test "preview residents are named individuals with deterministic schedules" {
  let profiles = ecosystem_preview_resident_profiles()
  assert_eq(profiles.length(), 12)
  let ids : Array[String] = []
  let names : Array[String] = []
  for profile in profiles {
    assert_true(!ids.contains(profile.id))
    assert_true(!names.contains(profile.name))
    assert_eq(profile.schedule.length(), 4)
    assert_true(ecosystem_schedule_total(profile) > 0)
    ids.push(profile.id)
    names.push(profile.name)
  }
  let lingxi = ecosystem_preview_resident_profile(4)
  let first = ecosystem_preview_resident_intention(lingxi, 0, "sunny", 0, [])
  let repeated = ecosystem_preview_resident_intention(lingxi, 0, "sunny", 0, [])
  assert_eq(first.short_label, repeated.short_label)
  assert_eq(first.place_id, repeated.place_id)
  assert_eq(first.started_tick, repeated.started_tick)
  assert_true(first.provenance is AmbientPreview)
  let later = ecosystem_preview_resident_intention(lingxi, 40, "sunny", 0, [])
  assert_true(first.place_id != later.place_id)
}

///|
test "preview intentions react to weather crowding and real work without impersonating it" {
  let guide = ecosystem_preview_resident_profile(9)
  let rainy = ecosystem_preview_resident_intention(guide, 7, "rain", 0, [
    "resident-twins",
  ])
  assert_true(rainy.short_label.has_prefix("雨棚下"))
  assert_true(rainy.detail.contains("Runtime Agent"))
  assert_true(rainy.detail.contains("不计入工作人数"))
  assert_true(rainy.provenance is AmbientPreview)
  let crowded = ecosystem_preview_resident_intention(guide, 30, "sunny", 4, [])
  assert_true(crowded.short_label.has_prefix("遇见邻居"))
  assert_eq(crowded.interaction_label, "加入闲聊")
  assert_true(crowded.detail.contains("本地剧本"))
}

///|
test "attention scoring prioritizes live blocked work and decays old signals" {
  let live = ecosystem_test_signal("live", RuntimeLive, 90, 10)
  let ambient = ecosystem_test_signal("ambient", AmbientPreview, 90, 10)
  let record = ecosystem_test_signal("record", RuntimeRecord, 90, 10)
  assert_true(
    ecosystem_attention_score(live, [], 10) >
    ecosystem_attention_score(ambient, [], 10),
  )
  assert_true(
    ecosystem_attention_score(ambient, [], 10) >
    ecosystem_attention_score(record, [], 10),
  )
  assert_true(
    ecosystem_attention_score(live, [], 20) <
    ecosystem_attention_score(live, [], 10),
  )
  assert_eq(ecosystem_attention_score(live, [], 60), -10000)
}

///|
test "attention cooldown reduces repetition and receipts stay bounded" {
  let signal = ecosystem_test_signal("repeat", AmbientPreview, 60, 10)
  let first_score = ecosystem_attention_score(signal, [], 10)
  let history = ecosystem_record_attention([], signal, 10, 3)
  assert_eq(history.length(), 1)
  assert_eq(history[0].show_count, 1)
  assert_true(ecosystem_attention_score(signal, history, 10) < first_score)
  let history = ecosystem_record_attention(history, signal, 12, 3)
  assert_eq(history.length(), 1)
  assert_eq(history[0].show_count, 2)
  let history = ecosystem_record_attention(
    history,
    ecosystem_test_signal("other-1", AmbientPreview, 50, 12),
    13,
    3,
  )
  let history = ecosystem_record_attention(
    history,
    ecosystem_test_signal("other-2", AmbientPreview, 50, 12),
    14,
    3,
  )
  let history = ecosystem_record_attention(
    history,
    ecosystem_test_signal("other-3", AmbientPreview, 50, 12),
    15,
    3,
  )
  assert_eq(history.length(), 3)
  assert_eq(history[0].cooldown_key, "other-3")
}

///|
test "attention ranking and progressive labels are deterministic" {
  let signals = [
    ecosystem_test_signal("zeta", AmbientPreview, 50, 10),
    ecosystem_test_signal("alpha", AmbientPreview, 50, 10),
    ecosystem_test_signal("live", RuntimeLive, 65, 10),
  ]
  let first = ecosystem_rank_attention(signals, [], 10, 2)
  let second = ecosystem_rank_attention(signals, [], 10, 2)
  assert_eq(first.length(), 2)
  assert_eq(first[0].signal.id, "live")
  assert_eq(first[0].signal.id, second[0].signal.id)
  assert_eq(first[1].signal.id, second[1].signal.id)
  let disclosure = ecosystem_attention_disclosure(first[0].signal)
  assert_true(disclosure.glance.contains("…"))
  assert_true(disclosure.nearby.contains("真实工作"))
  assert_true(disclosure.inspect.contains("Evidence-bearing detail"))
  assert_eq(disclosure.provenance_badge, "REAL · LIVE")
  assert_true(
    ecosystem_attention_label(first[0].signal, Glance) !=
    ecosystem_attention_label(first[0].signal, Inspect),
  )
}

///|
test "runtime adapters keep live work separate from stale records" {
  let live_model = {
    ..init_model(),
    tick: 20,
    energy_valley_runtime: ecosystem_attention_fixture_runtime_state(
      Live,
      "blocked",
    ),
  }
  let live = ecosystem_runtime_attention_signals(live_model, "policy-hall")
  assert_eq(live.length(), 1)
  assert_true(live[0].provenance is RuntimeLive)
  assert_true(live[0].headline.contains("阻塞"))
  assert_eq(live[0].place_id, "policy-hall")
  assert_eq(live[0].interaction_label, "查看真实工作收据")
  let stale_model = {
    ..live_model,
    energy_valley_runtime: ecosystem_attention_fixture_runtime_state(
      Stale,
      "blocked",
    ),
  }
  let stale = ecosystem_runtime_attention_signals(stale_model, "policy-hall")
  assert_eq(stale.length(), 1)
  assert_true(stale[0].provenance is RuntimeRecord)
  assert_true(stale[0].headline.contains("最近工作记录"))
  assert_true(stale[0].detail.contains("不代表 Agent 现在仍在执行"))
  assert_eq(stale[0].interaction_label, "查看最近工作收据")
  assert_true(
    ecosystem_attention_score(live[0], [], 20) >
    ecosystem_attention_score(stale[0], [], 20),
  )
  let projected = live_model.energy_valley_runtime.projection.unwrap()
  let unbound_state = {
    ..live_model.energy_valley_runtime,
    projection: Some({
      ..projected,
      tasks: [],
      agents: [{ ..projected.agents[0], status: "idle", workItemId: None }],
    }),
  }
  let unbound_model = { ..live_model, energy_valley_runtime: unbound_state }
  assert_true(ecosystem_runtime_attention_signals(unbound_model, "").is_empty())
  let completed_model = {
    ..live_model,
    energy_valley_runtime: ecosystem_attention_fixture_runtime_state(
      Live,
      "completed",
    ),
  }
  assert_true(ecosystem_live_work_place_ids(completed_model).is_empty())
}

///|
test "attention feed diversifies repeated runtime records with town life" {
  let model = {
    ..init_model(),
    tick: 20,
    energy_valley_runtime: ecosystem_attention_fixture_runtime_state(
      Stale,
      "completed",
    ),
  }
  let projection = model.energy_valley_runtime.projection.unwrap()
  let duplicated = {
    ..model,
    energy_valley_runtime: {
      ..model.energy_valley_runtime,
      projection: Some({
        ..projection,
        tasks: projection.tasks +
        [
          { ..projection.tasks[0], id: "task-attention-2" },
          { ..projection.tasks[0], id: "task-attention-3" },
        ],
        agents: projection.agents +
        [
          {
            ..projection.agents[0],
            id: "agent-attention-2",
            workItemId: Some("task-attention-2"),
          },
          {
            ..projection.agents[0],
            id: "agent-attention-3",
            workItemId: Some("task-attention-3"),
          },
        ],
      }),
    },
  }
  let feed = ecosystem_attention_feed(duplicated, 20260727, "", [], 3)
  assert_eq(feed.length(), 3)
  assert_eq(
    feed.filter(item => item.signal.provenance is RuntimeRecord).length(),
    1,
  )
  assert_true(feed.any(item => item.signal.provenance is AmbientPreview))
  assert_true(feed.any(item => item.signal.provenance is AuthoredPlace))
}
