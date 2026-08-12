///|
/// One entry in the authoritative local analytics event dictionary.
///
/// The browser currently stores compact `day|event|detail` records. This is
/// intentionally a local activity log, not a user analytics backend: it has
/// no user id, wall-clock timestamp, or session id and therefore must never be
/// presented as DAU, retention, or multi-user conversion data.
priv struct AnalyticsEventDef {
  name : String
  label : String
  category : String
}

///|
/// Authoritative v1 dictionary. There are exactly 20 event kinds. Keeping the
/// list executable (rather than only in a comment) lets ingestion, the ops UI,
/// and tests agree on the same contract.
fn analytics_event_dictionary() -> Array[AnalyticsEventDef] {
  [
    { name: "avatar_create", label: "创建角色", category: "onboarding" },
    { name: "avatar_edit", label: "编辑角色", category: "onboarding" },
    { name: "walk_step", label: "角色移动", category: "explore" },
    { name: "walk_mode", label: "切换行走模式", category: "explore" },
    { name: "building_visit", label: "视察大楼", category: "explore" },
    { name: "phone_open", label: "打开虚拟手机", category: "social" },
    {
      name: "phone_send",
      label: "发送本地剧本消息",
      category: "social",
    },
    {
      name: "phone_receive",
      label: "收到本地剧本回复",
      category: "social",
    },
    { name: "build_place", label: "放置楼宇", category: "build" },
    {
      name: "knowledge_topic",
      label: "设置知识主题",
      category: "knowledge",
    },
    {
      name: "knowledge_publish",
      label: "发布本地知识条目",
      category: "knowledge",
    },
    {
      name: "knowledge_collect",
      label: "收藏本地广场条目",
      category: "knowledge",
    },
    { name: "quest_complete", label: "完成任务", category: "onboarding" },
    { name: "checkin", label: "本地签到", category: "onboarding" },
    { name: "ops_open", label: "打开运营中心", category: "system" },
    {
      name: "ops_report",
      label: "生成本页运营快照",
      category: "system",
    },
    {
      name: "metro_toggle",
      label: "切换 17 号线图层",
      category: "explore",
    },
    { name: "square_open", label: "打开本地广场", category: "social" },
    { name: "board_open", label: "打开运行看板", category: "system" },
    { name: "guide_open", label: "打开指南", category: "system" },
  ]
}

///|
fn analytics_event_dictionary_version() -> String {
  "v1 · 20 种"
}

///|
fn analytics_event_is_known(event : String) -> Bool {
  analytics_event_dictionary().any(definition => definition.name == event)
}

///|
fn analytics_event_label(event : String) -> String {
  for definition in analytics_event_dictionary() {
    if definition.name == event {
      return definition.label
    }
  }
  "未知事件"
}

///|
let analytics_ring_capacity : Int = frontend_setting_int(
  "analytics_ring_capacity", 160,
)

///|
/// Append one validated local activity record. Unknown names are rejected so
/// spelling mistakes cannot silently create a second analytics contract.
/// Delimiters and line breaks are normalized to preserve the compact format.
fn track_event(model : Model, event : String, detail : String) -> Model {
  if !analytics_event_is_known(event) {
    return model
  }
  let day = energy_valley_sim_day(model)
  let safe_detail = detail
    .replace(old="|", new="／")
    .replace(old="\n", new=" ")
    .replace(old="\r", new=" ")
  let line = "\{day}|\{event}|\{safe_detail}"
  town_life_append_analytics_line(model, line)
}

///|
fn analytics_line_matches_event(line : String, event : String) -> Bool {
  let fields = line.split("|").to_array()
  fields.length() >= 2 && fields[1].to_owned() == event
}

///|
/// Count occurrences of one event on a given simulation day within the local
/// ring buffer. This is an event count, never a user count.
fn analytics_count_on(model : Model, day : Int, event : String) -> Int {
  let prefix = "\{day}|"
  let mut count = 0
  for line in model.analytics {
    if line.has_prefix(prefix) && analytics_line_matches_event(line, event) {
      count += 1
    }
  }
  count
}

