///|
fn test_player_avatar() -> PlayerAvatar {
  {
    name: "测试居民",
    persona: "researcher",
    color: 0,
    sprite_index: 0,
    title: "新居民",
  }
}

///|
fn town_life_persistence_test_post(
  id : String,
  topic : String,
  published : Bool,
  collected : Bool,
) -> KnowledgePost {
  {
    id,
    building_id: None,
    incarnation_id: None,
    created_stamp: None,
    updated_stamp: None,
    reset_epoch: None,
    building_name: "验收实验室",
    topic,
    author: "验收员",
    spark: if published {
      32
    } else {
      12
    },
    published,
    collected,
    mine: true,
  }
}

///|
fn town_life_persistence_test_save(
  spark : Int,
  quest_done : Array[String],
  phone_log : Array[PhoneMessage],
  posts : Array[KnowledgePost],
  analytics : Array[String],
  receipts : Array[EcosystemAttentionReceipt],
  reports : Array[String],
  post_generation : Int,
) -> TownLifeSave {
  {
    player: Some({
      name: "验收员",
      persona: "researcher",
      color: 3,
      sprite_index: 3,
      title: player_title_for(spark),
    }),
    player_position: Some({ x: 81.5, y: 63.5 }),
    player_stamp: None,
    player_position_stamp: None,
    writer_counters: Some([]),
    spark,
    spark_floor: Some(spark),
    spark_awards: Some([]),
    quest_done,
    phone_log,
    phone_events: None,
    phone_prune_watermarks: None,
    posts,
    post_reset_stamp: None,
    post_tombstones: None,
    analytics,
    analytics_events: None,
    analytics_prune_watermarks: None,
    ecosystem_attention_receipts: Some(receipts),
    attention_counters: None,
    attention_prune_watermarks: None,
    ops_reports: Some(reports),
    ops_report_events: None,
    ops_report_prune_watermarks: None,
    last_report_tick: 888,
    checkin_day: 1,
    world_states: None,
    post_generation: Some(post_generation),
    deleted_post_ids: Some([]),
  }
}

///|
fn town_life_test_text_event(
  id : String,
  writer_id : String,
  sequence : Int,
  value : String,
) -> TownLifeTextEvent {
  let dot : TownLifeDot = { writer_id, sequence }
  {
    id,
    dot,
    observed_dots: Some([dot]),
    stamp: { writer_id, lamport: sequence },
    value,
  }
}

///|
fn town_life_test_map_post(
  id : String,
  building_id : String,
  incarnation_id : String,
  reset_epoch : TownLifeCausalStamp?,
  updated : TownLifeCausalStamp,
) -> KnowledgePost {
  {
    id,
    building_id: Some(building_id),
    incarnation_id: Some(incarnation_id),
    created_stamp: Some({ writer_id: "origin", lamport: 1 }),
    updated_stamp: Some(updated),
    reset_epoch,
    building_name: "同名实验室",
    topic: "主题",
    author: "验收员",
    spark: 12,
    published: false,
    collected: false,
    mine: true,
  }
}

///|
test "town life reconciliation rejects an avatar-only stale writer" {
  let completed_quests = town_quest_chain().map(quest => quest.id)
  let completed = town_life_persistence_test_save(
    310,
    completed_quests,
    [{ contact: "mayor", from_me: true, text: "验收完成", tick: 60 }],
    [
      town_life_persistence_test_post(
        "mine-验收实验室", "多智能体协作验收", true, false,
      ),
    ],
    ["1|knowledge_publish|验收实验室"],
    [{ cooldown_key: "place:lab", last_shown_tick: 60, show_count: 2 }],
    ["第1天 · 完成验收"],
    4,
  )
  let stale = town_life_persistence_test_save(
    50,
    ["create-avatar"],
    [
      {
        contact: "mayor",
        from_me: false,
        text: "广场有新动态，快来看看！",
        tick: 720,
      },
    ],
    [town_life_persistence_test_post("mine-验收实验室", "", false, false)],
    ["1|phone_receive|mayor"],
    [{ cooldown_key: "place:metro", last_shown_tick: 720, show_count: 1 }],
    ["第2天 · 自动运营快照"],
    4,
  )
  let merged = town_life_reconcile_save(completed, stale)
  assert_eq(merged.quest_done, completed_quests)
  assert_eq(merged.spark, 310)
  assert_eq(merged.phone_log.length(), 2)
  assert_true(merged.phone_log.any(message => message.tick == 720))
  assert_true(merged.analytics.contains("1|knowledge_publish|验收实验室"))
  assert_true(merged.analytics.contains("1|phone_receive|mayor"))
  assert_true(
    merged.ops_reports.unwrap_or([]).contains("第2天 · 自动运营快照"),
  )
  assert_true(
    merged.ecosystem_attention_receipts
    .unwrap_or([])
    .any(receipt => receipt.cooldown_key == "place:metro"),
  )
  assert_eq(merged.posts.length(), 1)
  assert_eq(merged.posts[0].topic, "多智能体协作验收")
  assert_true(merged.posts[0].published)
}

