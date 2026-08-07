///|
/// Knowledge buildings: after placing a research/lab/workshop building the
/// player gives it a knowledge topic; the building can then be published as a
/// real browser URL and collected as a physical building on the map.
extern "js" fn knowledge_share_url_from_href(
  href : String,
  post_id : String,
  building_name : String,
  topic : String,
  author : String,
) -> String =
  #| (href, postId, buildingName, topic, author) => {
  #|   try {
  #|     const source = new URL(String(href || "http://localhost/"), "http://localhost/");
  #|     const webOrigin = source.protocol === "http:" || source.protocol === "https:"
  #|       ? source.origin
  #|       : "http://localhost";
  #|     const url = new URL(source.pathname || "/", webOrigin);
  #|     const seed = source.searchParams.get("seed");
  #|     if (seed) url.searchParams.set("seed", seed);
  #|     url.searchParams.set("share", "knowledge-building");
  #|     url.searchParams.set("shared_building", String(postId));
  #|     url.searchParams.set("shared_name", String(buildingName));
  #|     url.searchParams.set("shared_topic", String(topic));
  #|     url.searchParams.set("shared_author", String(author));
  #|     return url.toString();
  #|   } catch (_) {
  #|     return "http://localhost/?share=knowledge-building";
  #|   }
  #| }

///|
extern "js" fn browser_current_knowledge_href() -> String =
  #| () => globalThis.location?.href || "http://localhost/"

///|
fn browser_knowledge_share_url(
  post_id : String,
  building_name : String,
  topic : String,
  author : String,
) -> String {
  knowledge_share_url_from_href(
    browser_current_knowledge_href(),
    post_id,
    building_name,
    topic,
    author,
  )
}

///|
/// Copy the complete card for universal fallback, and open the native Web
/// Share sheet when available. Returning `true` only means a native share was
/// offered; clipboard remains the durable fallback either way.
extern "js" fn browser_share_knowledge_card(
  title : String,
  text : String,
  url : String,
) -> Bool =
  #| (title, text, url) => {
  #|   const card = `${title}\n${text}\n${url}`;
  #|   try {
  #|     if (typeof globalThis.navigator?.clipboard?.writeText === "function") {
  #|       globalThis.navigator.clipboard.writeText(card).catch(() => {});
  #|     } else if (globalThis.document?.body) {
  #|       const input = globalThis.document.createElement("textarea");
  #|       input.value = card;
  #|       input.setAttribute("readonly", "");
  #|       input.style.position = "fixed";
  #|       input.style.opacity = "0";
  #|       globalThis.document.body.appendChild(input);
  #|       input.select();
  #|       globalThis.document.execCommand?.("copy");
  #|       input.remove();
  #|     }
  #|     if (typeof globalThis.navigator?.share === "function") {
  #|       globalThis.navigator.share({ title, text, url }).catch(() => {});
  #|       return true;
  #|     }
  #|   } catch (_) {}
  #|   return false;
  #| }

///|
/// Honest offline examples for an empty runtime. They are never labeled as
/// real residents or real published work in the square.
fn community_square_posts() -> Array[KnowledgePost] {
  [
    {
      id: "community-robotics",
      building_id: None,
      incarnation_id: None,
      created_stamp: None,
      updated_stamp: None,
      reset_epoch: None,
      building_name: "具身智能研究塔",
      topic: "机器人如何学会在真实厨房打下手",
      author: "灵犀",
      spark: 186,
      published: true,
      collected: false,
      mine: false,
    },
    {
      id: "community-agents",
      building_id: None,
      incarnation_id: None,
      created_stamp: None,
      updated_stamp: None,
      reset_epoch: None,
      building_name: "多智能体协作实验室",
      topic: "让 25 个 Agent 像小镇居民一样分工",
      author: "望月",
      spark: 152,
      published: true,
      collected: false,
      mine: false,
    },
    {
      id: "community-energy",
      building_id: None,
      incarnation_id: None,
      created_stamp: None,
      updated_stamp: None,
      reset_epoch: None,
      building_name: "零碳工坊",
      topic: "能源谷的楼宇怎样一年省下一座湖的水",
      author: "知河",
      spark: 98,
      published: true,
      collected: false,
      mine: false,
    },
    {
      id: "community-garden",
      building_id: None,
      incarnation_id: None,
      created_stamp: None,
      updated_stamp: None,
      reset_epoch: None,
      building_name: "AI 花园自习室",
      topic: "每晚八点的论文共读会实录",
      author: "小谷",
      spark: 77,
      published: true,
      collected: false,
      mine: false,
    },
  ]
}

///|
fn knowledge_post_is_offline_example(post : KnowledgePost) -> Bool {
  post.id.has_prefix("community-")
}

///|
fn knowledge_runtime_result_link(
  task : EnergyValleyRuntimeWorkItem,
) -> EnergyValleyRuntimeResultLink? {
  match task.resultLinks {
    None => None
    Some(links) => {
      for link in links {
        if energy_valley_runtime_result_link_is_valid(link) {
          return Some(link)
        }
      }
      None
    }
  }
}

