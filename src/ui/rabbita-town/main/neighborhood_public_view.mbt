///|
fn neighborhood_status_label(state : String) -> String {
  match state {
    "published" => "报名中"
    "ended" => "已结束"
    "cancelled" => "已取消"
    "confirmed" => "报名成功"
    "waitlisted" => "候补中"
    "checked_in" => "已签到"
    "event_cancelled" => "活动已取消"
    "open" => "待跟进"
    "resolved" => "已有回复"
    _ => "状态待确认"
  }
}

///|
fn neighborhood_event_status(event : Json, now_ms : Double) -> String {
  if neighborhood_text(event, "state") != "published" {
    return neighborhood_status_label(neighborhood_text(event, "state"))
  }
  match
    (
      neighborhood_field(event, "starts_ms"),
      neighborhood_field(event, "ends_ms"),
    ) {
    (Some(Number(starts)), Some(Number(ends))) =>
      if now_ms >= ends {
        "报名截止"
      } else if now_ms >= starts {
        "进行中"
      } else {
        "报名中"
      }
    _ => "时间待确认"
  }
}

///|
fn neighborhood_status(
  message : String,
  error~ : Bool = false,
) -> @rabbita.Html {
  if message.is_empty() {
    return @html.nothing
  }
  p(
    class=if error { "nh-status nh-error" } else { "nh-status" },
    attrs=@html.Attrs::build()
      .role(if error { "alert" } else { "status" })
      .aria_live("polite"),
    message,
  )
}

///|
fn neighborhood_empty(title : String, detail : String) -> @rabbita.Html {
  div(class="nh-empty", [h3(title), p(class="nh-muted", detail)])
}

///|
fn render_neighborhood_login(
  dispatch : Dispatch[Msg],
  loading : Bool,
) -> @rabbita.Html {
  div(class="nh-card nh-stack", [
    p("登录后可报名、投稿和查看自己的进展。"),
    div(class="nh-actions", [
      a(
        class="nh-button nh-button-primary",
        href=shared_account_portal_url(current_browser_origin()),
        target=Blank,
        rel="noopener noreferrer",
        attrs=@html.Attrs::build().aria_label(
          "登录统一账户（新标签页）",
        ),
        "登录",
      ),
      button(
        type_="button",
        class="nh-button",
        disabled=loading,
        on_click=dispatch(NeighborhoodEvent(Refresh)),
        "已登录，刷新",
      ),
    ]),
  ])
}

///|
fn render_neighborhood_account_gate(
  dispatch : Dispatch[Msg],
  state : NeighborhoodState,
) -> @rabbita.Html {
  if !state.actor_id.is_empty() && !state.mine_error.is_empty() {
    return div(class="nh-card nh-stack", [
      p(
        "暂时无法读取我的街区。原有草稿仍在，刷新后继续。",
      ),
      button(
        type_="button",
        class="nh-button",
        disabled=state.mine_loading,
        on_click=dispatch(NeighborhoodEvent(Refresh)),
        "刷新",
      ),
    ])
  }
  render_neighborhood_login(dispatch, state.loading)
}

