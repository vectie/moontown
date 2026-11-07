///|
fn find_application(state : Registry, id : String) -> Application raise {
  guard state.applications.iter().find_first(app => app.id == id) is Some(app) else {
    raise Invalid("活动申请不存在。")
  }
  app
}

///|
fn find_grant(state : Registry, application_id : String) -> Grant raise {
  guard state.grants
    .iter()
    .find_first(grant => grant.application_id == application_id)
    is Some(grant) else {
    raise Denied
  }
  grant
}

///|
fn find_activity(state : Registry, id : String) -> Activity raise {
  guard state.activities.iter().find_first(activity => activity.id == id)
    is Some(activity) else {
    raise Invalid("活动不存在。")
  }
  activity
}

///|
fn grant_live(grant : Grant, now : UInt64) -> Bool {
  grant.status == "active" && now >= grant.starts_ms && now < grant.ends_ms
}

///|
fn grant_projection(grant : Grant, state : Registry) -> Json {
  let reserved = state.activities.filter(activity => {
    activity.application_id == grant.application_id
  })
  let image_quota = reserved.fold(init=0, (sum, activity) => {
    sum + activity.event_quota
  })
  let cash = reserved.fold(init=0, (sum, activity) => {
    sum + activity.cash_budget_cny
  })
  let result = grant.to_json()
  let map = fields(result)
  // The approved template hash is public audit evidence; template bytes stay private.
  map["remaining_instances"] = Json::number(
    (grant.max_instances - reserved.length()).max(0).to_double(),
  )
  map["remaining_generation_quota"] = Json::number(
    (grant.total_generation_quota - image_quota).max(0).to_double(),
  )
  map["remaining_cash_budget_cny"] = Json::number(
    (grant.cash_budget_cny - cash).max(0).to_double(),
  )
  result
}

///|
fn clean_binding(raw : String) -> Json {
  let parsed = @json.parse(raw) catch { _ => Json::object({}) }
  let input = fields(parsed)
  let output : Map[String, Json] = Map([])
  for
    key in [
      "ready", "book_id", "book_version", "source_book_id", "source_bundle_digest",
      "launch_digest", "curator_profile", "profile_digest", "agent_state", "workflow_id",
      "workflow_version",
    ] {
    if input.get(key) is Some(value) {
      match value {
        String(text) if text.length() <= 512 && !text.has_prefix("/") =>
          output[key] = value
        True | False if key == "ready" => output[key] = value
        _ => ()
      }
    }
  }
  Json::object(output)
}

///|
fn public_blueprint(activity : Activity) -> Json {
  {
    "id": activity.id,
    "application_id": activity.application_id,
    "title": activity.title,
    "topic": activity.topic,
    "scope": activity.scope,
    "first_person_solution": activity.first_person_solution,
    "prize_plan": activity.prize_plan,
    "status": activity.status,
    "reason": activity.reason,
    "opens_ms": activity.opens_ms,
    "deadline_ms": activity.deadline_ms,
    "voting_opens_ms": activity.voting_opens_ms,
    "voting_closes_ms": activity.voting_closes_ms,
    "awards_ms": activity.awards_ms,
    "event_quota": activity.event_quota,
    "participant_quota": activity.participant_quota,
    "binding": clean_binding(activity.binding_json),
  }
}

///|
fn activity_projection(
  activity : Activity,
  state : Registry,
  actor : String?,
  owner : Bool,
  now : UInt64,
) -> Json {
  let result = public_blueprint(activity)
  let grant = state.grants
    .iter()
    .find_first(g => g.application_id == activity.application_id)
  fields(result)["may_manage"] = Json::boolean(
    owner ||
    (
      actor == Some(activity.organizer_id) &&
      grant.map(g => grant_live(g, now)).unwrap_or(false)
    ),
  )
  fields(result)["may_publish"] = Json::boolean(
    activity.status == "ready" &&
    grant
    .map(g => {
      grant_live(g, now) &&
      (owner || (actor == Some(activity.organizer_id) && g.allow_publish))
    })
    .unwrap_or(false),
  )
  fields(result)["allow_generation"] = Json::boolean(
    activity.status == "published" &&
    grant.map(g => grant_live(g, now)).unwrap_or(false),
  )
  if owner || actor == Some(activity.organizer_id) {
    fields(result)["cash_budget_cny"] = Json::number(
      activity.cash_budget_cny.to_double(),
    )
    fields(result)["prepare_attempts"] = Json::number(
      activity.prepare_attempts.to_double(),
    )
  }
  result
}

///|
fn snapshot(
  state : Registry,
  template : Template,
  now : UInt64,
  actor : String?,
  owner : Bool,
) -> Json {
  let applications = state.applications.filter(app => {
    actor == Some(app.actor) || (owner && app.status != "draft")
  })
  let activities = state.activities.filter(activity => {
    actor == Some(activity.organizer_id) ||
    owner ||
    (
      activity.published_ms > 0UL &&
      ["published", "paused", "revoked"].contains(activity.status)
    )
  })
  {
    "revision": state.revision,
    "server_ms": now,
    "viewer": { "account_id": actor.unwrap_or(""), "owner": owner },
    "template": {
      "id": template.template_id,
      "name": "每周咖啡创作",
      "version": template.template_version,
      "book_id": template.book_id,
      "book_version": template.book_version,
      "curator_profile": template.curator_profile,
      "workflow_id": template.workflow_id,
      "workflow_version": template.workflow_version,
      "max_instances": template.max_instances,
      "max_total_quota": template.max_total_quota,
      "max_event_quota": template.max_event_quota,
      "max_participant_quota": template.max_participant_quota,
      "max_cash_budget_cny": template.max_cash_budget_cny,
      "max_grants": template.max_grants,
    },
    "applications": applications.map(app => {
      let result = app.to_json()
      fields(result)["grant"] = state.grants
        .iter()
        .find_first(g => g.application_id == app.id)
        .map(g => grant_projection(g, state))
        .unwrap_or(Json::null())
      result
    }),
    "activities": activities.map(activity => {
      activity_projection(activity, state, actor, owner, now)
    }),
    "audit": if owner {
      state.audit.map(event => event.to_json())
    } else {
      state.audit
      .filter(event => {
        applications.any(app => app.id == event.target) ||
        activities.any(activity => {
          activity.id == event.target && actor == Some(activity.organizer_id)
        })
      })
      .map(event => event.to_json())
    },
  }
}