///|
priv enum KnowledgeRuntimeEvidenceState {
  RuntimeVerifiedEvidence
  RuntimeReviewEvidence
  RuntimeInProgressEvidence
  RuntimeFailedEvidence
} derive(Eq)

///|
fn knowledge_runtime_progress_is_evidence(
  task : EnergyValleyRuntimeWorkItem,
) -> Bool {
  match task.progress {
    Some(progress) =>
      progress.acceptedFacts.unwrap_or(0) > 0 ||
      progress.pagesChanged.unwrap_or(0) > 0 ||
      progress.bookChanged.unwrap_or(false)
    None => false
  }
}

///|
fn knowledge_runtime_summary_reports_failure(
  task : EnergyValleyRuntimeWorkItem,
) -> Bool {
  match task.summary {
    Some(summary) => {
      let lower = summary.to_lower()
      lower.contains(" failed") ||
      lower.has_prefix("failed") ||
      lower.contains("timed out") ||
      lower.contains("error:")
    }
    None => false
  }
}

///|
/// A runtime card may be visible when it has auditable evidence, but its state
/// remains distinct from verified completion. Review, in-progress, and failed
/// evidence must never be presented as already published knowledge.
fn knowledge_runtime_task_evidence_state(
  task : EnergyValleyRuntimeWorkItem,
) -> KnowledgeRuntimeEvidenceState? {
  let has_evidence = knowledge_runtime_result_link(task) is Some(_) ||
    knowledge_runtime_progress_is_evidence(task) ||
    !task.artifacts.is_empty()
  if !has_evidence {
    return None
  }
  let status = task.status.to_lower()
  if knowledge_runtime_summary_reports_failure(task) ||
    status == "failed" ||
    status == "blocked" {
    Some(RuntimeFailedEvidence)
  } else {
    match status {
      "completed" | "accepted" | "done" | "succeeded" =>
        Some(RuntimeVerifiedEvidence)
      "waiting_review" | "needs_review" | "review" | "ready" =>
        Some(RuntimeReviewEvidence)
      _ => Some(RuntimeInProgressEvidence)
    }
  }
}

///|
fn knowledge_runtime_task_has_visible_evidence(
  task : EnergyValleyRuntimeWorkItem,
) -> Bool {
  knowledge_runtime_task_evidence_state(task) is Some(_)
}

///|
fn knowledge_runtime_task_topic(task : EnergyValleyRuntimeWorkItem) -> String {
  let summary = match task.summary {
    Some(value) if !value.trim().is_empty() =>
      compact_single_line(value, limit=180)
    _ =>
      match knowledge_runtime_result_link(task) {
        Some(link) => "可核验输出：\{link.label}"
        None if !task.artifacts.is_empty() =>
          "已记录 \{task.artifacts.length()} 项运行时证据"
        None => task.title
      }
  }
  match knowledge_runtime_task_evidence_state(task) {
    Some(RuntimeFailedEvidence) =>
      match knowledge_runtime_result_link(task) {
        Some(link) => "任务未完成；保留可核验输出：\{link.label}"
        None => "任务未完成；保留了可核验的阶段证据"
      }
    Some(RuntimeReviewEvidence) => "待审核：\{summary}"
    Some(RuntimeInProgressEvidence) => "进行中：\{summary}"
    _ => summary
  }
}

///|
fn knowledge_runtime_task_spark(task : EnergyValleyRuntimeWorkItem) -> Int {
  let evidence = match task.progress {
    Some(progress) =>
      progress.acceptedFacts.unwrap_or(0) * 3 +
      progress.pagesChanged.unwrap_or(0) * 2 +
      progress.checkedSources.unwrap_or(0)
    None => 0
  }
  24 + evidence
}

///|
fn knowledge_stored_post(model : Model, id : String) -> KnowledgePost? {
  for post in model.posts {
    if post.id == id {
      return Some(post)
    }
  }
  None
}

///|
fn knowledge_runtime_post(
  model : Model,
  task : EnergyValleyRuntimeWorkItem,
) -> KnowledgePost {
  let id = "runtime-\{task.id}"
  let collected = match knowledge_stored_post(model, id) {
    Some(post) => post.collected
    None => false
  }
  {
    id,
    building_id: None,
    incarnation_id: None,
    created_stamp: None,
    updated_stamp: None,
    reset_epoch: None,
    building_name: task.title,
    topic: knowledge_runtime_task_topic(task),
    author: task.agentName.unwrap_or("MoonTown Runtime"),
    spark: knowledge_runtime_task_spark(task),
    published: knowledge_runtime_task_evidence_state(task) ==
    Some(RuntimeVerifiedEvidence),
    collected,
    mine: false,
  }
}

///|
fn knowledge_runtime_posts(model : Model) -> Array[KnowledgePost] {
  match model.energy_valley_runtime.projection {
    None => []
    Some(projection) =>
      projection.tasks
      .filter(knowledge_runtime_task_has_visible_evidence)
      .map(task => knowledge_runtime_post(model, task))
  }
}

