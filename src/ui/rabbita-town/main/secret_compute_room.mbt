///|
priv struct SecretComputeAuthority {
  agent_boundary : String
  local_control_plane : String
  claim : String
} derive(Debug, Eq, FromJson)

///|
priv struct SecretComputeActiveTarget {
  app_type : String
  provider_label : String
} derive(Debug, Eq, FromJson)

///|
priv struct SecretComputeGateway {
  state : String
  active_targets : Array[SecretComputeActiveTarget]
  model_count : Int
} derive(Debug, Eq, FromJson)

///|
priv struct SecretComputeMachine {
  id : String
  label : String
  state : String
  architecture : String
  accelerator_count : Int
  memory_total_mib : Int
  memory_free_mib : Int
  healthy : Bool
  running_workloads : Int
  observed_at_unix_ms : String
} derive(Debug, Eq, FromJson)

///|
priv struct SecretComputeLocalCluster {
  configured : Bool
  state : String
  machines : Array[SecretComputeMachine]
} derive(Debug, Eq, FromJson)

///|
priv struct SecretComputeRemoteRoute {
  id : String
  label : String
  state : String
  evidence : String
} derive(Debug, Eq, FromJson)

///|
priv struct SecretComputeRoomProjection {
  schema : String
  mode : String
  observed_at : String
  authority : SecretComputeAuthority
  gateway : SecretComputeGateway
  local_cluster : SecretComputeLocalCluster
  remote_routes : Array[SecretComputeRemoteRoute]
} derive(Debug, Eq, FromJson)

