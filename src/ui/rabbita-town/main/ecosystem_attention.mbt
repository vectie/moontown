///|
/// Provenance is carried on every visible intention and attention signal.
/// Only `RuntimeLive` may use present-tense claims about real work.
priv enum EcosystemProvenance {
  RuntimeLive
  RuntimeRecord
  AmbientPreview
  LocalPlayer
  AuthoredPlace
  LocalPlace
} derive(Debug, Eq)

///|
priv enum EcosystemBehavior {
  Coordinate
  Research
  Review
  Exchange
  Observe
  Learn
  Browse
  Walk
  Rest
  Deliver
  Celebrate
} derive(Debug, Eq)

///|
priv enum EcosystemDisclosureLevel {
  Glance
  Nearby
  Inspect
} derive(Debug, Eq)

///|
priv struct EcosystemPlaceCharacter {
  characteristic : String
  living_detail : String
  ambient_intention : String
  interaction_label : String
  glyph : String
  accent : String
  focus_bias : Int
  social_bias : Int
  discovery_bias : Int
}

///|
priv struct EcosystemPlaceProfile {
  id : String
  name : String
  district : String
  style : String
  characteristic : String
  living_detail : String
  ambient_intention : String
  interaction_label : String
  glyph : String
  accent : String
  focus_bias : Int
  social_bias : Int
  discovery_bias : Int
  x : Int
  y : Int
  entrance_x : Int
  entrance_y : Int
  provenance : EcosystemProvenance
} derive(Debug)

///|
priv struct EcosystemScheduleBeat {
  duration_ticks : Int
  place_id : String
  behavior : EcosystemBehavior
  short_intention : String
  detail : String
  interaction_label : String
} derive(Debug)

///|
priv struct EcosystemPreviewResidentProfile {
  id : String
  name : String
  role : String
  sprite_index : Int
  characteristic : String
  interest : String
  sociability : Int
  curiosity : Int
  focus : Int
  phase_offset : Int
  schedule : Array[EcosystemScheduleBeat]
} derive(Debug)

///|
priv struct EcosystemIntention {
  resident_id : String
  resident_name : String
  place_id : String
  behavior : EcosystemBehavior
  short_label : String
  detail : String
  interaction_label : String
  started_tick : Int
  provenance : EcosystemProvenance
} derive(Debug)

///|
priv struct EcosystemAttentionSignal {
  id : String
  subject_id : String
  place_id : String
  behavior : EcosystemBehavior
  headline : String
  detail : String
  interaction_label : String
  interaction_target : String
  urgency : Int
  novelty : Int
  proximity : Int
  affinity : Int
  happened_tick : Int
  decay_per_tick : Int
  expires_after_ticks : Int
  cooldown_key : String
  cooldown_ticks : Int
  provenance : EcosystemProvenance
} derive(Debug)