///|
test "migration fence permanently rejects later v1 state" {
  let completed = town_life_persistence_test_save(
    310,
    town_quest_chain().map(quest => quest.id),
    [],
    [],
    [],
    [],
    [],
    0,
  )
  let legacy = {
    ..completed,
    spark_floor: None,
    spark_awards: None,
    post_generation: None,
    deleted_post_ids: None,
  }
  let migrated = town_life_migration_fallback(false, Some(legacy))
  assert_eq(migrated.spark, 310)
  assert_eq(migrated.spark_floor, Some(310))
  assert_true(migrated.spark_awards.unwrap_or([]).is_empty())
  assert_eq(migrated.quest_done, completed.quest_done)
  let fenced = town_life_migration_fallback(true, Some(legacy))
  assert_eq(fenced.spark, 0)
  assert_true(fenced.player is None)
  assert_true(fenced.quest_done.is_empty())
}

///|
test "exact incarnation tombstones converge for concurrent disjoint deletes" {
  let reset : TownLifeCausalStamp = { writer_id: "root", lamport: 7 }
  let created : TownLifeCausalStamp = { writer_id: "root", lamport: 8 }
  let first = {
    ..town_life_persistence_test_post("mine-first", "第一主题", true, false),
    building_id: Some("site-first"),
    incarnation_id: Some("inc-first"),
    created_stamp: Some(created),
    updated_stamp: Some(created),
    reset_epoch: Some(reset),
  }
  let second = {
    ..town_life_persistence_test_post(
      "mine-second", "第二主题", true, false,
    ),
    building_id: Some("site-second"),
    incarnation_id: Some("inc-second"),
    created_stamp: Some(created),
    updated_stamp: Some(created),
    reset_epoch: Some(reset),
  }
  let before = {
    ..town_life_persistence_test_save(
      310,
      [],
      [],
      [first, second],
      [],
      [],
      [],
      0,
    ),
    post_reset_stamp: Some(reset),
  }
  let delete_first = {
    ..before,
    posts: [second],
    post_tombstones: Some([
      {
        post_id: first.id,
        incarnation_id: "inc-first",
        reset_epoch: Some(reset),
        dot: { writer_id: "a", sequence: 9 },
        stamp: { writer_id: "a", lamport: 9 },
      },
    ]),
  }
  let delete_second = {
    ..before,
    posts: [first],
    post_tombstones: Some([
      {
        post_id: second.id,
        incarnation_id: "inc-second",
        reset_epoch: Some(reset),
        dot: { writer_id: "b", sequence: 9 },
        stamp: { writer_id: "b", lamport: 9 },
      },
    ]),
  }
  let left = town_life_reconcile_save(delete_first, delete_second)
  let right = town_life_reconcile_save(delete_second, delete_first)
  assert_true(left.posts.is_empty())
  assert_eq(left.post_tombstones.unwrap_or([]).length(), 2)
  assert_eq(
    ToJson::to_json(left).stringify(),
    ToJson::to_json(right).stringify(),
  )
}

