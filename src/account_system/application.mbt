///|
let account_store_mutex : @async.Mutex = Mutex()

///|
fn first_active_tenant_id(principal : AccountPrincipal) -> String? {
  for access in principal.tenant_access {
    if access.active {
      return Some(access.tenant_id)
    }
  }
  None
}

///|
pub fn account_application(
  state_path : String,
  bootstrap_principal : AccountPrincipal,
  bootstrap_session_id : String,
  bootstrap_opaque_token : String,
) -> AccountApplication raise {
  if bootstrap_opaque_token.length() < 12 ||
    !valid_account_id(bootstrap_principal.user_id) ||
    !valid_account_id(bootstrap_session_id) {
    fail("account bootstrap requires a strong session and symbolic identity")
  }
  validate_account_principal(bootstrap_principal)
  {
    state_path,
    bootstrap_principal,
    bootstrap_session_id,
    bootstrap_token_digest: account_token_digest(bootstrap_opaque_token),
  }
}

///|
fn AccountApplication::ensure_bootstrap(
  self : AccountApplication,
  state : AccountState,
) -> AccountState {
  let principals = state.principals.copy()
  let mut principal_was_present = true
  let principal = match
    account_principal_record_by_id(state, self.bootstrap_principal.user_id) {
    Some(persisted) => persisted
    None => {
      principal_was_present = false
      principals.push(self.bootstrap_principal)
      self.bootstrap_principal
    }
  }
  let mut bootstrap_session_exists = false
  for session in state.sessions {
    if session.session_id == self.bootstrap_session_id {
      bootstrap_session_exists = true
    }
  }
  let sessions = state.sessions.filter(session => {
    session.session_id != self.bootstrap_session_id &&
    session.token_digest != self.bootstrap_token_digest
  })
  if bootstrap_session_exists || !principal_was_present {
    sessions.push(self.bootstrap_session(state, principal))
  }
  { ..state, principals, sessions }
}

///|
fn AccountApplication::bootstrap_session(
  self : AccountApplication,
  state : AccountState,
  principal : AccountPrincipal,
) -> AccountSession {
  for session in state.sessions {
    if session.session_id == self.bootstrap_session_id &&
      session.token_digest == self.bootstrap_token_digest {
      let active_tenant_id = match session.active_tenant_id {
        Some(tenant_id) if principal_has_tenant(principal, tenant_id) =>
          Some(tenant_id)
        Some(_) => first_active_tenant_id(principal)
        None => None
      }
      return {
        ..session,
        principal_id: principal.user_id,
        active_tenant_id,
        expires_at_ms: 18446744073709551615UL,
      }
    }
  }
  {
    session_id: self.bootstrap_session_id,
    token_digest: self.bootstrap_token_digest,
    principal_id: principal.user_id,
    active_tenant_id: first_active_tenant_id(principal),
    expires_at_ms: 18446744073709551615UL,
    revoked: false,
    version: 1,
  }
}

///|
async fn AccountApplication::load_state(
  self : AccountApplication,
) -> AccountState {
  let state = match @support.read_optional_json_file(self.state_path) {
    Some(value) => {
      let decoded : AccountState = @json.from_json(
        migrate_account_state_json(value),
      ) catch {
        error => fail("account state is invalid: \{error}")
      }
      normalize_account_state(decoded)
    }
    None => empty_account_state()
  }
  validate_account_state(state)
  let bootstrapped = self.ensure_bootstrap(state)
  validate_account_state(bootstrapped)
  bootstrapped
}

///|
async fn AccountApplication::save_state(
  self : AccountApplication,
  state : AccountState,
) -> Unit {
  validate_account_state(state)
  let temp = self.state_path + ".next"
  @support.ensure_parent_directory(self.state_path)
  @fs.write_file(
    temp,
    state.to_json().stringify(indent=2) + "\n",
    create_mode=CreateOrTruncate,
    permission=0o600,
    sync=Full,
  )
  @fs.rename(temp, self.state_path, replace=true)
}

///|
/// Bound active sessions and discard anonymous principals after their last
/// usable session. The configured bootstrap principal is retained as a
/// revocation tombstone so signing out cannot recreate its fixed token.
fn AccountApplication::prune_state(
  self : AccountApplication,
  state : AccountState,
  now_ms : UInt64,
) -> AccountState {
  let pruned = account_prune_sessions(state, now_ms~)
  let principals = pruned.principals.filter(principal => {
    principal.user_id == self.bootstrap_principal.user_id ||
    principal.personal_plan != VisitorPlan ||
    principal.tenant_access.any(access => access.active) ||
    pruned.sessions.any(session => session.principal_id == principal.user_id)
  })
  let subscriptions = pruned.subscriptions.filter(subscription => {
    principals.any(principal => principal.user_id == subscription.principal_id)
  })
  if principals.length() == pruned.principals.length() &&
    subscriptions.length() == pruned.subscriptions.length() {
    pruned
  } else {
    { ..pruned, principals, subscriptions, version: pruned.version + 1 }
  }
}

///|
pub async fn AccountApplication::resolve(
  self : AccountApplication,
  opaque_token : String,
  now_ms~ : UInt64,
) -> AccountContext? {
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  let state = self.load_state()
  let pruned = self.prune_state(state, now_ms)
  if pruned != state {
    self.save_state(pruned)
  }
  account_context_for_session(pruned, opaque_token, now_ms~)
}

///|
pub async fn AccountApplication::create_visitor_session(
  self : AccountApplication,
  opaque_token : String,
  visitor_id : String,
  now_ms~ : UInt64,
  ttl_ms? : UInt64 = 0UL,
) -> VisitorSessionResult {
  let ttl_ms = if ttl_ms == 0UL {
    @system_settings.current_system_settings().visitor_session_ttl_ms.to_uint64()
  } else {
    ttl_ms
  }
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  let state = self.prune_state(self.load_state(), now_ms)
  let principal : AccountPrincipal = {
    user_id: visitor_id,
    display_name: "Visitor",
    personal_plan: VisitorPlan,
    platform_roles: [AccountMember],
    tenant_access: [],
    active: true,
    version: 1,
  }
  let next = account_register_session(
    state,
    principal,
    "visitor-session-\{visitor_id}",
    opaque_token,
    expires_at_ms=now_ms + ttl_ms,
  )
  self.save_state(next)
  { opaque_token, context: account_context_for(principal, None) }
}

///|
pub async fn AccountApplication::switch_tenant(
  self : AccountApplication,
  opaque_token : String,
  tenant_id : String?,
  now_ms~ : UInt64,
) -> AccountContext {
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  let next = account_switch_session_tenant(
    self.load_state(),
    opaque_token,
    tenant_id,
    now_ms~,
  )
  self.save_state(next)
  account_context_for_session(next, opaque_token, now_ms~).unwrap_or_else(() => {
    fail("account session disappeared during tenant switch")
  })
}

///|
pub async fn AccountApplication::logout(
  self : AccountApplication,
  opaque_token : String,
  now_ms~ : UInt64,
) -> Unit {
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  let revoked = account_revoke_session(self.load_state(), opaque_token, now_ms~)
  self.save_state(revoked)
}
