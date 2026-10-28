///|
test "compute selection shows health capacity and observation before advanced" {
  let base = secret_compute_room_fallback()
  let machine : SecretComputeMachine = {
    id: "node-a",
    label: "本地节点",
    state: "unhealthy",
    architecture: "arm64",
    accelerator_count: 2,
    memory_total_mib: 32768,
    memory_free_mib: 16384,
    healthy: false,
    running_workloads: 3,
    observed_at_unix_ms: "1000",
    metrics_reported: None,
  }
  let projection = {
    ..base,
    mode: "observed",
    observed_at: "2026-10-22T10:00:00Z",
    local_cluster: { configured: true, state: "observed", machines: [machine], },
  }
  let html = disclosure_test_html(
    render_secret_compute_evidence(projection, machine.id),
  )
  let primary = html.split("<details").to_array()[0]
  assert_true(primary.contains("本地节点"))
  assert_true(primary.contains("不健康"))
  assert_true(primary.contains("16 / 32 GiB 空闲"))
  assert_true(primary.contains("已上报工作负载：3"))
  assert_true(primary.contains("健康检查异常"))
  assert_true(primary.contains("物理位置未绑定"))
  assert_true(primary.contains(projection.observed_at))
  assert_false(primary.contains("read-only redacted projection"))
  assert_true(html.contains("read-only redacted projection"))
  let stage = disclosure_test_html(
    render_compute_spatial_stage(
      { ..init_model(), town_spatial_layer: Underground(None), },
      projection,
    ),
  )
  assert_true(stage.contains("town-space-host"))
  assert_true(stage.contains("node-a"))
  assert_true(stage.contains("16 / 32 GiB 空闲"))
  assert_false(stage.contains("rack_id"))
  assert_false(stage.contains("compute-world-machine-hotspot"))
}

///|
fn compute_test_reported_route() -> SecretComputeRoomProjection {
  {
    ..secret_compute_room_fallback(),
    remote_routes: [
      {
        id: "kimi",
        label: "Kimi",
        state: "not-observed",
        evidence: "MoonGate has not reported this route.",
      },
    ],
  }
}

///|
test "unavailable route stays visible without technical evidence upfront" {
  let html = disclosure_test_html(
    render_secret_compute_evidence(compute_test_reported_route(), "kimi"),
  )
  let primary = html.split("<details").to_array()[0]
  assert_true(primary.contains("Kimi"))
  assert_true(primary.contains("未观测"))
  assert_true(primary.contains("尚无观测快照"))
  assert_true(primary.contains("外部服务 · 不对应本地机柜"))
  assert_false(primary.contains("MoonGate has not reported"))
  assert_true(html.contains("MoonGate has not reported"))
  assert_false(html.contains(" open"))
}

///|
test "compute roster exposes selection without relying on color" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let html = disclosure_test_html(
    render_compute_world_roster(dispatch, compute_test_reported_route(), "kimi"),
  )
  assert_eq(html.split("aria-pressed=\"true\"").to_array().length(), 2)
  assert_true(html.contains("未观测"))
}

///|
test "unknown compute metrics and unassigned physical position remain primary" {
  let machine : SecretComputeMachine = {
    id: "trial-node",
    label: "Trial",
    state: "not-observed",
    architecture: "arm64",
    accelerator_count: 0,
    memory_total_mib: 0,
    memory_free_mib: 0,
    healthy: false,
    running_workloads: 0,
    observed_at_unix_ms: "",
    metrics_reported: Some(false),
  }
  let projection = {
    ..secret_compute_room_fallback(),
    local_cluster: {
      configured: true,
      state: "not-observed",
      machines: [machine],
    },
  }
  let html = disclosure_test_html(
    render_secret_compute_evidence(projection, machine.id),
  )
  let primary = html.split("<details").to_array()[0]
  for
    label in [
      "未观测", "显存未上报", "工作负载未上报", "健康状态未上报",
      "物理位置未绑定",
    ] {
    assert_true(primary.contains(label))
  }
  assert_false(primary.contains("健康检查异常"))
  assert_false(primary.contains("已上报工作负载：0"))
}

///|
test "indoor context keeps one start action and folds the full slot roster" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let base = { ..init_model(), energy_intro_open: false, }
  let snapshot = ecosystem_contract_town_snapshot(
    base,
    active_energy_valley_seed(),
  )
  let building = golden_valley_buildings(active_energy_valley_seed())[0]
  let place = town_snapshot_place_for_building_view(base, snapshot, building).unwrap()
  let slot = place.interaction_slots
    .iter()
    .find_first(slot => {
      slot.kind is @energy_valley_contract.Workstation ||
      slot.kind is @energy_valley_contract.ServicePoint ||
      slot.kind is @energy_valley_contract.ExchangeDesk
    })
    .unwrap()
  let model = {
    ..base,
    town_spatial_layer: Indoor(building),
    indoor_selected_slot_id: slot.id.local_key(),
  }
  let inspector = disclosure_test_html(
    render_indoor_slot_inspector(dispatch, model, snapshot, place),
  )
  let primary = inspector.split("<details").to_array()[0]
  assert_true(primary.contains(slot.label))
  assert_true(primary.contains("新工作"))
  assert_false(primary.contains("indoor-slot-roster"))
  assert_false(primary.contains("Place："))
  assert_true(inspector.contains("indoor-slot-roster"))
  assert_true(inspector.contains("aria-pressed=\"true\""))
  let html = disclosure_test_html(
    render_energy_valley_building_interior(dispatch, model, snapshot, building),
  )
  assert_eq(html.split(">新工作<").to_array().length(), 2)
  assert_true(html.contains("town-space-host"))
  assert_false(html.contains("<iframe"))
}

///|
test "pending space request does not offer a second start action" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let model = { ..init_model(), spatial_request_id: "accepted-request", }
  let html = disclosure_test_html(render_spatial_work_journey(dispatch, model))
  assert_true(html.contains("请求已提交"))
  assert_false(html.contains("新工作"))
}

///|
test "current work keeps missing resource binding above technical details" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let model = {
    ..resident_explorer_test_model(),
    spatial_selected_work_id: "research-task",
    town_spatial_layer: Underground(None),
  }
  let html = disclosure_test_html(render_spatial_work_journey(dispatch, model))
  let primary = html.split("<details").to_array()[0]
  assert_true(primary.contains("当前工作"))
  assert_true(primary.contains("执行资源尚未关联"))
  assert_false(primary.contains("Run："))
  assert_true(html.contains("没有可验证的 Run"))
}
