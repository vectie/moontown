///|
fn render_neighborhood_manage_events(
  dispatch : Dispatch[Msg],
  model : Model,
  mine : Json,
) -> @rabbita.Html {
  let events = neighborhood_items(mine, "events")
  let busy = neighborhood_busy(model)
  div(class="nh-stack", [
    if neighborhood_can_host(model) {
      div(class="nh-actions", [
        neighborhood_manage_button(
          dispatch,
          "创建活动",
          NewEvent,
          disabled=busy,
        ),
      ])
    } else {
      p(
        class="nh-muted",
        "当前账户不能创建新活动；已有的本人主办记录仍可在这里管理。",
      )
    },
    if events.is_empty() {
      p(class="nh-empty", "还没有你主办的活动。")
    } else {
      div(
        class="nh-actions",
        events.map(event => {
          neighborhood_manage_button(
            dispatch,
            neighborhood_text(event, "title") +
            " · " +
            neighborhood_manage_status(neighborhood_text(event, "state")),
            EditEvent(neighborhood_text(event, "id")),
            disabled=busy,
          )
        }),
      )
    },
    match model.neighborhood_manage.event {
      None => @html.nothing
      Some(form) => {
        let event = neighborhood_manage_find(mine, "events", form.id)
        let status = event
          .map(item => neighborhood_text(item, "state"))
          .unwrap_or("draft")
        let saved = neighborhood_manage_event_saved(form, mine)
        div(class="nh-card nh-stack", [
          if status == "draft" {
            div(class="nh-stack", [
              h3("活动安排"),
              neighborhood_manage_field(
                "nh-event-title",
                "活动名称",
                form.title,
                value => {
                  dispatch(NeighborhoodManageEvent(EventField("title", value)))
                },
                disabled=busy,
              ),
              neighborhood_manage_field(
                "nh-event-description",
                "做什么、适合谁参加",
                form.description,
                value => {
                  dispatch(
                    NeighborhoodManageEvent(EventField("description", value)),
                  )
                },
                disabled=busy,
                multiline=true,
              ),
              neighborhood_manage_field(
                "nh-event-location",
                "活动地点",
                form.location,
                value => {
                  dispatch(
                    NeighborhoodManageEvent(EventField("location", value)),
                  )
                },
                disabled=busy,
              ),
              p(class="nh-muted", "时间使用你当前设备所在时区。"),
              div(class="nh-grid", [
                neighborhood_manage_field(
                  "nh-event-starts",
                  "开始时间",
                  form.starts,
                  value => {
                    dispatch(
                      NeighborhoodManageEvent(EventField("starts", value)),
                    )
                  },
                  disabled=busy,
                  kind=DateTimeLocal,
                ),
                neighborhood_manage_field(
                  "nh-event-ends",
                  "结束时间",
                  form.ends,
                  value => {
                    dispatch(NeighborhoodManageEvent(EventField("ends", value)))
                  },
                  disabled=busy,
                  kind=DateTimeLocal,
                ),
                neighborhood_manage_field(
                  "nh-event-capacity",
                  "参加人数上限",
                  form.capacity,
                  value => {
                    dispatch(
                      NeighborhoodManageEvent(EventField("capacity", value)),
                    )
                  },
                  disabled=busy,
                  kind=Number,
                ),
              ]),
              div(class="nh-actions", [
                neighborhood_manage_button(
                  dispatch,
                  if saved {
                    "已保存安排"
                  } else {
                    "保存安排"
                  },
                  SaveEvent,
                  disabled=busy || saved,
                  primary=true,
                ),
                neighborhood_manage_button(
                  dispatch,
                  "放弃修改",
                  Confirm("discard-event", form.id),
                  disabled=busy,
                ),
              ]),
              if saved {
                div(class="nh-stack", [
                  p(
                    "发布后，活动名称、说明、时间、地点和名额会公开，并接受报名。报名名单和联系方式不会公开。",
                  ),
                  neighborhood_manage_button(
                    dispatch,
                    "发布活动",
                    PublishEvent,
                    disabled=busy,
                    primary=true,
                  ),
                ])
              } else {
                @html.nothing
              },
            ])
          } else {
            div(class="nh-stack", [
              h3(form.title),
              p(class="nh-status", neighborhood_manage_status(status)),
              p(form.description),
              p(form.location),
              p(
                form.starts.replace_all(old="T", new=" ") +
                " — " +
                form.ends.replace_all(old="T", new=" "),
              ),
              p("人数上限：" + form.capacity),
            ])
          },
          match event {
            None => @html.nothing
            Some(event) =>
              div(class="nh-stack", [
                div(class="nh-actions", [
                  if status == "published" &&
                    browser_now_ms() >=
                    neighborhood_manage_number(event, "starts_ms") {
                    neighborhood_manage_button(
                      dispatch,
                      "结束活动",
                      Confirm("end-event", form.id),
                      disabled=busy,
                    )
                  } else {
                    @html.nothing
                  },
                  if ["draft", "published"].contains(status) {
                    neighborhood_manage_button(
                      dispatch,
                      "取消活动",
                      Confirm("cancel-event", form.id),
                      disabled=busy,
                    )
                  } else {
                    @html.nothing
                  },
                ]),
                render_neighborhood_manage_roster(dispatch, model, event),
              ])
          },
        ])
      }
    },
  ])
}

///|
fn render_neighborhood_manage_roster(
  dispatch : Dispatch[Msg],
  model : Model,
  event : Json,
) -> @rabbita.Html {
  let registrations = neighborhood_items(event, "registrations")
  let page = model.neighborhood_manage.roster_page.min(
    (registrations.length() - 1).max(0) / 20,
  )
  let shown = registrations[page * 20:(page + 1) * 20].to_owned()
  let now = browser_now_ms()
  let busy = neighborhood_busy(model)
  div(class="nh-stack", [
    h3("报名与签到"),
    p(
      class="nh-muted",
      "仅本人主办管理可见。签到由主办方在活动时间内确认。",
    ),
    if registrations.is_empty() {
      p(class="nh-empty", "还没有报名记录。")
    } else {
      div(
        class="nh-stack",
        shown.map(registration => {
          article(class="nh-card nh-stack", [
            h3(neighborhood_text(registration, "display_name")),
            p(
              neighborhood_manage_status(
                neighborhood_text(registration, "state"),
              ),
            ),
            if neighborhood_text(registration, "contact").is_empty() {
              @html.nothing
            } else {
              @html.details([
                @html.summary("报名者留下的联系方式"),
                p(neighborhood_text(registration, "contact")),
              ])
            },
            if neighborhood_manage_can_check_in(event, registration, now) {
              neighborhood_manage_button(
                dispatch,
                "确认已到场",
                CheckIn(neighborhood_text(registration, "id")),
                disabled=busy,
              )
            } else {
              @html.nothing
            },
          ])
        }),
      )
    },
    if registrations.length() > 20 {
      div(class="nh-actions", [
        neighborhood_manage_button(
          dispatch,
          "上一页",
          RosterPage(page - 1),
          disabled=busy || page == 0,
        ),
        span("第 \{page + 1} / \{(registrations.length() + 19) / 20} 页"),
        neighborhood_manage_button(
          dispatch,
          "下一页",
          RosterPage(page + 1),
          disabled=busy || (page + 1) * 20 >= registrations.length(),
        ),
      ])
    } else {
      @html.nothing
    },
  ])
}
