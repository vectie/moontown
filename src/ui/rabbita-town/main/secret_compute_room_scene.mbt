///|
fn compute_scene_machine_normalized_position(index : Int) -> (Double, Double) {
  let column = index % 4
  let row = index / 4
  (0.58 + column.to_double() * 0.095, 0.18 + row.to_double() * 0.22)
}

///|
fn compute_scene_agent_normalized_position(index : Int) -> (Double, Double) {
  let column = index % 2
  let row = index / 2
  (0.10 + column.to_double() * 0.16, 0.45 + row.to_double() * 0.16)
}

///|
fn compute_scene_route_screen_position(
  index : Int,
  count : Int,
  width : Int,
  height : Int,
) -> (Double, Double) {
  let visible = count.min(6).max(1)
  let spread = if visible <= 1 {
    0.5
  } else {
    index.to_double() / (visible - 1).to_double()
  }
  ((0.28 + spread * 0.47) * width.to_double(), 0.31 * height.to_double())
}

///|
fn draw_secret_compute_world_canvas(
  model : Model,
  projection : SecretComputeRoomProjection,
) -> Unit {
  let canvas_id = "secret-compute-world-canvas"
  prepare_golden_valley_canvas(canvas_id)
  let width = golden_valley_canvas_width(canvas_id)
  let height = golden_valley_canvas_height(canvas_id)
  match @canvas.get_context2d(canvas_id) {
    None => ()
    Some(context) => {
      context.clear_rect(0.0, 0.0, width.to_double(), height.to_double())
      ignore(
        spatial_world_canvas_draw_plate(
          context, canvas_id, "/tilemap/rooms/moontown-spatial-v1/underground-empty-room.jpg",
          width, height, "#334b57",
        ),
      )
      let scale = spatial_scene_scale(width)
      let (gateway_x, gateway_y) = spatial_scene_anchor(
        width, height, 0.50, 0.64, true,
      )
      let route_visible = projection.remote_routes.length().min(6)
      for index in 0..<route_visible {
        let (route_x, route_y) = compute_scene_route_screen_position(
          index, route_visible, width, height,
        )
        spatial_world_canvas_draw_connection(
          context,
          gateway_x,
          gateway_y,
          route_x,
          route_y + 22.0 * scale,
          "rgba(131,190,208,.48)",
        )
      }
      let machine_visible = projection.local_cluster.machines.length().min(8)
      for index in 0..<machine_visible {
        let (normalized_x, normalized_y) = compute_scene_machine_normalized_position(
          index,
        )
        let (machine_x, machine_y) = spatial_scene_anchor(
          width, height, normalized_x, normalized_y, true,
        )
        spatial_world_canvas_draw_connection(
          context, gateway_x, gateway_y, machine_x, machine_y, "rgba(229,184,64,.38)",
        )
      }
      let agents = energy_valley_runtime_active_agents(
        model.energy_valley_runtime,
      )
      let agent_visible = agents.length().min(6)
      for index in 0..<agent_visible {
        let (normalized_x, normalized_y) = compute_scene_agent_normalized_position(
          index,
        )
        let (agent_x, agent_y) = spatial_scene_anchor(
          width, height, normalized_x, normalized_y, true,
        )
        spatial_world_canvas_draw_connection(
          context, agent_x, agent_y, gateway_x, gateway_y, "rgba(111,166,83,.40)",
        )
      }
      for index in 0..<route_visible {
        let route = projection.remote_routes[index]
        let (route_x, route_y) = compute_scene_route_screen_position(
          index, route_visible, width, height,
        )
        let authored = spatial_world_canvas_draw_atlas_prop(
          context,
          canvas_id,
          "/tilemap/props/moontown-spatial-v2/route-terminal.png",
          1,
          1,
          0,
          route_x,
          route_y + 16.0 * scale,
          scale,
          158.0,
          0.84,
          model.secret_compute_room_selected_id == route.id,
          route.state,
        )
        if !authored {
          spatial_world_canvas_draw_compute_entity(
            context,
            "terminal",
            route_x,
            route_y,
            scale,
            route.state,
            model.secret_compute_room_selected_id == route.id,
          )
        }
      }
      // Empty frames are physical capacity, not claimed machines. A projected
      // LunaNexa Node replaces the corresponding bay with an occupied rack.
      for index in machine_visible..<4 {
        let (normalized_x, normalized_y) = compute_scene_machine_normalized_position(
          index,
        )
        let (rack_x, rack_y) = spatial_scene_anchor(
          width, height, normalized_x, normalized_y, true,
        )
        ignore(
          spatial_world_canvas_draw_atlas_prop(
            context, canvas_id, "/tilemap/props/moontown-spatial-v2/compute-props-atlas.png",
            3, 2, 0, rack_x, rack_y, scale, 218.0, 0.84, false, "vacant",
          ),
        )
      }
      for index in 0..<machine_visible {
        let machine = projection.local_cluster.machines[index]
        let (normalized_x, normalized_y) = compute_scene_machine_normalized_position(
          index,
        )
        let (machine_x, machine_y) = spatial_scene_anchor(
          width, height, normalized_x, normalized_y, true,
        )
        let authored = spatial_world_canvas_draw_atlas_prop(
          context,
          canvas_id,
          "/tilemap/props/moontown-spatial-v2/compute-props-atlas.png",
          3,
          2,
          1,
          machine_x,
          machine_y,
          scale,
          218.0,
          0.84,
          model.secret_compute_room_selected_id == machine.id,
          machine.state,
        )
        if !authored {
          spatial_world_canvas_draw_compute_entity(
            context,
            "rack",
            machine_x,
            machine_y,
            scale,
            machine.state,
            model.secret_compute_room_selected_id == machine.id,
          )
        }
      }
      for index in 0..<agent_visible {
        let (normalized_x, normalized_y) = compute_scene_agent_normalized_position(
          index,
        )
        let (agent_x, agent_y) = spatial_scene_anchor(
          width, height, normalized_x, normalized_y, true,
        )
        let authored = spatial_world_canvas_draw_atlas_prop(
          context,
          canvas_id,
          "/tilemap/props/moontown-spatial-v2/compute-props-atlas.png",
          3,
          2,
          3,
          agent_x,
          agent_y,
          scale,
          224.0,
          0.84,
          false,
          agents[index].status,
        )
        if !authored {
          spatial_world_canvas_draw_compute_entity(
            context,
            "console",
            agent_x,
            agent_y,
            scale,
            agents[index].status,
            false,
          )
        }
        spatial_world_canvas_draw_agent(
          context,
          canvas_id,
          "/tilemap/actors/roster/resident_\{index.abs() % 3}.png",
          agent_x,
          agent_y + 24.0 * scale,
          scale,
          true,
        )
      }
      let authored_gateway = spatial_world_canvas_draw_atlas_prop(
        context,
        canvas_id,
        "/tilemap/props/moontown-spatial-v2/compute-props-atlas.png",
        3,
        2,
        2,
        gateway_x,
        gateway_y,
        scale,
        268.0,
        0.84,
        model.secret_compute_room_selected_id == "moongate",
        projection.gateway.state,
      )
      if !authored_gateway {
        spatial_world_canvas_draw_compute_entity(
          context,
          "gateway",
          gateway_x,
          gateway_y,
          scale,
          projection.gateway.state,
          model.secret_compute_room_selected_id == "moongate",
        )
      }
    }
  }
}