///|
fn render_neighborhood_panel(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let state = model.neighborhood
  if !state.open {
    return @html.nothing
  }
  section(
    id="neighborhood-panel",
    class="neighborhood-panel pointer-events-auto",
    attrs=@html.Attrs::build()
      .role("dialog")
      .aria_modal("false")
      .aria_labelledby("neighborhood-title")
      .on_keydown(event => {
        if event.key() == "Escape" {
          dispatch(NeighborhoodEvent(Close))
        } else {
          @rabbita.none
        }
      }),
    [
      header(class="nh-header", [
        div([
          p(class="nh-eyebrow", "MOONTOWN / 街区"),
          h2(id="neighborhood-title", "身边的人与事"),
        ]),
        div(class="nh-actions", [
          button(
            type_="button",
            class="town-ui-icon-button",
            disabled=state.loading || state.busy,
            title="刷新",
            attrs=@html.Attrs::build().aria_label("刷新街区"),
            on_click=dispatch(NeighborhoodEvent(Refresh)),
            town_ui_icon("refresh"),
          ),
          button(
            type_="button",
            class="town-ui-icon-button",
            autofocus=true,
            title="回到小镇",
            attrs=@html.Attrs::build().aria_label("关闭街区，回到小镇"),
            on_click=dispatch(NeighborhoodEvent(Close)),
            town_ui_icon("close"),
          ),
        ]),
      ]),
      div(
        class="nh-tabs",
        attrs=@html.Attrs::build().role("group").aria_label("街区内容"),
        [
          for
            item in [
              ("events", "clock", "活动"),
              ("stories", "book", "故事"),
              ("mine", "people", "我的"),
            ] => {
            button(
              type_="button",
              class=if state.section == item.0 {
                "nh-tab is-active"
              } else {
                "nh-tab"
              },
              attrs=@html.Attrs::build().aria_pressed(
                if state.section == item.0 {
                  "true"
                } else {
                  "false"
                },
              ),
              on_click=dispatch(NeighborhoodEvent(SelectSection(item.0))),
              town_ui_label(item.1, item.2),
            )
          }
        ],
      ),
      div(class="nh-body nh-stack", [
        neighborhood_status(state.error, error=true),
        neighborhood_status(state.mine_error, error=true),
        if state.needs_refresh {
          button(
            type_="button",
            class="nh-button",
            on_click=dispatch(NeighborhoodEvent(Refresh)),
            "刷新状态",
          )
        } else {
          @html.nothing
        },
        neighborhood_status(
          if state.busy {
            "正在保存…"
          } else {
            state.notice
          },
        ),
        if state.loading && state.snapshot is None {
          neighborhood_status("正在读取街区…")
        } else if state.section == "mine" {
          render_neighborhood_mine(dispatch, model)
        } else if !state.selected_id.is_empty() {
          render_neighborhood_detail(dispatch, model)
        } else {
          render_neighborhood_feed(dispatch, state)
        },
      ]),
    ],
  )
}

///|
fn render_neighborhood_feed(
  dispatch : Dispatch[Msg],
  state : NeighborhoodState,
) -> @rabbita.Html {
  guard state.snapshot is Some(snapshot) else {
    return neighborhood_empty(
      "街区暂未连接", "点击右上角刷新；小镇地图仍可使用。",
    )
  }
  let stories = state.section == "stories"
  let items = neighborhood_items(
    snapshot,
    if stories {
      "stories"
    } else {
      "events"
    },
  )
  if items.is_empty() {
    return neighborhood_empty(
      if stories {
        "还没有公开故事"
      } else {
        "还没有公开活动"
      },
      if stories {
        "居民发布的真实故事会出现在这里。"
      } else {
        "主办方发布活动后，可在这里查看和报名。"
      },
    )
  }
  div(
    class="nh-stack",
    [
      p(
        class="nh-muted",
        if stories {
          "街区居民分享的经历与想法。"
        } else {
          "了解安排，选择想参加的活动。时间为北京时间。"
        },
      ),
      ..items.map(item => {
        let id = neighborhood_text(item, "id")
        article(class="nh-card nh-stack", [
          if stories {
            @html.nothing
          } else {
            div(class="nh-card-meta", [
              span(
                class="nh-badge",
                neighborhood_event_status(item, browser_now_ms()),
              ),
              span(neighborhood_event_time(item)),
            ])
          },
          h3(neighborhood_text(item, "title")),
          if stories && !neighborhood_text(item, "author_name").is_empty() {
            p(class="nh-muted", neighborhood_text(item, "author_name"))
          } else {
            @html.nothing
          },
          p(
            class="nh-excerpt",
            neighborhood_text(
              item,
              if stories {
                "body"
              } else {
                "description"
              },
            ),
          ),
          if stories {
            @html.nothing
          } else {
            p(
              class="nh-muted",
              town_ui_label("pin", neighborhood_text(item, "location")),
            )
          },
          button(
            type_="button",
            class="nh-button nh-card-open",
            attrs=@html.Attrs::build().aria_label(
              "查看" + neighborhood_text(item, "title"),
            ),
            on_click=dispatch(
              NeighborhoodEvent(
                if stories {
                  SelectStory(id)
                } else {
                  SelectEvent(id)
                },
              ),
            ),
            "查看",
          ),
        ])
      }),
    ],
  )
}

