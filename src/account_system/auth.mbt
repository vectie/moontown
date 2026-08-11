///|
pub fn account_token_digest(token : String) -> String {
  "sha256:\{@crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(token)))}"
}

///|
fn valid_account_id(value : String) -> Bool {
  let trimmed = value.trim().to_owned()
  if trimmed.is_empty() || trimmed.length() > 128 {
    return false
  }
  for char in trimmed {
    if !((char >= 'a' && char <= 'z') ||
      (char >= 'A' && char <= 'Z') ||
      (char >= '0' && char <= '9') ||
      char == '-' ||
      char == '_' ||
      char == '.' ||
      char == ':') {
      return false
    }
  }
  true
}

///|
fn account_principal_by_id(
  state : AccountState,
  principal_id : String,
) -> AccountPrincipal? {
  for principal in state.principals {
    if principal.active && principal.user_id == principal_id {
      return Some(principal)
    }
  }
  None
}

///|
fn account_principal_record_by_id(
  state : AccountState,
  principal_id : String,
) -> AccountPrincipal? {
  for principal in state.principals {
    if principal.user_id == principal_id {
      return Some(principal)
    }
  }
  None
}

///|
fn principal_has_tenant(
  principal : AccountPrincipal,
  tenant_id : String,
) -> Bool {
  for access in principal.tenant_access {
    if access.active && access.tenant_id == tenant_id {
      return true
    }
  }
  false
}

///|
pub fn account_context_for_session(
  state : AccountState,
  opaque_token : String,
  now_ms~ : UInt64,
) -> AccountContext? {
  let digest = account_token_digest(opaque_token)
  for session in state.sessions {
    if session.token_digest == digest &&
      !session.revoked &&
      session.expires_at_ms > now_ms {
      return account_principal_by_id(state, session.principal_id).map(principal => {
        account_context_for(principal, session.active_tenant_id)
      })
    }
  }
  None
}

///|
pub fn account_register_session(
  state : AccountState,
  principal : AccountPrincipal,
  session_id : String,
  opaque_token : String,
  active_tenant_id? : String,
  expires_at_ms~ : UInt64,
) -> AccountState raise {
  if !valid_account_id(principal.user_id) ||
    !valid_account_id(session_id) ||
    opaque_token.length() < 12 {
    fail("invalid account principal or opaque session")
  }
  if active_tenant_id is Some(tenant_id) &&
    !principal_has_tenant(principal, tenant_id) {
    fail("active tenant is not available to the principal")
  }
  let principals = state.principals.filter(current => {
    current.user_id != principal.user_id
  })
  principals.push(principal)
  let digest = account_token_digest(opaque_token)
  let sessions = state.sessions.filter(current => {
    current.session_id != session_id && current.token_digest != digest
  })
  sessions.push({
    session_id,
    token_digest: digest,
    principal_id: principal.user_id,
    active_tenant_id,
    expires_at_ms,
    revoked: false,
    version: state.version + 1,
  })
  { ..state, principals, sessions, version: state.version + 1 }
}

///|
pub fn account_switch_session_tenant(
  state : AccountState,
  opaque_token : String,
  tenant_id : String?,
  now_ms~ : UInt64,
) -> AccountState raise {
  let digest = account_token_digest(opaque_token)
  let sessions = state.sessions.copy()
  let mut found = false
  for index, session in sessions {
    if session.token_digest == digest &&
      !session.revoked &&
      session.expires_at_ms > now_ms {
      let principal = account_principal_by_id(state, session.principal_id).unwrap_or_else(() => {
          fail("account principal is inactive")
        },
      )
      if tenant_id is Some(target) && !principal_has_tenant(principal, target) {
        fail("tenant is not available to this account")
      }
      sessions[index] = {
        ..session,
        active_tenant_id: tenant_id,
        version: session.version + 1,
      }
      found = true
    }
  }
  if !found {
    fail("missing, expired, or revoked account session")
  }
  { ..state, sessions, version: state.version + 1 }
}

///|
pub fn account_revoke_session(
  state : AccountState,
  opaque_token : String,
  now_ms~ : UInt64,
) -> AccountState raise {
  let digest = account_token_digest(opaque_token)
  let sessions = state.sessions.copy()
  let mut found = false
  for index, session in sessions {
    if session.token_digest == digest &&
      !session.revoked &&
      session.expires_at_ms > now_ms {
      sessions[index] = {
        ..session,
        revoked: true,
        version: session.version + 1,
      }
      found = true
    }
  }
  if !found {
    fail("missing, expired, or revoked account session")
  }
  { ..state, sessions, version: state.version + 1 }
}

///| Remove sessions that cannot resolve to an active principal. Revocation is

///|
/// retained only in the bounded audit log, not indefinitely in session state.
pub fn account_prune_sessions(
  state : AccountState,
  now_ms~ : UInt64,
) -> AccountState {
  let active_sessions = state.sessions.filter(session => {
    !session.revoked &&
    session.expires_at_ms > now_ms &&
    account_principal_by_id(state, session.principal_id) is Some(_)
  })
  let sessions = if active_sessions.length() > 1000 {
    active_sessions[active_sessions.length() - 1000:].to_owned()
  } else {
    active_sessions
  }
  if sessions.length() == state.sessions.length() {
    state
  } else {
    { ..state, sessions, version: state.version + 1 }
  }
}