///|
fn render_compute_world_hotspots(
  dispatch : Dispatch[Msg],
  projection : SecretComputeRoomProjection,
  selected : String,
) -> @rabbita.Html {
  let hotspots : Array[@rabbita.Html] = []
  hotspots.push(
    button(
      class="spatial-world-hotspot compute-world-gateway-hotspot" +
        (if selected == "moongate" { " is-selected" } else { "" }),
      style=spatial_scene_hotspot_style(0.50, 0.64, true, 12.0, 22.0),
      on_click=dispatch(SelectSecretComputeEndpoint("moongate")),
      attrs=@html.Attrs::build()
        .aria_label("查看 MoonGate 治理边界")
        .aria_pressed(if selected == "moongate" { "true" } else { "false" }),
      span(class="sr-only", "MoonGate"),
    ),
  )
  let machine_visible = projection.local_cluster.machines.length().min(8)
  for index in 0..<machine_visible {
    let machine = projection.local_cluster.machines[index]
    let (normalized_x, normalized_y) = compute_scene_machine_normalized_position(
      index,
    )
    hotspots.push(
      button(
        class="spatial-world-hotspot compute-world-machine-hotspot" +
          (if selected == machine.id { " is-selected" } else { "" }),
        style=spatial_scene_hotspot_style(
          normalized_x, normalized_y, true, 8.0, 22.0,
        ),
        on_click=dispatch(SelectSecretComputeEndpoint(machine.id)),
        attrs=@html.Attrs::build()
          .aria_label(
            "LunaNexa 机器 \{machine.label}，\{machine.architecture}，\{secret_compute_state_label(machine.state)}",
          )
          .aria_pressed(if selected == machine.id { "true" } else { "false" }),
        span(class="sr-only", "NODE · \{machine.id} · \{machine.label}"),
      ),
    )
  }
  let route_visible = projection.remote_routes.length().min(6)
  for index in 0..<route_visible {
    let route = projection.remote_routes[index]
    let spread = if route_visible <= 1 {
      0.5
    } else {
      index.to_double() / (route_visible - 1).to_double()
    }
    hotspots.push(
      button(
        class="spatial-world-hotspot compute-world-route-hotspot" +
          (if selected == route.id { " is-selected" } else { "" }),
        style=[
          "left: \{28.0 + spread * 47.0}%",
          "top: 31%",
          "width: 7%",
          "height: 13%",
        ],
        on_click=dispatch(SelectSecretComputeEndpoint(route.id)),
        attrs=@html.Attrs::build()
          .aria_label(
            "MoonGate 远程路由 \{route.label}，\{secret_compute_state_label(route.state)}",
          )
          .aria_pressed(if selected == route.id { "true" } else { "false" }),
        span(class="sr-only", "ROUTE · \{route.id} · \{route.label}"),
      ),
    )
  }
  div(class="spatial-world-hotspots", hotspots)
}

