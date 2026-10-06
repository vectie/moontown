///|
fn spatial_origin_building(model : Model) -> GoldenValleyBuilding? {
  match model.town_spatial_layer {
    Indoor(building) | Underground(Some(building)) => Some(building)
    _ => model.energy_selected_building
  }
}

///|
fn spatial_start_work_model(model : Model) -> Model {
  if model.request_submitting {
    return reopen_pending_operator_request_model(model)
  }
  let building = spatial_origin_building(model)
  let name = building.map(value => value.name).unwrap_or("小镇")
  let module_key = building.map(golden_valley_building_module_key).unwrap_or("")
  {
    ..close_town_transient_surfaces(model),
    town_spatial_layer: model.town_spatial_layer,
    energy_request_open: true,
    request_composer: StandingWatchComposer,
    request_title: "\{name} · 本地议题调查",
    request_prompt: "请围绕以下本地议题建立可追踪、可审阅的工作。\n\n议题与受影响的人群：\n希望改善的现状：\n已有材料：\n需要人来决定的事项：\n\n建筑上下文：\{module_key}\n工作台上下文：\{model.indoor_selected_slot_id}\n请区分问题、证据、政策选项、实施约束和待核实事项；列出来源与版本，最后提供可打开的结果页。建筑和工作台仅为上下文，最终 Agent 与机器由授权调度选择；不要自动执行政策或提交申请。",
    request_submitting: false,
    request_status: "补充议题后确认提交。接受请求不等于已执行。",
  }
}

///|
fn spatial_selected_work(model : Model) -> EnergyValleyRuntimeWorkItem? {
  guard model.energy_valley_runtime.projection is Some(projection) else {
    return None
  }
  let matches = fn(task : EnergyValleyRuntimeWorkItem) {
    task.id == model.spatial_selected_work_id ||
    (
      !model.spatial_request_id.is_empty() &&
      task.requestId == Some(model.spatial_request_id)
    )
  }
  // Explicit selection wins over a newly accepted request, including history.
  let all = projection.tasks.copy()
  for task in projection.history.unwrap_or([]) {
    all.push(task)
  }
  for task in all {
    if task.id == model.spatial_selected_work_id {
      return Some(task)
    }
  }
  all.iter().find_first(matches)
}

///|
fn spatial_work_review_key(task : EnergyValleyRuntimeWorkItem) -> String {
  "result-review:\{task.id}:\{task.runId.unwrap_or("")}"
}

///|
fn spatial_work_can_review(task : EnergyValleyRuntimeWorkItem) -> Bool {
  task.status == "completed" &&
  task.resultLinks.unwrap_or([]).any(energy_valley_runtime_result_link_is_valid)
}

///|
fn spatial_review_work_model(model : Model) -> Model {
  match spatial_selected_work(model) {
    Some(task) if spatial_work_can_review(task) =>
      town_life_add_spark_award(model, spatial_work_review_key(task), 10)
    _ => model
  }
}

///|
fn render_spatial_work_journey(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  section(class="spatial-work-journey building-interior-panel", [
    h2("从议题到可审阅的结果"),
    match spatial_selected_work(model) {
      None =>
        div([
          p(
            if model.spatial_request_id.is_empty() {
              "选择工作台提出本地议题；从楼内工作中选择一项，跟随负责人、执行记录和结果。"
            } else {
              "请求已接受，等待运行时关联工作。尚未证明 Agent 已开始执行；请勿重复提交。"
            },
          ),
          p("议题 → 工作与负责人 → 执行证据 → 结果审阅"),
          button(on_click=dispatch(StartIndoorWork), "提出本地议题"),
        ])
      Some(task) => {
        let reviewed = model.town_life_spark_awards.any(award => {
          award.id == spatial_work_review_key(task)
        })
        div([
          @html.strong(town_chronicle_safe_task_title(task)),
          p(
            "\{town_chronicle_status_label(task.status)} · \{task.agentName.unwrap_or("等待分配负责人")}",
          ),
          if !energy_valley_runtime_can_claim_active_work(
              model.energy_valley_runtime,
            ) {
            p(
              class="spatial-work-warning",
              "历史或过期快照；下列记录不代表此刻正在执行。",
            )
          } else {
            @html.nothing
          },
          match task.summary {
            Some(summary) => p(resident_safe_task_summary(summary))
            None => @html.nothing
          },
          @html.details([
            @html.summary("工作与执行记录"),
            p("工作：\{task.id}"),
            p("Run：\{task.runId.unwrap_or("尚未观测到")}"),
            p("请求：\{task.requestId.unwrap_or("未提供关联")}"),
            p(
              "此运行时记录没有可验证的 Run → 机器/远程路由绑定。算力室的可用资源不代表本项工作的执行资源。",
            ),
          ]),
          match model.town_spatial_layer {
            Underground(_) =>
              p(
                "下方是基础设施观测；不会据此推断本项工作使用了哪台机器。",
              )
            _ =>
              button(
                on_click=dispatch(OpenSecretComputeRoom),
                "查看算力与执行边界 ↓",
              )
          },
          render_resident_evidence(task),
          if reviewed {
            p(
              class="spatial-work-reviewed",
              "已记录你的结果审阅 · +10 星火。这不是政策批准或实施完成。",
            )
          } else if spatial_work_can_review(task) {
            button(
              on_click=dispatch(ReviewSpatialWork),
              "我已阅读结果，记录审阅 +10 星火",
            )
          } else {
            p(
              "等待完成且附有可打开的结果；失败或仅接受的请求不会获得完成奖励。",
            )
          },
        ])
      }
    },
  ])
}

///|
fn render_spatial_overlays(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  schedule_spatial_dialog_accessibility()
  div([
    if model.energy_request_open {
      div(
        class="town-modal-backdrop pointer-events-auto bg-slate-950/60",
        render_energy_valley_request_dialog(dispatch, model),
      )
    } else {
      @html.nothing
    },
    render_phone_panel(dispatch, model),
  ])
}