///|
test "spark awards merge distinct events and deduplicate one quest" {
  let base = town_life_persistence_test_save(
    50,
    ["create-avatar"],
    [],
    [],
    [],
    [],
    [],
    0,
  )
  let quest = {
    ..base,
    spark: 80,
    spark_floor: Some(50),
    spark_awards: Some([{ id: "quest:first-walk", amount: 30 }]),
    quest_done: ["create-avatar", "first-walk"],
  }
  let checkin = {
    ..base,
    spark: 70,
    spark_floor: Some(50),
    spark_awards: Some([{ id: "checkin:20260727:1", amount: 20 }]),
    analytics: ["1|checkin|"],
  }
  let distinct = town_life_reconcile_save(quest, checkin)
  assert_eq(distinct.spark, 100)
  assert_eq(distinct.spark_awards.unwrap_or([]).length(), 2)
  let duplicate = town_life_reconcile_save(quest, quest)
  assert_eq(duplicate.spark, 80)
  assert_eq(duplicate.spark_awards.unwrap_or([]).length(), 1)
}

///|
test "town life join is commutative associative and replay idempotent" {
  let base = town_life_persistence_test_save(50, [], [], [], [], [], [], 0)
  let a_event = town_life_test_text_event("a:1", "a", 1, "A")
  let b_event = town_life_test_text_event("b:1", "b", 1, "B")
  let c_event = town_life_test_text_event("c:1", "c", 1, "C")
  let a = { ..base, analytics: ["A"], analytics_events: Some([a_event]) }
  let b = { ..base, analytics: ["B"], analytics_events: Some([b_event]) }
  let c = { ..base, analytics: ["C"], analytics_events: Some([c_event]) }
  let left = town_life_reconcile_save(town_life_reconcile_save(a, b), c)
  let right = town_life_reconcile_save(a, town_life_reconcile_save(c, b))
  let reverse = town_life_reconcile_save(c, town_life_reconcile_save(b, a))
  assert_eq(
    ToJson::to_json(left).stringify(),
    ToJson::to_json(right).stringify(),
  )
  assert_eq(
    ToJson::to_json(left).stringify(),
    ToJson::to_json(reverse).stringify(),
  )
  assert_eq(
    ToJson::to_json(left).stringify(),
    ToJson::to_json(town_life_reconcile_save(left, left)).stringify(),
  )
  assert_eq(left.analytics, ["A", "B", "C"])
}

///|
test "semantic event aliases stay pruned when a losing shard replays" {
  let a = town_life_test_text_event(
    "scheduled-report:20260727:1", "a", 1, "第1天运营报告",
  )
  let b = town_life_test_text_event(
    "scheduled-report:20260727:1", "b", 1, "第1天运营报告",
  )
  let (deduped, first_watermarks) = town_life_merge_text_event_state(
    [a],
    [],
    [b],
    [],
    2,
  )
  assert_eq(deduped.length(), 1)
  assert_eq(town_life_text_event_dots(deduped[0]).length(), 2)
  let newer = [
    town_life_test_text_event("c:2", "c", 2, "C"),
    town_life_test_text_event("d:3", "d", 3, "D"),
  ]
  let (bounded, watermarks) = town_life_merge_text_event_state(
    deduped,
    first_watermarks,
    newer,
    [],
    2,
  )
  assert_true(!bounded.any(event => event.id == a.id))
  assert_eq(town_life_watermark_for(watermarks, "a"), 1)
  assert_eq(town_life_watermark_for(watermarks, "b"), 1)
  let (replayed, _) = town_life_merge_text_event_state(
    bounded,
    watermarks,
    [b],
    [],
    2,
  )
  assert_true(!replayed.any(event => event.id == a.id))
}

///|
test "attention uses per-writer maxima and newest causal cooldown tick" {
  let old_a : TownLifeAttentionCounter = {
    writer_id: "a",
    cooldown_key: "place:lab",
    count: 2,
    last_shown_tick: 900,
    dot: { writer_id: "a", sequence: 5 },
    stamp: { writer_id: "a", lamport: 5 },
  }
  let new_a = {
    ..old_a,
    count: 3,
    last_shown_tick: 10,
    dot: { writer_id: "a", sequence: 6 },
    stamp: { writer_id: "a", lamport: 6 },
  }
  let b : TownLifeAttentionCounter = {
    writer_id: "b",
    cooldown_key: "place:lab",
    count: 4,
    last_shown_tick: 20,
    dot: { writer_id: "b", sequence: 7 },
    stamp: { writer_id: "b", lamport: 7 },
  }
  let counters = town_life_merge_attention_counters([old_a], [new_a, b])
  assert_eq(counters.length(), 2)
  let a_counter = counters.filter(counter => counter.writer_id == "a")[0]
  assert_eq(a_counter.count, 3)
  assert_eq(a_counter.last_shown_tick, 10)
  let receipt = town_life_attention_receipts(counters)[0]
  assert_eq(receipt.show_count, 7)
  assert_eq(receipt.last_shown_tick, 20)
  assert_eq(town_life_merge_attention_counters(counters, counters), counters)
}