///|
fn secret_compute_room_fallback() -> SecretComputeRoomProjection {
  {
    schema: "moontown.secret-compute-room.v1",
    mode: "unavailable",
    observed_at: "",
    authority: {
      agent_boundary: "MoonGate",
      local_control_plane: "LunaNexa",
      claim: "read-only redacted projection",
    },
    gateway: { state: "unreachable", active_targets: [], model_count: 0 },
    local_cluster: { configured: false, state: "not-configured", machines: [] },
    remote_routes: [
      {
        id: "codex",
        label: "Codex / OpenAI",
        state: "not-observed",
        evidence: "MoonGate has not reported this route.",
      },
      {
        id: "deepseek",
        label: "DeepSeek",
        state: "not-observed",
        evidence: "MoonGate has not reported this route.",
      },
      {
        id: "glm",
        label: "GLM",
        state: "not-observed",
        evidence: "MoonGate has not reported this route.",
      },
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
fn secret_compute_room_projection_valid(
  projection : SecretComputeRoomProjection,
) -> Bool {
  projection.schema == "moontown.secret-compute-room.v1" &&
  projection.authority.agent_boundary == "MoonGate" &&
  projection.authority.local_control_plane == "LunaNexa" &&
  projection.local_cluster.machines.length() <= 64 &&
  projection.remote_routes.length() <= 16 &&
  projection.local_cluster.machines.all(machine => {
    !machine.id.trim().is_empty() &&
    !machine.label.trim().is_empty() &&
    machine.accelerator_count >= 0 &&
    machine.memory_total_mib >= 0 &&
    machine.memory_free_mib >= 0 &&
    machine.memory_free_mib <= machine.memory_total_mib
  }) &&
  projection.remote_routes.all(route => {
    !route.id.trim().is_empty() && !route.label.trim().is_empty()
  })
}

///|
fn parse_secret_compute_room_projection_text(
  text : String,
) -> SecretComputeRoomProjection {
  if text.is_empty() {
    return secret_compute_room_fallback()
  }
  let json = @json.parse(text) catch {
    _ => return secret_compute_room_fallback()
  }
  let projection : SecretComputeRoomProjection = @json.from_json(json) catch {
    _ => return secret_compute_room_fallback()
  }
  if secret_compute_room_projection_valid(projection) {
    projection
  } else {
    secret_compute_room_fallback()
  }
}

///|
fn parse_bootstrap_secret_compute_room_projection() -> SecretComputeRoomProjection {
  parse_secret_compute_room_projection_text(
    load_bootstrap_secret_compute_room_json(),
  )
}

///|
fn secret_compute_state_class(state : String) -> String {
  match state.to_lower() {
    "reachable" | "observed" | "active" | "ready" => " is-ready"
    "unreachable" | "unavailable" | "retired" => " is-offline"
    "unhealthy" => " is-offline"
    _ => " is-unknown"
  }
}

///|
fn secret_compute_state_label(state : String) -> String {
  match state.to_lower() {
    "reachable" => "可达"
    "observed" => "已观测"
    "active" => "活跃"
    "ready" => "就绪"
    "not-observed" => "未观测"
    "not-configured" => "未配置"
    "unreachable" => "不可达"
    "unavailable" => "不可用"
    "unhealthy" => "不健康"
    other => other
  }
}

///|
fn render_secret_compute_status(state : String) -> @rabbita.Html {
  span(class="compute-room-state" + secret_compute_state_class(state), [
    span(
      class="compute-room-state-dot",
      attrs=@html.Attrs::build().aria_hidden("true"),
      "",
    ),
    span(secret_compute_state_label(state)),
  ])
}

///|
fn render_secret_compute_agents(model : Model) -> @rabbita.Html {
  let agents = energy_valley_runtime_active_agents(model.energy_valley_runtime)
  let rows : Array[@rabbita.Html] = []
  for index, agent in agents {
    if index >= 6 {
      break
    }
    rows.push(
      div(class="compute-agent-row", [
        span(class="compute-agent-avatar", "AG"),
        div(class="compute-agent-copy", [
          @html.strong(agent.name),
          span("\{agent.role} · \{agent.status}"),
        ]),
        span(class="compute-route-badge", "经 MoonGate"),
      ]),
    )
  }
  if rows.is_empty() {
    rows.push(
      div(class="compute-room-empty compact", [
        @html.strong("当前没有活跃 Agent"),
        span("真实运行出现后，Agent 会在这里进入治理路由。"),
      ]),
    )
  }
  section(class="compute-room-zone compute-agent-zone", [
    header(class="compute-zone-head", [
      div([p(class="compute-kicker", "TOWN AGENTS"), h2("执行入口")]),
      span(class="compute-zone-count", "\{agents.length()}"),
    ]),
    div(class="compute-agent-list", rows),
    p(
      class="compute-zone-footnote",
      "连接线表示可治理路径，不代表已经获得执行授权。",
    ),
  ])
}

///|
fn render_secret_compute_gateway(
  dispatch : Dispatch[Msg],
  projection : SecretComputeRoomProjection,
  selected : String,
) -> @rabbita.Html {
  button(
    class="compute-gateway-core" +
      (if selected == "moongate" { " is-selected" } else { "" }),
    on_click=dispatch(SelectSecretComputeEndpoint("moongate")),
    attrs=@html.Attrs::build()
      .aria_label("查看 MoonGate 路由边界")
      .aria_pressed(if selected == "moongate" { "true" } else { "false" }),
    [
      span(class="compute-gateway-orbit orbit-one", ""),
      span(class="compute-gateway-orbit orbit-two", ""),
      span(class="compute-gateway-mark", "MG"),
      @html.strong("MoonGate"),
      render_secret_compute_status(projection.gateway.state),
      span(
        class="compute-gateway-caption",
        "凭据 · 路由 · 用量 · 故障转移",
      ),
    ],
  )
}

///|
fn secret_compute_memory_label(machine : SecretComputeMachine) -> String {
  if machine.memory_total_mib <= 0 {
    "显存未上报"
  } else {
    "\{machine.memory_free_mib / 1024} / \{machine.memory_total_mib / 1024} GiB 空闲"
  }
}

///|
fn render_secret_compute_local_cluster(
  dispatch : Dispatch[Msg],
  projection : SecretComputeRoomProjection,
  selected : String,
) -> @rabbita.Html {
  let rows : Array[@rabbita.Html] = []
  for machine in projection.local_cluster.machines {
    rows.push(
      button(
        class="compute-machine" +
          secret_compute_state_class(machine.state) +
          (if selected == machine.id { " is-selected" } else { "" }),
        on_click=dispatch(SelectSecretComputeEndpoint(machine.id)),
        attrs=@html.Attrs::build()
          .aria_label("查看 \{machine.label}")
          .aria_pressed(if selected == machine.id { "true" } else { "false" }),
        [
          span(class="compute-machine-rack", [
            span(class="compute-machine-light", ""),
            span(class="compute-machine-light", ""),
            span(class="compute-machine-light", ""),
          ]),
          span(class="compute-machine-copy", [
            @html.strong(machine.label),
            span(
              "\{machine.architecture} · \{machine.accelerator_count} accelerator",
            ),
            span(secret_compute_memory_label(machine)),
          ]),
          render_secret_compute_status(machine.state),
        ],
      ),
    )
  }
  if rows.is_empty() {
    rows.push(
      div(class="compute-room-empty", [
        @html.strong(
          if projection.local_cluster.configured {
            "LunaNexa 暂无可用机器证据"
          } else {
            "LunaNexa 尚未连接"
          },
        ),
        span(
          if projection.local_cluster.configured {
            "控制面已配置，但节点心跳当前不可用。"
          } else {
            "在 MoonTown 服务端配置受信任的 LunaNexa 端点后，真实节点会以脱敏别名出现。"
          },
        ),
      ]),
    )
  }
  section(class="compute-room-zone compute-local-zone", [
    header(class="compute-zone-head", [
      div([
        p(class="compute-kicker", "LOCAL · LUNANEXA"),
        h2("本地机器阵列"),
      ]),
      render_secret_compute_status(projection.local_cluster.state),
    ]),
    div(class="compute-machine-grid", rows),
    p(
      class="compute-zone-footnote",
      "只显示节点别名与容量摘要；地址、凭据、路径和容器身份不会进入小镇。",
    ),
  ])
}

///|
fn render_secret_compute_remote_routes(
  dispatch : Dispatch[Msg],
  projection : SecretComputeRoomProjection,
  selected : String,
) -> @rabbita.Html {
  let routes = projection.remote_routes.map(route => {
    button(
      class="compute-uplink" +
        secret_compute_state_class(route.state) +
        (if selected == route.id { " is-selected" } else { "" }),
      on_click=dispatch(SelectSecretComputeEndpoint(route.id)),
      attrs=@html.Attrs::build()
        .aria_label("查看 \{route.label} MoonGate 路由")
        .aria_pressed(if selected == route.id { "true" } else { "false" }),
      [
        span(class="compute-uplink-signal", [span(""), span(""), span("")]),
        span(class="compute-uplink-copy", [
          @html.strong(route.label),
          span("MoonGate remote route"),
        ]),
        render_secret_compute_status(route.state),
      ],
    )
  })
  section(class="compute-room-zone compute-remote-zone", [
    header(class="compute-zone-head", [
      div([
        p(class="compute-kicker", "REMOTE · MOONGATE"),
        h2("远程算力上行"),
      ]),
      span(class="compute-zone-count", "\{projection.remote_routes.length()}"),
    ]),
    div(class="compute-uplink-grid", routes),
    p(
      class="compute-zone-footnote",
      "未观测不是故障：它只表示 MoonGate 尚未提供匹配的活动目标或模型证据。",
    ),
  ])
}

///|
fn secret_compute_machine_by_id(
  machines : Array[SecretComputeMachine],
  id : String,
) -> SecretComputeMachine? {
  for machine in machines {
    if machine.id == id {
      return Some(machine)
    }
  }
  None
}

///|
fn secret_compute_route_by_id(
  routes : Array[SecretComputeRemoteRoute],
  id : String,
) -> SecretComputeRemoteRoute? {
  for route in routes {
    if route.id == id {
      return Some(route)
    }
  }
  None
}

///|
fn render_secret_compute_evidence(
  projection : SecretComputeRoomProjection,
  selected : String,
) -> @rabbita.Html {
  let selected_machine = secret_compute_machine_by_id(
    projection.local_cluster.machines,
    selected,
  )
  let selected_route = secret_compute_route_by_id(
    projection.remote_routes,
    selected,
  )
  let title = if selected == "moongate" {
    "MoonGate 治理边界"
  } else {
    match selected_machine {
      Some(machine) => machine.label
      None => selected_route.map(route => route.label).unwrap_or("算力证据")
    }
  }
  let detail = if selected == "moongate" {
    "所有 Agent 请求先进入 MoonGate。提供方被选择、绑定验证和执行授权是三项不同事实。"
  } else {
    match selected_machine {
      Some(machine) =>
        "\{machine.architecture} · \{machine.accelerator_count} accelerator · \{machine.running_workloads} 个已上报工作负载。节点身份已脱敏。"
      None =>
        selected_route
        .map(route => route.evidence)
        .unwrap_or("选择一个节点或上行，查看它的观测证据。")
    }
  }
  aside(
    class="compute-evidence-panel",
    attrs=@html.Attrs::build().aria_live("polite"),
    [
      div(class="compute-evidence-copy", [
        p(class="compute-kicker", "SELECTED EVIDENCE"),
        h2(title),
        p(detail),
      ]),
      @html.dl(class="compute-evidence-facts", [
        div([
          @html.dt("Agent boundary"),
          @html.dd(projection.authority.agent_boundary),
        ]),
        div([
          @html.dt("Local control"),
          @html.dd(projection.authority.local_control_plane),
        ]),
        div([@html.dt("Claim ceiling"), @html.dd(projection.authority.claim)]),
        div([
          @html.dt("Observed"),
          @html.dd(
            if projection.observed_at.is_empty() {
              "No fresh snapshot"
            } else {
              projection.observed_at
            },
          ),
        ]),
      ]),
    ],
  )
}

///|
fn render_secret_compute_room(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let projection = parse_bootstrap_secret_compute_room_projection()
  @html.main_(class="secret-compute-room", [
    div(class="compute-room-ambient ambient-a", ""),
    div(class="compute-room-ambient ambient-b", ""),
    header(class="compute-room-header", [
      div(class="compute-room-title", [
        p(class="compute-kicker", "MOONTOWN · LAYER −1 · READ ONLY"),
        h1("秘密算力室"),
        p(
          "看见真实机器与远程上行，同时把凭据、调度权和执行权留在各自的控制面。",
        ),
      ]),
      div(class="compute-room-header-actions", [
        render_secret_compute_status(projection.mode),
        button(
          class="compute-room-exit",
          on_click=dispatch(CloseSecretComputeRoom),
          attrs=@html.Attrs::build().aria_label("返回能源谷地面层"),
          "↑ 返回小镇",
        ),
      ]),
    ]),
    div(class="compute-room-boundary-note", [
      @html.strong("机密边界"),
      span(
        "这是受控本地环境中的脱敏投影；它不提供远程 Shell、凭据查看或直接调度。",
      ),
    ]),
    section(
      class="compute-room-scene",
      attrs=@html.Attrs::build().aria_label(
        "Agent 到算力控制面的连接图",
      ),
      [
        div(
          class="compute-room-route-lines",
          attrs=@html.Attrs::build().aria_hidden("true"),
          [
            span(class="route-line line-agent", ""),
            span(class="route-line line-local", ""),
            span(class="route-line line-remote", ""),
          ],
        ),
        render_secret_compute_agents(model),
        div(class="compute-gateway-zone", [
          p(class="compute-gateway-overline", "GOVERNED ROUTER"),
          render_secret_compute_gateway(
            dispatch,
            projection,
            model.secret_compute_room_selected_id,
          ),
          div(class="compute-receipt-legend", [
            span("① provider selected"),
            span("② binding verified"),
            span("③ execution receipt"),
          ]),
        ]),
        render_secret_compute_local_cluster(
          dispatch,
          projection,
          model.secret_compute_room_selected_id,
        ),
        render_secret_compute_remote_routes(
          dispatch,
          projection,
          model.secret_compute_room_selected_id,
        ),
      ],
    ),
    render_secret_compute_evidence(
      projection,
      model.secret_compute_room_selected_id,
    ),
  ])
}
