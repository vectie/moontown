///|
fn social_knowledge_runtime_state() -> EnergyValleyRuntimeState {
  energy_valley_runtime_state_from_text(
    (
      #|{
      #|  "schema": "moontown.energy-valley.runtime.v1",
      #|  "mode": "live",
      #|  "observedAt": "1970-01-01T00:01:40.000Z",
      #|  "knowledgeCatalogDigest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "tick": 42,
      #|  "tasks": [{
      #|    "id": "real-research",
      #|    "title": "能源谷协作研究",
      #|    "status": "completed",
      #|    "buildingModuleKey": "policy-hall",
      #|    "agentId": "agent-live",
      #|    "agentName": "Scout",
      #|    "role": "worker",
      #|    "runId": "run-real",
      #|    "summary": "三位 Agent 完成来源复核并产出报告",
      #|    "artifacts": ["report.md"],
      #|    "resultLinks": [{
      #|      "label": "研究报告",
      #|      "url": "/book-output/policy-hall/report.html",
      #|      "kind": "report"
      #|    }],
      #|    "progress": {
      #|      "checkedSources": 9,
      #|      "acceptedFacts": 4,
      #|      "pagesChanged": 2,
      #|      "bookChanged": true
      #|    },
      #|    "source": "operator-request"
      #|  }, {
      #|    "id": "review-research",
      #|    "title": "待审查研究",
      #|    "status": "waiting_review",
      #|    "buildingModuleKey": "policy-hall",
      #|    "agentName": "Reviewer",
      #|    "summary": "证据已汇总，等待 Keeper 审核",
      #|    "artifacts": ["review.md"],
      #|    "resultLinks": [{
      #|      "label": "待审查报告",
      #|      "url": "/book-output/policy-hall/review.html",
      #|      "kind": "review"
      #|    }],
      #|    "source": "operator-request"
      #|  }, {
      #|    "id": "running-research",
      #|    "title": "进行中的研究",
      #|    "status": "running",
      #|    "buildingModuleKey": "policy-hall",
      #|    "agentName": "Runner",
      #|    "summary": "正在复核阶段证据",
      #|    "artifacts": ["notes.md"],
      #|    "source": "operator-request"
      #|  }, {
      #|    "id": "failed-import",
      #|    "title": "失败的运行记录",
      #|    "status": "failed",
      #|    "buildingModuleKey": "policy-hall",
      #|    "summary": "Runtime handoff failed: /very/long/private/path should not be published as knowledge.",
      #|    "artifacts": ["failure.log"],
      #|    "resultLinks": [{
      #|      "label": "失败日志",
      #|      "url": "/book-output/policy-hall/failure.html",
      #|      "kind": "review"
      #|    }],
      #|    "progress": {
      #|      "checkedSources": 2,
      #|      "acceptedFacts": 1,
      #|      "pagesChanged": 0,
      #|      "bookChanged": false
      #|    },
      #|    "source": "operator-request"
      #|  }],
      #|  "agents": [{
      #|    "id": "agent-live",
      #|    "name": "Scout",
      #|    "role": "worker",
      #|    "status": "running",
      #|    "buildingModuleKey": "policy-hall",
      #|    "workItemId": "real-research",
      #|    "runId": "run-real",
      #|    "activityKind": "researching",
      #|    "activityLabel": "正在复核真实来源"
      #|  }]
      #|}
    ),
    1,
    110000.0,
  )
}

///|
fn social_knowledge_player() -> PlayerAvatar {
  {
    name: "测试居民",
    persona: "researcher",
    color: 0,
    sprite_index: 0,
    title: "新居民",
  }
}

///|
test "phone lists real runtime Agents without fabricating chat" {
  let runtime = social_knowledge_runtime_state()
  assert_eq(runtime.error, "")
  let model = {
    ..init_model(),
    player: Some(social_knowledge_player()),
    energy_valley_runtime: runtime,
    phone_open: true,
    phone_contact: "runtime:agent-live",
    phone_draft: "请继续研究",
    phone_log: [],
  }
  let contacts = phone_contacts(model)
  assert_eq(contacts[0].id, "runtime:agent-live")
  assert_true(contacts[0].role.contains("Runtime Agent"))
  assert_true(contacts[0].greeting.contains("正在复核真实来源"))
  assert_true(contacts[0].greeting.contains("Run run-real"))
  let next = phone_send_model(model)
  assert_true(next.phone_log.is_empty())
  assert_eq(next.phone_draft, "请继续研究")
  assert_true(next.life_toast.contains("消息没有伪装成已发送"))
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_phone_panel(dispatch, model)),
  )
  assert_true(html.contains("真实 Runtime Agent · 只读工作动态"))
  assert_true(html.contains("真实消息写入接口尚未连接"))
  assert_true(html.contains("创建真实工作请求"))
  assert_true(html.contains("disabled"))
}