///|
fn knowledge_shared_link_post() -> KnowledgePost? {
  if current_browser_query_param("share") != "knowledge-building" {
    return None
  }
  let id = current_browser_query_param("shared_building").trim().to_owned()
  let name = current_browser_query_param("shared_name").trim().to_owned()
  let topic = current_browser_query_param("shared_topic").trim().to_owned()
  let author = current_browser_query_param("shared_author").trim().to_owned()
  if id.is_empty() || name.is_empty() || topic.is_empty() {
    return None
  }
  Some({
    id: "shared-\{id}",
    building_id: None,
    incarnation_id: None,
    created_stamp: None,
    updated_stamp: None,
    reset_epoch: None,
    building_name: name,
    topic,
    author: if author.is_empty() {
      "MoonTown 居民"
    } else {
      author
    },
    spark: 20,
    published: true,
    collected: false,
    mine: false,
  })
}

///|
/// Prefer auditable runtime results. Persisted or seeded offline cards are a
/// fallback only; previously collected cards remain visible so user state is
/// never discarded when a runtime becomes available.
fn knowledge_community_posts(model : Model) -> Array[KnowledgePost] {
  let runtime = knowledge_runtime_posts(model)
  let community : Array[KnowledgePost] = []
  match knowledge_shared_link_post() {
    Some(post) =>
      match knowledge_stored_post(model, post.id) {
        Some(stored) =>
          community.push({
            ..post,
            collected: stored.collected,
            spark: stored.spark,
          })
        None => community.push(post)
      }
    None => ()
  }
  if !runtime.is_empty() {
    for post in runtime {
      if !community.any(existing => existing.id == post.id) {
        community.push(post)
      }
    }
    for post in model.posts {
      if !post.mine &&
        post.collected &&
        !community.any(existing => existing.id == post.id) {
        community.push(post)
      }
    }
    return community
  }
  let stored = model.posts.filter(post => !post.mine)
  let fallback = if stored.is_empty() {
    community_square_posts()
  } else {
    stored
  }
  for post in fallback {
    if !community.any(existing => existing.id == post.id) {
      community.push(post)
    }
  }
  community
}

///|
fn knowledge_community_post_by_id(
  model : Model,
  post_id : String,
) -> KnowledgePost? {
  for post in knowledge_community_posts(model) {
    if post.id == post_id {
      return Some(post)
    }
  }
  None
}

///|
fn knowledge_runtime_task_for_post(
  model : Model,
  post_id : String,
) -> EnergyValleyRuntimeWorkItem? {
  if !post_id.has_prefix("runtime-") {
    return None
  }
  match model.energy_valley_runtime.projection {
    None => None
    Some(projection) => {
      for task in projection.tasks {
        if "runtime-\{task.id}" == post_id {
          return Some(task)
        }
      }
      None
    }
  }
}

///|
fn knowledge_runtime_link_for_post(
  model : Model,
  post_id : String,
) -> EnergyValleyRuntimeResultLink? {
  match knowledge_runtime_task_for_post(model, post_id) {
    Some(task) => knowledge_runtime_result_link(task)
    None => None
  }
}

///|
fn knowledge_runtime_state_for_post(
  model : Model,
  post_id : String,
) -> KnowledgeRuntimeEvidenceState? {
  match knowledge_runtime_task_for_post(model, post_id) {
    Some(task) => knowledge_runtime_task_evidence_state(task)
    None => None
  }
}

///|
fn knowledge_runtime_state_label(
  state : KnowledgeRuntimeEvidenceState,
) -> String {
  match state {
    RuntimeVerifiedEvidence => "已完成 · 真实运行成果"
    RuntimeReviewEvidence => "待审核 · 运行时证据"
    RuntimeInProgressEvidence => "进行中 · 阶段证据"
    RuntimeFailedEvidence => "未完成 · 保留证据"
  }
}

///|
fn knowledge_post_can_collect(model : Model, post : KnowledgePost) -> Bool {
  match knowledge_runtime_state_for_post(model, post.id) {
    Some(RuntimeVerifiedEvidence) | None => true
    Some(_) => false
  }
}

///|
fn knowledge_post_collect_block_reason(
  model : Model,
  post : KnowledgePost,
) -> String {
  match knowledge_runtime_state_for_post(model, post.id) {
    Some(RuntimeReviewEvidence) =>
      "这项运行证据仍在审核，审核完成后才能收藏为知识楼。"
    Some(RuntimeInProgressEvidence) =>
      "这项任务仍在进行，完成后才能收藏为知识楼。"
    Some(RuntimeFailedEvidence) =>
      "这项任务未完成；证据可以查看，但不会伪装成可收藏成果。"
    _ => ""
  }
}

///|
fn knowledge_tool_building(tool : EnergyTool) -> Bool {
  match tool {
    ResearchTowerTool | LaboratoryTool | WorkshopTool => true
    _ => false
  }
}

