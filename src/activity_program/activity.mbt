///|
fn create_activity(
  state : Registry,
  payload : Json,
  actor : String,
  now : UInt64,
  template : Template,
) -> (Registry, String) raise {
  let application_id = text(payload, "application_id", 64)
  let app = find_application(state, application_id)
  let grant = find_grant(state, application_id)
  guard app.actor == actor && app.status == "approved" else { raise Denied }
  guard grant.approved_hash == app.submitted_hash &&
    grant.approved_revision == app.submitted_revision &&
    grant.template_hash == template.template_hash else {
    raise Conflict(
      "批准的方案或模板版本已变化，请联系审批人。",
    )
  }
  let intent = text(payload, "intent", 128)
  let id = hash("activity:" + application_id + ":" + intent)
  let opens_ms = millis(payload, "opens_ms")
  let deadline_ms = millis(payload, "deadline_ms")
  let voting_opens_ms = millis(payload, "voting_opens_ms")
  let voting_closes_ms = millis(payload, "voting_closes_ms")
  let awards_ms = millis(payload, "awards_ms")
  guard opens_ms >= grant.starts_ms &&
    opens_ms < deadline_ms &&
    deadline_ms <= voting_opens_ms &&
    voting_opens_ms < voting_closes_ms &&
    voting_closes_ms <= awards_ms &&
    awards_ms <= grant.ends_ms else {
    raise Invalid(
      "赛程需在批准的有效期内，且截止、投票和开奖顺序正确。",
    )
  }
  let event_quota = integer(payload, "event_quota", 1, grant.per_event_quota)
  let participant_quota = integer(
    payload,
    "participant_quota",
    1,
    grant.participant_quota.min(event_quota),
  )
  let cash_budget_cny = if fields(payload).contains("cash_budget_cny") {
    integer(payload, "cash_budget_cny", 0, grant.cash_budget_cny)
  } else {
    0
  }
  let title = text(payload, "title", 120)
  let topic = text(payload, "topic", 200)
  let scope = text(payload, "scope", 2000)
  let first_person_solution = text(payload, "first_person_solution", 2000)
  let prize_plan = text(payload, "prize_plan", 2000)
  let dossier : Json = {
    "schema": "moontown.activity-launch.v1",
    "activity_id": id,
    "application_id": application_id,
    "approved_revision": grant.approved_revision,
    "approved_hash": grant.approved_hash,
    "organizer_id": actor,
    "template_id": template.template_id,
    "template_version": template.template_version,
    "title": title,
    "topic": topic,
    "scope": scope,
    "first_person_solution": first_person_solution,
    "prize_plan": prize_plan,
    "cash_budget_cny": cash_budget_cny,
    "opens_ms": opens_ms,
    "deadline_ms": deadline_ms,
    "voting_opens_ms": voting_opens_ms,
    "voting_closes_ms": voting_closes_ms,
    "awards_ms": awards_ms,
    "event_quota": event_quota,
    "participant_quota": participant_quota,
    "model": template.model,
    "book_id": template.book_id,
    "book_version": template.book_version,
    "curator_profile": template.curator_profile,
    "workflow_id": template.workflow_id,
    "workflow_version": template.workflow_version,
  }
  let dossier_json = dossier.stringify()
  let blueprint_hash = hash(dossier_json)
  if state.activities.iter().find_first(activity => activity.id == id)
    is Some(existing) {
    guard existing.organizer_id == actor &&
      existing.blueprint_hash == blueprint_hash else {
      raise Conflict(
        "此创建请求已存在，请查看原活动或使用新的创建请求。",
      )
    }
    return (state, id)
  }
  guard grant_live(grant, now) else { raise Denied }
  guard now < deadline_ms else {
    raise Invalid("这场活动的投稿截止时间已过。")
  }
  let reserved = state.activities.filter(activity => {
    activity.application_id == application_id
  })
  guard reserved.length() < grant.max_instances &&
    reserved.fold(init=0, (sum, activity) => sum + activity.event_quota) +
    event_quota <=
    grant.total_generation_quota &&
    reserved.fold(init=0, (sum, activity) => sum + activity.cash_budget_cny) +
    cash_budget_cny <=
    grant.cash_budget_cny else {
    raise Conflict(
      "本方案剩余活动次数、算力或现金预算不足。",
    )
  }
  let activity : Activity = {
    id,
    application_id,
    organizer_id: actor,
    intent,
    blueprint_hash,
    status: "preparing",
    reason: "正在准备活动资料与资源。",
    title,
    topic,
    scope,
    first_person_solution,
    prize_plan,
    opens_ms,
    deadline_ms,
    voting_opens_ms,
    voting_closes_ms,
    awards_ms,
    event_quota,
    participant_quota,
    cash_budget_cny,
    template_json: template.raw.stringify(),
    dossier_json,
    config_sha256: "",
    binding_json: "{}",
    prepare_attempts: 0,
    published_ms: 0UL,
    created_ms: now,
    updated_ms: now,
  }
  (
    audit(
      { ..state, activities: state.activities + [activity], },
      "create-activity",
      actor,
      id,
      now,
      blueprint_hash,
    ),
    id,
  )
}

