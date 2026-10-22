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
  dispatch : Dispatch[Msg],
  model : Model,
  building : GoldenValleyBuilding,
) -> @rabbita.Html {
  let tasks = indoor_work_items(model, building)
  let rows : Array[@rabbita.Html] = []
  let count = tasks.length()
  for index in 0..<count {
    let task = tasks[index]
    let agent = task.agentName.unwrap_or("未绑定 Agent")
    rows.push(
      article(class="building-interior-work-row", [
        div(class="building-interior-work-head", [
          button(
            on_click=dispatch(SelectSpatialWork(task.id)),
            town_chronicle_safe_task_title(task),
          ),
          span(
            class="building-interior-work-state",
            town_chronicle_status_label(task.status),
          ),
        ]),
        p("\{agent} · \{indoor_task_route_label(model, building, task)}"),
        match task.destinationBuildingModuleKey {
          Some(destination) if destination !=
            golden_valley_building_module_key(building) =>
            button(
              on_click=dispatch(EnterEnergyBuilding(destination)),
              town_ui_label("building", "前往协作楼"),
            )
          _ => @html.nothing
        },
      ]),
    )
  }
  section(class="building-interior-panel building-interior-work", [
    header(class="building-interior-panel-head", [
      div([h2("楼内工作")]),
      span("\{tasks.length()} 项"),
    ]),
    if rows.is_empty() {
      p(
        class="building-interior-empty",
        if energy_valley_runtime_can_claim_active_work(
            model.energy_valley_runtime,
          ) {
          "暂无进行中的工作。"
        } else {
          "工作动态暂未连接。"
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
      let name = snapshot
        .find_actor_profile(presence.actor_id)
        .map(profile => profile.display_name)
        .unwrap_or("居民")
      let origin = if presence.provenance.kind
        is @energy_valley_contract.RuntimeProjection {
        "运行时记录"
      } else {
        "预览居民"
      }
      rows.push(
        div(class="semantic-interior-presence", [
          div([
            span(class="semantic-interior-presence-name", name),
            p(
              "\{origin} · \{town_snapshot_presence_phase_label(presence.phase)}",
            ),
          ]),
        ]),
      )
    }
  }
  section(class="building-interior-panel building-interior-agents", [
    header(class="building-interior-panel-head", [
      div([h2("室内居民")]),
      span("\{rows.length()} 位"),
    ]),
    if rows.is_empty() {
      p(class="building-interior-empty", "暂无代理入驻。")
    } else {
      div(class="building-interior-agent-list", rows)
    },
  ])
}

///|
fn render_indoor_compute_lift(dispatch : Dispatch[Msg]) -> @rabbita.Html {
  section(class="building-interior-panel building-compute-lift", [
    div(class="building-lift-copy", [
      h2("地下算力室"),
      p("查看机器、容量和连接状态。"),
    ]),
    button(
      class="building-lift-button",
      on_click=dispatch(OpenSecretComputeRoom),
      attrs=@html.Attrs::build().aria_label(
        "乘安全电梯前往地下算力室",
      ),
      town_ui_label("server", "地下"),
    ),
    render_advanced_details("算力如何连接", [
      p(
        "楼内 Agent 的请求经 MoonGate 路由至 LunaNexa 本地算力或远程模型。",
      ),
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
    ]),
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
          [span("小镇"), span("/"), @html.strong("室内")],
        ),
        h1(building.name),
      ]),
      button(
        class="building-interior-exit",
        title="返回地面小镇",
        on_click=dispatch(ExitEnergyBuilding),
        attrs=@html.Attrs::build().aria_label("返回地面小镇"),
        town_ui_label("back", "小镇"),
      ),
    ]),
    div(class="building-interior-grid", [
      section(class="building-interior-floor-shell", [
        match place {
          Some(value) =>
            render_town_snapshot_graphical_interior_scene(
              dispatch, model, snapshot, value,
            )
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
        render_policy_hall_question_action(dispatch, building),
        match place {
          Some(value) =>
            render_indoor_slot_inspector(dispatch, model, snapshot, value)
          None => @html.nothing
        },
        render_indoor_work(dispatch, model, building),
        render_spatial_work_journey(dispatch, model),
        render_indoor_compute_lift(dispatch),
        render_advanced_details(
          "居民与建筑信息",
          compact_label="居民与建筑",
          [
            p(golden_valley_building_description(building)),
            match place {
              Some(value) => render_indoor_presence_summary(snapshot, value)
              None => @html.nothing
            },
          ],
        ),
      ]),
    ]),
    render_spatial_overlays(dispatch, model),
  ])
}