///|
test "post mutable payload is wholly LWW including unpublished edits" {
  let reset : TownLifeCausalStamp = { writer_id: "root", lamport: 1 }
  let published = {
    ..town_life_test_map_post("mine-site-a", "site-a", "inc-a", Some(reset), {
      writer_id: "a",
      lamport: 5,
    }),
    topic: "第一版",
    spark: 32,
    published: true,
  }
  let edited = {
    ..published,
    topic: "第二版",
    spark: 12,
    published: false,
    updated_stamp: Some({ writer_id: "b", lamport: 6 }),
  }
  let left = town_life_merge_post(published, edited)
  let right = town_life_merge_post(edited, published)
  assert_eq(left.topic, "第二版")
  assert_true(!left.published)
  assert_eq(left.spark, 12)
  assert_eq(
    ToJson::to_json(left).stringify(),
    ToJson::to_json(right).stringify(),
  )
  assert_eq(
    ToJson::to_json(left).stringify(),
    ToJson::to_json(town_life_merge_post(left, published)).stringify(),
  )
}

///|
test "new reset rejects stale no-epoch map posts but keeps references" {
  let stale_map = town_life_persistence_test_post(
    "mine-stale", "旧地图楼", true, false,
  )
  let reference = {
    ..town_life_persistence_test_post(
      "community-reference", "共享资料", true, false,
    ),
    mine: false,
  }
  let stale = town_life_persistence_test_save(
    50,
    [],
    [],
    [stale_map, reference],
    [],
    [],
    [],
    0,
  )
  let reset = {
    ..town_life_persistence_test_save(50, [], [], [reference], [], [], [], 0),
    post_reset_stamp: Some({ writer_id: "reset", lamport: 10 }),
  }
  let left = town_life_reconcile_save(stale, reset)
  let right = town_life_reconcile_save(reset, stale)
  assert_eq(left.posts.length(), 1)
  assert_eq(left.posts[0].id, reference.id)
  assert_eq(
    ToJson::to_json(left).stringify(),
    ToJson::to_json(right).stringify(),
  )
}

///|
test "exact delete keeps tombstone while a new recollection incarnation lives" {
  let reset : TownLifeCausalStamp = { writer_id: "reset", lamport: 10 }
  let old = town_life_test_map_post(
    "community-a",
    "site-old",
    "inc-old",
    Some(reset),
    { writer_id: "a", lamport: 11 },
  )
  let fresh = {
    ..old,
    building_id: Some("site-new"),
    incarnation_id: Some("inc-new"),
    created_stamp: Some({ writer_id: "b", lamport: 13 }),
    updated_stamp: Some({ writer_id: "b", lamport: 13 }),
  }
  let tombstone : TownLifePostTombstone = {
    post_id: old.id,
    incarnation_id: "inc-old",
    reset_epoch: Some(reset),
    dot: { writer_id: "a", sequence: 12 },
    stamp: { writer_id: "a", lamport: 12 },
  }
  let deleted = {
    ..town_life_persistence_test_save(50, [], [], [], [], [], [], 0),
    post_reset_stamp: Some(reset),
    post_tombstones: Some([tombstone]),
  }
  let recollected = { ..deleted, posts: [fresh] }
  let merged = town_life_reconcile_save(deleted, recollected)
  assert_eq(merged.posts.length(), 1)
  assert_eq(merged.posts[0].incarnation_id, Some("inc-new"))
  assert_true(merged.post_tombstones.unwrap_or([]).contains(tombstone))
}