///|
fn control_activity(
  state : Registry,
  action : String,
  payload : Json,
  actor : String,
  owner : Bool,
  now : UInt64,
) -> (Registry, String) raise {
  let id = text(payload, "activity_id", 64)
  let activity = find_activity(state, id)
  let grant = find_grant(state, activity.application_id)
  guard owner || (activity.organizer_id == actor && grant_live(grant, now)) else {
    raise Denied
  }
  guard grant_live(grant, now) else {
    raise Conflict("授权已撤销或过期，不能恢复生成和发布。")
  }
  let status = match action {
    "publish-activity" => {
      guard activity.status == "ready" && (owner || grant.allow_publish) else {
        raise Conflict("活动尚未就绪或没有自行发布权限。")
      }
      "published"
    }
    "pause-activity" => {
      guard activity.status == "published" else {
        raise Conflict("当前活动不能暂停。")
      }
      "paused"
    }
    "resume-activity" => {
      guard activity.status == "paused" else {
        raise Conflict("当前活动不能恢复。")
      }
      "published"
    }
    "retry-activity" => {
      guard activity.status == "failed" else {
        raise Conflict("当前活动不需要重试准备。")
      }
      "preparing"
    }
    _ => raise Invalid("活动操作不存在。")
  }
  let changed = {
    ..activity,
    status,
    published_ms: if status == "published" && activity.published_ms == 0UL {
      now
    } else {
      activity.published_ms
    },
    reason: if status == "preparing" {
      "正在重新准备，保留原活动与已预留额度。"
    } else {
      ""
    },
    updated_ms: now,
  }
  let activities = state.activities.map(value => {
    if value.id == id {
      changed
    } else {
      value
    }
  })
  (audit({ ..state, activities, }, action, actor, id, now, ""), id)
}

///|
fn revoke_grant(
  state : Registry,
  payload : Json,
  actor : String,
  owner : Bool,
  now : UInt64,
) -> (Registry, String) raise {
  guard owner else { raise Denied }
  let id = text(payload, "application_id", 64)
  let grant = find_grant(state, id)
  let reason = text(payload, "reason", 2000)
  if grant.status == "revoked" {
    return (state, id)
  }
  let grants = state.grants.map(value => {
    if value.id == grant.id {
      { ..value, status: "revoked", reason, }
    } else {
      value
    }
  })
  let activities = state.activities.map(value => {
    if value.application_id == id {
      {
        ..value,
        status: "revoked",
        reason: "活动授权已撤销。",
        updated_ms: now,
      }
    } else {
      value
    }
  })
  (
    audit(
      { ..state, grants, activities, },
      "revoke-grant",
      actor,
      id,
      now,
      reason,
    ),
    id,
  )
}

///|
fn activity_config(activity : Activity) -> String raise {
  let config = fields(@json.parse(activity.template_json))
  let brief = fields(config.get("brief").unwrap_or(Json::object({})))
  brief["id"] = Json::string(activity.id)
  brief["name"] = Json::string(activity.title)
  brief["topic"] = Json::string(activity.topic)
  brief["scope"] = Json::string(activity.scope)
  brief["first_person_solution"] = Json::string(activity.first_person_solution)
  brief["deadline_ms"] = Json::string(activity.deadline_ms.to_string())
  brief["published"] = Json::boolean(true)
  config["brief"] = Json::object(brief)
  config["opens_ms"] = Json::string(activity.opens_ms.to_string())
  config["voting_opens_ms"] = Json::string(activity.voting_opens_ms.to_string())
  config["voting_closes_ms"] = Json::string(
    activity.voting_closes_ms.to_string(),
  )
  config["awards_ms"] = Json::string(activity.awards_ms.to_string())
  config["event_quota"] = Json::number(activity.event_quota.to_double())
  config["participant_quota"] = Json::number(
    activity.participant_quota.to_double(),
  )
  config["manager_account_ids"] = Json::array([])
  ignore(config.remove("participant_account_ids"))
  config["voting_mode"] = Json::string("builtin")
  config["prize_plan"] = Json::string(activity.prize_plan)
  Json::object(config).stringify()
}