///|
test "offline phone replies are explicitly local scripts" {
  let model = {
    ..init_model(),
    player: Some(social_knowledge_player()),
    phone_open: true,
    phone_contact: "mayor",
    phone_draft: "你好",
    phone_log: [],
  }
  let next = phone_send_model(model)
  assert_eq(next.phone_log.length(), 2)
  let day = energy_valley_sim_day(next)
  assert_eq(analytics_count_on(next, day, "phone_send"), 1)
  assert_eq(analytics_count_on(next, day, "phone_receive"), 1)
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_phone_panel(dispatch, next)),
  )
  assert_true(html.contains("离线居民 · 本地剧本（非 AI）"))
  assert_true(html.contains("望月 · 本地剧本"))
}

///|
test "offline resident pings are infrequent and bounded" {
  let base = {
    ..init_model(),
    player: Some(social_knowledge_player()),
    phone_open: false,
    phone_log: [],
  }
  assert_true(phone_maybe_receive({ ..base, tick: 22 }).phone_log.is_empty())
  let pinged = phone_maybe_receive({ ..base, tick: 720 })
  assert_eq(pinged.phone_log.length(), 1)
  assert_eq(pinged.phone_unread, 1)
  assert_true(pinged.life_toast.contains("离线剧本居民"))
}

///|
test "phone renders only the newest contact history" {
  let log : Array[PhoneMessage] = []
  for index in 0..<52 {
    log.push({
      contact: "mayor",
      from_me: index % 2 == 0,
      text: "消息 \{index}",
      tick: index,
    })
  }
  log.push({ contact: "keeper", from_me: false, text: "别的会话", tick: 99 })
  let model = { ..init_model(), phone_log: log }
  let thread = phone_thread(model, "mayor")
  assert_eq(thread.length(), 36)
  assert_eq(thread[0].text, "消息 16")
  assert_eq(thread[35].text, "消息 51")
  assert_true(!thread.any(message => message.text == "别的会话"))
}

///|
test "phone marks stale Agents and preserves a vanished runtime identity" {
  let runtime = social_knowledge_runtime_state()
  let stale = { ..runtime, phase: Stale }
  let stale_model = {
    ..init_model(),
    player: Some(social_knowledge_player()),
    energy_valley_runtime: stale,
    phone_open: true,
    phone_contact: "runtime:agent-live",
  }
  let stale_contact = phone_contact_by_id(stale_model, "runtime:agent-live")
  assert_true(stale_contact.role.contains("快照已过期"))
  assert_true(!stale_contact.role.contains("工作中"))
  let projection = runtime.projection.unwrap()
  let vanished = { ..runtime, projection: Some({ ..projection, agents: [] }) }
  let vanished_model = { ..stale_model, energy_valley_runtime: vanished }
  let disconnected = phone_contact_by_id(vanished_model, "runtime:agent-live")
  assert_eq(disconnected.id, "runtime:agent-live")
  assert_true(disconnected.name.contains("已断开"))
  assert_true(disconnected.role.contains("当前投影中不存在"))
  assert_true(phone_contacts(vanished_model)[0].id == "runtime:agent-live")
  let queued_identity = phone_contact_by_id(init_model(), "runtime:old-agent")
  assert_eq(queued_identity.id, "runtime:old-agent")
  assert_true(queued_identity.name.contains("已断开"))
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_phone_panel(dispatch, vanished_model)),
  )
  assert_true(html.contains("已断开的 Runtime Agent"))
  assert_true(!html.contains("望月 · Mayor"))
}

