///|
fn account_roles_are_unique(roles : Array[AccountRole]) -> Bool {
  let seen : Array[AccountRole] = []
  for role in roles {
    if seen.contains(role) {
      return false
    }
    seen.push(role)
  }
  true
}

///|
fn validate_account_principal(principal : AccountPrincipal) -> Unit raise {
  if !valid_account_id(principal.user_id) ||
    principal.display_name.trim().is_empty() ||
    principal.version < 1 {
    fail("account principal identity or version is invalid")
  }
  if principal.personal_plan == EnterprisePlan {
    fail("enterprise plans must be tenant-scoped, not personal plans")
  }
  if !account_roles_are_unique(principal.platform_roles) ||
    principal.platform_roles.contains(OrganizationAdmin) {
    fail("platform roles are duplicated or contain a tenant-scoped role")
  }
  let tenant_ids : Array[String] = []
  for access in principal.tenant_access {
    if !valid_account_id(access.tenant_id) ||
      access.tenant_name.trim().is_empty() ||
      access.plan != EnterprisePlan ||
      access.version < 1 {
      fail("account tenant access is invalid")
    }
    if tenant_ids.contains(access.tenant_id) {
      fail("account principal has duplicate tenant access")
    }
    if !account_roles_are_unique(access.roles) ||
      access.roles.contains(PlatformAdmin) {
      fail("tenant roles are duplicated or contain a platform-scoped role")
    }
    tenant_ids.push(access.tenant_id)
  }
}

///|
/// Validate referential and uniqueness invariants before persisted account
/// state is trusted by authorization code.
fn validate_account_state(state : AccountState) -> Unit raise {
  if state.schema != account_state_schema() || state.version < 1 {
    fail("unsupported or invalid account state schema")
  }
  let principal_ids : Array[String] = []
  for principal in state.principals {
    validate_account_principal(principal)
    if principal_ids.contains(principal.user_id) {
      fail("account state contains duplicate principals")
    }
    principal_ids.push(principal.user_id)
  }
  let session_ids : Array[String] = []
  let token_digests : Array[String] = []
  for session in state.sessions {
    if !valid_account_id(session.session_id) ||
      !session.token_digest.has_prefix("sha256:") ||
      session.token_digest.length() != 71 ||
      session.version < 1 {
      fail("account state contains an invalid session")
    }
    if session_ids.contains(session.session_id) ||
      token_digests.contains(session.token_digest) {
      fail("account state contains duplicate sessions")
    }
    let principal = account_principal_record_by_id(state, session.principal_id).unwrap_or_else(() => {
        fail("account session references a missing principal")
      },
    )
    match session.active_tenant_id {
      Some(tenant_id) if !principal_has_tenant(principal, tenant_id) =>
        fail("account session references unavailable tenant access")
      _ => ()
    }
    session_ids.push(session.session_id)
    token_digests.push(session.token_digest)
  }
  let subscription_principals : Array[String] = []
  for subscription in state.subscriptions {
    let principal = account_principal_record_by_id(
      state,
      subscription.principal_id,
    ).unwrap_or_else(() => {
      fail("account subscription references a missing principal")
    })
    if subscription.plan != principal.personal_plan ||
      subscription.plan == EnterprisePlan ||
      subscription.status.trim().is_empty() ||
      subscription.version < 1 {
      fail("account subscription contradicts its principal billing state")
    }
    if subscription_principals.contains(subscription.principal_id) {
      fail("account state contains duplicate subscriptions")
    }
    subscription_principals.push(subscription.principal_id)
  }
  let audit_ids : Array[String] = []
  for event in state.audit_events {
    if event.event_id.trim().is_empty() || event.version < 1 {
      fail("account state contains an invalid audit event")
    }
    if audit_ids.contains(event.event_id) {
      fail("account state contains duplicate audit events")
    }
    audit_ids.push(event.event_id)
  }
}