///|
fn knowledge_local_post_id(building_id : String) -> String {
  "mine-site-\{building_id}"
}

///|
fn knowledge_building_stable_id(building : GoldenValleyBuilding) -> String? {
  match golden_valley_nonempty_authored_id(building) {
    Some(value) => Some(value)
    None =>
      match building.module_key {
        Some(value) if !value.trim().is_empty() => Some(value.trim().to_owned())
        _ => None
      }
  }
}

///|
fn knowledge_local_author(model : Model) -> String {
  match model.player {
    Some(player) => player.name
    None => "我"
  }
}

///|
fn knowledge_custom_building_accepts_topic(
  building : GoldenValleyBuilding,
) -> Bool {
  building.module_key is None &&
  (match building.style {
    "custom-tower" | "custom-lab" | "custom-hall" => true
    _ => false
  })
}

///|
fn knowledge_building_has_topic(
  model : Model,
  building : GoldenValleyBuilding,
) -> Bool {
  let stable_id = knowledge_building_stable_id(building)
  let legacy_matches = model.posts.filter(post => {
    post.mine && post.building_id is None && post.building_name == building.name
  })
  let legacy_buildings = energy_valley_model_buildings(model).filter(candidate => {
    candidate.name == building.name
  })
  model.posts.any(post => {
    post.mine &&
    (match (post.building_id, stable_id) {
      (Some(post_id), Some(building_id)) => post_id == building_id
      (None, _) =>
        legacy_matches.length() == 1 &&
        legacy_buildings.length() == 1 &&
        post.building_name == building.name
      _ => false
    }) &&
    !post.topic.trim().is_empty()
  })
}

///|
fn knowledge_pending_buildings(model : Model) -> Array[GoldenValleyBuilding] {
  energy_valley_model_buildings(model).filter(building => {
    knowledge_custom_building_accepts_topic(building) &&
    !knowledge_building_has_topic(model, building)
  })
}

///|
fn knowledge_posts_after_demolition(
  posts : Array[KnowledgePost],
  removed_buildings : Array[GoldenValleyBuilding],
  all_buildings : Array[GoldenValleyBuilding],
) -> Array[KnowledgePost] {
  posts.filter(post => {
    !removed_buildings.any(building => {
      let stable_id = knowledge_building_stable_id(building)
      match post.building_id {
        Some(post_building_id) => stable_id == Some(post_building_id)
        None => {
          // Legacy display-name fallback is permitted only when both the post
          // and physical building are unique. Ambiguous same-name state is
          // never guessed or destructively deleted.
          let expected_name = if post.collected {
            knowledge_collected_building_name(post)
          } else {
            post.building_name
          }
          let matching_posts = posts.filter(candidate => {
            candidate.building_id is None &&
            (if candidate.collected {
              knowledge_collected_building_name(candidate) == expected_name
            } else {
              candidate.building_name == expected_name
            })
          })
          let matching_buildings = all_buildings.filter(candidate => {
            candidate.name == expected_name
          })
          (post.mine || post.collected) &&
          building.name == expected_name &&
          matching_posts.length() == 1 &&
          matching_buildings.length() == 1
        }
      }
    })
  })
}

///|
/// Resetting the physical map invalidates every locally authored building and
/// every collected copy. Uncollected imported/offline entries remain useful
/// square references because they never claimed to occupy a local map lot.
fn knowledge_posts_after_map_reset(
  posts : Array[KnowledgePost],
) -> Array[KnowledgePost] {
  posts.filter(post => !post.mine && !post.collected)
}

///|
fn knowledge_posts_with_draft(
  model : Model,
  building : GoldenValleyBuilding,
) -> Model {
  let stable_id = knowledge_building_stable_id(building)
  if model.posts.any(post => {
      post.mine &&
      (match (post.building_id, stable_id) {
        (Some(post_id), Some(building_id)) => post_id == building_id
        _ => false
      })
    }) {
    return model
  }
  let identity = stable_id.unwrap_or(
    "legacy-\{building.x}-\{building.y}-\{town_life_stable_hash(building.name)}",
  )
  let draft : KnowledgePost = {
    id: knowledge_local_post_id(identity),
    building_id: stable_id,
    incarnation_id: None,
    created_stamp: None,
    updated_stamp: None,
    reset_epoch: model.town_life_post_reset_stamp,
    building_name: building.name,
    topic: "",
    author: knowledge_local_author(model),
    spark: 0,
    published: false,
    collected: false,
    mine: true,
  }
  let (stamped, draft) = town_life_new_post_incarnation(
    model,
    draft,
    stable_id.unwrap_or(""),
  )
  { ..stamped, posts: stamped.posts + [draft] }
}