///|
test "community square labels runtime evidence without promoting unfinished work" {
  let model = {
    ..init_model(),
    energy_valley_runtime: social_knowledge_runtime_state(),
    posts: community_square_posts(),
    square_open: true,
  }
  let posts = knowledge_community_posts(model)
  assert_eq(posts.length(), 4)
  assert_eq(posts[0].id, "runtime-real-research")
  assert_true(posts[0].topic.contains("三位 Agent"))
  assert_true(posts.any(post => post.id == "runtime-review-research"))
  assert_true(posts.any(post => post.id == "runtime-running-research"))
  assert_true(posts.any(post => post.id == "runtime-failed-import"))
  assert_true(posts[0].published)
  assert_true(!posts[1].published)
  assert_true(!posts[2].published)
  assert_true(!posts[3].published)
  assert_true(!posts.any(post => knowledge_post_is_offline_example(post)))
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_square_panel(dispatch, model)),
  )
  assert_true(html.contains("已完成 · 真实运行成果"))
  assert_true(html.contains("待审核 · 运行时证据"))
  assert_true(html.contains("进行中 · 阶段证据"))
  assert_true(html.contains("未完成 · 保留证据"))
  assert_true(html.contains("审核完成后可收藏"))
  assert_true(html.contains("未完成，不可收藏"))
  assert_true(html.contains("/book-output/policy-hall/report.html"))
  assert_true(!html.contains("/very/long/private/path"))
  assert_true(!html.contains("尚未发现可核验的运行时成果"))
  let blocked = knowledge_collect_model(model, "runtime-review-research")
  assert_true(energy_valley_model_buildings(blocked).is_empty())
  assert_true(blocked.life_toast.contains("仍在审核"))
}

///|
test "publishing creates an ordinary browser URL and complete share card" {
  let post : KnowledgePost = {
    id: "mine-share",
    building_id: Some("site-share"),
    incarnation_id: Some("inc-share"),
    created_stamp: Some({ writer_id: "test", lamport: 1 }),
    updated_stamp: Some({ writer_id: "test", lamport: 1 }),
    reset_epoch: None,
    building_name: "协作实验室",
    topic: "MoonBit 多 Agent 研究",
    author: "测试居民",
    spark: 12,
    published: false,
    collected: false,
    mine: true,
  }
  let model = { ..init_model(), posts: [post] }
  let link = knowledge_share_link(model, post)
  assert_true(link.has_prefix("http://") || link.has_prefix("https://"))
  assert_true(link.contains("share=knowledge-building"))
  assert_true(link.contains("shared_topic="))
  let card = knowledge_share_card_text(post)
  assert_true(card.contains("知识大楼：协作实验室"))
  assert_true(card.contains("共建者：测试居民"))
  let next = knowledge_publish_model(model, post.id)
  assert_true(next.posts[0].published)
  assert_true(next.life_toast.contains("本机标记为可分享"))
  let shared_again = knowledge_publish_model(next, post.id)
  assert_eq(shared_again.posts[0].spark, next.posts[0].spark)
}

///|
test "knowledge share URL keeps only the public allowlist" {
  let link = knowledge_share_url_from_href(
    "https://town.example/app/index.html?seed=20260727&moonflow_handoff=SECRET&panel=runtime&token=PRIVATE#debug",
    "mine-safe", "安全实验室", "可分享主题", "测试居民",
  )
  assert_true(link.has_prefix("https://town.example/app/index.html?"))
  assert_true(link.contains("seed=20260727"))
  assert_true(link.contains("share=knowledge-building"))
  assert_true(link.contains("shared_building=mine-safe"))
  assert_true(!link.contains("moonflow_handoff"))
  assert_true(!link.contains("SECRET"))
  assert_true(!link.contains("panel=runtime"))
  assert_true(!link.contains("token="))
  assert_true(!link.contains("#debug"))
}

///|
fn social_knowledge_valid_workshop(model : Model) -> GoldenValleyBuilding? {
  let world = energy_valley_base_contract_world_for_seed(
    active_energy_valley_seed(),
  )
  let scale = energy_valley_semantic_cells_per_planning_cell()
  for y in 1..<(golden_valley_rows() - 1) {
    for x in 1..<(golden_valley_cols() - 1) {
      if x % scale != 0 || y % scale != 0 {
        continue
      }
      match golden_valley_custom_building(WorkshopTool, x, y, 1) {
        Some(building) if golden_valley_custom_placement_block_in_world(
            world, building,
          )
          is None => return Some(building)
        _ => ()
      }
    }
  }
  ignore(model)
  None
}

