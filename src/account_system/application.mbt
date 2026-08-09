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
  let principals = state.principals.filter(principal => {
    principal.user_id != self.bootstrap_principal.user_id
  })
  principals.push(self.bootstrap_principal)
  let sessions = state.sessions.filter(session => {
    session.session_id != self.bootstrap_session_id &&
    session.token_digest != self.bootstrap_token_digest
  })
  sessions.push(self.bootstrap_session(state))
  { ..state, principals, sessions }
}

///|
fn AccountApplication::bootstrap_session(
  self : AccountApplication,
  state : AccountState,
) -> AccountSession {
  for session in state.sessions {
    if session.session_id == self.bootstrap_session_id &&
      session.token_digest == self.bootstrap_token_digest {
      let active_tenant_id = match session.active_tenant_id {
        Some(tenant_id) if principal_has_tenant(
            self.bootstrap_principal,
            tenant_id,
          ) => Some(tenant_id)
        Some(_) => first_active_tenant_id(self.bootstrap_principal)
        None => None
      }
      return {
        ..session,
        principal_id: self.bootstrap_principal.user_id,
        active_tenant_id,
        expires_at_ms: 18446744073709551615UL,
        revoked: false,
      }
    }
  }
  {
    session_id: self.bootstrap_session_id,
    token_digest: self.bootstrap_token_digest,
    principal_id: self.bootstrap_principal.user_id,
    active_tenant_id: first_active_tenant_id(self.bootstrap_principal),
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
      let decoded : AccountState = @json.from_json(value) catch {
        error => fail("account state is invalid: \{error}")
      }
      if decoded.schema != account_state_schema() {
        fail("unsupported account state schema")
      }
      decoded
    }
    None => empty_account_state()
  }
  self.ensure_bootstrap(state)
}

///|
async fn AccountApplication::save_state(
  self : AccountApplication,
  state : AccountState,
) -> Unit {
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
pub async fn AccountApplication::resolve(
  self : AccountApplication,
  opaque_token : String,
  now_ms~ : UInt64,
) -> AccountContext? {
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  account_context_for_session(self.load_state(), opaque_token, now_ms~)
}

///|
pub async fn AccountApplication::create_visitor_session(
  self : AccountApplication,
  opaque_token : String,
  visitor_id : String,
  now_ms~ : UInt64,
  ttl_ms? : UInt64 = 86400000UL,
) -> VisitorSessionResult {
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  let state = self.load_state()
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
