///|
pub fn account_state_schema() -> String {
  "moontown.account-store.v2"
}

///|
pub fn empty_account_state() -> AccountState {
  {
    schema: account_state_schema(),
    principals: [],
    sessions: [],
    subscriptions: [],
    audit_events: [],
    version: 1,
  }
}

///|
/// Upgrade the original account store without discarding installed sessions.
fn migrate_account_state_json(value : Json) -> Json {
  guard value is Object(fields) else { return value }
  match fields.get("schema") {
    Some(String("moontown.account-store.v1")) =>
      fields["schema"] = account_state_schema().to_json()
    _ => ()
  }
  if fields.get("subscriptions") is None {
    fields["subscriptions"] = Json::array([])
  }
  if fields.get("audit_events") is None {
    fields["audit_events"] = Json::array([])
  }
  Json::object(fields)
}

///|
/// v1 allowed an enterprise plan to leak into the personal billing field.
/// Enterprise authority is tenant-scoped in v2, so retain the paid personal
/// workspace while preserving all tenant access during migration.
fn normalize_account_state(state : AccountState) -> AccountState {
  let principals = state.principals.map(principal => {
    if principal.personal_plan == EnterprisePlan {
      { ..principal, personal_plan: PaidPlan }
    } else {
      principal
    }
  })
  let subscriptions = state.subscriptions.map(subscription => {
    let mut plan = if subscription.plan == EnterprisePlan {
      PaidPlan
    } else {
      subscription.plan
    }
    for principal in principals {
      if principal.user_id == subscription.principal_id {
        plan = principal.personal_plan
      }
    }
    { ..subscription, plan, }
  })
  { ..state, principals, subscriptions }
}

///|
fn optional_account_string_projection(value : String?) -> Json {
  match value {
    Some(text) => text.to_json()
    None => Json::null()
  }
}

///|
pub fn account_context_projection(context : AccountContext) -> Json {
  let tenant_choices : Array[Json] = context.tenant_choices.map(access => {
    "tenant_id": access.tenant_id,
    "tenant_name": access.tenant_name,
    "plan": account_plan_name(access.plan),
    "roles": access.roles.map(account_role_name),
  })
  {
    "contract_id": "moontown.account-context.v1",
    "user_id": context.user_id,
    "display_name": context.display_name,
    "account_kind": account_kind_name(context.account_kind),
    "plan": account_plan_name(context.plan),
    "roles": context.roles.map(account_role_name).to_json(),
    "entitlements": context.entitlements.map(account_entitlement_name).to_json(),
    "active_tenant_id": optional_account_string_projection(
      context.active_tenant_id,
    ),
    "active_tenant_name": optional_account_string_projection(
      context.active_tenant_name,
    ),
    "tenant_choices": tenant_choices,
    "home_surface": account_home_surface_name(context.home_surface),
    "visitor": context.visitor,
  }
}
