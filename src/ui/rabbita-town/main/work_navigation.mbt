///|
fn work_workspace_title(focus : RequestComposerFocus) -> String {
  match focus {
    ResultsComposer => "成果"
    AttentionComposer => "待我处理"
    _ => "工作"
  }
}

///|
fn open_work_workspace(
  dispatch : Dispatch[Msg],
  model : Model,
  focus : RequestComposerFocus,
) -> (Cmd, Model) {
  replace_browser_query_param("community", "0")
  replace_browser_query_param("layer", "")
  replace_browser_query_param("building", "")
  if parse_bootstrap_account_experience().kind() == AdminExperience {
    replace_browser_query_param("view", "town")
  }
  let next = set_request_composer_model(
    {
      ..close_town_transient_surfaces(model),
      energy_request_open: true,
      energy_board_open: false,
      energy_intro_open: false,
      selection: Overview,
    },
    focus,
  )
  let next = if model.collaboration.busy() && model.request_composer != focus {
    { ..next, collaboration: model.collaboration.dismiss(), }
  } else {
    next
  }
  if public_platform_enabled() {
    return collaboration_replace(next, next.collaboration)
  }
  match focus {
    ResultsComposer | AttentionComposer =>
      collaboration_action(dispatch, next, "outcome-list", "", "")
    CollaborationComposer =>
      collaboration_action(dispatch, next, "list", "", "")
    _ => collaboration_replace(next, next.collaboration)
  }
}

///|
fn render_work_workspace_tabs(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let selected = match model.request_composer {
    ResultsComposer => ResultsComposer
    AttentionComposer => AttentionComposer
    _ => StandingWatchComposer
  }
  @html.nav(
    class="work-workspace-tabs",
    attrs=@html.Attrs::build().aria_label("工作与成果"),
    [
      (StandingWatchComposer, "work", "工作"),
      (ResultsComposer, "book", "成果"),
      (AttentionComposer, "clock", "待我处理"),
    ].map(item => {
      button(
        class=if selected == item.0 {
          "work-workspace-tab is-active"
        } else {
          "work-workspace-tab"
        },
        attrs=@html.Attrs::build().aria_pressed(
          if selected == item.0 {
            "true"
          } else {
            "false"
          },
        ),
        on_click=dispatch(OpenWorkWorkspace(item.0)),
        town_ui_label(item.1, item.2),
      )
    }),
  )
}