///|
fn neighborhood_selected(state : NeighborhoodState) -> Json? {
  state.snapshot.bind(snapshot => {
    neighborhood_items(
      snapshot,
      if state.section == "stories" {
        "stories"
      } else {
        "events"
      },
    )
    .iter()
    .find_first(item => neighborhood_text(item, "id") == state.selected_id)
  })
}

///|
fn neighborhood_registration(
  state : NeighborhoodState,
  event_id : String,
) -> Json? {
  state.mine.bind(mine => {
    let registrations = neighborhood_items(mine, "registrations")
    // Re-registration gets a fresh record; an old cancelled record must not win.
    let active = registrations
      .iter()
      .find_first(item => {
        neighborhood_text(item, "event_id") == event_id &&
        neighborhood_text(item, "state") != "cancelled"
      })
    match active {
      Some(_) => active
      None =>
        registrations
        .iter()
        .find_first(item => neighborhood_text(item, "event_id") == event_id)
    }
  })
}

///|
fn neighborhood_followup(state : NeighborhoodState, event_id : String) -> Json? {
  state.mine.bind(mine => {
    neighborhood_items(mine, "followups")
    .iter()
    .find_first(item => neighborhood_text(item, "event_id") == event_id)
  })
}

///|
fn neighborhood_registration_open(event : Json) -> Bool {
  neighborhood_text(event, "state") == "published" &&
  (match neighborhood_field(event, "ends_ms") {
    Some(Number(ends)) => browser_now_ms() < ends
    _ => false
  })
}

///|
fn render_neighborhood_detail(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let state = model.neighborhood
  div(class="nh-stack", [
    button(
      type_="button",
      class="nh-button nh-back",
      on_click=dispatch(NeighborhoodEvent(Back)),
      town_ui_label("back", "返回"),
    ),
    match neighborhood_selected(state) {
      None =>
        neighborhood_empty(
          "内容已不可用", "它可能已被撤回；返回列表查看最新内容。",
        )
      Some(item) =>
        article(class="nh-stack", [
          h3(class="nh-detail-title", neighborhood_text(item, "title")),
          if state.section == "stories" &&
            !neighborhood_text(item, "author_name").is_empty() {
            p(class="nh-muted", neighborhood_text(item, "author_name"))
          } else {
            @html.nothing
          },
          if state.section == "stories" {
            @html.nothing
          } else {
            div(class="nh-card-meta", [
              span(
                class="nh-badge",
                neighborhood_event_status(item, browser_now_ms()),
              ),
              span(neighborhood_event_time(item)),
              span(town_ui_label("pin", neighborhood_text(item, "location"))),
              span(
                "名额 " +
                neighborhood_number(item, "confirmed_count").to_string() +
                " / " +
                neighborhood_number(item, "capacity").to_string(),
              ),
            ])
          },
          p(
            class="nh-prose",
            neighborhood_text(
              item,
              if state.section == "stories" {
                "body"
              } else {
                "description"
              },
            ),
          ),
          if state.section == "stories" {
            @html.nothing
          } else {
            render_neighborhood_participation(dispatch, model, item)
          },
        ])
    },
  ])
}

///|
fn render_neighborhood_field(
  dispatch : Dispatch[Msg],
  state : NeighborhoodState,
  field : String,
  label : String,
  value : String,
  limit : Int32,
) -> @rabbita.Html {
  @html.label(class="nh-field", [
    span(label),
    input(input_type=Text, value~, maxlength=limit, read_only=state.busy, on_input=value => {
      dispatch(NeighborhoodEvent(Edit(field, value)))
    }),
  ])
}

