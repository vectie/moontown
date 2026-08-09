///|
pub fn account_state_schema() -> String {
  "moontown.account-store.v1"
}

///|
pub fn empty_account_state() -> AccountState {
  { schema: account_state_schema(), principals: [], sessions: [], version: 1 }
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
