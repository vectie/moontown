///|
fn watch_request_mode_label(mode : WatchRequestMode) -> String {
  match mode {
    CadenceWatch => "Cadence watch"
    LocalMaterialWatch => "Local material changes"
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
    class="request-action-dock",
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
      "Opt in to exact local source comparison. Enter existing UTF-8 file paths relative to the target Book, one per line. The town validates the files when saving; no files are uploaded or discovered here.",
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
    p(
      class="request-status",
      "The request above is the saved intent. The first due check establishes a baseline without dispatching work. Unchanged bytes stay quiet; changed sources or plan enter the existing Book review flow. A byte change is not automatically accepted knowledge.",
    ),
  ])
}
