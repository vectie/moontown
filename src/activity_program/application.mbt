///|
fn application_defaults(
  id : String,
  actor : String,
  now : UInt64,
) -> Application {
  {
    id,
    actor,
    revision: 0,
    status: "draft",
    title: "",
    topic: "",
    scope: "",
    audience: "",
    proposal: "",
    prize_plan: "",
    contact: "",
    cash_budget_cny: 0,
    requested_instances: 1,
    requested_total_quota: 10,
    requested_participant_quota: 3,
    submitted_revision: 0,
    submitted_hash: "",
    review_note: "",
    created_ms: now,
    updated_ms: now,
  }
}

///|
fn save_application(
  state : Registry,
  payload : Json,
  actor : String,
  now : UInt64,
  template : Template,
) -> (Registry, String) raise {
  let requested = text(payload, "application_id", 64, optional=true)
  let intent = text(payload, "intent", 128)
  let id = if requested.is_empty() {
    hash("application:" + actor + ":" + intent)
  } else {
    requested
  }
  guard valid_activity_id(id) else { raise Invalid("申请编号不可用。") }
  let prior = state.applications.iter().find_first(app => app.id == id)
  let defaults = application_defaults(id, actor, now)
  let base = prior.unwrap_or({
    ..defaults,
    requested_total_quota: defaults.requested_total_quota.min(
      template.max_total_quota,
    ),
    requested_participant_quota: defaults.requested_participant_quota.min(
      template.max_participant_quota,
    ),
  })
  guard base.actor == actor else { raise Denied }
  let expected = integer(payload, "expected_revision", 0, 2147483646)
  let merged = fields(base.to_json())
  for (key, value) in fields(payload) {
    merged[key] = value
  }
  let input = Json::object(merged)
  let candidate : Application = {
    ..base,
    title: text(input, "title", 120),
    topic: text(input, "topic", 200, optional=true),
    scope: text(input, "scope", 2000, optional=true),
    audience: text(input, "audience", 1000, optional=true),
    proposal: text(input, "proposal", 12000, optional=true),
    prize_plan: text(input, "prize_plan", 2000, optional=true),
    contact: text(input, "contact", 500, optional=true),
    cash_budget_cny: integer(
      input,
      "cash_budget_cny",
      0,
      template.max_cash_budget_cny,
    ),
    requested_instances: integer(
      input,
      "requested_instances",
      1,
      template.max_instances,
    ),
    requested_total_quota: integer(
      input,
      "requested_total_quota",
      1,
      template.max_total_quota,
    ),
    requested_participant_quota: integer(
      input,
      "requested_participant_quota",
      1,
      template.max_participant_quota,
    ),
  }
  if prior is Some(_) && requested.is_empty() && expected == 0 {
    if proposal_hash({ ..candidate, submitted_revision: 0, }) ==
      proposal_hash({ ..base, submitted_revision: 0, }) {
      return (state, id)
    }
    raise Conflict("这次申请已保存，请读取最新版本。")
  }
  guard expected == base.revision &&
    ["draft", "changes_requested", "rejected"].contains(base.status) else {
    raise Conflict("申请状态或版本已变化，请刷新后重试。")
  }
  guard prior is Some(_) || state.applications.length() < 1000 else {
    raise Conflict("申请数量已达上限。")
  }
  let saved = {
    ..candidate,
    revision: base.revision + 1,
    status: "draft",
    submitted_revision: 0,
    submitted_hash: "",
    updated_ms: now,
  }
  let applications = state.applications.filter(app => app.id != id) + [saved]
  (
    audit({ ..state, applications, }, "save-application", actor, id, now, ""),
    id,
  )
}

