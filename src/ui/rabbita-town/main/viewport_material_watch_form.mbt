///|
fn watch_request_mode_label(mode : WatchRequestMode) -> String {
  match mode {
    CadenceWatch => "定期检查"
    LocalMaterialWatch => "本地资料"
  }
}

///|
fn render_watch_request_mode(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  if model.request_submitting {
    return p(
      class="request-status",
      "保存中… · \{watch_request_mode_label(model.request_watch_mode)}",
    )
  }
  div(
    class="request-action-dock request-mode-dock",
    attrs=@html.Attrs::build().role("group").aria_label("Watch mode"),
    [
      for mode in [CadenceWatch, LocalMaterialWatch] => {
        button(
          type_="button",
          class=if mode == model.request_watch_mode {
            "request-action-button is-active"
          } else {
            "request-action-button"
          },
          attrs=@html.Attrs::build().aria_pressed(
            if mode == model.request_watch_mode {
              "true"
            } else {
              "false"
            },
          ),
          on_click=dispatch(SetRequestWatchMode(mode)),
          watch_request_mode_label(mode),
        )
      }
    ],
  )
}

///|
fn render_material_watch_request_fields(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  if model.request_watch_mode != LocalMaterialWatch {
    return div(no_children())
  }
  div(class="request-desk-stack", [
    p(
      class="request-status",
      "每行一个已有 UTF-8 文本路径（相对目标知识册）；只比较文件，不上传资料。",
    ),
    render_request_textarea_field(
      "Existing source paths",
      "sources/customer-assumption.txt\nsources/market-assumption.txt",
      model.request_material_sources,
      value => dispatch(SetRequestMaterialSources(value)),
      compact=true,
      disabled=model.request_submitting,
    ),
    render_request_textarea_field(
      "Acceptance criteria",
      "资料变化后，审阅人需要核实什么？",
      model.request_material_acceptance,
      value => dispatch(SetRequestMaterialAcceptance(value)),
      compact=true,
      disabled=model.request_submitting,
    ),
    render_request_textarea_field(
      "Next owner action",
      "审阅后由谁决定，下一步做什么？",
      model.request_material_next_action,
      value => dispatch(SetRequestMaterialNextAction(value)),
      compact=true,
      disabled=model.request_submitting,
    ),
    render_advanced_details("检查规则", [
      p(
        class="request-status",
        "首次检查建立基线；资料不变时保持安静，变化先进入审阅。",
      ),
    ]),
  ])
}