///|
/// Detect a just-placed knowledge building after a canvas click and open the
/// topic dialog for it. A durable empty draft makes closing the dialog
/// recoverable from the square instead of stranding onboarding state.
fn knowledge_maybe_prompt_for_new_building(
  before : Model,
  after : Model,
) -> Model {
  if !knowledge_tool_building(before.energy_tool) {
    return after
  }
  let after_buildings = energy_valley_model_buildings(after)
  if after_buildings.length() <= energy_valley_model_buildings(before).length() {
    return after
  }
  let building = after_buildings[after_buildings.length() - 1]
  let drafted = knowledge_posts_with_draft(after, building)
  let next = {
    ..drafted,
    knowledge_dialog_open: true,
    knowledge_target_building: building.name,
    knowledge_target_site_id: knowledge_building_stable_id(building).unwrap_or(
      "",
    ),
    knowledge_draft_topic: "",
  }
  let next = track_event(next, "build_place", building.name)
  complete_quest(next, "build-knowledge")
}

///|
fn knowledge_post_matches_dialog_target(
  model : Model,
  post : KnowledgePost,
) -> Bool {
  if !post.mine {
    return false
  }
  if !model.knowledge_target_site_id.is_empty() {
    return post.building_id == Some(model.knowledge_target_site_id)
  }
  let matching_posts = model.posts.filter(candidate => {
    candidate.mine &&
    candidate.building_id is None &&
    candidate.building_name == model.knowledge_target_building
  })
  let matching_buildings = energy_valley_model_buildings(model).filter(building => {
    building.name == model.knowledge_target_building
  })
  matching_posts.length() == 1 &&
  matching_buildings.length() == 1 &&
  post.building_id is None &&
  post.building_name == model.knowledge_target_building
}

///|
fn knowledge_open_dialog_model(model : Model, post_id : String) -> Model {
  match knowledge_stored_post(model, post_id) {
    Some(post) if post.mine =>
      {
        ..model,
        knowledge_dialog_open: true,
        knowledge_target_building: post.building_name,
        knowledge_target_site_id: post.building_id.unwrap_or(""),
        knowledge_draft_topic: post.topic,
      }
    _ => model
  }
}

///|
fn knowledge_confirm_topic_model(model : Model) -> Model {
  let topic = model.knowledge_draft_topic.trim().to_owned()
  if topic.is_empty() {
    return {
      ..model,
      knowledge_dialog_open: true,
      life_toast: "请先填写知识主题；也可以点「稍后再说」，之后从广场继续设置。",
      life_toast_tick: model.tick,
    }
  }
  let author = knowledge_local_author(model)
  let found = model.posts.any(post => {
    knowledge_post_matches_dialog_target(model, post)
  })
  let posts = model.posts.map(post => {
    if knowledge_post_matches_dialog_target(model, post) {
      {
        ..post,
        topic,
        author,
        spark: if post.spark < 12 {
          12
        } else {
          post.spark
        },
        published: false,
      }
    } else {
      post
    }
  })
  let updated = if found {
    let incarnation = posts.filter(post => {
      knowledge_post_matches_dialog_target(model, post)
    })[0].incarnation_id.unwrap_or("")
    town_life_touch_post({ ..model, posts, }, incarnation)
  } else {
    let identity = if model.knowledge_target_site_id.is_empty() {
      "legacy-dialog-\{town_life_stable_hash(model.knowledge_target_building)}"
    } else {
      model.knowledge_target_site_id
    }
    let draft : KnowledgePost = {
      id: knowledge_local_post_id(identity),
      building_id: if model.knowledge_target_site_id.is_empty() {
        None
      } else {
        Some(model.knowledge_target_site_id)
      },
      incarnation_id: None,
      created_stamp: None,
      updated_stamp: None,
      reset_epoch: model.town_life_post_reset_stamp,
      building_name: model.knowledge_target_building,
      topic,
      author,
      spark: 12,
      published: false,
      collected: false,
      mine: true,
    }
    let (stamped, draft) = town_life_new_post_incarnation(
      model,
      draft,
      model.knowledge_target_site_id,
    )
    { ..stamped, posts: stamped.posts + [draft] }
  }
  let next = {
    ..updated,
    knowledge_dialog_open: false,
    knowledge_draft_topic: "",
    life_toast: "📚 「\{model.knowledge_target_building}」已注入主题：\{topic}",
    life_toast_tick: model.tick,
  }
  let next = track_event(
    next,
    "knowledge_topic",
    model.knowledge_target_building,
  )
  complete_quest(next, "build-knowledge")
}

///|
fn knowledge_share_link(model : Model, post : KnowledgePost) -> String {
  ignore(model)
  browser_knowledge_share_url(
    post.id,
    post.building_name,
    post.topic,
    post.author,
  )
}

///|
fn knowledge_share_card_text(post : KnowledgePost) -> String {
  "《\{post.topic}》\n知识大楼：\{post.building_name}\n共建者：\{post.author}"
}

