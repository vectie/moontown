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
      "Watch mode: \{watch_request_mode_label(model.request_watch_mode)}. Mode is locked while saving.",
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
      "每行填写一个已有资料路径（相对于目标知识册）。这里只比较文件，不上传资料。",
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
      "What must a reviewer verify before accepting a source-backed change?",
      model.request_material_acceptance,
      value => dispatch(SetRequestMaterialAcceptance(value)),
      compact=true,
      disabled=model.request_submitting,
    ),
    render_request_textarea_field(
      "Next owner action",
      "Who should decide or act after reviewing a change?",
      model.request_material_next_action,
      value => dispatch(SetRequestMaterialNextAction(value)),
      compact=true,
      disabled=model.request_submitting,
    ),
    render_advanced_details("How checks work", [
      p(
        class="request-status",
        "The first check establishes a baseline. Unchanged sources stay quiet; changes enter review before being accepted.",
      ),
    ]),
  ])
}
