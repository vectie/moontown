///|
fn account_context_or_fail(
  state : AccountState,
  opaque_token : String,
  now_ms : UInt64,
) -> AccountContext raise {
  account_context_for_session(state, opaque_token, now_ms~).unwrap_or_else(() => {
    fail("missing, expired, or revoked account session")
  })
}

///|
fn account_principal_or_fail(
  state : AccountState,
  principal_id : String,
) -> AccountPrincipal raise {
  account_principal_record_by_id(state, principal_id).unwrap_or_else(() => {
    fail("account principal does not exist")
  })
}

///|
fn require_management_entitlement(
  state : AccountState,
  opaque_token : String,
  entitlement : AccountEntitlement,
  now_ms : UInt64,
) -> AccountContext raise {
  let context = account_context_or_fail(state, opaque_token, now_ms)
  if !context.has_entitlement(entitlement) {
    fail("account management entitlement is required")
  }
  context
}

///|
fn replace_account_principal(
  state : AccountState,
  replacement : AccountPrincipal,
) -> AccountState {
  let principals = state.principals.filter(principal => {
    principal.user_id != replacement.user_id
  })
  principals.push(replacement)
  { ..state, principals, version: state.version + 1 }
}

///|
fn append_account_audit(
  state : AccountState,
  actor_id : String,
  action : String,
  target_id : String,
  detail : String,
  now_ms : UInt64,
) -> AccountState {
  let audit_events = state.audit_events.copy()
  audit_events.push({
    event_id: "audit:\{now_ms}:\{state.version + 1}",
    actor_id,
    action,
    target_id,
    detail,
    occurred_at_ms: now_ms,
    version: state.version + 1,
  })
  while audit_events.length() > 500 {
    ignore(audit_events.remove(0))
  }
  { ..state, audit_events, version: state.version + 1 }
}

///|
fn update_account_subscription(
  state : AccountState,
  principal_id : String,
  plan : AccountPlan,
  status : String,
  now_ms : UInt64,
) -> AccountState {
  let subscriptions = state.subscriptions.filter(subscription => {
    subscription.principal_id != principal_id
  })
  subscriptions.push({
    principal_id,
    plan,
    status,
    changed_at_ms: now_ms,
    version: state.version + 1,
  })
  { ..state, subscriptions, version: state.version + 1 }
}

///|
fn subscription_for_principal(
  state : AccountState,
  principal_id : String,
) -> AccountSubscription? {
  for subscription in state.subscriptions {
    if subscription.principal_id == principal_id {
      return Some(subscription)
    }
  }
  None
}

///|
fn account_subscription_projection(
  state : AccountState,
  context : AccountContext,
) -> Json {
  let status = subscription_for_principal(state, context.user_id)
    .map(subscription => subscription.status)
    .unwrap_or(if context.plan == VisitorPlan { "inactive" } else { "active" })
  {
    "contract_id": "moontown.account-billing.v1",
    "account_kind": account_kind_name(context.account_kind),
    "plan": account_plan_name(context.plan),
    "status": status,
    "can_upgrade": context.account_kind == VisitorAccount,
    "can_cancel": context.account_kind == PaidUserAccount,
    "managed_by_organization": context.account_kind == EnterpriseAccount,
  }
}

///|
fn account_principal_projection(principal : AccountPrincipal) -> Json {
  let context = account_context_for(
    principal,
    first_active_tenant_id(principal),
  )
  {
    "user_id": principal.user_id,
    "display_name": principal.display_name,
    "account_kind": account_kind_name(context.account_kind),
    "personal_plan": account_plan_name(principal.personal_plan),
    "platform_roles": principal.platform_roles.map(account_role_name).to_json(),
    "tenant_count": principal.tenant_access.count_if(access => access.active),
    "active": principal.active,
    "version": principal.version,
  }
}

///|
fn tenant_member_projection(
  principal : AccountPrincipal,
  access : AccountTenantAccess,
) -> Json {
  {
    "user_id": principal.user_id,
    "display_name": principal.display_name,
    "roles": access.roles.map(account_role_name).to_json(),
    "active": principal.active && access.active,
    "version": access.version,
  }
}

