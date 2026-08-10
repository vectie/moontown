///|
/// Avatar creation wizard and the resident chip (walk / follow / edit
/// controls). The wizard is the new first-run experience: three small steps
/// instead of a wall of explanatory text.
fn avatar_persona_options() -> Array[(String, String, String)] {
  [
    ("researcher", "🔬 研究者", "喜欢泡实验室，追着新知识跑"),
    (
      "creator", "🛠️ 创造者", "热衷盖楼共建，把想法变成地标",
    ),
    ("observer", "🌙 观察者", "爱逛爱聊，镇上的故事都知道"),
  ]
}

///|
fn avatar_persona_label(persona : String) -> String {
  match persona {
    "researcher" => "研究者"
    "creator" => "创造者"
    _ => "观察者"
  }
}

///|
fn render_avatar_wizard_step_indicator(step : Int) -> @rabbita.Html {
  let dots : Array[@rabbita.Html] = []
  for index in 0..<3 {
    dots.push(
      span(
        class=if index == step {
          "wizard-dot wizard-dot-active"
        } else if index < step {
          "wizard-dot wizard-dot-done"
        } else {
          "wizard-dot"
        },
        if index < step {
          "✓"
        } else {
          (index + 1).to_string()
        },
      ),
    )
  }
  div(class="wizard-steps", dots)
}

///|
fn render_avatar_wizard(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let step = model.avatar_wizard_step
  let body : Array[@rabbita.Html] = []
  if step == 0 {
    body.push(
      div(class="wizard-body", [
        div(
          id="avatar-wizard-title",
          class="wizard-title",
          "你叫什么？ 🌱",
        ),
        p(
          class="wizard-copy",
          "能源谷会把真实 Runtime Agent 的工作投影进大楼；离线时只展示明确标注的预览居民。给自己起个名字，他们就认识你了。",
        ),
        @html.label(
          class="wizard-label",
          for_="avatar-name-input",
          "你的名字",
        ),
        input(
          id="avatar-name-input",
          class="wizard-input",
          placeholder="例如：小谷",
          value=model.avatar_draft_name,
          on_input=value => dispatch(AvatarDraftName(value)),
        ),
      ]),
    )
  } else if step == 1 {
    body.push(
      div(class="wizard-body", [
        div(
          id="avatar-wizard-title",
          class="wizard-title",
          "你想怎样参与？ 🧭",
        ),
        p(
          class="wizard-copy",
          "选择一种人设。它会成为你的居民身份，并显示在角色卡与居民档案里。",
        ),
        div(class="wizard-label", "你的气质"),
        div(
          class="wizard-persona-grid",
          avatar_persona_options().map(option => {
            let (id, label, copy) = option
            button(
              class=if model.avatar_draft_persona == id {
                "wizard-persona wizard-persona-active"
              } else {
                "wizard-persona"
              },
              on_click=dispatch(AvatarDraftPersona(id)),
              attrs=@html.Attrs::build()
                .aria_label(label)
                .aria_pressed(
                  if model.avatar_draft_persona == id {
                    "true"
                  } else {
                    "false"
                  },
                ),
              [
                div(class="wizard-persona-label", label),
                div(class="wizard-persona-copy", copy),
              ],
            )
          }),
        ),
      ]),
    )
  } else {
    body.push(
      div(class="wizard-body", [
        div(
          id="avatar-wizard-title",
          class="wizard-title",
          "挑一个醒目的形象 🎨",
        ),
        p(
          class="wizard-copy",
          "地图上你的角色会带着这颗专属色的小星星，朋友一眼就能认出你。",
        ),
        div(
          class="wizard-color-grid",
          player_avatar_colors.mapi((index, color) => {
            button(
              class=if model.avatar_draft_color == index {
                "wizard-color wizard-color-active"
              } else {
                "wizard-color"
              },
              style=["background: \{color}"],
              on_click=dispatch(AvatarDraftColor(index)),
              attrs=@html.Attrs::build()
                .aria_label("形象色 \{index + 1}")
                .aria_pressed(
                  if model.avatar_draft_color == index {
                    "true"
                  } else {
                    "false"
                  },
                ),
              "",
            )
          }),
        ),
        div(class="wizard-preview", [
          img(
            src="/tilemap/actors/roster/resident_\{model.avatar_draft_color % 12}_walk_strip.png",
            alt="角色预览",
            class="wizard-preview-sprite",
          ),
          span(
            class="wizard-preview-star",
            style=["color: \{player_avatar_colors[model.avatar_draft_color]}"],
            "★",
          ),
          span(class="wizard-preview-name", model.avatar_draft_name),
        ]),
        div(class="wizard-hint", [
          span("下一步：沿道路行走"),
          span("再去视察、联系居民、共建知识大楼"),
        ]),
      ]),
    )
  }
  let can_next = if step == 0 {
    !model.avatar_draft_name.trim().is_empty()
  } else if step == 1 {
    !model.avatar_draft_persona.is_empty()
  } else {
    true
  }
  let footer : Array[@rabbita.Html] = []
  if step > 0 {
    footer.push(
      button(
        class="wizard-button-secondary",
        on_click=dispatch(AvatarWizardBack),
        "上一步",
      ),
    )
  }
  let next_class = if can_next {
    "wizard-button-primary"
  } else {
    "wizard-button-primary wizard-button-disabled"
  }
  let next_cmd = if can_next {
    dispatch(AvatarWizardNext)
  } else {
    dispatch(ViewportControlNoop)
  }
  let next_button = if step < 2 {
    button(
      class=next_class,
      on_click=next_cmd,
      attrs=@html.Attrs::build()
        .disabled(!can_next)
        .aria_disabled(if can_next { "false" } else { "true" }),
      "继续",
    )
  } else {
    button(
      class="wizard-button-primary",
      on_click=dispatch(AvatarCreate),
      if model.player is Some(_) {
        "保存形象"
      } else {
        "正式入住"
      },
    )
  }
  footer.push(next_button)
  section(
    class="avatar-wizard",
    [
      render_avatar_wizard_step_indicator(step),
      ..body,
      div(class="wizard-footer", footer),
    ],
  )
}

