///|
pub fn miniapp_dev_login(
  state : MiniappIdentityState,
  login : MiniappDevLogin,
) -> (MiniappIdentityState, MiniappLoginResult)? {
  match miniapp_identity_user_by_id(state, login.login_id) {
    Some(user) => {
      let session : @miniapp_contracts.MiniappSession = {
        id: "dev-session-\{user.id}-\{login.now_ms}",
        user_id: user.id,
        token_label: "dev:\{user.id}",
        expires_at_ms: login.now_ms + login.ttl_ms,
        version: state.version + 1,
      }
      let next = {
        ..state,
        sessions: miniapp_replace_session(state.sessions, session),
        version: state.version + 1,
      }
      Some((next, miniapp_login_result_for_user(next, user, session)))
    }
    None => None
  }
}

///|
pub fn miniapp_session_context(
  state : MiniappIdentityState,
  session_id : String,
  now_ms~ : UInt64,
) -> MiniappSessionContext? {
  match miniapp_identity_session_by_id(state, session_id, now_ms~) {
    Some(session) =>
      match miniapp_identity_user_by_id(state, session.user_id) {
        Some(user) => {
          let organizations = miniapp_identity_user_organizations(
            state,
            user.id,
          )
          let workspaces = miniapp_identity_user_workspaces(state, user.id)
          let roles = miniapp_identity_user_roles(state, user.id)
          let user_id = user.id
          let organization_ids = organizations.map(organization => {
            organization.id
          })
          let workspace_ids = workspaces.map(workspace => workspace.id)
          Some({
            user,
            session,
            viewer: @miniapp_projection.miniapp_viewer_context(
              user_id~,
              organization_ids~,
              workspace_ids~,
              roles~,
            ),
            organizations,
            workspaces,
          })
        }
        None => None
      }
    None => None
  }
}

///|
fn miniapp_login_result_for_user(
  state : MiniappIdentityState,
  user : @miniapp_contracts.MiniappUser,
  session : @miniapp_contracts.MiniappSession,
) -> MiniappLoginResult {
  {
    user,
    session,
    organizations: miniapp_identity_user_organizations(state, user.id),
    workspaces: miniapp_identity_user_workspaces(state, user.id),
    roles: miniapp_identity_user_roles(state, user.id),
  }
}

///|
fn miniapp_replace_session(
  sessions : Array[@miniapp_contracts.MiniappSession],
  session : @miniapp_contracts.MiniappSession,
) -> Array[@miniapp_contracts.MiniappSession] {
  let next : Array[@miniapp_contracts.MiniappSession] = []
  for current in sessions {
    if current.user_id != session.user_id {
      next.push(current)
    }
  }
  next.push(session)
  next
}
