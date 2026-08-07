///|
/// New-resident quest chain: seven steps that teach the whole game loop
/// (create → move → visit → chat → build → publish → collect) with spark
/// rewards ("谷光值") and title progression. The chain is the retention
/// backbone: it always gives the player one obvious next thing to do.
priv struct QuestDef {
  id : String
  title : String
  hint : String
  spark_reward : Int
}

///|
fn town_quest_chain() -> Array[QuestDef] {
  [
    {
      id: "create-avatar",
      title: "创建你的角色",
      hint: "给自己起个名字，选一种气质，正式入住能源谷",
      spark_reward: 50,
    },
    {
      id: "first-walk",
      title: "在镇上走一段路",
      hint: "点底部「行走」后点地图，或用 WASD / 方向键直接移动",
      spark_reward: 30,
    },
    {
      id: "visit-building",
      title: "视察一栋大楼",
      hint: "用视察工具点任意一栋楼，看看里面在做什么",
      spark_reward: 30,
    },
    {
      id: "first-chat",
      title: "给一位居民发条消息",
      hint: "点右下角手机，挑一位居民打个招呼",
      spark_reward: 40,
    },
    {
      id: "build-knowledge",
      title: "建造一栋知识大楼",
      hint: "底部工具坞选研发塔楼/实验室/创新工坊，找块空地放下",
      spark_reward: 60,
    },
    {
      id: "publish-knowledge",
      title: "生成一次知识分享",
      hint: "在「广场」把自己的大楼标记为可分享，生成普通网页链接",
      spark_reward: 60,
    },
    {
      id: "collect-building",
      title: "收藏一座别人的知识楼",
      hint: "在「广场」挑一座喜欢的大楼，收进自己的小镇",
      spark_reward: 40,
    },
  ]
}

///|
fn quest_completed(model : Model, id : String) -> Bool {
  model.quest_done.contains(id)
}

///|
fn current_quest(model : Model) -> QuestDef? {
  for quest in town_quest_chain() {
    if !quest_completed(model, quest.id) {
      return Some(quest)
    }
  }
  None
}

///|
/// A quest is available only after every earlier step in the authored chain
/// has completed. Event handlers may still fire out of order (for example an
/// experienced user can open the phone immediately), but they no longer skip
/// onboarding milestones or award later rewards prematurely.
fn quest_unlocked(model : Model, id : String) -> Bool {
  for quest in town_quest_chain() {
    if quest.id == id {
      return true
    }
    if !quest_completed(model, quest.id) {
      return false
    }
  }
  false
}

///|
fn quest_progress_count(model : Model) -> Int {
  let mut count = 0
  for quest in town_quest_chain() {
    if !quest_completed(model, quest.id) {
      break
    }
    count += 1
  }
  count
}

///|
fn player_title_for(spark : Int) -> String {
  if spark >= 400 {
    "能源谷合伙人"
  } else if spark >= 250 {
    "谷光建造者"
  } else if spark >= 120 {
    "正式谷民"
  } else {
    "新居民"
  }
}

///|
/// Complete a quest once: award spark, raise a celebratory toast, and track
/// the analytics event. Safe to call unconditionally — it no-ops when the
/// quest is already done or unknown.
fn complete_quest(model : Model, id : String) -> Model {
  if quest_completed(model, id) || !quest_unlocked(model, id) {
    return model
  }
  for quest in town_quest_chain() {
    if quest.id == id {
      let rewarded = town_life_add_spark_award(
        model,
        "quest:\{quest.id}",
        quest.spark_reward,
      )
      let quest_done = rewarded.quest_done
      quest_done.push(id)
      let next = {
        ..rewarded,
        quest_done,
        life_toast: "✅ 任务完成「\{quest.title}」 +\{quest.spark_reward} 谷光值",
        life_toast_tick: model.tick,
      }
      return track_event(next, "quest_complete", id)
    }
  }
  model
}

///|
/// Combine quest completion with an optional extra toast suffix.
fn complete_quest_with_note(model : Model, id : String, note : String) -> Model {
  let next = complete_quest(model, id)
  if note.is_empty() {
    next
  } else if quest_completed(model, id) {
    { ..next, life_toast: next.life_toast + " · " + note }
  } else {
    next
  }
}