///|
test "legacy wildcard deletion is a cutoff not a permanent logical-id ban" {
  let legacy = town_life_persistence_test_post(
    "community-a", "旧收藏", false, true,
  )
  let wildcard : TownLifePostTombstone = {
    post_id: legacy.id,
    incarnation_id: "legacy-any:\{legacy.id}",
    reset_epoch: None,
    dot: { writer_id: "migration", sequence: 5 },
    stamp: { writer_id: "migration", lamport: 5 },
  }
  let fresh = {
    ..legacy,
    building_id: Some("site-new"),
    incarnation_id: Some("inc-new"),
    created_stamp: Some({ writer_id: "live", lamport: 6 }),
    updated_stamp: Some({ writer_id: "live", lamport: 6 }),
  }
  let stale = {
    ..town_life_persistence_test_save(50, [], [], [legacy], [], [], [], 0),
    post_tombstones: Some([wildcard]),
  }
  let rebuilt = {
    ..town_life_persistence_test_save(50, [], [], [fresh], [], [], [], 0),
    post_tombstones: Some([wildcard]),
  }
  let left = town_life_reconcile_save(stale, rebuilt)
  let right = town_life_reconcile_save(rebuilt, stale)
  assert_eq(left.posts.length(), 1)
  assert_eq(left.posts[0].incarnation_id, Some("inc-new"))
  assert_eq(
    ToJson::to_json(left).stringify(),
    ToJson::to_json(right).stringify(),
  )
}

///|
test "avatar and position use deterministic causal LWW" {
  let older = {
    ..town_life_persistence_test_save(50, [], [], [], [], [], [], 0),
    player: Some({
      name: "旧居民",
      persona: "researcher",
      color: 1,
      sprite_index: 1,
      title: "新居民",
    }),
    player_position: Some({ x: 10.0, y: 10.0 }),
    player_stamp: Some({ writer_id: "a", lamport: 5 }),
    player_position_stamp: Some({ writer_id: "a", lamport: 5 }),
  }
  let newer = {
    ..older,
    player: Some({
      name: "新居民",
      persona: "builder",
      color: 2,
      sprite_index: 2,
      title: "新居民",
    }),
    player_position: Some({ x: 20.0, y: 20.0 }),
    player_stamp: Some({ writer_id: "b", lamport: 6 }),
    player_position_stamp: Some({ writer_id: "b", lamport: 6 }),
  }
  let left = town_life_reconcile_save(older, newer)
  let right = town_life_reconcile_save(newer, older)
  assert_true(left.player is Some({ name: "新居民", .. }))
  assert_eq(left.player_position.map(value => value.x), Some(20.0))
  assert_eq(
    ToJson::to_json(left).stringify(),
    ToJson::to_json(right).stringify(),
  )
}

///|
test "event allocator advances above every observed writer" {
  let model = {
    ..init_model(),
    town_life_writer_id: "local",
    town_life_writer_counters: [
      { writer_id: "a", sequence: 5 },
      { writer_id: "b", sequence: 9 },
    ],
  }
  let (dot, stamp, _, next) = town_life_next_event(model, "test")
  assert_eq(dot, { writer_id: "local", sequence: 10 })
  assert_eq(stamp, { writer_id: "local", lamport: 10 })
  assert_true(
    next.town_life_writer_counters.contains({ writer_id: "local", sequence: 10 }),
  )
}

///|
test "disk-only event survives a local commit aggregate" {
  let disk_event = town_life_test_text_event("disk:1", "disk", 1, "disk")
  let local_event = town_life_test_text_event("local:2", "local", 2, "local")
  let disk = {
    ..town_life_persistence_test_save(50, [], [], [], ["disk"], [], [], 0),
    analytics_events: Some([disk_event]),
  }
  let model = {
    ..init_model(),
    analytics: ["local"],
    town_life_analytics_events: [local_event],
  }
  let cumulative = town_life_cumulative_save(model, [
    ToJson::to_json(disk).stringify(),
  ])
  assert_true(cumulative.analytics.contains("disk"))
  assert_true(cumulative.analytics.contains("local"))
  let live = town_life_model_with_save(
    model,
    town_life_reconcile_save(disk, town_life_save_for_model(model)),
  )
  assert_true(live.analytics.contains("disk"))
  assert_true(live.analytics.contains("local"))
}