///|
fn render_neighborhood_participation(
  dispatch : Dispatch[Msg],
  model : Model,
  event : Json,
) -> @rabbita.Html {
  let state = model.neighborhood
  let event_id = neighborhood_text(event, "id")
  if state.mine_loading {
    return neighborhood_status("正在读取我的报名…")
  }
  if state.mine is None {
    return render_neighborhood_account_gate(dispatch, state)
  }
  let registration = neighborhood_registration(state, event_id)
  let active_registration = registration
    .map(item => {
      ["confirmed", "waitlisted", "checked_in", "event_cancelled"].contains(
        neighborhood_text(item, "state"),
      )
    })
    .unwrap_or(false)
  div(class="nh-card nh-stack", [
    if registration is Some(item) {
      p(
        class="nh-status",
        "我的状态 · " +
        neighborhood_status_label(neighborhood_text(item, "state")),
      )
    } else {
      @html.nothing
    },
    if neighborhood_registration_open(event) && !active_registration {
      div(class="nh-stack", [
        h3("参加活动"),
        render_neighborhood_field(
          dispatch,
          state,
          "name",
          "报名姓名",
          state.display_name,
          100,
        ),
        render_neighborhood_field(
          dispatch,
          state,
          "contact",
          "联系方式（选填，仅主办方可见）",
          state.contact,
          500,
        ),
        p(
          class="nh-muted",
          "姓名和联系方式仅用于本次活动，不公开展示。",
        ),
        button(
          type_="button",
          class="nh-button nh-button-primary",
          disabled=neighborhood_busy(model) ||
            state.display_name.trim().is_empty(),
          on_click=dispatch(
            NeighborhoodEvent(
              Action("register", {
                "event_id": event_id,
                "display_name": state.display_name,
                "contact": state.contact,
              }),
            ),
          ),
          if neighborhood_number(event, "confirmed_count") >=
            neighborhood_number(event, "capacity") {
            "加入候补"
          } else {
            "报名"
          },
        ),
      ])
    } else if registration is Some(item) &&
      neighborhood_registration_open(event) &&
      ["confirmed", "waitlisted"].contains(neighborhood_text(item, "state")) {
      @html.details(class="nh-disclosure", [
        @html.summary("更改报名"),
        div(class="nh-stack", [
          p(
            class="nh-muted",
            "取消后会释放名额；之后可在活动结束前重新报名。",
          ),
          button(
            type_="button",
            class="nh-button",
            disabled=neighborhood_busy(model),
            on_click=dispatch(
              NeighborhoodEvent(
                Action("cancel-registration", {
                  "registration_id": neighborhood_text(item, "id"),
                }),
              ),
            ),
            "取消报名",
          ),
        ]),
      ])
    } else if neighborhood_text(event, "state") == "cancelled" {
      p(class="nh-muted", "活动已取消，无需继续报名。")
    } else if neighborhood_text(event, "state") != "ended" &&
      !neighborhood_registration_open(event) {
      p(class="nh-muted", "报名已截止。")
    } else {
      @html.nothing
    },
    match neighborhood_followup(state, event_id) {
      Some(followup) => render_neighborhood_followup_receipt(followup)
      None =>
        if neighborhood_text(event, "state") == "ended" &&
          registration
          .map(item => {
            ["confirmed", "checked_in"].contains(
              neighborhood_text(item, "state"),
            )
          })
          .unwrap_or(false) {
          render_neighborhood_followup_form(dispatch, state, event_id)
        } else {
          @html.nothing
        }
    },
  ])
}

