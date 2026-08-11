///|
let moonclaw_guide_contact_id = "moonclaw-guide"

///|
fn phone_contact_is_moonclaw_guide(id : String) -> Bool {
  id == moonclaw_guide_contact_id
}

///|
fn moonclaw_guide_contact() -> PhoneContact {
  {
    id: moonclaw_guide_contact_id,
    name: "小爪",
    role: "Moonclaw Guide · 本地 Agent",
    avatar_glyph: "爪",
    greeting: "忘记下一步也没关系。我是住在谷光手机里的 Moonclaw Guide，可以解释 MoonTown 的界面、MoonBook、大楼、居民和真实工作入口。先选一个常见问题，或者直接问我。",
  }
}

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
  let runtime_contacts = phone_runtime_contacts(model)
  let contacts = if runtime_contacts.is_empty() {
    [moonclaw_guide_contact()] + offline_phone_contacts()
  } else {
    runtime_contacts + [moonclaw_guide_contact()] + offline_phone_contacts()
  }
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
  if phone_contact_is_moonclaw_guide(contact) {
    return model
  }
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
fn moonclaw_guide_context(model : Model) -> String {
  if policy_hall_question_selected(model) {
    policy_hall_question_context_key
  } else if model.player is None {
    "before-avatar"
  } else if current_quest(model) is Some(_) {
    "onboarding"
  } else {
    "town"
  }
}

///|
fn moonclaw_guide_send_cmd(
  dispatch : Dispatch[Msg],
  message : String,
  context : String,
) -> Cmd {
  @rabbita.perform(fn(raw) { dispatch(MoonclawGuideReplied(raw)) }, async fn() noraise {
    wait_request_response_json(
      submit_moonclaw_guide_json(
        message,
        context,
        browser_moonclaw_guide_session_id(),
      ),
    )
  })
}

///|
fn moonclaw_guide_send_update(
  dispatch : Dispatch[Msg],
  model : Model,
  input : String,
) -> (Cmd, Model) {
  let message = input.trim().to_owned()
  if message.is_empty() || model.moonclaw_guide_pending {
    return model_only_update(model)
  }
  let sent = town_life_append_phone_message(model, {
    contact: moonclaw_guide_contact_id,
    from_me: true,
    text: message,
    tick: model.tick,
  })
  let next = track_event(
    {
      ..sent,
      phone_open: true,
      phone_contact: moonclaw_guide_contact_id,
      phone_draft: "",
      moonclaw_guide_pending: true,
      moonclaw_guide_error: "",
    },
    "phone_send",
    moonclaw_guide_contact_id,
  )
  let (persist_cmd, persisted) = town_life_commit(next)
  (
    @rabbita.batch([
      persist_cmd,
      moonclaw_guide_send_cmd(dispatch, message, moonclaw_guide_context(model)),
    ]),
    persisted,
  )
}

///|
fn moonclaw_guide_reply_result(raw : String) -> Result[String, String] {
  let parsed = @json.parse(raw) catch {
    _ =>
      return Err("Moonclaw 返回了无法识别的响应，请稍后再试。")
  }
  guard parsed is Object(fields) else {
    return Err("Moonclaw 返回了无法识别的响应，请稍后再试。")
  }
  if fields.get("ok") is Some(True) {
    match fields.get("reply") {
      Some(String(reply)) if !reply.trim().is_empty() =>
        Ok(reply.trim().to_owned())
      _ => Err("Moonclaw 已完成请求，但没有返回文字回复。")
    }
  } else {
    match fields.get("error") {
      Some(String(error)) if !error.trim().is_empty() =>
        Err(moonclaw_guide_safe_error(error))
      _ =>
        Err(
          "Moonclaw 目前无法连接，请确认本地网关正在运行。",
        )
    }
  }
}

///|
fn moonclaw_guide_safe_error(value : String) -> String {
  let error = value.trim().to_owned()
  let lower = error.to_lower()
  if error.length() > 240 ||
    error.contains("\n") ||
    lower.contains("<!doctype") ||
    lower.contains("<html") ||
    lower.contains("</") {
    "Moonclaw 目前无法连接，请确认本地网关正在运行。"
  } else {
    error
  }
}

