///|
pub(all) enum AccountPlan {
  VisitorPlan
  PaidPlan
  EnterprisePlan
} derive(Debug, Eq, ToJson, FromJson)

///| The product-facing account kind. Billing remains represented by

///| `AccountPlan`; administrator authority remains represented by roles.

///| This explicit projection prevents either concern from masquerading as the

///|
/// other while still providing four independently routed experiences.
pub(all) enum AccountKind {
  VisitorAccount
  PaidUserAccount
  EnterpriseAccount
  AdminAccount
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum AccountRole {
  AccountMember
  AccountEditor
  AccountPublisher
  OrganizationAdmin
  PlatformAdmin
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum AccountHomeSurface {
  PublicTownHome
  PersonalTownHome
  EnterpriseTownHome
  AdminConsoleHome
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum AccountEntitlement {
  ExplorePublicTown
  DiscoverPublicServices
  UsePersonalAgent
  ManagePersonalWorkspace
  UseMarketplaceActions
  ManagePersonalBilling
  UseTeamWorkspaces
  UseSharedAgents
  ViewMemberDirectory
  ViewOrganizationUsage
  ViewComplianceControls
  PublishTownContent
  ManageOrganization
  ManageOrganizationMembers
  ManageOrganizationBilling
  AccessAdminConsole
  ManagePlatformUsers
  ManagePlatformTenants
  ModerateTownContent
  ViewPlatformAnalytics
  ViewAuditLog
  ManageSystemHealth
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AccountTenantAccess {
  tenant_id : String
  tenant_name : String
  plan : AccountPlan
  roles : Array[AccountRole]
  active : Bool
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AccountPrincipal {
  user_id : String
  display_name : String
  personal_plan : AccountPlan
  platform_roles : Array[AccountRole]
  tenant_access : Array[AccountTenantAccess]
  active : Bool
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AccountSession {
  session_id : String
  token_digest : String
  principal_id : String
  active_tenant_id : String?
  expires_at_ms : UInt64
  revoked : Bool
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AccountSubscription {
  principal_id : String
  plan : AccountPlan
  status : String
  changed_at_ms : UInt64
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AccountAuditEvent {
  event_id : String
  actor_id : String
  action : String
  target_id : String
  detail : String
  occurred_at_ms : UInt64
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AccountState {
  schema : String
  principals : Array[AccountPrincipal]
  sessions : Array[AccountSession]
  subscriptions : Array[AccountSubscription]
  audit_events : Array[AccountAuditEvent]
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AccountContext {
  user_id : String
  display_name : String
  account_kind : AccountKind
  plan : AccountPlan
  roles : Array[AccountRole]
  entitlements : Array[AccountEntitlement]
  active_tenant_id : String?
  active_tenant_name : String?
  tenant_choices : Array[AccountTenantAccess]
  home_surface : AccountHomeSurface
  visitor : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct VisitorSessionResult {
  opaque_token : String
  context : AccountContext
} derive(Debug, Eq, ToJson)

///|
pub(all) struct AccountApplication {
  state_path : String
  bootstrap_principal : AccountPrincipal
  bootstrap_session_id : String
  bootstrap_token_digest : String
} derive(Debug, Eq)
