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
  assert_true(primary.contains(projection.observed_at))
  assert_false(primary.contains("read-only redacted projection"))
  assert_true(html.contains("read-only redacted projection"))
}

///|
test "unavailable route stays visible without technical evidence upfront" {
  let html = disclosure_test_html(
    render_secret_compute_evidence(secret_compute_room_fallback(), "kimi"),
  )
  let primary = html.split("<details").to_array()[0]
  assert_true(primary.contains("Kimi"))
  assert_true(primary.contains("未观测"))
  assert_true(primary.contains("尚无观测快照"))
  assert_false(primary.contains("MoonGate has not reported"))
  assert_true(html.contains("MoonGate has not reported"))
  assert_false(html.contains(" open"))
}

///|
test "compute roster exposes selection without relying on color" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let html = disclosure_test_html(
    render_compute_world_roster(
      dispatch,
      secret_compute_room_fallback(),
      "kimi",
    ),
  )
  assert_eq(html.split("aria-pressed=\"true\"").to_array().length(), 2)
  assert_true(html.contains("未观测"))
}