///|
fn principal_for_account_kind(
  user_id : String,
  display_name : String,
  account_kind : String,
  tenant_id : String,
  tenant_name : String,
) -> AccountPrincipal raise {
  if !valid_account_id(user_id) || display_name.trim().is_empty() {
    fail("account identity is invalid")
  }
  let normalized_kind = account_kind.trim().to_lower()
  let (personal_plan, platform_roles, tenant_access) = match normalized_kind {
    "visitor" => (VisitorPlan, [AccountMember], [])
    "paid-user" | "paid" => (PaidPlan, [AccountMember], [])
    "enterprise" => {
      if !valid_account_id(tenant_id) || tenant_name.trim().is_empty() {
        fail("enterprise accounts require a valid tenant")
      }
      (
        PaidPlan,
        [AccountMember],
        [
          {
            tenant_id,
            tenant_name: tenant_name.trim().to_owned(),
            plan: EnterprisePlan,
            roles: [AccountMember, OrganizationAdmin],
            active: true,
            version: 1,
          },
        ],
      )
    }
    "admin" => (PaidPlan, [AccountMember, PlatformAdmin], [])
    _ => fail("account_kind must be visitor, paid-user, enterprise, or admin")
  }
  {
    user_id,
    display_name: display_name.trim().to_owned(),
    personal_plan,
    platform_roles,
    tenant_access,
    active: true,
    version: 1,
  }
}

///|
pub async fn AccountApplication::billing_snapshot(
  self : AccountApplication,
  opaque_token : String,
  now_ms~ : UInt64,
) -> Json {
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  let state = self.prune_state(self.load_state(), now_ms)
  account_subscription_projection(
    state,
    account_context_or_fail(state, opaque_token, now_ms),
  )
}

///|
pub async fn AccountApplication::set_paid_subscription(
  self : AccountApplication,
  opaque_token : String,
  active : Bool,
  now_ms~ : UInt64,
) -> AccountContext {
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  let state = self.prune_state(self.load_state(), now_ms)
  let context = account_context_or_fail(state, opaque_token, now_ms)
  if context.account_kind == AdminAccount ||
    context.account_kind == EnterpriseAccount {
    fail("organization and administrator billing is managed separately")
  }
  let principal = account_principal_or_fail(state, context.user_id)
  let updated = {
    ..principal,
    personal_plan: if active {
      PaidPlan
    } else {
      VisitorPlan
    },
    version: principal.version + 1,
  }
  let replaced = replace_account_principal(state, updated)
  let subscribed = update_account_subscription(
    replaced,
    context.user_id,
    if active {
      PaidPlan
    } else {
      VisitorPlan
    },
    if active {
      "active"
    } else {
      "cancelled"
    },
    now_ms,
  )
  let next = append_account_audit(
    subscribed,
    context.user_id,
    if active {
      "subscription.activated"
    } else {
      "subscription.cancelled"
    },
    context.user_id,
    "self-service billing change",
    now_ms,
  )
  self.save_state(next)
  account_context_for(updated, context.active_tenant_id)
}

///|
pub async fn AccountApplication::admin_snapshot(
  self : AccountApplication,
  opaque_token : String,
  now_ms~ : UInt64,
) -> Json {
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  let state = self.prune_state(self.load_state(), now_ms)
  ignore(
    require_management_entitlement(
      state,
      opaque_token,
      ManagePlatformUsers,
      now_ms,
    ),
  )
  let active_tenants : Array[String] = []
  for principal in state.principals {
    for access in principal.tenant_access {
      if access.active && !active_tenants.contains(access.tenant_id) {
        active_tenants.push(access.tenant_id)
      }
    }
  }
  {
    "contract_id": "moontown.admin-management.v2",
    "users": state.principals.map(account_principal_projection),
    "tenant_ids": active_tenants.to_json(),
    "active_sessions": state.sessions.length(),
    "audit_events": state.audit_events.rev().map(event => event.to_json()),
    "impersonation": "disabled",
  }
}