///|
fn render_compute_world_roster(
  dispatch : Dispatch[Msg],
  projection : SecretComputeRoomProjection,
  selected : String,
) -> @rabbita.Html {
  let entries : Array[@rabbita.Html] = []
  entries.push(
    button(
      class="compute-world-roster-entry" +
        (if selected == "moongate" { " is-selected" } else { "" }),
      on_click=dispatch(SelectSecretComputeEndpoint("moongate")),
      [
        @html.strong("MoonGate"),
        span(secret_compute_state_label(projection.gateway.state)),
      ],
    ),
  )
  for machine in projection.local_cluster.machines {
    entries.push(
      button(
        class="compute-world-roster-entry" +
          (if selected == machine.id { " is-selected" } else { "" }),
        on_click=dispatch(SelectSecretComputeEndpoint(machine.id)),
        [
          @html.strong(machine.label),
          span(secret_compute_state_label(machine.state)),
        ],
      ),
    )
  }
  for route in projection.remote_routes {
    entries.push(
      button(
        class="compute-world-roster-entry" +
          (if selected == route.id { " is-selected" } else { "" }),
        on_click=dispatch(SelectSecretComputeEndpoint(route.id)),
        [
          @html.strong(route.label),
          span(secret_compute_state_label(route.state)),
        ],
      ),
    )
  }
  div(
    class="compute-world-roster",
    attrs=@html.Attrs::build().aria_label("算力室实体检查器"),
    entries,
  )
}

///|
fn render_secret_compute_graphical_scene(
  dispatch : Dispatch[Msg],
  model : Model,
  projection : SecretComputeRoomProjection,
) -> @rabbita.Html {
  schedule_spatial_world_canvas("secret-compute-world-canvas", () => {
    draw_secret_compute_world_canvas(model, projection)
  })
  section(
    class="compute-physical-room compute-world-scene",
    attrs=@html.Attrs::build().aria_label(
      "地下算力室等距世界：运行时 Agent 经 MoonGate 连接 LunaNexa 机器和远程路由",
    ),
    [
      div(class="spatial-world-stage compute-world-stage", [
        canvas(
          id="secret-compute-world-canvas",
          class="spatial-world-canvas",
          attrs=@html.Attrs::build().aria_label(
            "等距地下算力室：Actor、MoonGate、Node 与 Route 的治理拓扑",
          ),
          no_children(),
        ),
        render_compute_world_hotspots(
          dispatch,
          projection,
          model.secret_compute_room_selected_id,
        ),
      ]),
      render_compute_world_roster(
        dispatch,
        projection,
        model.secret_compute_room_selected_id,
      ),
      div(class="spatial-world-legend compute-world-legend", [
        span("Actor = 活跃运行时 Agent"),
        span("Node = LunaNexa 观测机器"),
        span("空机架 = 物理容量，不代表观测机器"),
        span("Route = MoonGate 远程上行"),
        span("机房结构与线缆仅为渲染结构"),
        span("不会用装饰性服务器冒充真实机器"),
      ]),
    ],
  )
}