///|
fn knowledge_publish_model(model : Model, post_id : String) -> Model {
  match knowledge_stored_post(model, post_id) {
    None => return model
    Some(post) if !post.mine => return model
    Some(post) if post.mine && post.topic.trim().is_empty() =>
      return {
        ..model,
        knowledge_dialog_open: true,
        knowledge_target_building: post.building_name,
        knowledge_target_site_id: post.building_id.unwrap_or(""),
        life_toast: "先为这栋楼设置知识主题，再生成分享链接。",
        life_toast_tick: model.tick,
      }
    _ => ()
  }
  let posts = model.posts.map(post => {
    if post.id == post_id && post.mine {
      {
        ..post,
        published: true,
        spark: if post.published {
          post.spark
        } else {
          post.spark + 20
        },
      }
    } else {
      post
    }
  })
  for post in posts {
    if post.id == post_id {
      let updated = town_life_touch_post(
        { ..model, posts, },
        post.incarnation_id.unwrap_or(""),
      )
      let link = knowledge_share_link(model, post)
      let native_share = browser_share_knowledge_card(
        "MoonTown · \{post.building_name}",
        knowledge_share_card_text(post),
        link,
      )
      let next = {
        ..updated,
        life_toast: if native_share {
          "📣 「\{post.building_name}」已在本机标记为可分享；已请求打开系统分享面板，是否完成请以系统提示为准。"
        } else {
          "📣 「\{post.building_name}」已在本机标记为可分享；已请求复制完整分享卡，若浏览器拦截请复制分享网址。"
        },
        life_toast_tick: model.tick,
      }
      let next = track_event(next, "knowledge_publish", post.building_name)
      return complete_quest(next, "publish-knowledge")
    }
  }
  { ..model, posts, }
}

///|
fn knowledge_collected_building_name(post : KnowledgePost) -> String {
  "共建 · \{post.building_name}"
}

///|
fn knowledge_collected_building_key(post : KnowledgePost) -> String {
  let identity = "\{post.id}|\{post.topic}|\{post.author}"
  let mut hash = 17
  for char in identity {
    hash = (hash * 31 + char.to_int()) % 1000003
  }
  "knowledge-copy-\{hash}"
}

///|
fn knowledge_collected_building_style(post : KnowledgePost) -> String {
  let identity = "\{post.building_name} \{post.topic}".to_lower()
  if identity.contains("实验") || identity.contains("lab") {
    "custom-lab"
  } else if identity.contains("工坊") || identity.contains("workshop") {
    "custom-hall"
  } else {
    "custom-tower"
  }
}

///|
fn knowledge_collected_building_floors(post : KnowledgePost) -> Int {
  match knowledge_collected_building_style(post) {
    "custom-tower" => 5
    _ => 2
  }
}

///|
fn knowledge_collected_building_at(
  post : KnowledgePost,
  x : Int,
  y : Int,
) -> GoldenValleyBuilding {
  let scale = energy_valley_semantic_cells_per_planning_cell()
  {
    authored_id: None,
    module_key: Some(knowledge_collected_building_key(post)),
    name: knowledge_collected_building_name(post),
    style: knowledge_collected_building_style(post),
    x,
    y,
    width: 2 * scale,
    depth: 2 * scale,
    entrance_x: None,
    entrance_y: None,
    floors: knowledge_collected_building_floors(post),
  }
}

///|
fn knowledge_has_collected_building(
  model : Model,
  post : KnowledgePost,
) -> Bool {
  let key = knowledge_collected_building_key(post)
  let name = knowledge_collected_building_name(post)
  energy_valley_model_buildings(model).any(building => {
    match post.building_id {
      Some(building_id) =>
        knowledge_building_stable_id(building) == Some(building_id)
      None =>
        building.module_key == Some(key) ||
        (building.module_key is None && building.name == name)
    }
  })
}

///|
/// Find a real, road-accessible map lot using the same Wenyu placement rules
/// as player-built buildings. The deterministic offset spreads consecutive
/// collections instead of filling the same corner first.
fn knowledge_collection_placement(
  model : Model,
  post : KnowledgePost,
) -> GoldenValleyBuilding? {
  let scale = energy_valley_semantic_cells_per_planning_cell()
  let columns = golden_valley_cols() / scale
  let rows = golden_valley_rows() / scale
  let slot_count = columns * rows
  if slot_count <= 0 {
    return None
  }
  let start = (
      post.id.length() * 17 + energy_valley_model_buildings(model).length() * 31
    ) %
    slot_count
  for offset in 0..<slot_count {
    let slot = (start + offset) % slot_count
    let candidate = knowledge_collected_building_at(
      post,
      slot % columns * scale,
      slot / columns * scale,
    )
    if golden_valley_custom_placement_clear(model, candidate) {
      return Some(candidate)
    }
  }
  None
}

///|
fn knowledge_store_collected_post(
  model : Model,
  source : KnowledgePost,
  building : GoldenValleyBuilding,
) -> Model {
  let building_id = knowledge_building_stable_id(building).unwrap_or("")
  let mut previous_spark = source.spark
  for post in model.posts {
    if post.id == source.id && !post.mine {
      previous_spark = previous_spark.max(post.spark)
    }
  }
  let collected : KnowledgePost = {
    ..source,
    building_id: if building_id.is_empty() {
      None
    } else {
      Some(building_id)
    },
    incarnation_id: None,
    created_stamp: None,
    updated_stamp: None,
    reset_epoch: model.town_life_post_reset_stamp,
    collected: true,
    spark: previous_spark + 8,
  }
  let (stamped, collected) = town_life_new_post_incarnation(
    model, collected, building_id,
  )
  {
    ..stamped,
    posts: stamped.posts.filter(post => post.id != source.id || post.mine) +
    [collected],
  }
}

