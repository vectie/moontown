///|
fn render_neighborhood_manage_followups(
  dispatch : Dispatch[Msg],
  model : Model,
  mine : Json,
) -> @rabbita.Html {
  let groups = neighborhood_items(mine, "events").filter(event => {
    !neighborhood_items(event, "followups").is_empty()
  })
  if groups.is_empty() {
    return p(class="nh-empty", "还没有参与者提交的会后跟进。")
  }
  div(
    class="nh-stack",
    [
      p(class="nh-muted", "回复参与者，记录下一步。"),
      ..groups.map(event => {
        div(
          class="nh-stack",
          [
            h3(neighborhood_text(event, "title")),
            ..neighborhood_items(event, "followups")
            .filter(followup => neighborhood_text(followup, "state") == "open")
            .map(followup => {
              render_neighborhood_manage_followup(
                dispatch,
                model,
                followup,
                neighborhood_manage_followup_name(event, followup),
              )
            }),
            if neighborhood_items(event, "followups").any(followup => {
                neighborhood_text(followup, "state") != "open"
              }) {
              @html.details(
                class="nh-stack",
                [
                  @html.summary("已记录的跟进"),
                  ..neighborhood_items(event, "followups")
                  .filter(followup => {
                    neighborhood_text(followup, "state") != "open"
                  })
                  .map(followup => {
                    render_neighborhood_manage_followup(
                      dispatch,
                      model,
                      followup,
                      neighborhood_manage_followup_name(event, followup),
                    )
                  }),
                ],
              )
            } else {
              @html.nothing
            },
          ],
        )
      }),
      @html.details(class="nh-disclosure town-advanced", [
        @html.summary("高级 · 跟进说明"),
        p(
          class="nh-muted",
          "只处理参与者自愿留下的需求。记录下一步不会自动创建任务、发送通知或转交其他人。",
        ),
      ]),
    ],
  )
}

///|
fn render_neighborhood_manage_followup(
  dispatch : Dispatch[Msg],
  model : Model,
  followup : Json,
  participant_name : String,
) -> @rabbita.Html {
  let id = neighborhood_text(followup, "id")
  let busy = neighborhood_busy(model)
  let open = neighborhood_text(followup, "state") == "open"
  article(class="nh-card nh-stack", [
    h3(participant_name),
    p(
      class="nh-status",
      neighborhood_manage_status(neighborhood_text(followup, "state")),
    ),
    p(neighborhood_text(followup, "message")),
    if neighborhood_text(followup, "contact").is_empty() {
      @html.nothing
    } else {
      @html.details([
        @html.summary("对方为此次跟进留下的联系方式"),
        p(neighborhood_text(followup, "contact")),
      ])
    },
    if open {
      div(class="nh-stack", [
        neighborhood_manage_field(
          "nh-followup-" + id + "-next",
          "准备如何跟进",
          model.neighborhood_manage.followup_fields
          .get(id + ":next_step")
          .unwrap_or(""),
          value => {
            dispatch(
              NeighborhoodManageEvent(FollowupField(id, "next_step", value)),
            )
          },
          disabled=busy,
          multiline=true,
        ),
        neighborhood_manage_field(
          "nh-followup-" + id + "-outcome",
          "已有回应或结果（选填）",
          model.neighborhood_manage.followup_fields
          .get(id + ":outcome")
          .unwrap_or(""),
          value => {
            dispatch(
              NeighborhoodManageEvent(FollowupField(id, "outcome", value)),
            )
          },
          disabled=busy,
          multiline=true,
        ),
        neighborhood_manage_button(
          dispatch,
          "记录下一步",
          ResolveFollowup(id),
          disabled=busy,
          primary=true,
        ),
      ])
    } else {
      div(class="nh-stack", [
        p("下一步：" + neighborhood_text(followup, "next_step")),
        if neighborhood_text(followup, "outcome").is_empty() {
          @html.nothing
        } else {
          p("回应：" + neighborhood_text(followup, "outcome"))
        },
        neighborhood_manage_button(
          dispatch,
          if public_platform_enabled() {
            "准备工作说明"
          } else {
            "到工作区继续"
          },
          ContinueWork(id),
          disabled=busy,
        ),
      ])
    },
  ])
}

///|
fn neighborhood_manage_followup_name(event : Json, followup : Json) -> String {
  let participant = neighborhood_text(followup, "participant_id")
  if participant.is_empty() {
    return "参与者"
  }
  neighborhood_items(event, "registrations")
  .iter()
  .find_first(registration => {
    neighborhood_text(registration, "participant_id") == participant
  })
  .map(registration => neighborhood_text(registration, "display_name"))
  .unwrap_or("参与者")
}