///|
pub async fn AccountApplication::admin_create_account(
  self : AccountApplication,
  actor_token : String,
  user_id : String,
  display_name : String,
  account_kind : String,
  tenant_id : String,
  tenant_name : String,
  session_id : String,
  opaque_token : String,
  now_ms~ : UInt64,
  ttl_ms? : UInt64 = 604800000UL,
) -> VisitorSessionResult {
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  let state = self.prune_state(self.load_state(), now_ms)
  let actor = require_management_entitlement(
    state,
    actor_token,
    ManagePlatformUsers,
    now_ms,
  )
  if account_principal_record_by_id(state, user_id) is Some(_) {
    fail("account already exists")
  }
  let principal = principal_for_account_kind(
    user_id, display_name, account_kind, tenant_id, tenant_name,
  )
  let initial_tenant = first_active_tenant_id(principal)
  let registered = match initial_tenant {
    Some(tenant_id) =>
      account_register_session(
        state,
        principal,
        session_id,
        opaque_token,
        active_tenant_id=tenant_id,
        expires_at_ms=now_ms + ttl_ms,
      )
    None =>
      account_register_session(
        state,
        principal,
        session_id,
        opaque_token,
        expires_at_ms=now_ms + ttl_ms,
      )
  }
  let next = append_account_audit(
    registered,
    actor.user_id,
    "account.created",
    user_id,
    account_kind,
    now_ms,
  )
  self.save_state(next)
  { opaque_token, context: account_context_for(principal, initial_tenant) }
}

///|
pub async fn AccountApplication::admin_set_account_active(
  self : AccountApplication,
  actor_token : String,
  user_id : String,
  active : Bool,
  now_ms~ : UInt64,
) -> Json {
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  let state = self.prune_state(self.load_state(), now_ms)
  let actor = require_management_entitlement(
    state,
    actor_token,
    ManagePlatformUsers,
    now_ms,
  )
  if actor.user_id == user_id && !active {
    fail("administrators cannot deactivate their current account")
  }
  let principal = account_principal_or_fail(state, user_id)
  let updated = { ..principal, active, version: principal.version + 1 }
  let replaced = replace_account_principal(state, updated)
  let sessions = if active {
    replaced.sessions
  } else {
    replaced.sessions.map(session => {
      if session.principal_id == user_id {
        { ..session, revoked: true, version: session.version + 1 }
      } else {
        session
      }
    })
  }
  let next = append_account_audit(
    { ..replaced, sessions, },
    actor.user_id,
    if active {
      "account.activated"
    } else {
      "account.deactivated"
    },
    user_id,
    "administrator lifecycle change",
    now_ms,
  )
  self.save_state(next)
  account_principal_projection(updated)
}

///|
pub async fn AccountApplication::enterprise_snapshot(
  self : AccountApplication,
  opaque_token : String,
  now_ms~ : UInt64,
) -> Json {
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  let state = self.prune_state(self.load_state(), now_ms)
  let actor = require_management_entitlement(
    state,
    opaque_token,
    UseTeamWorkspaces,
    now_ms,
  )
  let tenant_id = actor.active_tenant_id.unwrap_or_else(() => {
    fail("enterprise management requires an active tenant")
  })
  let members : Array[Json] = []
  let mut tenant_name = actor.active_tenant_name.unwrap_or(tenant_id)
  for principal in state.principals {
    for access in principal.tenant_access {
      if access.tenant_id == tenant_id && access.active {
        tenant_name = access.tenant_name
        members.push(tenant_member_projection(principal, access))
      }
    }
  }
  {
    "contract_id": "moontown.enterprise-management.v2",
    "tenant_id": tenant_id,
    "tenant_name": tenant_name,
    "members": members,
    "usage": {
      "active_members": members.length(),
      "active_sessions": state.sessions.count_if(session => {
        members.any(entry => {
          match entry {
            Object(fields) =>
              fields.get("user_id") == Some(session.principal_id.to_json())
            _ => false
          }
        })
      }),
    },
    "compliance": {
      "session_tokens_stored_as_digests": true,
      "audit_log_enabled": true,
      "impersonation_disabled": true,
    },
    "can_manage_members": actor.has_entitlement(ManageOrganizationMembers),
    "can_manage_billing": actor.has_entitlement(ManageOrganizationBilling),
  }
}