///|
test "unfinished knowledge building is durable and recoverable from square" {
  let before = {
    ..init_model(),
    player: Some(social_knowledge_player()),
    energy_tool: WorkshopTool,
    posts: [],
    quest_done: ["create-avatar", "first-walk", "visit-building", "first-chat"],
  }
  let building = social_knowledge_valid_workshop(before).unwrap()
  let (after, identified) = energy_valley_model_add_building_delta_with_identity(
    before,
    building,
    energy_valley_model_budget(before),
    energy_valley_model_next_authored_building_sequence(before),
  )
  let prompted = knowledge_maybe_prompt_for_new_building(before, after)
  assert_true(prompted.knowledge_dialog_open)
  assert_true(prompted.quest_done.contains("build-knowledge"))
  assert_eq(prompted.posts.length(), 1)
  assert_true(prompted.posts[0].topic.is_empty())
  assert_eq(prompted.posts[0].building_id, identified.authored_id)
  assert_eq(knowledge_pending_buildings(prompted).length(), 1)
  let deferred = { ..prompted, knowledge_dialog_open: false, square_open: true }
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let square_html = @rabbita.render_to_string(
    @rabbita.static_cell(render_square_panel(dispatch, deferred)),
  )
  assert_true(square_html.contains("待完善知识大楼"))
  assert_true(square_html.contains("继续设置主题"))
  assert_true(square_html.contains(identified.name))
  let rejected = knowledge_confirm_topic_model({
    ..prompted,
    knowledge_draft_topic: "   ",
  })
  assert_true(rejected.knowledge_dialog_open)
  assert_true(rejected.life_toast.contains("请先填写知识主题"))
  let completed = knowledge_confirm_topic_model({
    ..prompted,
    knowledge_draft_topic: "能源谷多 Agent 协作",
  })
  assert_eq(completed.posts.length(), 1)
  assert_eq(completed.posts[0].topic, "能源谷多 Agent 协作")
  assert_true(knowledge_pending_buildings(completed).is_empty())
}

///|
test "demolition removes the local knowledge post instead of orphaning it" {
  let local_post : KnowledgePost = {
    id: "mine-实验室 1",
    building_id: Some("site-lab-1"),
    incarnation_id: Some("inc-lab-1"),
    created_stamp: Some({ writer_id: "test", lamport: 1 }),
    updated_stamp: Some({ writer_id: "test", lamport: 1 }),
    reset_epoch: None,
    building_name: "实验室 1",
    topic: "已分享主题",
    author: "测试居民",
    spark: 32,
    published: true,
    collected: false,
    mine: true,
  }
  let other : KnowledgePost = {
    ..local_post,
    id: "mine-实验室 2",
    building_id: Some("site-lab-2"),
    incarnation_id: Some("inc-lab-2"),
    building_name: "实验室 2",
  }
  let community = community_square_posts()[0]
  let removed : GoldenValleyBuilding = {
    authored_id: Some("site-lab-1"),
    module_key: None,
    name: "实验室 1",
    style: "custom-lab",
    x: 40,
    y: 40,
    width: 8,
    depth: 8,
    entrance_x: None,
    entrance_y: None,
    floors: 2,
  }
  let remaining = knowledge_posts_after_demolition(
    [local_post, other, community],
    [removed],
    [removed],
  )
  assert_eq(remaining.length(), 2)
  assert_true(!remaining.any(post => post.id == "mine-实验室 1"))
  assert_true(remaining.any(post => post.id == "mine-实验室 2"))
  assert_true(remaining.any(post => post.id == community.id))
}

///|
test "same-name buildings use authored identity and legacy ambiguity is untouched" {
  let first_building : GoldenValleyBuilding = {
    authored_id: Some("site-a"),
    module_key: None,
    name: "同名实验室",
    style: "custom-lab",
    x: 40,
    y: 40,
    width: 8,
    depth: 8,
    entrance_x: None,
    entrance_y: None,
    floors: 2,
  }
  let second_building = { ..first_building, authored_id: Some("site-b"), x: 64 }
  let first : KnowledgePost = {
    id: "mine-site-a",
    building_id: Some("site-a"),
    incarnation_id: Some("inc-a"),
    created_stamp: Some({ writer_id: "test", lamport: 1 }),
    updated_stamp: Some({ writer_id: "test", lamport: 1 }),
    reset_epoch: None,
    building_name: "同名实验室",
    topic: "A",
    author: "测试居民",
    spark: 12,
    published: false,
    collected: false,
    mine: true,
  }
  let second = {
    ..first,
    id: "mine-site-b",
    building_id: Some("site-b"),
    incarnation_id: Some("inc-b"),
    topic: "B",
  }
  let exact = knowledge_posts_after_demolition(
    [first, second],
    [first_building],
    [first_building, second_building],
  )
  assert_eq(exact.length(), 1)
  assert_eq(exact[0].building_id, Some("site-b"))
  let legacy_first = {
    ..first,
    id: "legacy-a",
    building_id: None,
    incarnation_id: None,
    created_stamp: None,
    updated_stamp: None,
  }
  let legacy_second = { ..legacy_first, id: "legacy-b", topic: "B" }
  let ambiguous = knowledge_posts_after_demolition(
    [legacy_first, legacy_second],
    [{ ..first_building, authored_id: None }],
    [
      { ..first_building, authored_id: None },
      { ..second_building, authored_id: None },
    ],
  )
  assert_eq(ambiguous.length(), 2)
}