///|
fn analytics_wrap_index(day_index : Int, length : Int) -> Int {
  let raw = day_index % length
  if raw < 0 {
    raw + length
  } else {
    raw
  }
}

///|
fn analytics_event_count_on(model : Model, day : Int) -> Int {
  let prefix = "\{day}|"
  let mut count = 0
  for line in model.analytics {
    if line.has_prefix(prefix) {
      count += 1
    }
  }
  count
}

///|
fn analytics_today_activity(model : Model) -> Int {
  analytics_event_count_on(model, energy_valley_sim_day(model))
}

///|
fn analytics_today_builds(model : Model) -> Int {
  analytics_count_on(model, energy_valley_sim_day(model), "build_place")
}

///|
fn analytics_today_chat_sent(model : Model) -> Int {
  analytics_count_on(model, energy_valley_sim_day(model), "phone_send")
}

///|
fn analytics_today_chat_replies(model : Model) -> Int {
  analytics_count_on(model, energy_valley_sim_day(model), "phone_receive")
}

///|
fn analytics_today_chats(model : Model) -> Int {
  analytics_today_chat_sent(model) + analytics_today_chat_replies(model)
}

///|
/// Exact local activity totals for the latest simulation days. Zeroes remain
/// zeroes; no demo baseline is mixed into this series.
fn analytics_activity_series(model : Model, days : Int) -> Array[Int] {
  let today = energy_valley_sim_day(model)
  let result : Array[Int] = []
  for offset in 0..<days {
    result.push(analytics_event_count_on(model, today - days + 1 + offset))
  }
  result
}

///|
fn analytics_active_recorded_days(model : Model, days : Int) -> Int {
  analytics_activity_series(model, days).filter(value => value > 0).length()
}

///|
/// Today's exact local event-category counts. These measure interactions from
/// this browser profile, not residents or unique people.
fn analytics_today_categories(model : Model) -> Array[(String, Int)] {
  let categories = [
    ("引导", "onboarding"),
    ("探索", "explore"),
    ("本地社交", "social"),
    ("建造", "build"),
    ("知识", "knowledge"),
    ("系统", "system"),
  ]
  let today = energy_valley_sim_day(model)
  let result : Array[(String, Int)] = []
  for item in categories {
    let (label, category) = item
    let mut count = 0
    for definition in analytics_event_dictionary() {
      if definition.category == category {
        count += analytics_count_on(model, today, definition.name)
      }
    }
    result.push((label, count))
  }
  result
}

///|
/// Current local profile journey. Values are binary completion states rather
/// than invented cohort/user counts.
fn analytics_funnel(model : Model) -> Array[(String, Int)] {
  [
    (
      "创建角色",
      if quest_completed(model, "create-avatar") {
        1
      } else {
        0
      },
    ),
    ("首次行走", if quest_completed(model, "first-walk") { 1 } else { 0 }),
    (
      "视察大楼",
      if quest_completed(model, "visit-building") {
        1
      } else {
        0
      },
    ),
    ("首次聊天", if quest_completed(model, "first-chat") { 1 } else { 0 }),
    (
      "首次建造",
      if quest_completed(model, "build-knowledge") {
        1
      } else {
        0
      },
    ),
    (
      "发布分享",
      if quest_completed(model, "publish-knowledge") {
        1
      } else {
        0
      },
    ),
    (
      "收藏共建",
      if quest_completed(model, "collect-building") {
        1
      } else {
        0
      },
    ),
  ]
}

///|
fn analytics_funnel_completed(model : Model) -> Int {
  analytics_funnel(model).filter(stage => stage.1 == 1).length()
}

///|
fn analytics_local_knowledge_counts(model : Model) -> Array[(String, Int)] {
  [
    ("我的条目", model.posts.filter(post => post.mine).length()),
    (
      "已发布",
      model.posts.filter(post => post.mine && post.published).length(),
    ),
    ("已收藏", model.posts.filter(post => post.collected).length()),
    ("自建楼宇", energy_valley_model_buildings(model).length()),
    ("广场示例", model.posts.filter(post => !post.mine).length()),
  ]
}