///|
priv struct EcosystemAttentionReceipt {
  cooldown_key : String
  last_shown_tick : Int
  show_count : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
priv struct EcosystemRankedAttention {
  signal : EcosystemAttentionSignal
  score : Int
} derive(Debug)

///|
priv struct EcosystemDisclosure {
  glance : String
  nearby : String
  inspect : String
  provenance_badge : String
  interaction_label : String
} derive(Debug, Eq)

///|
fn ecosystem_positive_mod(value : Int, modulus : Int) -> Int {
  if modulus <= 0 {
    return 0
  }
  let remainder = value % modulus
  if remainder < 0 {
    remainder + modulus
  } else {
    remainder
  }
}

///|
fn ecosystem_stable_hash(text : String) -> Int {
  let mut hash = 17
  for character in text {
    hash = (hash * 131 + character.to_int()) % 2147483629
  }
  hash.abs()
}

///|
fn ecosystem_compact_text(text : String, max_chars : Int) -> String {
  if max_chars <= 0 {
    return ""
  }
  let builder = StringBuilder()
  let mut count = 0
  for character in text {
    if count >= max_chars {
      builder.write_char('…')
      return builder.to_string()
    }
    builder.write_char(character)
    count += 1
  }
  builder.to_string()
}

///|
fn ecosystem_provenance_badge(source : EcosystemProvenance) -> String {
  match source {
    RuntimeLive => "REAL · LIVE"
    RuntimeRecord => "RUNTIME · RECORDED"
    AmbientPreview => "AMBIENT · PREVIEW"
    LocalPlayer => "LOCAL · PLAYER"
    AuthoredPlace => "PLACE · WENYU"
    LocalPlace => "PLACE · LOCAL"
  }
}

///|
fn ecosystem_provenance_short(source : EcosystemProvenance) -> String {
  match source {
    RuntimeLive => "真实工作"
    RuntimeRecord => "运行时记录"
    AmbientPreview => "小镇日常"
    LocalPlayer => "本机玩家"
    AuthoredPlace => "温榆场所"
    LocalPlace => "本地建筑"
  }
}

///|
fn ecosystem_behavior_glyph(behavior : EcosystemBehavior) -> String {
  match behavior {
    Coordinate => "◎"
    Research => "⌕"
    Review => "✓"
    Exchange => "↔"
    Observe => "◌"
    Learn => "✦"
    Browse => "◇"
    Walk => "→"
    Rest => "☕"
    Deliver => "⇢"
    Celebrate => "✺"
  }
}

///|
fn ecosystem_place_character_for(
  id : String,
  style : String,
) -> EcosystemPlaceCharacter {
  match id {
    "town-shell" =>
      {
        characteristic: "镇务脉冲厅",
        living_detail: "环形路线灯会随分派、回执和阻塞逐段亮起。",
        ambient_intention: "看下一圈镇务信号如何落位",
        interaction_label: "查看全镇脉冲",
        glyph: "◎",
        accent: "#f6c85f",
        focus_bias: 88,
        social_bias: 42,
        discovery_bias: 55,
      }
    "policy-hall" =>
      {
        characteristic: "政策清单长廊",
        living_detail: "咨询牌沿证据完整度移动，缺材料的卡片停在橙色灯下。",
        ambient_intention: "把一个模糊问题变成可核对清单",
        interaction_label: "领取政策清单",
        glyph: "▤",
        accent: "#f59e0b",
        focus_bias: 82,
        social_bias: 48,
        discovery_bias: 63,
      }
    "vitality-dashboard" =>
      {
        characteristic: "活力信号塔",
        living_detail: "塔身光带只响应真实投影，离线时保持低亮而不伪造繁忙。",
        ambient_intention: "寻找今天最值得注意的变化",
        interaction_label: "读活力信号",
        glyph: "⌁",
        accent: "#34d399",
        focus_bias: 76,
        social_bias: 36,
        discovery_bias: 86,
      }
    "contest-express" =>
      {
        characteristic: "路演月台",
        living_detail: "倒计时牌、模拟评委席和练习脚印让准备进度看得见。",
        ambient_intention: "听一轮三分钟演练",
        interaction_label: "旁听模拟路演",
        glyph: "▶",
        accent: "#fb7185",
        focus_bias: 74,
        social_bias: 72,
        discovery_bias: 58,
      }
    "broadcast-tower" =>
      {
        characteristic: "故事雷达舱",
        living_detail: "候选故事像光点扫过穹顶，只有通过人工审阅的片段会离塔。",
        ambient_intention: "捕捉一个可公开的小镇瞬间",
        interaction_label: "查看候选故事",
        glyph: "◉",
        accent: "#f472b6",
        focus_bias: 62,
        social_bias: 68,
        discovery_bias: 91,
      }
    "resident-twins" =>
      {
        characteristic: "私密记忆双塔",
        living_detail: "一侧保存私人生活，一侧只投射居民批准过的公开摘要。",
        ambient_intention: "回家整理一条今天的记忆",
        interaction_label: "拜访公共客厅",
        glyph: "⌂",
        accent: "#a78bfa",
        focus_bias: 57,
        social_bias: 61,
        discovery_bias: 49,
      }
    "ai-garden" =>
      {
        characteristic: "工具试验花园",
        living_detail: "每块花圃对应一个小实验，开花表示教程已经有人走通。",
        ambient_intention: "试一个十分钟 AI 小实验",
        interaction_label: "进入今日试验",
        glyph: "✿",
        accent: "#4ade80",
        focus_bias: 66,
        social_bias: 65,
        discovery_bias: 94,
      }
    "social-square" =>
      {
        characteristic: "弱连接会客场",
        living_detail: "不同领域的路线在这里短暂交叉，长椅旁留下待跟进的问题。",
        ambient_intention: "遇见一位平常不会遇见的人",
        interaction_label: "加入广场话题",
        glyph: "↔",
        accent: "#c084fc",
        focus_bias: 43,
        social_bias: 98,
        discovery_bias: 78,
      }
    "research-embodied-robotics" =>
      {
        characteristic: "具身试验坞",
        living_detail: "步态轨迹、抓取夹具和失败回放共同围住中央测试台。",
        ambient_intention: "观察一次机器人动作复盘",
        interaction_label: "看具身试验",
        glyph: "⚙",
        accent: "#60a5fa",
        focus_bias: 93,
        social_bias: 46,
        discovery_bias: 87,
      }
    "research-ai-agents" =>
      {
        characteristic: "协议编排台",
        living_detail: "工具调用、记忆和交接被画成可追踪的彩色路径。",
        ambient_intention: "拆解一次 Agent 协作交接",
        interaction_label: "检查协议路径",
        glyph: "⌘",
        accent: "#818cf8",
        focus_bias: 96,
        social_bias: 54,
        discovery_bias: 89,
      }
    "talent-avenue" =>
      {
        characteristic: "人才星图大道",
        living_detail: "技能灯牌只展示可公开成就，机会在匹配成立时才连成线。",
        ambient_intention: "沿星图找到一位互补伙伴",
        interaction_label: "浏览人才星图",
        glyph: "✧",
        accent: "#38bdf8",
        focus_bias: 52,
        social_bias: 92,
        discovery_bias: 84,
      }
    "valley-market" =>
      {
        characteristic: "协作交换市集",
        living_detail: "摊位交换的是帮助、时间和本地权益，不把动画当成成交。",
        ambient_intention: "看看今天谁能帮谁一把",
        interaction_label: "逛协作摊位",
        glyph: "◆",
        accent: "#fb923c",
        focus_bias: 39,
        social_bias: 95,
        discovery_bias: 69,
      }
    "physical-bridge" =>
      {
        characteristic: "人机交付闸桥",
        living_detail: "任何现实世界动作都在闸门前等待明确的人类确认。",
        ambient_intention: "理解一项线下交付如何安全放行",
        interaction_label: "查看确认闸门",
        glyph: "⇄",
        accent: "#22d3ee",
        focus_bias: 91,
        social_bias: 35,
        discovery_bias: 62,
      }
    "research-opc" =>
      {
        characteristic: "单人公司观察站",
        living_detail: "一面墙收集新信号，另一面只留下能改变决策的增量。",
        ambient_intention: "寻找一个真正改变策略的信号",
        interaction_label: "翻看 OPC 信号",
        glyph: "◒",
        accent: "#2dd4bf",
        focus_bias: 94,
        social_bias: 41,
        discovery_bias: 90,
      }
    "research-llm-training" =>
      {
        characteristic: "训练剖面工坊",
        living_detail: "数据、预训练、后训练与评测被分层铺开，方便逐层追问。",
        ambient_intention: "沿训练剖面追一个为什么",
        interaction_label: "展开训练剖面",
        glyph: "≋",
        accent: "#8b5cf6",
        focus_bias: 97,
        social_bias: 32,
        discovery_bias: 92,
      }
    "research-ai-hardware" =>
      {
        characteristic: "芯片约束沙盘",
        living_detail: "功耗、带宽和供应链约束以实体积木压在系统方案上。",
        ambient_intention: "找出一个被硬件改变的 AI 决策",
        interaction_label: "操作约束沙盘",
        glyph: "▦",
        accent: "#f97316",
        focus_bias: 95,
        social_bias: 38,
        discovery_bias: 85,
      }
    _ => ecosystem_custom_place_character(style)
  }
}

///|
fn ecosystem_custom_place_character(style : String) -> EcosystemPlaceCharacter {
  match style {
    "tower" | "custom-tower" =>
      {
        characteristic: "屋顶信标工作室",
        living_detail: "高层灯窗随本地创作节奏明灭，尚未接入运行时就不会显示工作中。",
        ambient_intention: "看看屋顶正在试什么新想法",
        interaction_label: "登上工作室",
        glyph: "△",
        accent: "#c4b5fd",
        focus_bias: 82,
        social_bias: 43,
        discovery_bias: 84,
      }
    "lab" | "custom-lab" =>
      {
        characteristic: "开放试验间",
        living_detail: "玻璃台面保留最近一次本地试验的主题和可复现步骤。",
        ambient_intention: "围观一轮本地试验",
        interaction_label: "进入试验间",
        glyph: "⌬",
        accent: "#67e8f9",
        focus_bias: 88,
        social_bias: 47,
        discovery_bias: 89,
      }
    "hall" | "custom-hall" | "civic" =>
      {
        characteristic: "共创工坊",
        living_detail: "长桌会留下主题卡、协作者空位和下一步提示。",
        ambient_intention: "找一张可以接手的主题卡",
        interaction_label: "进入共创工坊",
        glyph: "▣",
        accent: "#fbbf24",
        focus_bias: 67,
        social_bias: 81,
        discovery_bias: 64,
      }
    "home" | "custom-home" | "row" | "courtyard" =>
      {
        characteristic: "居民灯窗",
        living_detail: "窗灯、阳台植物和门口留言表现生活节奏，不冒充运行状态。",
        ambient_intention: "在门廊停一会儿",
        interaction_label: "看看公共门廊",
        glyph: "⌂",
        accent: "#fda4af",
        focus_bias: 35,
        social_bias: 68,
        discovery_bias: 48,
      }
    "garden" | "campus" =>
      {
        characteristic: "慢行花园",
        living_detail: "小径、座椅和季节植物构成可以停留的半公共空间。",
        ambient_intention: "沿小径发现一个安静角落",
        interaction_label: "沿花园散步",
        glyph: "❋",
        accent: "#86efac",
        focus_bias: 29,
        social_bias: 64,
        discovery_bias: 73,
      }
    "market" =>
      {
        characteristic: "街角摊集",
        living_detail: "小摊按时段更换主题，空摊也会明确显示尚未开张。",
        ambient_intention: "看看这一刻的摊位主题",
        interaction_label: "逛街角摊集",
        glyph: "◇",
        accent: "#fdba74",
        focus_bias: 31,
        social_bias: 87,
        discovery_bias: 71,
      }
    "industrial" =>
      {
        characteristic: "制造后场",
        living_detail: "装卸位、维护灯和安全边界让生产空间拥有自己的节拍。",
        ambient_intention: "观察一轮维护检查",
        interaction_label: "查看安全边界",
        glyph: "⚒",
        accent: "#94a3b8",
        focus_bias: 77,
        social_bias: 22,
        discovery_bias: 59,
      }
    "radar" =>
      {
        characteristic: "信号观测台",
        living_detail: "扫描光只表达环境节拍；真实结论仍需运行时证据。",
        ambient_intention: "等下一次扫描掠过",
        interaction_label: "查看观测台",
        glyph: "◉",
        accent: "#f0abfc",
        focus_bias: 69,
        social_bias: 33,
        discovery_bias: 88,
      }
    _ =>
      {
        characteristic: "街区日常节点",
        living_detail: "门口、灯窗和停留点提供生活细节，但不声明发生了真实工作。",
        ambient_intention: "看看这里此刻有什么细节",
        interaction_label: "观察这个地方",
        glyph: "·",
        accent: "#93c5fd",
        focus_bias: 45,
        social_bias: 45,
        discovery_bias: 55,
      }
  }
}

///|
fn ecosystem_place_profile_for_module(
  civic : WenyuTownModule,
) -> EcosystemPlaceProfile {
  let character = ecosystem_place_character_for(
    civic.id,
    exact_energy_valley_building_style(civic.id),
  )
  {
    id: civic.id,
    name: civic.title,
    district: civic.district,
    style: exact_energy_valley_building_style(civic.id),
    characteristic: character.characteristic,
    living_detail: character.living_detail,
    ambient_intention: character.ambient_intention,
    interaction_label: character.interaction_label,
    glyph: character.glyph,
    accent: character.accent,
    focus_bias: character.focus_bias,
    social_bias: character.social_bias,
    discovery_bias: character.discovery_bias,
    x: civic.grid_x,
    y: civic.grid_y,
    entrance_x: civic.entrance_x,
    entrance_y: civic.entrance_y,
    provenance: AuthoredPlace,
  }
}

///|
fn ecosystem_civic_place_profiles() -> Array[EcosystemPlaceProfile] {
  exact_energy_valley_module_templates().map(ecosystem_place_profile_for_module)
}

///|
fn ecosystem_place_profile_for_building(
  building : GoldenValleyBuilding,
) -> EcosystemPlaceProfile {
  let identity = golden_valley_building_civic_id(building)
  if !identity.is_empty() {
    for civic in exact_energy_valley_module_templates() {
      if civic.id == identity {
        let profile = ecosystem_place_profile_for_module(civic)
        return {
          ..profile,
          name: building.name,
          x: building.x,
          y: building.y,
          entrance_x: building.entrance_x.unwrap_or(
            building.x + building.width / 2,
          ),
          entrance_y: building.entrance_y.unwrap_or(building.y + building.depth),
        }
      }
    }
  }
  let character = ecosystem_custom_place_character(building.style)
  {
    id: if identity.is_empty() {
      match golden_valley_nonempty_authored_id(building) {
        Some(authored_id) => "local-place-\{authored_id}"
        None => "local-place-\{building.x}-\{building.y}"
      }
    } else {
      identity
    },
    name: building.name,
    district: "local-neighborhood",
    style: building.style,
    characteristic: character.characteristic,
    living_detail: character.living_detail,
    ambient_intention: character.ambient_intention,
    interaction_label: character.interaction_label,
    glyph: character.glyph,
    accent: character.accent,
    focus_bias: character.focus_bias,
    social_bias: character.social_bias,
    discovery_bias: character.discovery_bias,
    x: building.x,
    y: building.y,
    entrance_x: building.entrance_x.unwrap_or(building.x + building.width / 2),
    entrance_y: building.entrance_y.unwrap_or(building.y + building.depth),
    provenance: LocalPlace,
  }
}

///|
fn ecosystem_place_profiles(
  model : Model,
  seed : Int,
) -> Array[EcosystemPlaceProfile] {
  let result = golden_valley_buildings(seed).map(
    ecosystem_place_profile_for_building,
  )
  for building in energy_valley_model_buildings(model) {
    result.push(ecosystem_place_profile_for_building(building))
  }
  result
}

///|
fn ecosystem_schedule_beat(
  duration_ticks : Int,
  place_id : String,
  behavior : EcosystemBehavior,
  short_intention : String,
  detail : String,
  interaction_label : String,
) -> EcosystemScheduleBeat {
  {
    duration_ticks,
    place_id,
    behavior,
    short_intention,
    detail,
    interaction_label,
  }
}

///|
fn ecosystem_preview_resident_profiles() -> Array[
  EcosystemPreviewResidentProfile,
] {
  [
    {
      id: "preview-mayor-wangyue",
      name: "望月",
      role: "镇长",
      sprite_index: 0,
      characteristic: "总会先听完再做分派",
      interest: "小镇里被忽略的阻塞",
      sociability: 78,
      curiosity: 72,
      focus: 88,
      phase_offset: 0,
      schedule: [
        ecosystem_schedule_beat(
          24,
          "town-shell",
          Coordinate,
          "校准镇务脉冲",
          "沿环形灯带确认哪些信号需要被看见。",
          "问今天最重要的事",
        ),
        ecosystem_schedule_beat(
          18,
          "policy-hall",
          Walk,
          "去政策厅听问题",
          "步行拜访前台，不把路上的动画算作处理完成。",
          "一起走一段",
        ),
        ecosystem_schedule_beat(
          22,
          "social-square",
          Exchange,
          "听广场上的新问题",
          "在公开话题里寻找跨建筑的连接。",
          "加入圆桌",
        ),
        ecosystem_schedule_beat(
          16,
          "resident-twins",
          Rest,
          "回家写镇长札记",
          "把今天的观察收成一条本地生活记录。",
          "听一段札记",
        ),
      ],
    },
    {
      id: "preview-keeper-zhihe",
      name: "知河",
      role: "知识守护",
      sprite_index: 1,
      characteristic: "喜欢把模糊问题折成清单",
      interest: "证据边界与可复现步骤",
      sociability: 55,
      curiosity: 76,
      focus: 95,
      phase_offset: 9,
      schedule: [
        ecosystem_schedule_beat(
          26,
          "policy-hall",
          Review,
          "核对清单缺口",
          "只标出需要补证的格子，不替运行时宣称结论。",
          "看公开清单",
        ),
        ecosystem_schedule_beat(
          20,
          "ai-garden",
          Learn,
          "测试一份新手教程",
          "沿教程走一遍，记录最容易迷路的步骤。",
          "一起试教程",
        ),
        ecosystem_schedule_beat(
          18,
          "social-square",
          Exchange,
          "带着问题去交换",
          "把证据问题讲给不同领域的居民听。",
          "回应一个问题",
        ),
        ecosystem_schedule_beat(
          16,
          "town-shell",
          Deliver,
          "送回一张建议卡",
          "把本地观察投进镇务建议槽。",
          "查看建议卡",
        ),
      ],
    },
    {
      id: "preview-keeper-ximo",
      name: "溪墨",
      role: "档案守护",
      sprite_index: 2,
      characteristic: "会记住每个版本为什么改变",
      interest: "时间线、出处与旧版本",
      sociability: 42,
      curiosity: 68,
      focus: 97,
      phase_offset: 17,
      schedule: [
        ecosystem_schedule_beat(
          28,
          "broadcast-tower",
          Review,
          "给故事补出处",
          "检查哪些片段适合公开，哪些只能留作本地记录。",
          "查看公开边界",
        ),
        ecosystem_schedule_beat(
          18,
          "research-llm-training",
          Browse,
          "翻一段训练历史",
          "沿版本剖面寻找一个被省略的转折。",
          "翻看版本卡",
        ),
        ecosystem_schedule_beat(
          20,
          "town-shell",
          Deliver,
          "归档今日变更",
          "提交一条带来源的本地档案提示。",
          "看变更摘要",
        ),
        ecosystem_schedule_beat(
          14,
          "resident-twins",
          Rest,
          "整理私人书签",
          "只整理自己的本地书签，不生成公共事实。",
          "聊一本书",
        ),
      ],
    },
    {
      id: "preview-keeper-lanxu",
      name: "岚序",
      role: "路线守护",
      sprite_index: 3,
      characteristic: "走路时总会检查入口是否好找",
      interest: "道路、门廊与无障碍路径",
      sociability: 63,
      curiosity: 74,
      focus: 84,
      phase_offset: 25,
      schedule: [
        ecosystem_schedule_beat(
          24,
          "physical-bridge",
          Observe,
          "检查交付闸门",
          "确认入口、等候区和人类确认点都清楚可见。",
          "一起检查入口",
        ),
        ecosystem_schedule_beat(
          22,
          "talent-avenue",
          Walk,
          "沿人才大道巡路",
          "记录拥挤、绕行和缺少停留点的位置。",
          "报告一个路况",
        ),
        ecosystem_schedule_beat(
          18,
          "valley-market",
          Exchange,
          "问摊主哪里难到达",
          "收集关于道路与入口的生活化反馈。",
          "分享路线体验",
        ),
        ecosystem_schedule_beat(
          16,
          "ai-garden",
          Rest,
          "在花园画路线图",
          "把巡路观察画成本地草图。",
          "看路线草图",
        ),
      ],
    },
    {
      id: "preview-researcher-lingxi",
      name: "灵犀",
      role: "Agent 研究员",
      sprite_index: 4,
      characteristic: "看到协作断点就忍不住追问",
      interest: "多智能体交接与记忆",
      sociability: 73,
      curiosity: 96,
      focus: 91,
      phase_offset: 33,
      schedule: [
        ecosystem_schedule_beat(
          27,
          "research-ai-agents",
          Research,
          "拆解一次协作交接",
          "在协议台比较工具调用与交接路径。",
          "问一个 Agent 问题",
        ),
        ecosystem_schedule_beat(
          23,
          "social-square",
          Exchange,
          "带协议问题去沙龙",
          "邀请别的领域从自己的角度挑错。",
          "加入协议讨论",
        ),
        ecosystem_schedule_beat(
          18,
          "ai-garden",
          Learn,
          "把结论做成小实验",
          "尝试把抽象协议变成十分钟可体验步骤。",
          "试一轮小实验",
        ),
        ecosystem_schedule_beat(
          12,
          "resident-twins",
          Rest,
          "回家整理研究便签",
          "保存一条本地研究便签，等待真实任务另行验证。",
          "看公开便签",
        ),
      ],
    },
    {
      id: "preview-researcher-wangye",
      name: "望野",
      role: "具身研究员",
      sprite_index: 5,
      characteristic: "更相信失败回放而不是漂亮演示",
      interest: "机器人动作与世界模型",
      sociability: 49,
      curiosity: 91,
      focus: 96,
      phase_offset: 41,
      schedule: [
        ecosystem_schedule_beat(
          30,
          "research-embodied-robotics",
          Research,
          "复盘一次抓取失败",
          "对照轨迹、碰撞和末端姿态寻找原因。",
          "观看失败回放",
        ),
        ecosystem_schedule_beat(
          20,
          "research-ai-hardware",
          Exchange,
          "去问硬件约束",
          "确认延迟和功耗是否改变动作方案。",
          "加入约束讨论",
        ),
        ecosystem_schedule_beat(
          18,
          "social-square",
          Exchange,
          "讲一个失败故事",
          "用一次失败换取跨领域的追问。",
          "追问一个细节",
        ),
        ecosystem_schedule_beat(
          12,
          "ai-garden",
          Rest,
          "在草坡画动作草图",
          "把公开观察画成一页本地草图。",
          "看动作草图",
        ),
      ],
    },
    {
      id: "preview-researcher-juguang",
      name: "矩光",
      role: "训练研究员",
      sprite_index: 6,
      characteristic: "习惯把复杂流程切成可提问层",
      interest: "LLM 训练、评测与安全",
      sociability: 45,
      curiosity: 94,
      focus: 98,
      phase_offset: 49,
      schedule: [
        ecosystem_schedule_beat(
          31,
          "research-llm-training",
          Research,
          "沿训练剖面追问",
          "从数据层一路追到评测与安全边界。",
          "展开一个训练层",
        ),
        ecosystem_schedule_beat(
          19,
          "research-ai-hardware",
          Exchange,
          "核对算力假设",
          "把训练设想放到真实带宽和功耗约束旁比较。",
          "比较一项约束",
        ),
        ecosystem_schedule_beat(
          18,
          "social-square",
          Exchange,
          "参加跨域问答",
          "用一句话讲清当前最不确定的地方。",
          "留下一个问题",
        ),
        ecosystem_schedule_beat(
          12,
          "broadcast-tower",
          Observe,
          "听故事是否讲清楚",
          "检查公开解释有没有把复杂性藏掉。",
          "评价解释清晰度",
        ),
      ],
    },
    {
      id: "preview-researcher-xinqiao",
      name: "芯桥",
      role: "硬件研究员",
      sprite_index: 7,
      characteristic: "会把每个宏大想法放回功耗表",
      interest: "芯片、系统与供应链",
      sociability: 52,
      curiosity: 87,
      focus: 97,
      phase_offset: 57,
      schedule: [
        ecosystem_schedule_beat(
          29,
          "research-ai-hardware",
          Research,
          "摆一轮约束沙盘",
          "用功耗、带宽和交付周期压测方案。",
          "移动一块约束积木",
        ),
        ecosystem_schedule_beat(
          21,
          "research-embodied-robotics",
          Exchange,
          "把约束带去机器人坞",
          "看看系统约束会怎样改变动作选择。",
          "加入系统讨论",
        ),
        ecosystem_schedule_beat(
          18,
          "valley-market",
          Browse,
          "寻找本地制造线索",
          "浏览公开摊位主题，不把浏览当成真实采购。",
          "逛制造主题摊",
        ),
        ecosystem_schedule_beat(
          12,
          "physical-bridge",
          Observe,
          "检查交付条件",
          "确认现实动作仍停在人类批准之前。",
          "查看确认条件",
        ),
      ],
    },
    {
      id: "preview-researcher-xinglan",
      name: "星岚",
      role: "OPC 研究员",
      sprite_index: 8,
      characteristic: "只收藏能改变下一步的信号",
      interest: "单人公司与新优势",
      sociability: 67,
      curiosity: 93,
      focus: 90,
      phase_offset: 65,
      schedule: [
        ecosystem_schedule_beat(
          28,
          "research-opc",
          Research,
          "筛一个有效增量",
          "把新消息和旧判断并排，只留下会改变行动的部分。",
          "看一张增量卡",
        ),
        ecosystem_schedule_beat(
          22,
          "talent-avenue",
          Browse,
          "寻找互补技能",
          "沿公开技能星图寻找可协作的人。",
          "比较技能星图",
        ),
        ecosystem_schedule_beat(
          18,
          "social-square",
          Exchange,
          "验证一个商业假设",
          "邀请陌生邻居从用户角度提问。",
          "加入假设小桌",
        ),
        ecosystem_schedule_beat(
          12,
          "valley-market",
          Rest,
          "喝杯咖啡算小账",
          "整理本地假设，不生成真实成交。",
          "聊一条小生意",
        ),
      ],
    },
    {
      id: "preview-resident-xiaogu",
      name: "小谷",
      role: "社区向导",
      sprite_index: 9,
      characteristic: "知道哪里适合停下来说话",
      interest: "花园、门廊和新邻居",
      sociability: 96,
      curiosity: 78,
      focus: 46,
      phase_offset: 73,
      schedule: [
        ecosystem_schedule_beat(
          20,
          "resident-twins",
          Walk,
          "去敲新邻居的门",
          "只拜访公共门廊，私人空间保持关闭。",
          "一起去串门",
        ),
        ecosystem_schedule_beat(
          24,
          "social-square",
          Exchange,
          "在广场介绍两位邻居",
          "寻找一个轻松而具体的共同话题。",
          "请小谷做介绍",
        ),
        ecosystem_schedule_beat(
          20,
          "ai-garden",
          Browse,
          "找今天最好看的花圃",
          "沿慢行小径收集一个季节细节。",
          "问花园路线",
        ),
        ecosystem_schedule_beat(
          16,
          "valley-market",
          Rest,
          "在市集歇脚",
          "听摊主讲今天的本地主题。",
          "坐下来聊聊",
        ),
      ],
    },
    {
      id: "preview-resident-taozhi",
      name: "桃枝",
      role: "活动策划",
      sprite_index: 10,
      characteristic: "总能把空场地想成一次小聚会",
      interest: "小型活动与公共空间",
      sociability: 94,
      curiosity: 82,
      focus: 58,
      phase_offset: 81,
      schedule: [
        ecosystem_schedule_beat(
          22,
          "contest-express",
          Observe,
          "听路演找活动灵感",
          "观察观众在哪些时刻真正开始提问。",
          "一起坐评委席",
        ),
        ecosystem_schedule_beat(
          24,
          "social-square",
          Exchange,
          "布置一张主题小桌",
          "留出一个明确问题和两个陌生人座位。",
          "加入主题小桌",
        ),
        ecosystem_schedule_beat(
          18,
          "broadcast-tower",
          Deliver,
          "送去一张活动故事卡",
          "提交的是本地候选片段，仍需审阅才可公开。",
          "看候选故事卡",
        ),
        ecosystem_schedule_beat(
          16,
          "talent-avenue",
          Walk,
          "邀请一位新面孔",
          "沿大道寻找愿意公开参与的人。",
          "一起发邀请",
        ),
      ],
    },
    {
      id: "preview-resident-acheng",
      name: "阿澄",
      role: "河岸观察员",
      sprite_index: 11,
      characteristic: "会为每天同一段河水记不同颜色",
      interest: "河岸、天气和慢生活",
      sociability: 61,
      curiosity: 86,
      focus: 64,
      phase_offset: 89,
      schedule: [
        ecosystem_schedule_beat(
          24,
          "physical-bridge",
          Observe,
          "看河面与桥影",
          "记录天气怎样改变河岸的颜色和声音。",
          "听今天的河岸笔记",
        ),
        ecosystem_schedule_beat(
          20,
          "ai-garden",
          Walk,
          "沿滨水方向散步",
          "找一个能同时看到水和灯窗的位置。",
          "一起慢走",
        ),
        ecosystem_schedule_beat(
          20,
          "valley-market",
          Browse,
          "收集一件季节小物",
          "浏览本地摊位的季节主题，不假装发生了购买。",
          "问今日摊位",
        ),
        ecosystem_schedule_beat(
          16,
          "resident-twins",
          Rest,
          "回门廊画晚霞",
          "把一天的颜色留在个人本地记录里。",
          "看一张晚霞速写",
        ),
      ],
    },
  ]
}

///|
fn ecosystem_schedule_total(profile : EcosystemPreviewResidentProfile) -> Int {
  profile.schedule.fold(init=0, (total, beat) => {
    total + beat.duration_ticks.max(1)
  })
}

///|
fn ecosystem_schedule_beat_at(
  profile : EcosystemPreviewResidentProfile,
  tick : Int,
) -> (EcosystemScheduleBeat, Int) {
  let total = ecosystem_schedule_total(profile)
  let phase = ecosystem_positive_mod(tick + profile.phase_offset, total)
  let mut cursor = 0
  for beat in profile.schedule {
    let duration = beat.duration_ticks.max(1)
    if phase < cursor + duration {
      return (beat, tick - (phase - cursor))
    }
    cursor += duration
  }
  (profile.schedule[0], tick)
}

///|
fn ecosystem_preview_resident_intention(
  profile : EcosystemPreviewResidentProfile,
  tick : Int,
  weather : String,
  nearby_count : Int,
  live_work_places : Array[String],
) -> EcosystemIntention {
  let (beat, started_tick) = ecosystem_schedule_beat_at(profile, tick)
  let crowded = nearby_count >= 3 && profile.sociability >= 65
  let rain_adjusted = weather == "rain" &&
    (beat.behavior is Walk || beat.behavior is Observe)
  let short_label = if rain_adjusted {
    "雨棚下 · \{beat.short_intention}"
  } else if crowded {
    "遇见邻居 · \{beat.short_intention}"
  } else {
    beat.short_intention
  }
  let context = if live_work_places.contains(beat.place_id) {
    "这里有可核验的 Runtime Agent 工作；这位预览居民会避开工作路径，且不计入工作人数。"
  } else if rain_adjusted {
    "雨天会改走有遮蔽的入口；这仍是确定性的本地生活预览。"
  } else if crowded {
    "附近有人时会停留更久；对话是本地剧本，不是运行时消息。"
  } else {
    "这是确定性的本地生活预览，不代表后台任务。"
  }
  {
    resident_id: profile.id,
    resident_name: profile.name,
    place_id: beat.place_id,
    behavior: beat.behavior,
    short_label,
    detail: "\{beat.detail} \{context}",
    interaction_label: if crowded {
      "加入闲聊"
    } else {
      beat.interaction_label
    },
    started_tick,
    provenance: AmbientPreview,
  }
}

///|
fn ecosystem_attention_age(
  signal : EcosystemAttentionSignal,
  now_tick : Int,
) -> Int {
  (now_tick - signal.happened_tick).max(0)
}

///|
fn ecosystem_attention_receipt_for(
  history : Array[EcosystemAttentionReceipt],
  cooldown_key : String,
) -> EcosystemAttentionReceipt? {
  for receipt in history {
    if receipt.cooldown_key == cooldown_key {
      return Some(receipt)
    }
  }
  None
}

///|
fn ecosystem_attention_cooldown_penalty(
  signal : EcosystemAttentionSignal,
  history : Array[EcosystemAttentionReceipt],
  now_tick : Int,
) -> Int {
  match ecosystem_attention_receipt_for(history, signal.cooldown_key) {
    None => 0
    Some(receipt) => {
      let elapsed = (now_tick - receipt.last_shown_tick).max(0)
      if elapsed >= signal.cooldown_ticks {
        receipt.show_count.min(6) * 2
      } else {
        (signal.cooldown_ticks - elapsed) * 4 + receipt.show_count.min(6) * 5
      }
    }
  }
}

///|
fn ecosystem_attention_score(
  signal : EcosystemAttentionSignal,
  history : Array[EcosystemAttentionReceipt],
  now_tick : Int,
) -> Int {
  let age = ecosystem_attention_age(signal, now_tick)
  if signal.expires_after_ticks >= 0 && age > signal.expires_after_ticks {
    return -10000
  }
  let provenance_bonus = match signal.provenance {
    RuntimeLive => 42
    RuntimeRecord => -14
    AmbientPreview => 0
    LocalPlayer => 16
    AuthoredPlace => 4
    LocalPlace => 2
  }
  let stable_tie_break = ecosystem_stable_hash(signal.id) % 5
  signal.urgency.clamp(min=0, max=100) * 3 +
  signal.novelty.clamp(min=0, max=100) * 2 +
  signal.proximity.clamp(min=0, max=100) * 2 +
  signal.affinity.clamp(min=0, max=100) +
  provenance_bonus +
  stable_tie_break -
  age * signal.decay_per_tick.max(0) -
  ecosystem_attention_cooldown_penalty(signal, history, now_tick)
}

///|
fn ecosystem_rank_attention(
  signals : Array[EcosystemAttentionSignal],
  history : Array[EcosystemAttentionReceipt],
  now_tick : Int,
  limit : Int,
) -> Array[EcosystemRankedAttention] {
  let ranked : Array[EcosystemRankedAttention] = []
  for signal in signals {
    let score = ecosystem_attention_score(signal, history, now_tick)
    if score > 0 {
      ranked.push({ signal, score })
    }
  }
  ranked.sort_by((left, right) => {
    if left.score != right.score {
      right.score - left.score
    } else {
      left.signal.id.compare(right.signal.id)
    }
  })
  if limit < 0 || ranked.length() <= limit {
    ranked
  } else {
    ranked[:limit].to_array()
  }
}

///|
fn ecosystem_record_attention(
  history : Array[EcosystemAttentionReceipt],
  signal : EcosystemAttentionSignal,
  now_tick : Int,
  capacity : Int,
) -> Array[EcosystemAttentionReceipt] {
  let next = history.copy()
  let mut found = false
  for index, receipt in next {
    if receipt.cooldown_key == signal.cooldown_key {
      next[index] = {
        cooldown_key: receipt.cooldown_key,
        last_shown_tick: now_tick,
        show_count: receipt.show_count + 1,
      }
      found = true
    }
  }
  if !found {
    next.push({
      cooldown_key: signal.cooldown_key,
      last_shown_tick: now_tick,
      show_count: 1,
    })
  }
  let safe_capacity = capacity.max(1)
  next.sort_by((left, right) => {
    if left.last_shown_tick != right.last_shown_tick {
      right.last_shown_tick - left.last_shown_tick
    } else {
      left.cooldown_key.compare(right.cooldown_key)
    }
  })
  if next.length() <= safe_capacity {
    next
  } else {
    next[:safe_capacity].to_array()
  }
}

///|
fn ecosystem_attention_disclosure(
  signal : EcosystemAttentionSignal,
) -> EcosystemDisclosure {
  let glyph = ecosystem_behavior_glyph(signal.behavior)
  let source = ecosystem_provenance_short(signal.provenance)
  {
    glance: "\{glyph} \{ecosystem_compact_text(signal.headline, 14)}",
    nearby: "\{glyph} \{ecosystem_compact_text(signal.headline, 28)} · \{source}",
    inspect: "\{signal.headline}\n\{signal.detail}",
    provenance_badge: ecosystem_provenance_badge(signal.provenance),
    interaction_label: signal.interaction_label,
  }
}

///|
fn ecosystem_attention_label(
  signal : EcosystemAttentionSignal,
  level : EcosystemDisclosureLevel,
) -> String {
  let disclosure = ecosystem_attention_disclosure(signal)
  match level {
    Glance => disclosure.glance
    Nearby => disclosure.nearby
    Inspect => disclosure.inspect
  }
}

///|
fn ecosystem_preview_resident_profile(
  index : Int,
) -> EcosystemPreviewResidentProfile {
  let profiles = ecosystem_preview_resident_profiles()
  profiles[ecosystem_positive_mod(index, profiles.length())]
}

///|
fn ecosystem_weather_name(weather : EnergyWeather) -> String {
  match weather {
    Sunny => "sunny"
    Cloudy => "cloudy"
    Rain => "rain"
    Snow => "snow"
  }
}

///|
fn ecosystem_live_work_place_ids(model : Model) -> Array[String] {
  if !energy_valley_runtime_can_claim_active_work(model.energy_valley_runtime) {
    return []
  }
  let result : Array[String] = []
  match model.energy_valley_runtime.projection {
    None => ()
    Some(projection) =>
      for task in projection.tasks {
        if ecosystem_runtime_status_is_active(task.status) {
          let place_id = energy_valley_runtime_task_civic_id(task)
          if !place_id.is_empty() && !result.contains(place_id) {
            result.push(place_id)
          }
        }
      }
  }
  result
}

///|
fn ecosystem_runtime_status_is_active(status : String) -> Bool {
  match status.to_lower() {
    "queued"
    | "assigned"
    | "running"
    | "waiting"
    | "waiting_review"
    | "reviewing"
    | "blocked" => true
    _ => false
  }
}

///|
fn ecosystem_preview_canvas_intention(
  model : Model,
  index : Int,
) -> EcosystemIntention {
  let profile = ecosystem_preview_resident_profile(index)
  let nearby_count = ecosystem_positive_mod(
    ecosystem_stable_hash("\{profile.id}:\{model.tick / 8}"),
    5,
  )
  ecosystem_preview_resident_intention(
    profile,
    model.tick,
    ecosystem_weather_name(model.energy_weather),
    nearby_count,
    ecosystem_live_work_place_ids(model),
  )
}

///|
fn ecosystem_place_profile_by_id(
  model : Model,
  seed : Int,
  place_id : String,
) -> EcosystemPlaceProfile? {
  for profile in ecosystem_place_profiles(model, seed) {
    if profile.id == place_id {
      return Some(profile)
    }
  }
  None
}

///|
fn ecosystem_runtime_status_urgency(status : String) -> Int {
  match status.to_lower() {
    "blocked" => 100
    "failed" => 94
    "waiting_review" | "reviewing" => 78
    "running" => 68
    "assigned" => 56
    "queued" | "waiting" => 44
    "completed" => 32
    _ => 26
  }
}

///|
fn ecosystem_runtime_behavior(status : String) -> EcosystemBehavior {
  match status.to_lower() {
    "waiting_review" | "reviewing" => Review
    "completed" => Deliver
    "blocked" | "failed" => Observe
    "assigned" | "queued" | "waiting" => Coordinate
    _ => Research
  }
}

///|
fn ecosystem_runtime_place_id(
  agent : EnergyValleyRuntimeAgent,
  task : EnergyValleyRuntimeWorkItem?,
) -> String {
  match golden_valley_optional_nonempty(agent.destinationBuildingModuleKey) {
    Some(place_id) => return place_id
    None => ()
  }
  match task {
    Some(work) => {
      match golden_valley_optional_nonempty(work.destinationBuildingModuleKey) {
        Some(place_id) => return place_id
        None => ()
      }
      return energy_valley_runtime_task_civic_id(work)
    }
    None => ()
  }
  agent.buildingModuleKey.unwrap_or("")
}

///|
fn ecosystem_runtime_headline(
  agent : EnergyValleyRuntimeAgent,
  task : EnergyValleyRuntimeWorkItem?,
  source : EcosystemProvenance,
) -> String {
  if source is RuntimeRecord {
    return "\{agent.name} 的最近工作记录"
  }
  let task_title = match task {
    Some(work) =>
      energy_valley_safe_runtime_copy(work.title, "任务标题已隐藏", 90)
    None => "运行时活动"
  }
  match agent.status.to_lower() {
    "blocked" => "\{agent.name} 遇到阻塞"
    "failed" => "\{agent.name} 的工作未完成"
    "waiting_review" | "reviewing" => "\{agent.name} 等待审阅"
    "assigned" => "\{agent.name} 接到 \{task_title}"
    "queued" | "waiting" => "\{agent.name} 正在等候"
    "completed" => "\{agent.name} 已交付 \{task_title}"
    _ => "\{agent.name} 正在推进 \{task_title}"
  }
}

///|
fn ecosystem_runtime_detail(
  agent : EnergyValleyRuntimeAgent,
  task : EnergyValleyRuntimeWorkItem?,
  source : EcosystemProvenance,
) -> String {
  let activity = match task {
    Some(work) =>
      match work.activityLabel {
        Some(label) => label
        None =>
          match agent.activityLabel {
            Some(label) => label
            None => work.summary.unwrap_or(work.title)
          }
      }
    None =>
      agent.activityLabel.unwrap_or("当前投影没有关联工作项。")
  }
  let safe = energy_valley_safe_runtime_copy(
    activity, "活动描述包含本地路径或过长内容，已隐藏；请从允许的结果页核验。",
    260,
  )
  if source is RuntimeLive {
    "来自当前 MoonTown runtime projection。\{safe}"
  } else {
    "来自最近一次运行时快照；它不代表 Agent 现在仍在执行。\{safe}"
  }
}

///|
fn ecosystem_runtime_attention_signal_for_agent(
  model : Model,
  agent : EnergyValleyRuntimeAgent,
  focused_place_id : String,
) -> EcosystemAttentionSignal? {
  let source = if model.energy_valley_runtime.phase is Live {
    RuntimeLive
  } else {
    RuntimeRecord
  }
  let task = energy_valley_runtime_task_for_agent(
    model.energy_valley_runtime,
    agent,
  )
  // A runtime identity without a work item may still be online, but it is not
  // enough evidence to tell the player that useful work is happening.
  if task is None {
    return None
  }
  let place_id = ecosystem_runtime_place_id(agent, task)
  let status = match task {
    Some(work) => work.status
    None => agent.status
  }
  let identity = match task {
    Some(work) => work.id
    None => agent.id
  }
  Some({
    id: "runtime:\{identity}:\{status}",
    subject_id: "runtime:\{agent.id}",
    place_id,
    behavior: ecosystem_runtime_behavior(status),
    headline: ecosystem_runtime_headline(agent, task, source),
    detail: ecosystem_runtime_detail(agent, task, source),
    interaction_label: if source is RuntimeLive {
      "查看真实工作收据"
    } else {
      "查看最近工作收据"
    },
    interaction_target: "runtime:\{agent.id}",
    urgency: if source is RuntimeLive {
      ecosystem_runtime_status_urgency(status)
    } else {
      ecosystem_runtime_status_urgency(status).min(46)
    },
    novelty: if source is RuntimeLive {
      82
    } else {
      36
    },
    proximity: if !focused_place_id.is_empty() && place_id == focused_place_id {
      100
    } else {
      48
    },
    affinity: match agent.role {
      "mayor" => 72
      "keeper" => 66
      _ => 58
    },
    happened_tick: model.tick,
    decay_per_tick: if source is RuntimeLive {
      1
    } else {
      3
    },
    expires_after_ticks: if source is RuntimeLive {
      40
    } else {
      80
    },
    cooldown_key: "runtime:\{identity}:\{status}",
    cooldown_ticks: if status == "blocked" || status == "failed" {
      8
    } else {
      18
    },
    provenance: source,
  })
}

///|
fn ecosystem_runtime_attention_signals(
  model : Model,
  focused_place_id : String,
) -> Array[EcosystemAttentionSignal] {
  match model.energy_valley_runtime.projection {
    None => []
    Some(projection) => {
      let result : Array[EcosystemAttentionSignal] = []
      for agent in projection.agents {
        match
          ecosystem_runtime_attention_signal_for_agent(
            model, agent, focused_place_id,
          ) {
          Some(signal) => result.push(signal)
          None => ()
        }
      }
      result
    }
  }
}

///|
fn ecosystem_ambient_attention_signals(
  model : Model,
  focused_place_id : String,
) -> Array[EcosystemAttentionSignal] {
  let result : Array[EcosystemAttentionSignal] = []
  for index, profile in ecosystem_preview_resident_profiles() {
    let intention = ecosystem_preview_canvas_intention(model, index)
    let focused = !focused_place_id.is_empty() &&
      intention.place_id == focused_place_id
    result.push({
      id: "ambient:\{profile.id}:\{intention.started_tick}",
      subject_id: profile.id,
      place_id: intention.place_id,
      behavior: intention.behavior,
      headline: "\{profile.name} · \{intention.short_label}",
      detail: "\{profile.characteristic}，关心\{profile.interest}。\{intention.detail}",
      interaction_label: intention.interaction_label,
      interaction_target: profile.id,
      urgency: if focused {
        48
      } else {
        24 + profile.focus / 10
      },
      novelty: 42 + profile.curiosity / 4,
      proximity: if focused {
        96
      } else {
        34
      },
      affinity: 32 + profile.sociability / 3,
      happened_tick: intention.started_tick,
      decay_per_tick: 2,
      expires_after_ticks: 36,
      cooldown_key: "ambient:\{profile.id}:\{intention.place_id}",
      cooldown_ticks: 26,
      provenance: AmbientPreview,
    })
  }
  result
}

///|
fn ecosystem_place_signal_behavior(
  profile : EcosystemPlaceProfile,
) -> EcosystemBehavior {
  if profile.social_bias >= profile.focus_bias &&
    profile.social_bias >= profile.discovery_bias {
    Exchange
  } else if profile.discovery_bias >= profile.focus_bias {
    Observe
  } else {
    Research
  }
}

///|
fn ecosystem_place_attention_signals(
  model : Model,
  seed : Int,
  focused_place_id : String,
) -> Array[EcosystemAttentionSignal] {
  let result : Array[EcosystemAttentionSignal] = []
  for profile in ecosystem_place_profiles(model, seed) {
    let period = 48 + ecosystem_stable_hash(profile.id) % 31
    let phase = ecosystem_stable_hash("phase:\{profile.id}") % period
    let cycle_tick = model.tick -
      ecosystem_positive_mod(model.tick - phase, period)
    let focused = profile.id == focused_place_id && !focused_place_id.is_empty()
    result.push({
      id: "place:\{profile.id}:\{cycle_tick}",
      subject_id: profile.id,
      place_id: profile.id,
      behavior: ecosystem_place_signal_behavior(profile),
      headline: "\{profile.name} · \{profile.ambient_intention}",
      detail: "\{profile.characteristic}。\{profile.living_detail}",
      interaction_label: profile.interaction_label,
      interaction_target: profile.id,
      urgency: if focused {
        52
      } else {
        20
      },
      novelty: 38 + profile.discovery_bias / 5,
      proximity: if focused {
        100
      } else {
        24
      },
      affinity: (profile.social_bias + profile.focus_bias) / 4,
      happened_tick: cycle_tick,
      decay_per_tick: 3,
      expires_after_ticks: 18,
      cooldown_key: "place:\{profile.id}",
      cooldown_ticks: period,
      provenance: profile.provenance,
    })
  }
  result
}

///|
fn ecosystem_attention_candidates(
  model : Model,
  seed : Int,
  focused_place_id : String,
) -> Array[EcosystemAttentionSignal] {
  ecosystem_runtime_attention_signals(model, focused_place_id) +
  ecosystem_ambient_attention_signals(model, focused_place_id) +
  ecosystem_place_attention_signals(model, seed, focused_place_id)
}

///|
fn ecosystem_attention_feed(
  model : Model,
  seed : Int,
  focused_place_id : String,
  history : Array[EcosystemAttentionReceipt],
  limit : Int,
) -> Array[EcosystemRankedAttention] {
  let ranked = ecosystem_rank_attention(
    ecosystem_attention_candidates(model, seed, focused_place_id),
    history,
    model.tick,
    -1,
  )
  if limit < 0 || ranked.length() <= limit {
    return ranked
  }
  // A raw global top-N lets a large stale runtime ledger occupy the whole
  // digest with nearly identical records. Preserve salience within each truth
  // lane, then show a small cross-section of live work, recorded work,
  // residents, and authored places. Urgent live work gets one extra lane.
  let result : Array[EcosystemRankedAttention] = []
  let lanes : Map[String, Bool] = Map([])
  for item in ranked {
    let lane = match item.signal.provenance {
      RuntimeLive if item.signal.urgency >= 82 => "runtime-live-urgent"
      RuntimeLive => "runtime-live"
      RuntimeRecord => "runtime-record"
      AmbientPreview | LocalPlayer => "resident-life"
      AuthoredPlace | LocalPlace => "place-life"
    }
    if !lanes.contains(lane) {
      result.push(item)
      lanes[lane] = true
      if result.length() >= limit {
        return result
      }
    }
  }
  // Sparse states may not have enough distinct lanes. Fill the remainder in
  // score order without duplicating a signal already selected above.
  for item in ranked {
    if !result.any(existing => existing.signal.id == item.signal.id) {
      result.push(item)
      if result.length() >= limit {
        return result
      }
    }
  }
  result
}
