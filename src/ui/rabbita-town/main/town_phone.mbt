///|
/// The offline phone directory. These are clearly presented as fictional,
/// deterministic residents; they keep the phone useful without claiming that
/// a runtime Agent or an LLM produced their replies.
fn offline_phone_contacts() -> Array[PhoneContact] {
  [
    {
      id: "mayor",
      name: "望月",
      role: "镇长 · Mayor",
      avatar_glyph: "🌙",
      greeting: "我是望月，能源谷的镇长。镇上每一栋知识大楼的落成我都记得，欢迎回家。",
    },
    {
      id: "keeper",
      name: "知河",
      role: "守护 · Keeper",
      avatar_glyph: "🛡️",
      greeting: "我是知河，负责把大家的灵感守成秩序。路网、台账、提案包，都归我管。",
    },
    {
      id: "lingxi",
      name: "灵犀",
      role: "研究员 · Researcher",
      avatar_glyph: "🔬",
      greeting: "灵犀在此～ 最近在能源谷实验室盯一个多智能体课题，有新论文第一时间告诉你。",
    },
    {
      id: "xiaogu",
      name: "小谷",
      role: "邻居 · Resident",
      avatar_glyph: "🌱",
      greeting: "嗨！我是小谷，比你早来几天的邻居。镇上哪家天台看晚霞最好，问我！",
    },
  ]
}

///|
fn phone_contact_is_runtime(id : String) -> Bool {
  id.has_prefix("runtime:")
}

///|
fn phone_runtime_contact_id(agent : EnergyValleyRuntimeAgent) -> String {
  "runtime:\{agent.id}"
}

///|
fn phone_runtime_role_label(role : String) -> String {
  match role {
    "mayor" => "Mayor"
    "keeper" => "Keeper"
    _ => "Worker"
  }
}

///|
fn phone_runtime_status_label(model : Model, status : String) -> String {
  match model.energy_valley_runtime.phase {
    Stale => "快照已过期"
    Loading => "正在连接"
    Unavailable => "运行时不可用"
    Error => "运行时读取失败"
    Live =>
      match status {
        "running" => "工作中"
        "assigned" => "已分派"
        "waiting" => "等待中"
        "blocked" => "受阻"
        "offline" => "离线"
        _ => "空闲"
      }
  }
}

///|
fn phone_runtime_task_for_agent(
  model : Model,
  agent : EnergyValleyRuntimeAgent,
) -> EnergyValleyRuntimeWorkItem? {
  energy_valley_runtime_task_for_agent(model.energy_valley_runtime, agent)
}

///|
fn phone_runtime_agent_greeting(
  model : Model,
  agent : EnergyValleyRuntimeAgent,
) -> String {
  let freshness = match model.energy_valley_runtime.phase {
    Live => "实时运行时投影"
    Stale => "最近一次运行时投影（已过期）"
    Loading => "正在连接运行时"
    Unavailable => "运行时当前不可用"
    Error => "运行时读取失败"
  }
  let work = match phone_runtime_task_for_agent(model, agent) {
    Some(task) => {
      let unsafe_activity = match agent.activityLabel {
        Some(label) => label
        None =>
          match task.activityLabel {
            Some(label) => label
            None => task.summary.unwrap_or(task.title)
          }
      }
      let activity = energy_valley_safe_runtime_copy(
        unsafe_activity, "活动描述包含本地路径或过长内容，已隐藏；请从结果页核验",
        240,
      )
      let title = energy_valley_safe_runtime_copy(
        task.title,
        "任务标题包含本地路径或过长内容，已隐藏",
        180,
      )
      let run_id = match task.runId {
        Some(run_id) => Some(run_id)
        None => agent.runId
      }
      let run = match run_id {
        Some(run_id) => " · Run \{run_id}"
        None => ""
      }
      "\{title} · \{task.status} · \{activity}\{run}"
    }
    None =>
      energy_valley_safe_runtime_copy(
        agent.activityLabel.unwrap_or("目前没有关联的真实工作项"),
        "活动描述包含本地路径或过长内容，已隐藏",
        240,
      )
  }
  "\{freshness}：\{work}。这里展示的是可核验的 Agent 工作动态；手机暂未接入运行时消息写入接口。"
}

///|
fn phone_runtime_contacts(model : Model) -> Array[PhoneContact] {
  match model.energy_valley_runtime.projection {
    None => []
    Some(projection) =>
      projection.agents.map(agent => {
        id: phone_runtime_contact_id(agent),
        name: agent.name,
        role: "Runtime Agent · \{phone_runtime_role_label(agent.role)} · \{phone_runtime_status_label(model, agent.status)}",
        avatar_glyph: match agent.role {
          "mayor" => "🌙"
          "keeper" => "🛡️"
          _ => "⚙️"
        },
        greeting: phone_runtime_agent_greeting(model, agent),
      })
  }
}