///|
fn knowledge_collect_model(model : Model, post_id : String) -> Model {
  let source = match knowledge_community_post_by_id(model, post_id) {
    Some(post) => post
    None => return model
  }
  if source.mine {
    return model
  }
  if !knowledge_post_can_collect(model, source) {
    return {
      ..model,
      life_toast: knowledge_post_collect_block_reason(model, source),
      life_toast_tick: model.tick,
    }
  }
  if source.collected && knowledge_has_collected_building(model, source) {
    return {
      ..model,
      life_toast: "这栋楼已经收藏并落位在地图上啦",
      life_toast_tick: model.tick,
    }
  }
  match knowledge_collection_placement(model, source) {
    None =>
      {
        ..model,
        life_toast: "收藏未完成：当前没有临路空地。请先整理地块或铺路后重试。",
        life_toast_tick: model.tick,
      }
    Some(building) => {
      let (with_building, identified) = energy_valley_model_add_building_delta_with_identity(
        model,
        building,
        energy_valley_model_budget(model),
        energy_valley_model_next_authored_building_sequence(model),
      )
      let collected = knowledge_store_collected_post(
        with_building, source, identified,
      )
      let next = {
        ..collected,
        energy_selected_building: Some(identified),
        energy_tool: InspectTool,
        energy_toast: "\{identified.name} 已按能源谷临路规则落位",
        life_toast: "🏘️ 已把「\{source.building_name}」放进你的小镇地图！",
        life_toast_tick: model.tick,
      }
      golden_focus_building_camera(
        identified.x.to_double() + identified.width.to_double() / 2.0,
        identified.y.to_double() + identified.depth.to_double() / 2.0,
      )
      let next = track_event(next, "knowledge_collect", source.building_name)
      complete_quest(next, "collect-building")
    }
  }
}

///|
fn collected_count(model : Model) -> Int {
  model.posts.filter(post => post.collected).length()
}

///|
fn render_knowledge_dialog(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  if !model.knowledge_dialog_open {
    return @html.nothing
  }
  div(
    class="absolute inset-0 z-40 flex items-center justify-center bg-slate-950/60 p-4",
    [
      section(
        class="knowledge-dialog pointer-events-auto",
        attrs=@html.Attrs::build()
          .role("dialog")
          .aria_modal("true")
          .aria_labelledby("knowledge-dialog-title"),
        [
          div(
            id="knowledge-dialog-title",
            class="wizard-title",
            "🎉 新楼落成：\{model.knowledge_target_building}",
          ),
          p(
            class="wizard-copy",
            "给它注入一个知识主题吧——主题是这栋楼的灵魂，也是分享链接里的核心内容。现在不填也没关系，之后可从广场的「待完善」列表继续。",
          ),
          input(
            id="knowledge-topic-input",
            class="wizard-input",
            placeholder="例如：多智能体怎样一起写出一本好书",
            value=model.knowledge_draft_topic,
            on_input=value => dispatch(KnowledgeDraftTopic(value)),
          ),
          div(class="wizard-footer", [
            button(
              class="wizard-button-secondary",
              on_click=dispatch(CloseKnowledgeDialog),
              "稍后再说",
            ),
            button(
              class="wizard-button-primary",
              on_click=dispatch(ConfirmKnowledgeTopic),
              "注入主题",
            ),
          ]),
        ],
      ),
    ],
  )
}

///|
fn render_square_post_card(
  dispatch : Dispatch[Msg],
  model : Model,
  post : KnowledgePost,
) -> @rabbita.Html {
  let runtime_state = knowledge_runtime_state_for_post(model, post.id)
  div(class="square-card", [
    div(class="square-card-head", [
      span(class="square-card-building", [
        span(post.building_name),
        span(
          class="square-tag",
          if post.mine {
            "我的大楼"
          } else if runtime_state is Some(state) {
            knowledge_runtime_state_label(state)
          } else if post.id.has_prefix("shared-") {
            "分享链接"
          } else if knowledge_post_is_offline_example(post) {
            "离线示例"
          } else {
            "社区成果"
          },
        ),
      ]),
      span(class="square-card-spark", "✨\{post.spark}"),
    ]),
    div(class="square-card-topic", post.topic),
    div(class="square-card-foot", [
      span(class="square-card-author", "by \{post.author}"),
      if post.mine {
        if post.published {
          span(
            class="square-tag square-tag-published",
            "本机已标记可分享",
          )
        } else {
          button(
            class="square-action",
            on_click=dispatch(PublishBuilding(post.id)),
            "🔗 生成分享链接",
          )
        }
      } else if post.collected {
        span(class="square-tag square-tag-collected", "已收藏 ✓")
      } else if !knowledge_post_can_collect(model, post) {
        span(
          class="square-tag",
          match runtime_state {
            Some(RuntimeReviewEvidence) => "审核完成后可收藏"
            Some(RuntimeInProgressEvidence) => "任务完成后可收藏"
            Some(RuntimeFailedEvidence) => "未完成，不可收藏"
            _ => "暂不可收藏"
          },
        )
      } else {
        button(
          class="square-action",
          on_click=dispatch(CollectBuilding(post.id)),
          "🏘️ 收藏到我的小镇",
        )
      },
      match knowledge_runtime_link_for_post(model, post.id) {
        Some(link) =>
          a(
            class="square-action",
            href=link.url,
            "查看真实\{link.kind} · \{link.label}",
          )
        None => @html.nothing
      },
    ]),
  ])
}

