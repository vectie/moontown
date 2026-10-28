///|
fn neighborhood_manage_button(
  dispatch : Dispatch[Msg],
  label : String,
  message : NeighborhoodManageMsg,
  disabled~ : Bool,
  primary~ : Bool = false,
) -> @rabbita.Html {
  button(
    class=if primary { "nh-button nh-button-primary" } else { "nh-button" },
    disabled~,
    on_click=dispatch(NeighborhoodManageEvent(message)),
    label,
  )
}

///|
fn neighborhood_manage_field(
  id : String,
  label : String,
  value : String,
  on_input : (String) -> Cmd,
  disabled~ : Bool,
  multiline~ : Bool = false,
  kind~ : @html.InputType = Text,
) -> @rabbita.Html {
  div(class="nh-field", [
    @html.label(for_=id, label),
    if multiline {
      textarea(
        id~,
        class="request-textarea request-textarea-compact",
        value~,
        disabled~,
        on_input~,
        no_children(),
      )
    } else {
      input(
        id~,
        input_type=kind,
        class="request-input",
        value~,
        on_input~,
        attrs=@html.Attrs::build().disabled(disabled),
        step=1,
      )
    },
  ])
}

///|
fn render_neighborhood_manage(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  guard neighborhood_mine(model) is Some(mine) else { return @html.nothing }
  let state = model.neighborhood_manage
  let busy = neighborhood_busy(model)
  let can_manage_events = neighborhood_can_host(model) ||
    !neighborhood_items(mine, "events").is_empty()
  section(id="neighborhood-manage", class="nh-stack", [
    div(
      class="nh-actions",
      attrs=@html.Attrs::build()
        .role("group")
        .aria_label("管理自己的街区内容"),
      [
        (ManageStories, "我的故事"),
        (ManageEvents, "主办活动"),
        (ManageFollowups, "会后跟进"),
      ]
      .filter(item => item.0 == ManageStories || can_manage_events)
      .map(item => {
        button(
          class=if state.section == item.0 {
            "nh-button nh-button-primary"
          } else {
            "nh-button"
          },
          disabled=busy,
          attrs=@html.Attrs::build().aria_pressed(
            if state.section == item.0 {
              "true"
            } else {
              "false"
            },
          ),
          on_click=dispatch(NeighborhoodManageEvent(Section(item.0))),
          item.1,
        )
      }),
    ),
    if state.notice.is_empty() {
      @html.nothing
    } else {
      p(
        class="nh-status",
        attrs=@html.Attrs::build().role("status").aria_live("polite"),
        state.notice,
      )
    },
    render_neighborhood_manage_confirmation(dispatch, model),
    match state.section {
      ManageStories => render_neighborhood_manage_stories(dispatch, model, mine)
      ManageEvents if can_manage_events =>
        render_neighborhood_manage_events(dispatch, model, mine)
      ManageFollowups if can_manage_events =>
        render_neighborhood_manage_followups(dispatch, model, mine)
      _ => render_neighborhood_manage_stories(dispatch, model, mine)
    },
    if public_platform_enabled() {
      render_neighborhood_work_context(dispatch, model)
    } else {
      @html.nothing
    },
  ])
}

///|
/// Only confirmed private data can create a personal attention shortcut.
/// Missing/failed reads are never converted into a zero-pending assertion.
fn render_neighborhood_manage_attention(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  guard neighborhood_mine(model) is Some(mine) else { return @html.nothing }
  let events = neighborhood_items(mine, "events")
  let count = events.fold(init=0, (count, event) => {
    count +
    neighborhood_items(event, "followups")
    .filter(followup => neighborhood_text(followup, "state") == "open")
    .length()
  })
  let now = browser_now_ms()
  let active = events.filter(event => {
    neighborhood_text(event, "state") == "published" &&
    now >= neighborhood_manage_number(event, "starts_ms") &&
    now <= neighborhood_manage_number(event, "ends_ms")
  })
  if count == 0 && active.is_empty() {
    return @html.nothing
  }
  div(
    class="nh-actions",
    [
      if count > 0 {
        neighborhood_manage_button(
          dispatch,
          "待跟进 \{count}",
          Section(ManageFollowups),
          disabled=neighborhood_busy(model),
          primary=true,
        )
      } else {
        @html.nothing
      },
      ..active.map(event => {
        neighborhood_manage_button(
          dispatch,
          "管理签到 · " + neighborhood_text(event, "title"),
          EditEvent(neighborhood_text(event, "id")),
          disabled=neighborhood_busy(model),
        )
      }),
    ],
  )
}

