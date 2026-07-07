///|
pub(all) struct MiniappMembership {
  user_id : String
  organization_id : String
  roles : Array[@miniapp_contracts.MiniappPermissionRole]
  active : Bool
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappWorkspaceAccess {
  user_id : String
  workspace_id : String
  roles : Array[@miniapp_contracts.MiniappPermissionRole]
  active : Bool
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappIdentityState {
  users : Array[@miniapp_contracts.MiniappUser]
  organizations : Array[@miniapp_contracts.MiniappOrganization]
  workspaces : Array[@miniapp_contracts.MiniappWorkspace]
  memberships : Array[MiniappMembership]
  workspace_access : Array[MiniappWorkspaceAccess]
  sessions : Array[@miniapp_contracts.MiniappSession]
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappDevLogin {
  login_id : String
  now_ms : UInt64
  ttl_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappLoginResult {
  user : @miniapp_contracts.MiniappUser
  session : @miniapp_contracts.MiniappSession
  organizations : Array[@miniapp_contracts.MiniappOrganization]
  workspaces : Array[@miniapp_contracts.MiniappWorkspace]
  roles : Array[@miniapp_contracts.MiniappPermissionRole]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappSessionContext {
  user : @miniapp_contracts.MiniappUser
  session : @miniapp_contracts.MiniappSession
  viewer : @miniapp_projection.MiniappViewerContext
  organizations : Array[@miniapp_contracts.MiniappOrganization]
  workspaces : Array[@miniapp_contracts.MiniappWorkspace]
} derive(Debug, Eq)