///|
test "migration loser returns the V3 checkpoint authority" {
  let loser = town_life_persistence_test_save(
    50,
    ["create-avatar"],
    [],
    [],
    [],
    [],
    [],
    0,
  )
  let winner = town_life_persistence_test_save(
    310,
    town_quest_chain().map(quest => quest.id),
    [],
    [],
    [],
    [],
    [],
    0,
  )
  let selected = town_life_migration_committed_result(loser, [
    ToJson::to_json(winner).stringify(),
  ])
  assert_eq(selected.spark, 310)
  assert_eq(selected.quest_done, winner.quest_done)
}

///|
test "player spawn snaps to the migrated Wenyu road graph" {
  let model = { ..init_model(), player: Some(test_player_avatar()) }
  let seed = 20260727
  let (x, y) = player_home_position(model)
  assert_true(
    golden_valley_walkable(model, seed, x.floor().to_int(), y.floor().to_int()),
  )
}

///|
test "idle player uses the persisted road endpoint after reload" {
  let model = {
    ..init_model(),
    player: Some(test_player_avatar()),
    player_position: Some({ x: 81.5, y: 63.5 }),
    player_motion: None,
  }
  assert_eq(player_current_position(model), Some((81.5, 63.5)))
}

///|
test "every direction control can start a walk from the player spawn" {
  let model = { ..init_model(), player: Some(test_player_avatar()) }
  let directions = [(-1, -1), (1, 1), (-1, 1), (1, -1)]
  for direction in directions {
    let next = player_step_direction_model(model, direction.0, direction.1)
    assert_true(next.player_motion is Some(_))
  }
}

///|
test "direction update rewards walking only after visible movement" {
  let model = {
    ..init_model(),
    player: Some(test_player_avatar()),
    quest_done: ["create-avatar"],
  }
  let (_, next) = player_step_direction_update(model, -1, -1)
  assert_true(!next.quest_done.contains("first-walk"))
  guard next.player_motion is Some(motion) else {
    fail("expected a road motion")
  }
  let walked = player_maybe_complete_first_walk({
    ..next,
    player_motion: Some({
      ..motion,
      started_seconds: golden_animation_seconds() - 100.0,
    }),
  })
  assert_true(walked.quest_done.contains("first-walk"))
  assert_eq(walked.spark, 30)
  assert_true(walked.player_position is Some(_))
}

///|
test "avatar wizard follows name persona color and edit remains reachable" {
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let name_html = @rabbita.render_to_string(
    @rabbita.static_cell(render_avatar_wizard(dispatch, init_model())),
  )
  assert_true(name_html.contains("你叫什么"))
  assert_true(name_html.contains("id=\"avatar-wizard-title\""))
  assert_true(!name_html.contains("你的气质"))
  assert_true(name_html.contains("disabled"))
  let persona_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_avatar_wizard(dispatch, {
        ..init_model(),
        avatar_wizard_step: 1,
        avatar_draft_name: "测试居民",
      }),
    ),
  )
  assert_true(persona_html.contains("你的气质"))
  assert_true(!persona_html.contains("wizard-color-grid"))
  let color_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_avatar_wizard(dispatch, {
        ..init_model(),
        avatar_wizard_step: 2,
        avatar_draft_name: "测试居民",
        avatar_draft_persona: "researcher",
      }),
    ),
  )
  assert_true(color_html.contains("wizard-color-grid"))
  assert_true(color_html.contains("正式入住"))
  let (_, editing) = avatar_open_editor_update({
    ..init_model(),
    player: Some(test_player_avatar()),
  })
  assert_true(editing.energy_intro_open)
  assert_true(editing.player is Some(_))
  assert_eq(editing.avatar_draft_name, "测试居民")
}

///|
test "analytics baseline wraps negative day indices" {
  assert_eq(analytics_wrap_index(-1, 13), 12)
  assert_eq(analytics_wrap_index(-13, 13), 0)
  assert_eq(analytics_wrap_index(14, 13), 1)
}