///|
fn phone_contacts(model : Model) -> Array[PhoneContact] {
  let contacts = phone_runtime_contacts(model) + offline_phone_contacts()
  if phone_contact_is_runtime(model.phone_contact) &&
    !contacts.any(contact => contact.id == model.phone_contact) {
    [phone_disconnected_runtime_contact(model.phone_contact)] + contacts
  } else {
    contacts
  }
}

///|
/// Preserve a selected runtime identity when a refreshed projection no longer
/// contains it. Falling back visually to an offline resident would make the
/// composer and send policy contradict the contact shown onscreen.
fn phone_disconnected_runtime_contact(id : String) -> PhoneContact {
  {
    id,
    name: "已断开的 Runtime Agent",
    role: "Runtime Agent · 当前投影中不存在",
    avatar_glyph: "⚠️",
    greeting: "这个 Agent 已不在当前运行时投影中，可能已经结束、重启或更换身份。这里不会把它替换成离线居民，也不会伪造后续消息。",
  }
}

///|
fn phone_contact_by_id(model : Model, id : String) -> PhoneContact {
  for contact in phone_contacts(model) {
    if contact.id == id {
      return contact
    }
  }
  if phone_contact_is_runtime(id) {
    return phone_disconnected_runtime_contact(id)
  }
  offline_phone_contacts()[0]
}

///|
fn phone_thread(model : Model, contact : String) -> Array[PhoneMessage] {
  let messages = model.phone_log.filter(message => message.contact == contact)
  let visible_limit = 36
  if messages.length() <= visible_limit {
    messages
  } else {
    messages[messages.length() - visible_limit:].to_owned()
  }
}

///|
/// Offline persona script: keyword routing plus per-contact voice, rotated
/// deterministically. This is intentionally not called for runtime contacts.
fn offline_resident_reply(
  contact : String,
  input : String,
  salt : Int,
) -> String {
  let lower = input.to_lower()
  let topic = if lower.contains("地铁") ||
    lower.contains("17号") ||
    lower.contains("十七号") {
    "metro"
  } else if lower.contains("你好") ||
    lower.contains("在吗") ||
    lower.contains("嗨") ||
    lower.contains("hi") ||
    lower.contains("hello") {
    "greeting"
  } else if lower.contains("知识") ||
    lower.contains("大楼") ||
    lower.contains("盖楼") ||
    lower.contains("建") {
    "knowledge"
  } else if lower.contains("聊天") ||
    lower.contains("朋友") ||
    lower.contains("玩") {
    "social"
  } else if lower.contains("天气") ||
    lower.contains("下雨") ||
    lower.contains("雪") {
    "weather"
  } else if lower.contains("任务") ||
    lower.contains("怎么") ||
    lower.contains("如何") {
    "guide"
  } else if lower.contains("再见") || lower.contains("拜") {
    "bye"
  } else {
    "chat"
  }
  let options : Array[String] = match contact {
    "mayor" =>
      match topic {
        "greeting" =>
          [
            "你好呀！镇长办公室永远向新居民敞开。", "欢迎！有什么想建的、想改的，直接跟我说。",
          ]
        "metro" =>
          [
            "17 号线就在镇东边，未来科学城站和未来科学城北站都能上车，去望京只要四站。",
            "坐地铁来能源谷最方便，两个站我都去接过新居民。",
          ]
        "knowledge" =>
          [
            "建知识大楼是镇上最光荣的事。落成那天记得告诉我，我亲自去剪彩。",
            "每栋新楼都会登记进镇志，你的名字也会留在门牌上。",
          ]
        "guide" =>
          [
            "跟着左上角的新手任务走就不会迷路：先走一走，再逛逛楼，然后给大家发条消息。",
          ]
        _ =>
          [
            "嗯，这事我记下了，镇务会上帮你问问。", "有意思，继续说，我在听。",
            "镇上的事，没有小事。",
          ]
      }
    "keeper" =>
      match topic {
        "greeting" =>
          [
            "在。台账显示你是新入住的居民，欢迎。", "你好，有什么需要守护的吗？",
          ]
        "knowledge" =>
          [
            "新楼落成后我会做合规登记，知识主题越清晰，检索越快。",
            "提案包已经备好，你的大楼随时可以开工。",
          ]
        "guide" =>
          [
            "流程很简单：视察一栋楼看看内部，再去广场发布你的第一栋。",
          ]
        _ =>
          [
            "收到，已归档。", "我核对一下再答复你。", "规矩之内，都好办。",
          ]
      }
    "lingxi" =>
      match topic {
        "greeting" =>
          [
            "哈喽哈喽！正好实验间隙，聊五毛钱的～", "嗨！你是新搬来的吧，我在天台见过你！",
          ]
        "metro" =>
          [
            "我天天坐 17 号线通勤！未来科学城站下来走五分钟就到实验室。",
          ]
        "knowledge" =>
          [
            "我们实验室最近在具身智能方向有新进展，等你盖好楼我来做个分享！",
            "知识大楼的主题越聚焦越好，比如「多智能体协作」就很棒。",
          ]
        "weather" =>
          [
            "下雨天实验数据都更温柔了，不信你看窗外的温榆河。",
          ]
        _ =>
          [
            "这个问题有意思！让我想想……", "哈哈我也是这么觉得！",
            "等下，先让我把这个 epoch 跑完……好了，你刚才说啥？",
          ]
      }
    _ =>
      match topic {
        "greeting" =>
          [
            "嗨嗨！欢迎欢迎！晚上广场有露天电影，一起来？",
            "新邻居！我正想找人去滨水栈道散步呢。",
          ]
        "metro" =>
          ["17 号线的站台设计超好看，蓝白配色，拍照出片！"]
        "knowledge" =>
          [
            "你盖楼的时候一定要叫我，我帮你暖房！", "我收藏了三栋别人的楼了，广场里淘一淘，灵感特别多。",
          ]
        "social" =>
          [
            "镇上的居民都很好聊，多敲几个人试试～", "广场最近有共建活动，一起参加能赚谷光值！",
          ]
        "guide" =>
          [
            "新手任务超简单，我半小时就做完了，奖励的谷光值能换装饰！",
          ]
        _ =>
          [
            "哈哈哈哈哈真的吗", "走啊，一起去！", "你这话我爱听。",
          ]
      }
  }
  options[(salt + input.length()) % options.length()]
}