///|
/// Bottom-left resident chip. The resident identity stays visible, while
/// everyday account and camera actions live in a native disclosure. During
/// onboarding the one action needed by the current quest remains direct.
fn render_player_chip(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  match model.player {
    None => @html.nothing
    Some(player) => {
      let onboarding = current_quest(model) is Some(_)
      let progress = quest_progress_count(model)
      let walk_class = if model.walk_mode {
        "chip-button chip-button-active"
      } else {
        "chip-button"
      }
      let follow_class = if model.player_follow {
        "chip-button chip-button-active"
      } else {
        "chip-button"
      }
      let resident_actions : Array[@rabbita.Html] = [
        button(
          class=walk_class,
          title="开启后点击道路即可沿路走过去",
          on_click=dispatch(ToggleWalkMode),
          attrs=@html.Attrs::build()
            .aria_label("点地行走模式")
            .aria_pressed(if model.walk_mode { "true" } else { "false" }),
          "行走",
        ),
        button(
          class=follow_class,
          title="相机跟随你的角色",
          on_click=dispatch(TogglePlayerFollow),
          attrs=@html.Attrs::build()
            .aria_label("跟随角色")
            .aria_pressed(if model.player_follow { "true" } else { "false" }),
          "跟随",
        ),
        if model.checkin_day == energy_valley_sim_day(model) {
          span(class="chip-button chip-button-muted", "已签到")
        } else {
          button(
            class="chip-button chip-button-checkin",
            title="每日签到领取谷光值",
            on_click=dispatch(DailyCheckin),
            "签到",
          )
        },
        button(
          class="chip-button",
          title="重新编辑名字与形象",
          on_click=dispatch(AvatarOpenEditor),
          attrs=@html.Attrs::build().aria_label("编辑角色"),
          "编辑",
        ),
      ]
      div(class="player-chip pointer-events-auto", [
        span(
          class="player-chip-dot",
          style=["background: \{player_avatar_color(model)}"],
          "★",
        ),
        div(class="player-chip-id", [
          div(class="player-chip-name", player.name),
          div(
            class="player-chip-title",
            "\{avatar_persona_label(player.persona)} · \{player.title} · 谷光 \{model.spark}",
          ),
        ]),
        if onboarding && progress == 1 {
          button(
            class=walk_class,
            title="开启后点击道路即可沿路走过去",
            on_click=dispatch(ToggleWalkMode),
            attrs=@html.Attrs::build()
              .aria_label("点地行走模式")
              .aria_pressed(if model.walk_mode { "true" } else { "false" }),
            "行走",
          )
        } else {
          @html.nothing
        },
        if !onboarding {
          @html.details(
            class="player-chip-disclosure",
            attrs=@html.Attrs::build().name("moontown-hud-disclosure"),
            [
              @html.summary(
                class="chip-button player-chip-menu-toggle",
                "居民",
              ),
              div(class="player-chip-menu", resident_actions),
            ],
          )
        } else {
          @html.nothing
        },
      ])
    }
  }
}