///|
fn render_pending_knowledge_building(
  dispatch : Dispatch[Msg],
  model : Model,
  building : GoldenValleyBuilding,
) -> @rabbita.Html {
  let stable_id = knowledge_building_stable_id(building)
  let mut post_id = ""
  match stable_id {
    Some(building_site) =>
      for post in model.posts {
        if post.mine && post.building_id == Some(building_site) {
          post_id = post.id
        }
      }
    None => {
      let legacy_posts = model.posts.filter(post => {
        post.mine &&
        post.building_id is None &&
        post.building_name == building.name
      })
      let legacy_buildings = energy_valley_model_buildings(model).filter(candidate => {
        candidate.name == building.name
      })
      if legacy_posts.length() == 1 && legacy_buildings.length() == 1 {
        post_id = legacy_posts[0].id
      }
    }
  }
  div(class="square-card", [
    div(class="square-card-head", [
      span(class="square-card-building", [
        span(building.name),
        span(class="square-tag", "待完善"),
      ]),
    ]),
    div(
      class="square-card-topic",
      "楼体已经落位，但还没有知识主题；完成主题后才会生成可分享条目。",
    ),
    div(class="square-card-foot", [
      button(
        class="square-action",
        on_click=dispatch(OpenKnowledgeDialog(post_id)),
        disabled=post_id.is_empty(),
        "📚 继续设置主题",
      ),
    ]),
  ])
}

///|
/// Town square: my buildings to publish, community buildings to collect.
/// This is the co-building hub — every card is someone's knowledge made
/// visible.
fn render_square_panel(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  if !model.square_open {
    return @html.nothing
  }
  let mine = model.posts.filter(post => {
    post.mine && !post.topic.trim().is_empty()
  })
  let pending = knowledge_pending_buildings(model)
  let community = knowledge_community_posts(model)
  let has_runtime = !knowledge_runtime_posts(model).is_empty()
  section(
    class="square-panel pointer-events-auto",
    attrs=@html.Attrs::build().role("dialog").aria_label("小镇广场"),
    [
      div(class="square-panel-head", [
        span(class="square-panel-title", "🏛️ 小镇广场"),
        span(
          class="square-panel-sub",
          "收藏夹 \{collected_count(model)} 座",
        ),
        button(
          class="phone-panel-close",
          on_click=dispatch(ToggleSquare),
          attrs=@html.Attrs::build().aria_label("关闭小镇广场"),
          "✕",
        ),
      ]),
      div(class="square-panel-scroll", [
        if pending.is_empty() {
          @html.nothing
        } else {
          div([
            div(class="square-section-title", "待完善知识大楼"),
            p(
              class="square-empty",
              "这些楼已经保存在地图上，但尚未设置主题；可以随时回来继续。",
            ),
            div(
              class="square-grid",
              pending.map(building => {
                render_pending_knowledge_building(dispatch, model, building)
              }),
            ),
          ])
        },
        div(class="square-section-title", "我的知识大楼"),
        if mine.is_empty() {
          p(
            class="square-empty",
            if pending.is_empty() {
              "还没有自己的大楼。用底部工具坞盖一栋研发塔楼、实验室或创新工坊吧！"
            } else {
              "完成上方待完善楼宇的主题后，可在这里生成分享链接。"
            },
          )
        } else {
          div(
            class="square-grid",
            mine.map(post => render_square_post_card(dispatch, model, post)),
          )
        },
        div(
          class="square-section-title",
          if has_runtime {
            "运行时证据与成果"
          } else {
            "离线共建示例"
          },
        ),
        p(
          class="square-empty",
          if has_runtime {
            "以下卡片来自当前 MoonTown 运行时；完成、待审核、进行中与未完成状态分别标注，只有已完成成果可收藏。"
          } else {
            "尚未发现可核验的运行时成果；以下内容是明确标注的离线示例。"
          },
        ),
        if community.is_empty() {
          p(
            class="square-empty",
            "当前还没有可发布或收藏的知识成果。",
          )
        } else {
          div(
            class="square-grid",
            community.map(post => render_square_post_card(dispatch, model, post)),
          )
        },
      ]),
    ],
  )
}