///|
/// Proactive resident ping: when the phone stays closed for a while, a
/// resident reaches out first — the town feels alive and pulls the player
/// back into the social loop.
fn phone_maybe_receive(model : Model) -> Model {
  if model.player is None || model.phone_open {
    return model
  }
  // Keep the town alive without turning the phone into a notification fire
  // hose. At the normal simulation speed this is several minutes between
  // fictional resident pings, not one every few seconds.
  let interval = 720
  if model.tick <= 0 || model.tick % interval != 0 {
    return model
  }
  // Never fabricate an unsolicited message from a real runtime Agent. Only
  // the explicitly fictional offline residents can generate local pings.
  let contacts = offline_phone_contacts()
  let contact = contacts[model.tick / interval % contacts.length()]
  let teasers = [
    "在吗？给你看个东西～", "刚刚路过你家楼下，灯亮着真好。",
    "广场有新动态，快来看看！", "今天能源谷的晚霞绝了。",
    "有件小事想请你帮个忙～",
  ]
  let text = teasers[model.tick / interval % teasers.length()]
  let recorded = town_life_append_phone_message(model, {
    contact: contact.id,
    from_me: false,
    text,
    tick: model.tick,
  })
  let next = {
    ..recorded,
    phone_unread: model.phone_unread + 1,
    life_toast: "📱 离线剧本居民 \{contact.name} 给你发来一条本地消息",
    life_toast_tick: model.tick,
  }
  track_event(next, "phone_receive", contact.id)
}

///|
fn phone_send_model(model : Model) -> Model {
  let text = model.phone_draft.trim().to_owned()
  if text.is_empty() {
    return model
  }
  let contact = model.phone_contact
  if phone_contact_is_runtime(contact) {
    return {
      ..model,
      life_toast: "这位 Runtime Agent 的手机动态目前只读；消息没有伪装成已发送。请从真实工作请求入口提交任务。",
      life_toast_tick: model.tick,
    }
  }
  let sent = town_life_append_phone_message(model, {
    contact,
    from_me: true,
    text,
    tick: model.tick,
  })
  // The resident answers in the same beat; the reply reads the whole thread
  // length as its rotation salt, so consecutive sends get varied replies.
  let reply = offline_resident_reply(contact, text, sent.phone_log.length())
  let replied = town_life_append_phone_message(sent, {
    contact,
    from_me: false,
    text: reply,
    tick: model.tick,
  })
  let next = { ..replied, phone_draft: "" }
  let next = track_event(next, "phone_send", contact)
  let next = track_event(next, "phone_receive", contact)
  complete_quest(next, "first-chat")
}