///|
fn render_neighborhood_followup_form(
  dispatch : Dispatch[Msg],
  state : NeighborhoodState,
  event_id : String,
) -> @rabbita.Html {
  div(class="nh-stack", [
    h3("会后跟进（自愿）"),
    p(
      class="nh-muted",
      "有需要可以告诉主办方；不提交也不影响参与记录。",
    ),
    @html.label(class="nh-field", [
      span("希望获得什么帮助？"),
      textarea(
        value=state.followup_message,
        rows=4,
        maxlength=5000,
        disabled=state.busy,
        on_input=value => dispatch(NeighborhoodEvent(Edit("followup", value))),
        "",
      ),
    ]),
    render_neighborhood_field(
      dispatch,
      state,
      "contact",
      "联系方式（选填，仅主办方可见）",
      state.contact,
      500,
    ),
    @html.label(class="nh-consent", [
      input(
        input_type=Checkbox,
        checked=state.followup_consent,
        attrs=@html.Attrs::build().disabled(state.busy),
        on_change=_ => {
          dispatch(
            NeighborhoodEvent(SetFollowupConsent(!state.followup_consent)),
          )
        },
      ),
      span(
        "我愿意将以上需求和联系方式交给本次活动主办方跟进。",
      ),
    ]),
    button(
      type_="button",
      class="nh-button nh-button-primary",
      disabled=state.busy ||
        state.needs_refresh ||
        !state.followup_consent ||
        state.followup_message.trim().is_empty(),
      on_click=dispatch(
        NeighborhoodEvent(
          Action("request-follow-up", {
            "event_id": event_id,
            "message": state.followup_message,
            "contact": state.contact,
            "consent": true,
          }),
        ),
      ),
      "发送需求",
    ),
  ])
}

///|
fn render_neighborhood_followup_receipt(followup : Json) -> @rabbita.Html {
  div(class="nh-stack", [
    h3(
      "会后跟进 · " +
      neighborhood_status_label(neighborhood_text(followup, "state")),
    ),
    p(class="nh-prose", neighborhood_text(followup, "message")),
    if neighborhood_text(followup, "state") == "resolved" {
      div(class="nh-stack", [
        p(
          class="nh-prose",
          "下一步 · " + neighborhood_text(followup, "next_step"),
        ),
        if neighborhood_text(followup, "outcome").is_empty() {
          @html.nothing
        } else {
          p(
            class="nh-prose",
            "回复 · " + neighborhood_text(followup, "outcome"),
          )
        },
        @html.details(class="nh-disclosure town-advanced", [
          @html.summary("高级 · 回复说明"),
          p(
            class="nh-muted",
            "这是主办方的回复记录，不代表已自动创建任务或完成服务。",
          ),
        ]),
      ])
    } else {
      p(class="nh-muted", "主办方收到后，可在这里回复下一步。")
    },
  ])
}

///|
fn render_neighborhood_mine(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let state = model.neighborhood
  if state.mine_loading {
    return neighborhood_status("正在读取我的街区…")
  }
  guard state.mine is Some(mine) else {
    return render_neighborhood_account_gate(dispatch, state)
  }
  let registrations = neighborhood_items(mine, "registrations")
  div(
    class="nh-stack",
    [
      render_neighborhood_manage_attention(dispatch, model),
      ..neighborhood_items(mine, "followups").map(followup => {
        let event_id = neighborhood_text(followup, "event_id")
        let event = state.snapshot.bind(snapshot => {
          neighborhood_items(snapshot, "events")
          .iter()
          .find_first(item => neighborhood_text(item, "id") == event_id)
        })
        div(class="nh-card nh-stack", [
          if event is Some(item) {
            p(class="nh-muted", neighborhood_text(item, "title"))
          } else {
            @html.nothing
          },
          render_neighborhood_followup_receipt(followup),
        ])
      }),
      h3("我的报名"),
      if registrations.is_empty() {
        p(class="nh-muted", "还没有报名。去活动页看看吧。")
      } else {
        div(
          class="nh-stack",
          registrations.map(registration => {
            let event_id = neighborhood_text(registration, "event_id")
            let event = state.snapshot.bind(snapshot => {
              neighborhood_items(snapshot, "events")
              .iter()
              .find_first(item => neighborhood_text(item, "id") == event_id)
            })
            div(class="nh-card nh-stack", [
              h3(
                event
                .map(item => neighborhood_text(item, "title"))
                .unwrap_or("活动已不可用"),
              ),
              p(
                class="nh-muted",
                neighborhood_status_label(
                  neighborhood_text(registration, "state"),
                ),
              ),
              if event is Some(_) {
                button(
                  type_="button",
                  class="nh-button",
                  on_click=dispatch(NeighborhoodEvent(SelectEvent(event_id))),
                  "查看",
                )
              } else {
                @html.nothing
              },
            ])
          }),
        )
      },
      render_neighborhood_manage(dispatch, model),
    ],
  )
}
