///|
test "account compute distinguishes binding from machine telemetry" {
  let projection = parse_secret_compute_room_projection_text(
    (
      #|{"schema":"moontown.secret-compute-room.v1","mode":"observed","observed_at":"now","scope":{"state":"bound","account":{"contract_id":"moontown.account-context.v1","user_id":"lunanexa:a","display_name":"Alice","account_kind":"member","plan":"visitor","roles":["member"],"entitlements":["town.public.explore","town.public.discover","compute.own.view"],"active_tenant_id":null,"active_tenant_name":null,"tenant_choices":[],"home_surface":"public-town","visitor":false},"organizations":[]},"authority":{"agent_boundary":"MoonGate","local_control_plane":"LunaNexa","claim":"account-owned"},"gateway":{"state":"not-observed","active_targets":[],"model_count":0},"local_cluster":{"configured":true,"state":"bound","machines":[{"id":"assigned-machine:a","label":"lease-a","state":"ready","architecture":"未提供硬件信息","accelerator_count":0,"memory_total_mib":0,"memory_free_mib":0,"healthy":true,"running_workloads":0,"observed_at_unix_ms":"","metrics_reported":false}]},"remote_routes":[]}
    ),
  )
  assert_true(
    projection.scope
    is Some(
      { state: "bound", account: Some({ display_name: "Alice", .. }), .. }
    ),
  )
  let machine = projection.local_cluster.machines[0]
  assert_eq(secret_compute_workload_label(machine), "工作负载未上报")
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_compute_account_scope(projection)),
  )
  assert_true(html.contains("Alice"))
  assert_true(html.contains("1 台授权机器"))
  let unknown = {
    ..projection,
    local_cluster: {
      ..projection.local_cluster,
      machines: [{ ..machine, healthy: false, }],
    },
  }
  let evidence = @rabbita.render_to_string(
    @rabbita.static_cell(render_secret_compute_evidence(unknown, machine.id)),
  )
  assert_true(evidence.contains("健康状态未上报"))
  assert_false(evidence.contains("健康检查异常"))
  assert_eq(secret_compute_state_label("public-demo"), "公共展示")
}

///|
test "organization choices are action links not opaque identity fields" {
  let projection = {
    ..secret_compute_room_fallback(),
    scope: Some({
      state: "select-organization",
      audience: Some("personal"),
      account: None,
      organizations: [{ id: "org-a", label: "研发团队", }],
    }),
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_compute_account_scope(projection)),
  )
  assert_true(html.contains("选择要查看的组织"))
  assert_true(html.contains("compute-organization=org-a"))
  assert_true(html.contains("研发团队"))
  assert_false(html.contains("<input"))
}

///|
test "shared account entry preserves the deployed origin and never promises local binding" {
  assert_eq(
    shared_account_portal_url("https://suanli.kechuangfuwu.com"),
    "https://suanli.kechuangfuwu.com/user/",
  )
  let public_entry = "https://suanli.kechuangfuwu.com:8443/user/"
  for
    origin in [
      "https://suanli.kechuangfuwu.com:8443", "http://127.0.0.1:17842", "https://suanli.kechuangfuwu.com.evil.example",
      "",
    ] {
    assert_eq(shared_account_portal_url(origin), public_entry)
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_compute_account_scope(secret_compute_room_fallback()),
    ),
  )
  assert_true(html.contains(public_entry))
  assert_true(html.contains("在线账户"))
  assert_true(html.contains("统一账户尚未接入"))
  assert_true(html.contains("noopener noreferrer"))
  assert_true(html.contains("新标签页"))
  assert_false(html.contains("账户已连接"))
}
