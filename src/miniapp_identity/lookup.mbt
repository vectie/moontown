///|
pub fn miniapp_identity_user_by_id(
  state : MiniappIdentityState,
  user_id : String,
) -> @miniapp_contracts.MiniappUser? {
  for user in state.users {
    if user.id == user_id {
      return Some(user)
    }
  }
  None
}

///|
pub fn miniapp_identity_session_by_id(
  state : MiniappIdentityState,
  session_id : String,
  now_ms~ : UInt64,
) -> @miniapp_contracts.MiniappSession? {
  for session in state.sessions {
    if session.id == session_id && session.expires_at_ms > now_ms {
      return Some(session)
    }
  }
  None
}

///|
pub fn miniapp_identity_user_organizations(
  state : MiniappIdentityState,
  user_id : String,
) -> Array[@miniapp_contracts.MiniappOrganization] {
  let organizations : Array[@miniapp_contracts.MiniappOrganization] = []
  for membership in state.memberships {
    if membership.user_id == user_id && membership.active {
      match
        miniapp_identity_organization_by_id(state, membership.organization_id) {
        Some(organization) => organizations.push(organization)
        None => ()
      }
    }
  }
  organizations
}

///|
pub fn miniapp_identity_user_workspaces(
  state : MiniappIdentityState,
  user_id : String,
) -> Array[@miniapp_contracts.MiniappWorkspace] {
  let workspaces : Array[@miniapp_contracts.MiniappWorkspace] = []
  for workspace in state.workspaces {
    if workspace.owner_kind == @miniapp_contracts.UserOwner &&
      workspace.owner_id == user_id {
      workspaces.push(workspace)
    }
  }
  for access in state.workspace_access {
    if access.user_id == user_id && access.active {
      match miniapp_identity_workspace_by_id(state, access.workspace_id) {
        Some(workspace) =>
          if !miniapp_workspace_array_contains(workspaces, workspace.id) {
            workspaces.push(workspace)
          }
        None => ()
      }
    }
  }
  workspaces
}

///|
pub fn miniapp_identity_user_roles(
  state : MiniappIdentityState,
  user_id : String,
) -> Array[@miniapp_contracts.MiniappPermissionRole] {
  let roles : Array[@miniapp_contracts.MiniappPermissionRole] = []
  for access in state.workspace_access {
    if access.user_id == user_id && access.active {
      for role in access.roles {
        miniapp_push_role_once(roles, role)
      }
    }
  }
  for membership in state.memberships {
    if membership.user_id == user_id && membership.active {
      for role in membership.roles {
        miniapp_push_role_once(roles, role)
      }
    }
  }
  roles
}

///|
fn miniapp_identity_organization_by_id(
  state : MiniappIdentityState,
  organization_id : String,
) -> @miniapp_contracts.MiniappOrganization? {
  for organization in state.organizations {
    if organization.id == organization_id {
      return Some(organization)
    }
  }
  None
}

///|
fn miniapp_identity_workspace_by_id(
  state : MiniappIdentityState,
  workspace_id : String,
) -> @miniapp_contracts.MiniappWorkspace? {
  for workspace in state.workspaces {
    if workspace.id == workspace_id {
      return Some(workspace)
    }
  }
  None
}

///|
fn miniapp_workspace_array_contains(
  workspaces : Array[@miniapp_contracts.MiniappWorkspace],
  workspace_id : String,
) -> Bool {
  for workspace in workspaces {
    if workspace.id == workspace_id {
      return true
    }
  }
  false
}

///|
fn miniapp_push_role_once(
  roles : Array[@miniapp_contracts.MiniappPermissionRole],
  role : @miniapp_contracts.MiniappPermissionRole,
) -> Unit {
  if !roles.contains(role) {
    roles.push(role)
  }
}