///|
fn render_neighborhood_manage_confirmation(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  guard model.neighborhood_manage.confirmation is Some((action, _)) else {
    return @html.nothing
  }
  let (title, detail) = match action {
    "withdraw-story" =>
      (
        "撤下故事？", "故事将不再向访客展示，自己的记录仍会保留。",
      )
    "cancel-event" =>
      (
        "取消活动？", "活动停止报名，已有报名会标记为活动取消；公开过的活动保留取消通知。",
      )
    "end-event" =>
      (
        "结束活动？", "活动将结束，不再接受报名或签到。会后自愿跟进仍保留。",
      )
    "discard-story" | "discard-event" =>
      (
        "放弃未保存修改？", "只丢弃这次本地编辑，服务器上已保存的记录不会删除。",
      )
    _ => ("确认操作？", "")
  }
  div(class="nh-card nh-stack", attrs=@html.Attrs::build().role("alert"), [
    h3(title),
    p(detail),
    div(class="nh-actions", [
      neighborhood_manage_button(
        dispatch,
        "确认",
        CommitConfirmation,
        disabled=neighborhood_busy(model),
      ),
      neighborhood_manage_button(
        dispatch,
        "返回",
        CancelConfirmation,
        disabled=neighborhood_busy(model),
      ),
    ]),
  ])
}

///|
fn render_neighborhood_manage_stories(
  dispatch : Dispatch[Msg],
  model : Model,
  mine : Json,
) -> @rabbita.Html {
  let stories = neighborhood_items(mine, "stories")
  let busy = neighborhood_busy(model)
  div(class="nh-stack", [
    div(class="nh-actions", [
      neighborhood_manage_button(dispatch, "写故事", NewStory, disabled=busy),
    ]),
    if stories.is_empty() {
      p(
        class="nh-empty",
        "还没有自己的故事。先写草稿，只有你明确发布后才会公开。",
      )
    } else {
      div(
        class="nh-actions",
        stories.map(story => {
          neighborhood_manage_button(
            dispatch,
            neighborhood_text(story, "title") +
            " · " +
            neighborhood_manage_status(neighborhood_text(story, "state")),
            EditStory(neighborhood_text(story, "id")),
            disabled=busy,
          )
        }),
      )
    },
    match model.neighborhood_manage.story {
      None => @html.nothing
      Some(form) => {
        let saved = neighborhood_manage_story_saved(form, mine)
        let published = match
          neighborhood_manage_find(mine, "stories", form.id) {
          Some(story) => neighborhood_text(story, "state") == "published"
          None => false
        }
        if published {
          article(class="nh-card nh-stack", [
            h3(form.title),
            p(class="nh-muted", "已公开 · " + form.author_name),
            @html.pre(class="nh-copy", form.body),
            neighborhood_manage_button(
              dispatch,
              "撤下后编辑",
              Confirm("withdraw-story", form.id),
              disabled=busy,
            ),
          ])
        } else {
          div(class="nh-card nh-stack", [
            h3("故事草稿"),
            neighborhood_manage_field(
              "nh-story-title",
              "标题",
              form.title,
              value => {
                dispatch(NeighborhoodManageEvent(StoryField("title", value)))
              },
              disabled=busy,
            ),
            neighborhood_manage_field(
              "nh-story-author",
              "公开署名（选填）",
              form.author_name,
              value => {
                dispatch(
                  NeighborhoodManageEvent(StoryField("author_name", value)),
                )
              },
              disabled=busy,
            ),
            neighborhood_manage_field(
              "nh-story-body",
              "正文",
              form.body,
              value => {
                dispatch(NeighborhoodManageEvent(StoryField("body", value)))
              },
              disabled=busy,
              multiline=true,
            ),
            div(class="nh-actions", [
              neighborhood_manage_button(
                dispatch,
                if saved {
                  "已保存草稿"
                } else {
                  "保存草稿"
                },
                SaveStory,
                disabled=busy || saved,
                primary=true,
              ),
              neighborhood_manage_button(
                dispatch,
                "放弃修改",
                Confirm("discard-story", form.id),
                disabled=busy,
              ),
            ]),
            if saved {
              div(class="nh-stack", [
                @html.label(class="nh-consent", for_="nh-story-consent", [
                  input(
                    id="nh-story-consent",
                    input_type=Checkbox,
                    checked=form.consent,
                    attrs=@html.Attrs::build().disabled(busy),
                    on_change=_ => {
                      dispatch(
                        NeighborhoodManageEvent(StoryConsent(!form.consent)),
                      )
                    },
                  ),
                  span(
                    "我有权公开此署名、标题和正文；发布后任何访客都能查看。",
                  ),
                ]),
                neighborhood_manage_button(
                  dispatch,
                  "公开发布",
                  PublishStory,
                  disabled=busy || !form.consent,
                  primary=true,
                ),
              ])
            } else {
              @html.nothing
            },
          ])
        }
      }
    },
  ])
}

///|
fn render_neighborhood_work_context(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let context = model.neighborhood_manage.work_context
  if context.is_empty() || neighborhood_mine(model) is None {
    return @html.nothing
  }
  article(class="nh-card nh-stack", [
    h3("工作说明"),
    span(class="nh-badge", "尚未提交"),
    @html.pre(class="nh-copy", context),
    if public_platform_enabled() {
      div(class="nh-stack", [
        p("复制到工作区后提交。"),
        render_shared_account_entry("signed-in"),
      ])
    } else {
      @html.nothing
    },
    neighborhood_manage_button(
      dispatch,
      "收起",
      ClearWorkContext,
      disabled=false,
    ),
  ])
}
