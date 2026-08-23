///|
fn indoor_building_name_for_module_key(
  model : Model,
  module_key : String,
) -> String {
  if module_key.is_empty() {
    return "未指定建筑"
  }
  let buildings = golden_valley_buildings(active_energy_valley_seed())
  for building in energy_valley_model_buildings(model) {
    buildings.push(building)
  }
  for building in buildings {
    if golden_valley_building_module_key(building) == module_key {
      return building.name
    }
  }
  "另一座协作建筑"
}

///|
fn indoor_task_route_label(
  model : Model,
  building : GoldenValleyBuilding,
  task : EnergyValleyRuntimeWorkItem,
) -> String {
  match (task.originBuildingModuleKey, task.destinationBuildingModuleKey) {
    (Some(origin), Some(destination)) if origin != destination =>
      "\{indoor_building_name_for_module_key(model, origin)} → \{indoor_building_name_for_module_key(model, destination)}"
    (_, Some(destination)) if destination !=
      golden_valley_building_module_key(building) =>
      "\{building.name} → \{indoor_building_name_for_module_key(model, destination)}"
    (Some(origin), _) if origin != golden_valley_building_module_key(building) =>
      "\{indoor_building_name_for_module_key(model, origin)} → \{building.name}"
    _ => "在本楼工作"
  }
}

///|
fn render_indoor_work(
  model : Model,
  building : GoldenValleyBuilding,
) -> @rabbita.Html {
  let tasks = golden_valley_runtime_tasks_for_building(
    model.energy_valley_runtime,
    building,
  )
  let rows : Array[@rabbita.Html] = []
  let count = tasks.length().min(6)
  for index in 0..<count {
    let task = tasks[index]
    let agent = task.agentName.unwrap_or("未绑定 Agent")
    rows.push(
      article(class="building-interior-work-row", [
        div(class="building-interior-work-head", [
          @html.strong(task.title),
          span(
            class="building-interior-work-state",
            town_chronicle_status_label(task.status),
          ),
        ]),
        p("\{agent} · \{indoor_task_route_label(model, building, task)}"),
      ]),
    )
  }
  section(class="building-interior-panel building-interior-work", [
    header(class="building-interior-panel-head", [
      div([
        p(class="building-interior-eyebrow", "BUILDING WORK"),
        h2("楼内工作与跨楼交接"),
      ]),
      span("\{tasks.length()} 项"),
    ]),
    if rows.is_empty() {
      p(
        class="building-interior-empty",
        if energy_valley_runtime_can_claim_active_work(
            model.energy_valley_runtime,
          ) {
          "运行时已连接，但这座建筑当前没有真实工作。"
        } else {
          "当前没有可声明为实时的楼内工作；不会用演示活动代替。"
        },
      )
    } else {
      div(class="building-interior-work-list", rows)
    },
  ])
}

///|
fn render_indoor_presence_summary(
  snapshot : @energy_valley_contract.TownSnapshot,
  place : @energy_valley_contract.Place,
) -> @rabbita.Html {
  let rows : Array[@rabbita.Html] = []
  for presence in snapshot.presences_at(place.id) {
    if presence.phase is @energy_valley_contract.Inside {
      rows.push(render_town_snapshot_inside_presence(presence))
    }
  }
  section(class="building-interior-panel building-interior-agents", [
    header(class="building-interior-panel-head", [
      div([
        p(class="building-interior-eyebrow", "INDOOR PRESENCE"),
        h2("正在室内的 Agent"),
      ]),
      span("\{rows.length()} 位"),
    ]),
    if rows.is_empty() {
      p(
        class="building-interior-empty",
        "当前没有 Agent 被真实分配到本楼交互位。",
      )
    } else {
      div(class="building-interior-agent-list", rows)
    },
  ])
}

///|
fn render_indoor_compute_lift(dispatch : Dispatch[Msg]) -> @rabbita.Html {
  section(class="building-interior-panel building-compute-lift", [
    div(class="building-lift-copy", [
      p(class="building-interior-eyebrow", "SECURED LIFT · LAYER −1"),
      h2("地下算力链路"),
      p(
        "楼内 Agent 不直接连接机器。请求先穿过 MoonGate，再由受控路由选择 LunaNexa 本地算力或远程模型。",
      ),
    ]),
    div(
      class="building-lift-route",
      attrs=@html.Attrs::build().aria_label(
        "楼内 Agent 经 MoonGate 连接地下算力",
      ),
      [
        span("楼内 Agent"),
        span(class="building-lift-arrow", "→"),
        @html.strong("MoonGate"),
        span(class="building-lift-arrow", "↓"),
        span("LunaNexa / Remote"),
      ],
    ),
    button(
      class="building-lift-button",
      on_click=dispatch(OpenSecretComputeRoom),
      attrs=@html.Attrs::build().aria_label(
        "乘安全电梯前往地下算力室",
      ),
      "乘安全电梯前往地下 →",
    ),
  ])
}

///|
fn render_energy_valley_building_interior(
  dispatch : Dispatch[Msg],
  model : Model,
  snapshot : @energy_valley_contract.TownSnapshot,
  building : GoldenValleyBuilding,
) -> @rabbita.Html {
  let place = town_snapshot_place_for_building_view(model, snapshot, building)
  @html.main_(class="building-interior-layer", [
    header(class="building-interior-header", [
      div(class="building-interior-title", [
        @html.nav(
          class="building-layer-breadcrumb",
          attrs=@html.Attrs::build().aria_label("MoonTown 空间层级"),
          [
            button(on_click=dispatch(ExitEnergyBuilding), "地面小镇"),
            span("/"),
            @html.strong("室内层"),
            span("/"),
            button(on_click=dispatch(OpenSecretComputeRoom), "地下算力"),
          ],
        ),
        p(class="building-interior-eyebrow", "MOONTOWN · LAYER 0 · INDOOR"),
        h1(building.name),
        p(golden_valley_building_description(building)),
      ]),
      button(
        class="building-interior-exit",
        on_click=dispatch(ExitEnergyBuilding),
        attrs=@html.Attrs::build().aria_label("返回地面小镇"),
        "← 返回地面",
      ),
    ]),
    div(class="building-interior-location", [
      span(class="is-complete", "地面"),
      span(class="building-location-line", ""),
      span(class="is-current", "室内"),
      span(class="building-location-line", ""),
      span("地下"),
    ]),
    div(class="building-interior-grid", [
      section(class="building-interior-floor-shell", [
        match place {
          Some(value) =>
            render_town_snapshot_graphical_interior_scene(snapshot, value)
          None =>
            div(class="building-interior-unavailable", [
              h2("室内结构尚不可用"),
              p(
                "这座建筑仍可返回地面，但尚未发布可验证的交互位。",
              ),
            ])
        },
      ]),
      div(class="building-interior-side", [
        match place {
          Some(value) => render_indoor_presence_summary(snapshot, value)
          None => @html.nothing
        },
        render_indoor_work(model, building),
      ]),
    ]),
    render_indoor_compute_lift(dispatch),
  ])
}