///|
fn submit_application(
  state : Registry,
  payload : Json,
  actor : String,
  now : UInt64,
) -> (Registry, String) raise {
  let id = text(payload, "application_id", 64)
  let app = find_application(state, id)
  guard app.actor == actor else { raise Denied }
  guard app.revision == integer(payload, "expected_revision", 1, 2147483646) &&
    ["draft", "changes_requested"].contains(app.status) else {
    raise Conflict("申请状态或版本已变化。")
  }
  guard [
    app.topic,
    app.scope,
    app.audience,
    app.proposal,
    app.prize_plan,
    app.contact,
  ].all(value => !value.trim().is_empty()) else {
    raise Invalid(
      "请补齐主题、范围、受众、企划、奖品和联系方式后提交。",
    )
  }
  let next = {
    ..app,
    revision: app.revision + 1,
    submitted_revision: app.revision + 1,
    status: "submitted",
    updated_ms: now,
    review_note: "",
  }
  let submitted = { ..next, submitted_hash: proposal_hash(next), }
  let applications = state.applications.map(value => {
    if value.id == id {
      submitted
    } else {
      value
    }
  })
  (
    audit(
      { ..state, applications, },
      "submit-application",
      actor,
      id,
      now,
      submitted.submitted_hash,
    ),
    id,
  )
}

///|
fn review_application(
  state : Registry,
  payload : Json,
  actor : String,
  owner : Bool,
  now : UInt64,
  template : Template,
) -> (Registry, String) raise {
  guard owner else { raise Denied }
  let id = text(payload, "application_id", 64)
  let app = find_application(state, id)
  guard app.status == "submitted" &&
    app.revision == integer(payload, "expected_revision", 1, 2147483646) &&
    app.submitted_hash == proposal_hash(app) else {
    raise Conflict("申请状态或版本已变化。")
  }
  let decision = text(payload, "decision", 40)
  guard ["approve", "request-changes", "reject"].contains(decision) else {
    raise Invalid("审核决定不可用。")
  }
  let note = text(payload, "note", 2000, optional=decision == "approve")
  let grants = state.grants.copy()
  if decision == "approve" {
    guard !grants.any(grant => grant.application_id == id) &&
      grants.length() < template.max_grants else {
      raise Conflict("已存在授权或授权数量达到上限。")
    }
    let starts_ms = millis(payload, "starts_ms")
    let ends_ms = millis(payload, "ends_ms")
    guard starts_ms < ends_ms &&
      now < ends_ms &&
      ends_ms - starts_ms <= 31622400000UL else {
      raise Invalid("请检查授权有效期。")
    }
    let max_instances = integer(
      payload,
      "max_instances",
      1,
      app.requested_instances,
    )
    let total_generation_quota = integer(
      payload,
      "total_generation_quota",
      1,
      app.requested_total_quota,
    )
    let per_event_quota = integer(
      payload,
      "per_event_quota",
      1,
      total_generation_quota.min(template.max_event_quota),
    )
    let participant_quota = integer(
      payload,
      "participant_quota",
      1,
      app.requested_participant_quota.min(per_event_quota),
    )
    let cash_budget_cny = if fields(payload).contains("cash_budget_cny") {
      integer(payload, "cash_budget_cny", 0, app.cash_budget_cny)
    } else {
      app.cash_budget_cny
    }
    guard grants.fold(init=0, (sum, grant) => sum + grant.total_generation_quota) +
      total_generation_quota <=
      template.max_total_quota &&
      grants.fold(init=0, (sum, grant) => sum + grant.cash_budget_cny) +
      cash_budget_cny <=
      template.max_cash_budget_cny else {
      raise Conflict("可审批的总算力或现金预算不足。")
    }
    grants.push({
      id: hash("grant:" + id + ":" + app.submitted_hash),
      application_id: id,
      organizer_id: app.actor,
      approved_revision: app.submitted_revision,
      approved_hash: app.submitted_hash,
      approved_by: actor,
      approved_ms: now,
      starts_ms,
      ends_ms,
      max_instances,
      total_generation_quota,
      per_event_quota,
      participant_quota,
      cash_budget_cny,
      allow_publish: bool(payload, "allow_publish"),
      template_id: template.template_id,
      template_version: template.template_version,
      template_hash: template.template_hash,
      status: "active",
      reason: "",
    })
  }
  let reviewed = {
    ..app,
    revision: app.revision + 1,
    status: if decision == "approve" {
      "approved"
    } else if decision == "request-changes" {
      "changes_requested"
    } else {
      "rejected"
    },
    review_note: note,
    updated_ms: now,
  }
  let applications = state.applications.map(value => {
    if value.id == id {
      reviewed
    } else {
      value
    }
  })
  (
    audit(
      { ..state, applications, grants, },
      "review-application:" + decision,
      actor,
      id,
      now,
      note,
    ),
    id,
  )
}