///|
/// Hidden direction buttons clicked by the WASD/arrow key bridge; keeping
/// them in the DOM means movement rides the normal message loop.
fn render_player_walk_buttons(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  if model.player is None {
    return @html.nothing
  }
  div(class="sr-only", [
    button(
      on_click=dispatch(PlayerStepDirection(-1, -1)),
      attrs=@html.Attrs::build().aria_label("向屏幕上走"),
      "up",
    ),
    button(
      on_click=dispatch(PlayerStepDirection(1, 1)),
      attrs=@html.Attrs::build().aria_label("向屏幕下走"),
      "down",
    ),
    button(
      on_click=dispatch(PlayerStepDirection(-1, 1)),
      attrs=@html.Attrs::build().aria_label("向屏幕左走"),
      "left",
    ),
    button(
      on_click=dispatch(PlayerStepDirection(1, -1)),
      attrs=@html.Attrs::build().aria_label("向屏幕右走"),
      "right",
    ),
  ])
}

///|
/// Quest tracker under the town badge: always shows the single next step so
/// a beginner never wonders what to do.
fn render_quest_tracker(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  if model.player is None {
    return @html.nothing
  }
  match current_quest(model) {
    Some(quest) => {
      let done_count = quest_progress_count(model)
      let total = town_quest_chain().length()
      div(class="quest-tracker pointer-events-auto", [
        div(class="quest-tracker-head", [
          span(class="quest-tracker-badge", "镇务 \{done_count + 1}/\{total}"),
          span(class="quest-tracker-title", quest.title),
        ]),
        div(class="quest-tracker-hint", quest.hint),
        render_quest_primary_action(dispatch, model, quest),
        div(class="quest-tracker-bar", [
          div(
            class="quest-tracker-fill",
            style=["width: \{done_count * 100 / total}%"],
            "",
          ),
        ]),
      ])
    }
    None =>
      div(class="quest-tracker pointer-events-auto quest-tracker-done", [
        div(class="quest-tracker-head", [
          span(class="quest-tracker-badge", "常住居民"),
          span(
            class="quest-tracker-title",
            "继续共建：分享或收藏知识",
          ),
        ]),
        div(
          class="quest-tracker-hint",
          "去广场为知识大楼生成分享链接，或者收藏可核验成果一起共建吧。",
        ),
        button(
          class="quest-tracker-action quest-tracker-action-civic",
          on_click=dispatch(ToggleSquare),
          attrs=@html.Attrs::build().aria_label("打开小镇知识广场"),
          "前往知识广场",
        ),
      ])
  }
}

///|
fn render_quest_primary_action(
  dispatch : Dispatch[Msg],
  model : Model,
  quest : QuestDef,
) -> @rabbita.Html {
  let (label, message) = match quest.id {
    "first-walk" =>
      (
        if model.walk_mode {
          "✓ 行走模式已开启"
        } else {
          "开始沿路行走"
        },
        ToggleWalkMode,
      )
    "visit-building" => ("拿起视察工具", SetEnergyTool(InspectTool))
    "first-chat" => ("打开谷光手机", TogglePhone)
    "build-knowledge" => ("选择创新工坊", SetEnergyTool(WorkshopTool))
    "publish-knowledge" => ("去广场生成分享链接", ToggleSquare)
    "collect-building" => ("去广场收藏", ToggleSquare)
    _ => ("继续", ViewportControlNoop)
  }
  button(class="quest-tracker-action", on_click=dispatch(message), label)
}