///|
test "map reset removes authored and collected physical post state" {
  let mine_post : KnowledgePost = {
    id: "mine-reset",
    building_id: Some("site-reset"),
    incarnation_id: Some("inc-reset"),
    created_stamp: Some({ writer_id: "test", lamport: 1 }),
    updated_stamp: Some({ writer_id: "test", lamport: 1 }),
    reset_epoch: None,
    building_name: "研发塔楼 1",
    topic: "本机主题",
    author: "测试居民",
    spark: 20,
    published: true,
    collected: false,
    mine: true,
  }
  let collected = { ..community_square_posts()[0], collected: true }
  let example = community_square_posts()[1]
  let remaining = knowledge_posts_after_map_reset([
    mine_post, collected, example,
  ])
  assert_eq(remaining.length(), 1)
  assert_eq(remaining[0].id, example.id)
  assert_true(!remaining[0].collected)
  assert_true(!remaining[0].mine)
}

///|
test "collecting places a persistent road-accessible map building once" {
  let source = community_square_posts()[0]
  let model = {
    ..init_model(),
    energy_valley_runtime: energy_valley_runtime_loading_state(),
    posts: [source],
    quest_done: [
      "create-avatar", "first-walk", "visit-building", "first-chat", "build-knowledge",
      "publish-knowledge",
    ],
  }
  let next = knowledge_collect_model(model, source.id)
  let next_buildings = energy_valley_model_buildings(next)
  assert_eq(next_buildings.length(), 1)
  assert_true(next.posts[0].collected)
  let building = next_buildings[0]
  assert_eq(building.name, knowledge_collected_building_name(source))
  assert_eq(building.module_key, Some(knowledge_collected_building_key(source)))
  assert_true(golden_valley_custom_building_has_road_access(next, building))
  assert_true(next.quest_done.contains("collect-building"))
  let again = knowledge_collect_model(next, source.id)
  assert_eq(energy_valley_model_buildings(again).length(), 1)
  assert_true(again.life_toast.contains("已经收藏并落位"))
}

///|
test "demolishing a collected building clears and tombstones its post" {
  let source = community_square_posts()[0]
  let model = {
    ..init_model(),
    energy_valley_runtime: energy_valley_runtime_loading_state(),
    posts: [source],
    quest_done: [
      "create-avatar", "first-walk", "visit-building", "first-chat", "build-knowledge",
      "publish-knowledge",
    ],
  }
  let collected = knowledge_collect_model(model, source.id)
  let removed_incarnation = collected.posts.filter(post => {
    post.id == source.id && post.collected
  })[0].incarnation_id.unwrap_or("")
  let building = energy_valley_model_buildings(collected)[0]
  let demolished = golden_valley_demolish_at_model(
    collected,
    building.x,
    building.y,
  )
  assert_true(energy_valley_model_buildings(demolished).is_empty())
  assert_true(
    !demolished.posts.any(post => {
      post.id == source.id &&
      (post.collected || post.mine || post.building_id is Some(_))
    }),
  )
  assert_true(
    demolished.town_life_post_tombstones.any(tombstone => {
      tombstone.incarnation_id == removed_incarnation
    }),
  )
  let available = knowledge_community_post_by_id(demolished, source.id)
  assert_true(available is Some({ collected: false, .. }))
  let recollected = knowledge_collect_model(demolished, source.id)
  assert_true(
    recollected.posts.any(post => post.id == source.id && post.collected),
  )
  let new_incarnation = recollected.posts.filter(post => {
    post.id == source.id && post.collected
  })[0].incarnation_id.unwrap_or("")
  assert_true(new_incarnation != removed_incarnation)
  assert_true(
    recollected.town_life_post_tombstones.any(tombstone => {
      tombstone.incarnation_id == removed_incarnation
    }),
  )
}