///|
pub async fn AccountApplication::enterprise_upsert_member(
  self : AccountApplication,
  actor_token : String,
  user_id : String,
  display_name : String,
  organization_admin : Bool,
  session_id : String,
  opaque_token : String,
  now_ms~ : UInt64,
  ttl_ms? : UInt64 = 604800000UL,
) -> VisitorSessionResult {
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  let state = self.prune_state(self.load_state(), now_ms)
  let actor = require_management_entitlement(
    state,
    actor_token,
    ManageOrganizationMembers,
    now_ms,
  )
  let tenant_id = actor.active_tenant_id.unwrap_or_else(() => {
    fail("enterprise management requires an active tenant")
  })
  let tenant_name = actor.active_tenant_name.unwrap_or(tenant_id)
  let existing = account_principal_record_by_id(state, user_id)
  let principal = match existing {
    Some(value) => value
    None =>
      principal_for_account_kind(user_id, display_name, "paid-user", "", "")
  }
  let tenant_access = principal.tenant_access.filter(access => {
    access.tenant_id != tenant_id
  })
  tenant_access.push({
    tenant_id,
    tenant_name,
    plan: EnterprisePlan,
    roles: if organization_admin {
      [AccountMember, OrganizationAdmin]
    } else {
      [AccountMember]
    },
    active: true,
    version: state.version + 1,
  })
  let updated = {
    ..principal,
    display_name: if display_name.trim().is_empty() {
      principal.display_name
    } else {
      display_name.trim().to_owned()
    },
    tenant_access,
    active: true,
    version: principal.version + 1,
  }
  let registered = account_register_session(
    state,
    updated,
    session_id,
    opaque_token,
    active_tenant_id=tenant_id,
    expires_at_ms=now_ms + ttl_ms,
  )
  let next = append_account_audit(
    registered,
    actor.user_id,
    "organization.member.upserted",
    user_id,
    tenant_id,
    now_ms,
  )
  self.save_state(next)
  { opaque_token, context: account_context_for(updated, Some(tenant_id)) }
}

///|
pub async fn AccountApplication::enterprise_remove_member(
  self : AccountApplication,
  actor_token : String,
  user_id : String,
  now_ms~ : UInt64,
) -> Json {
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  let state = self.prune_state(self.load_state(), now_ms)
  let actor = require_management_entitlement(
    state,
    actor_token,
    ManageOrganizationMembers,
    now_ms,
  )
  let tenant_id = actor.active_tenant_id.unwrap_or_else(() => {
    fail("enterprise management requires an active tenant")
  })
  if actor.user_id == user_id {
    fail("organization administrators cannot remove themselves")
  }
  let principal = account_principal_or_fail(state, user_id)
  let mut found = false
  let tenant_access = principal.tenant_access.map(access => {
    if access.tenant_id == tenant_id && access.active {
      found = true
      { ..access, active: false, version: access.version + 1 }
    } else {
      access
    }
  })
  if !found {
    fail("organization member does not exist")
  }
  let updated = { ..principal, tenant_access, version: principal.version + 1 }
  let replaced = replace_account_principal(state, updated)
  let sessions = replaced.sessions.map(session => {
    if session.principal_id == user_id &&
      session.active_tenant_id == Some(tenant_id) {
      { ..session, active_tenant_id: None, version: session.version + 1 }
    } else {
      session
    }
  })
  let next = append_account_audit(
    { ..replaced, sessions, },
    actor.user_id,
    "organization.member.removed",
    user_id,
    tenant_id,
    now_ms,
  )
  self.save_state(next)
  account_principal_projection(updated)
}
