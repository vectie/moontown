///|
pub fn marketplace_token_digest(token : String) -> String {
  sha256_text(token)
}

///|
fn principal_by_id(
  state : MarketplaceState,
  principal_id : String,
) -> MarketplacePrincipal? {
  for principal in state.principals {
    if principal.principal_id == principal_id && principal.active {
      return Some(principal)
    }
  }
  None
}

///| Resolve identity exclusively from an opaque server-issued session token.

///|
/// Caller-selected principal headers are never accepted by this API.
pub fn marketplace_principal_for_session(
  state : MarketplaceState,
  opaque_token : String,
  now_ms~ : UInt64,
) -> MarketplacePrincipal? {
  let digest = marketplace_token_digest(opaque_token)
  for session in state.sessions {
    if session.token_digest == digest &&
      !session.revoked &&
      session.expires_at_ms > now_ms {
      return principal_by_id(state, session.principal_id)
    }
  }
  None
}

///|
fn principal_has_role(principal : MarketplacePrincipal, role : String) -> Bool {
  principal.roles.contains(role)
}

///|
pub fn marketplace_register_session(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  session_id : String,
  opaque_token : String,
  expires_at_ms : UInt64,
) -> MarketplaceState raise {
  if !valid_symbolic_id(principal.principal_id) ||
    !valid_symbolic_id(principal.tenant_id) ||
    !valid_symbolic_id(session_id) ||
    opaque_token.length() < 12 {
    fail("invalid marketplace principal or opaque session")
  }
  let principals = state.principals.filter(current => {
    current.principal_id != principal.principal_id
  })
  principals.push({ ..principal, version: principal.version.max(1) })
  let sessions = state.sessions.filter(current => {
    current.session_id != session_id &&
    current.token_digest != marketplace_token_digest(opaque_token)
  })
  sessions.push({
    session_id,
    token_digest: marketplace_token_digest(opaque_token),
    principal_id: principal.principal_id,
    expires_at_ms,
    revoked: false,
    version: state.version + 1,
  })
  { ..state, principals, sessions, version: state.version + 1 }
}