///|
fn moonclaw_guide_reply_update(raw : String, model : Model) -> (Cmd, Model) {
  match moonclaw_guide_reply_result(raw) {
    Ok(reply) => {
      let received = town_life_append_phone_message(model, {
        contact: moonclaw_guide_contact_id,
        from_me: false,
        text: reply,
        tick: model.tick,
      })
      let next = complete_quest(
        track_event(
          {
            ..received,
            moonclaw_guide_pending: false,
            moonclaw_guide_error: "",
          },
          "phone_receive",
          moonclaw_guide_contact_id,
        ),
        "first-chat",
      )
      town_life_commit(next)
    }
    Err(error) =>
      model_only_update({
        ..model,
        moonclaw_guide_pending: false,
        moonclaw_guide_error: error,
      })
  }
}

///|
/// The existing phone entry becomes the Moonclaw pet. It remains the single
/// gateway to all phone contacts and opens the live guide in one click.
fn render_phone_fab(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  button(
    class="moonclaw-pet pointer-events-auto",
    on_click=dispatch(OpenMoonclawGuide),
    attrs=@html.Attrs::build()
      .aria_label("打开谷光手机，询问 Moonclaw Guide")
      .aria_controls("town-phone-panel")
      .aria_expanded(if model.phone_open { "true" } else { "false" }),
    [
      span(
        class="moonclaw-pet-art",
        attrs=@html.Attrs::build().aria_hidden("true"),
        [
          span(class="moonclaw-pet-ear moonclaw-pet-ear-left", no_children()),
          span(class="moonclaw-pet-ear moonclaw-pet-ear-right", no_children()),
          span(class="moonclaw-pet-face", [
            span(class="moonclaw-pet-eye moonclaw-pet-eye-left", no_children()),
            span(class="moonclaw-pet-eye moonclaw-pet-eye-right", no_children()),
            span(class="moonclaw-pet-smile", no_children()),
          ]),
          span(class="moonclaw-pet-moon", "☾"),
        ],
      ),
      span(class="moonclaw-pet-label", [
        span(class="moonclaw-pet-name", "小爪"),
        span(class="moonclaw-pet-hint", "忘了？问我"),
      ]),
      if model.phone_unread > 0 {
        span(class="moonclaw-pet-badge", model.phone_unread.to_string())
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
fn render_phone_thread(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let contact = phone_contact_by_id(model, model.phone_contact)
  let thread = phone_thread(model, contact.id)
  let guide_contact = phone_contact_is_moonclaw_guide(contact.id)
  let policy_context = guide_contact && policy_hall_question_selected(model)
  let sender_label = if guide_contact {
    "\{contact.name} · Moonclaw Agent"
  } else if phone_contact_is_runtime(contact.id) {
    "\{contact.name} · Runtime 工作动态"
  } else {
    "\{contact.name} · 本地剧本"
  }
  let bubbles : Array[@rabbita.Html] = []
  if thread.is_empty() {
    bubbles.push(
      div(class="phone-bubble phone-bubble-them", [
        span(class="phone-bubble-name", sender_label),
        span(
          if policy_context {
            policy_hall_question_greeting()
          } else {
            contact.greeting
          },
        ),
      ]),
    )
    if guide_contact {
      let prompts = if policy_context {
        policy_hall_question_prompts()
      } else {
        [
          "我现在应该先做什么？", "MoonTown 里的大楼、MoonBook 和 Agent 是什么关系？",
          "我在哪里查看真实工作和结果？",
        ]
      }
      bubbles.push(
        div(
          class="phone-guide-prompts",
          [
            span(
              class="phone-guide-prompts-label",
              if policy_context {
                "可以从资格、材料或复核开始："
              } else {
                "可以先问："
              },
            ),
          ] +
          prompts.map(prompt => {
            button(
              class="phone-guide-prompt",
              on_click=dispatch(MoonclawGuideAsk(prompt)),
              attrs=@html.Attrs::build().disabled(model.moonclaw_guide_pending),
              prompt,
            )
          }),
        ),
      )
    }
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
  if guide_contact && model.moonclaw_guide_pending {
    bubbles.push(
      div(
        class="phone-bubble phone-bubble-them phone-guide-thinking",
        attrs=@html.Attrs::build().aria_live("polite"),
        [
          span(class="phone-bubble-name", sender_label),
          span(class="phone-guide-thinking-dots", [
            span(no_children()),
            span(no_children()),
            span(no_children()),
          ]),
          span("Moonclaw 正在查看你的问题…"),
        ],
      ),
    )
  }
  if guide_contact && !model.moonclaw_guide_error.is_empty() {
    bubbles.push(
      div(class="phone-guide-error", attrs=@html.Attrs::build().role("alert"), [
        span(class="phone-guide-error-title", "暂时没连上 Moonclaw"),
        span(model.moonclaw_guide_error),
        span(
          "确认本地 Moonclaw gateway 已启动后，可以直接重试。",
        ),
      ]),
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
  let guide_contact = phone_contact_is_moonclaw_guide(contact.id)
  let policy_context = guide_contact && policy_hall_question_selected(model)
  section(
    id="town-phone-panel",
    class="phone-panel pointer-events-auto",
    attrs=@html.Attrs::build().role("dialog").aria_label("谷光手机"),
    [
      div(class="phone-panel-head", [
        span(class="phone-panel-heading", [
          span(class="phone-panel-title", "谷光手机"),
          span(
            class="phone-panel-mode",
            if guide_contact {
              if policy_context {
                "Policy Hall · 昌平青创政策问答"
              } else {
                "Moonclaw Guide · 真实本地 Agent"
              }
            } else if runtime_contact {
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
        div(
          class="phone-chat",
          attrs=@html.Attrs::build().aria_busy(
            if guide_contact && model.moonclaw_guide_pending {
              "true"
            } else {
              "false"
            },
          ),
          [
            div(class="phone-chat-head", [
              span(class="phone-contact-avatar", contact.avatar_glyph),
              span(class="phone-chat-title", [
                span(class="phone-contact-name", contact.name),
                span(class="phone-contact-role", contact.role),
              ]),
              if guide_contact {
                span(
                  class=if model.moonclaw_guide_pending {
                    "phone-guide-state phone-guide-state-busy"
                  } else if !model.moonclaw_guide_error.is_empty() {
                    "phone-guide-state phone-guide-state-error"
                  } else {
                    "phone-guide-state"
                  },
                  if model.moonclaw_guide_pending {
                    "思考中"
                  } else if !model.moonclaw_guide_error.is_empty() {
                    "未连接"
                  } else {
                    "可提问"
                  },
                )
              } else {
                @html.nothing
              },
            ]),
            if policy_context {
              aside(
                class="phone-policy-context",
                attrs=@html.Attrs::build().role("note"),
                [
                  span(class="phone-policy-context-title", "答复边界"),
                  span(
                    "依据昌平青创政策 MoonBook；区分官网确认、现场 OCR 与待复核项。信息导航不等于审批意见。",
                  ),
                ],
              )
            } else {
              @html.nothing
            },
            render_phone_thread(dispatch, model),
            if guide_contact {
              div(class="phone-guide-composer", [
                span(
                  id="moonclaw-guide-composer-label",
                  class="phone-composer-label",
                  if policy_context {
                    "描述你的情况，询问昌平青创政策"
                  } else {
                    "问小爪关于 MoonTown 的问题"
                  },
                ),
                div(class="phone-composer", [
                  input(
                    id="phone-draft-input",
                    class="phone-input",
                    placeholder=if policy_context {
                      "例如：我 29 岁，硕士，在昌注册公司 8 个月…"
                    } else {
                      "例如：我接下来该做什么？"
                    },
                    value=model.phone_draft,
                    on_input=value => dispatch(PhoneDraft(value)),
                    attrs=@html.Attrs::build()
                      .disabled(model.moonclaw_guide_pending)
                      .aria_labelledby("moonclaw-guide-composer-label"),
                  ),
                  button(
                    class=if model.moonclaw_guide_pending {
                      "phone-send phone-send-disabled"
                    } else {
                      "phone-send"
                    },
                    on_click=dispatch(PhoneSend),
                    attrs=@html.Attrs::build()
                      .disabled(model.moonclaw_guide_pending)
                      .aria_label(
                        if policy_context {
                          "发送昌平青年创新创业政策问题"
                        } else {
                          "发送问题给 Moonclaw Guide"
                        },
                      ),
                    if model.moonclaw_guide_pending {
                      "请稍候"
                    } else {
                      "发送"
                    },
                  ),
                ]),
              ])
            } else if runtime_contact {
              div(class="phone-runtime-contact-actions", [
                p(
                  class="phone-policy-context-copy",
                  "真实 Runtime Agent 动态为只读。需要协作时，创建可追踪、可审核的工作请求。",
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
          ],
        ),
      ]),
    ],
  )
}