///|
test "town life dialogs expose their mode and accessible names" {
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let model = {
    ..init_model(),
    player: Some(test_player_avatar()),
    phone_open: true,
    knowledge_dialog_open: true,
    knowledge_target_building: "测试工坊",
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      div([
        render_phone_panel(dispatch, model),
        render_knowledge_dialog(dispatch, model),
      ]),
    ),
  )
  assert_true(html.contains("离线居民 · 本地剧本（非 AI）"))
  assert_true(html.contains("id=\"knowledge-dialog-title\""))
  assert_true(html.contains("aria-labelledby=\"knowledge-dialog-title\""))
}

///|
test "placement and reward feedback render in one collision-free stack" {
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let model = {
    ..init_model(),
    player: Some(test_player_avatar()),
    energy_toast: "道路仅可铺在自然地表或河面",
    life_toast: "获得 30 谷光值",
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_energy_valley_toast_stack(dispatch, model)),
  )
  assert_true(html.contains("town-toast-stack pointer-events-none"))
  assert_true(html.contains("class=\"town-toast\""))
  assert_true(html.contains("life-toast pointer-events-auto"))
  assert_true(html.contains("道路仅可铺在自然地表或河面"))
  assert_true(html.contains("获得 30 谷光值"))
}

///|
test "quest tracker reports only the contiguous ordered progress" {
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let model = {
    ..init_model(),
    player: Some(test_player_avatar()),
    quest_done: [
      "create-avatar", "first-chat", "build-knowledge", "publish-knowledge", "collect-building",
    ],
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_quest_tracker(dispatch, model)),
  )
  assert_true(html.contains("进度 1/7"))
  assert_true(html.contains("在镇上走一段路"))
  assert_true(!html.contains("任务 6/7"))
}

///|
test "publishing a knowledge building creates a shareable town link" {
  let post : KnowledgePost = {
    id: "mine-test-lab",
    building_id: Some("site-test-lab"),
    incarnation_id: Some("inc-test-lab"),
    created_stamp: Some({ writer_id: "test", lamport: 1 }),
    updated_stamp: Some({ writer_id: "test", lamport: 1 }),
    reset_epoch: None,
    building_name: "测试实验室",
    topic: "MoonBit 协作研究",
    author: "测试居民",
    spark: 12,
    published: false,
    collected: false,
    mine: true,
  }
  let model = {
    ..init_model(),
    player: Some(test_player_avatar()),
    posts: [post],
    quest_done: [
      "create-avatar", "first-walk", "visit-building", "first-chat", "build-knowledge",
    ],
  }
  let link = knowledge_share_link(model, post)
  let next = knowledge_publish_model(model, post.id)
  assert_true(link.has_prefix("http://") || link.has_prefix("https://"))
  assert_true(link.contains("share=knowledge-building"))
  assert_true(next.posts[0].published)
  assert_eq(next.posts[0].spark, 32)
  assert_true(next.quest_done.contains("publish-knowledge"))
}

///|
test "town life surfaces open with competing overlays closed" {
  let base = {
    ..init_model(),
    player: Some(test_player_avatar()),
    phone_open: false,
    square_open: true,
    ops_open: true,
    energy_request_open: true,
  }
  let (_, phone) = phone_toggle_update(base)
  assert_true(phone.phone_open)
  assert_true(
    !phone.square_open && !phone.ops_open && !phone.energy_request_open,
  )
  let (_, square) = square_toggle_update({ ..base, square_open: false })
  assert_true(square.square_open)
  assert_true(
    !square.phone_open && !square.ops_open && !square.energy_request_open,
  )
  let (_, ops) = ops_toggle_update({ ..base, ops_open: false })
  assert_true(ops.ops_open)
  assert_true(!ops.phone_open && !ops.square_open && !ops.energy_request_open)
}

///|
test "phone work handoff carries the selected contact context" {
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let model = {
    ..init_model(),
    player: Some(test_player_avatar()),
    phone_open: true,
  }
  let (_, next) = update_non_form_message(
    dispatch,
    OpenEnergyRequestForAgent("mayor"),
    model,
  )
  assert_true(next.energy_request_open)
  assert_true(!next.phone_open)
  assert_true(next.request_title.contains("望月"))
  assert_true(next.request_prompt.contains("mayor"))
  assert_true(next.request_prompt.contains("调度策略"))
}