///|
/// Floating phone entry with unread badge, bottom-right above the guide
/// buttons. Always reachable in one click from anywhere.
fn render_phone_fab(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  if model.player is None {
    return @html.nothing
  }
  button(
    class="phone-fab pointer-events-auto",
    on_click=dispatch(TogglePhone),
    attrs=@html.Attrs::build()
      .aria_label("打开虚拟手机")
      .aria_expanded(if model.phone_open { "true" } else { "false" }),
    [
      span(class="phone-fab-icon", "📱"),
      if model.phone_unread > 0 {
        span(class="phone-fab-badge", model.phone_unread.to_string())
      } else {
        @html.nothing
      },
    ],
  )
}

///|
fn render_phone_contact_row(
  dispatch : Dispatch[Msg],
  model : Model,
  contact : PhoneContact,
) -> @rabbita.Html {
  let thread = phone_thread(model, contact.id)
  let last = if thread.is_empty() {
    contact.greeting
  } else {
    thread[thread.length() - 1].text
  }
  button(
    class=if model.phone_contact == contact.id {
      "phone-contact phone-contact-active"
    } else {
      "phone-contact"
    },
    on_click=dispatch(PhoneSelectContact(contact.id)),
    [
      span(class="phone-contact-avatar", contact.avatar_glyph),
      span(class="phone-contact-meta", [
        span(class="phone-contact-name", contact.name),
        span(class="phone-contact-last", last),
      ]),
    ],
  )
}

///|
fn render_phone_thread(model : Model) -> @rabbita.Html {
  let contact = phone_contact_by_id(model, model.phone_contact)
  let thread = phone_thread(model, contact.id)
  let sender_label = if phone_contact_is_runtime(contact.id) {
    "\{contact.name} · Runtime 工作动态"
  } else {
    "\{contact.name} · 本地剧本"
  }
  let bubbles : Array[@rabbita.Html] = []
  if thread.is_empty() {
    bubbles.push(
      div(class="phone-bubble phone-bubble-them", [
        span(class="phone-bubble-name", sender_label),
        span(contact.greeting),
      ]),
    )
  }
  for message in thread {
    bubbles.push(
      if message.from_me {
        div(class="phone-bubble phone-bubble-me", message.text)
      } else {
        div(class="phone-bubble phone-bubble-them", [
          span(class="phone-bubble-name", sender_label),
          span(message.text),
        ])
      },
    )
  }
  div(class="phone-thread", bubbles)
}

///|
fn render_phone_panel(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  if !model.phone_open {
    return @html.nothing
  }
  let contact = phone_contact_by_id(model, model.phone_contact)
  let runtime_contact = phone_contact_is_runtime(contact.id)
  section(
    class="phone-panel pointer-events-auto",
    attrs=@html.Attrs::build().role("dialog").aria_label("虚拟手机"),
    [
      div(class="phone-panel-head", [
        span(class="phone-panel-heading", [
          span(class="phone-panel-title", "📱 谷光手机"),
          span(
            class="phone-panel-mode",
            if runtime_contact {
              "真实 Runtime Agent · 只读工作动态"
            } else {
              "离线居民 · 本地剧本（非 AI）"
            },
          ),
        ]),
        button(
          class="phone-panel-close",
          on_click=dispatch(TogglePhone),
          attrs=@html.Attrs::build().aria_label("收起手机"),
          "✕",
        ),
      ]),
      div(class="phone-panel-body", [
        div(
          class="phone-contacts",
          phone_contacts(model).map(c => {
            render_phone_contact_row(dispatch, model, c)
          }),
        ),
        div(class="phone-chat", [
          div(class="phone-chat-head", [
            span(class="phone-contact-avatar", contact.avatar_glyph),
            span(class="phone-chat-title", [
              span(class="phone-contact-name", contact.name),
              span(class="phone-contact-role", contact.role),
            ]),
          ]),
          render_phone_thread(model),
          if runtime_contact {
            div(class="phone-composer", [
              input(
                id="phone-draft-input",
                class="phone-input",
                placeholder="真实消息写入接口尚未连接",
                value="",
                attrs=@html.Attrs::build()
                  .disabled(true)
                  .aria_label("Runtime Agent 工作动态为只读"),
              ),
              button(
                class="phone-send",
                on_click=dispatch(OpenEnergyRequestForAgent(contact.id)),
                attrs=@html.Attrs::build().aria_label(
                  "打开真实工作请求表单",
                ),
                "创建真实工作请求",
              ),
            ])
          } else {
            div(class="phone-composer", [
              input(
                id="phone-draft-input",
                class="phone-input",
                placeholder="发送本地剧本消息给 \{contact.name}…",
                value=model.phone_draft,
                on_input=value => dispatch(PhoneDraft(value)),
              ),
              button(
                class="phone-send",
                on_click=dispatch(PhoneSend),
                attrs=@html.Attrs::build().aria_label(
                  "发送本地剧本消息",
                ),
                "发送",
              ),
            ])
          },
        ]),
      ]),
    ],
  )
}
