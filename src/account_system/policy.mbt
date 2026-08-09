///|
fn push_entitlement_once(
  entitlements : Array[AccountEntitlement],
  entitlement : AccountEntitlement,
) -> Unit {
  if !entitlements.contains(entitlement) {
    entitlements.push(entitlement)
  }
}

///|
fn push_role_once(roles : Array[AccountRole], role : AccountRole) -> Unit {
  if !roles.contains(role) {
    roles.push(role)
  }
}

///|
pub fn account_entitlements_for(
  plan : AccountPlan,
  roles : Array[AccountRole],
) -> Array[AccountEntitlement] {
  let entitlements = [ExplorePublicTown, DiscoverPublicServices]
  if plan == PaidPlan || plan == EnterprisePlan {
    for
      entitlement in [
        UsePersonalAgent,
        ManagePersonalWorkspace,
        UseMarketplaceActions,
        ManagePersonalBilling,
      ] {
      push_entitlement_once(entitlements, entitlement)
    }
  }
  if plan == EnterprisePlan {
    for
      entitlement in [
        UseTeamWorkspaces,
        UseSharedAgents,
        ViewMemberDirectory,
        ViewOrganizationUsage,
        ViewComplianceControls,
      ] {
      push_entitlement_once(entitlements, entitlement)
    }
  }
  if roles.contains(AccountPublisher) ||
    roles.contains(OrganizationAdmin) ||
    roles.contains(PlatformAdmin) {
    push_entitlement_once(entitlements, PublishTownContent)
  }
  if roles.contains(OrganizationAdmin) || roles.contains(PlatformAdmin) {
    for
      entitlement in [
        ManageOrganization,
        ManageOrganizationMembers,
        ManageOrganizationBilling,
      ] {
      push_entitlement_once(entitlements, entitlement)
    }
  }
  if roles.contains(PlatformAdmin) {
    for
      entitlement in [
        AccessAdminConsole,
        ManagePlatformUsers,
        ManagePlatformTenants,
        ModerateTownContent,
        ViewPlatformAnalytics,
        ViewAuditLog,
        ManageSystemHealth,
      ] {
      push_entitlement_once(entitlements, entitlement)
    }
  }
  entitlements
}

///|
pub fn AccountContext::has_entitlement(
  self : AccountContext,
  entitlement : AccountEntitlement,
) -> Bool {
  self.entitlements.contains(entitlement)
}

///|
fn active_tenant_access(
  principal : AccountPrincipal,
  tenant_id : String?,
) -> AccountTenantAccess? {
  match tenant_id {
    Some(target) => {
      for access in principal.tenant_access {
        if access.active && access.tenant_id == target {
          return Some(access)
        }
      }
      None
    }
    None => None
  }
}

///|
pub fn account_context_for(
  principal : AccountPrincipal,
  active_tenant_id : String?,
) -> AccountContext {
  let active_tenant = active_tenant_access(principal, active_tenant_id)
  let plan = match active_tenant {
    Some(access) => access.plan
    None => principal.personal_plan
  }
  let roles = principal.platform_roles.copy()
  match active_tenant {
    Some(access) =>
      for role in access.roles {
        push_role_once(roles, role)
      }
    None => ()
  }
  let home_surface = if roles.contains(PlatformAdmin) {
    AdminConsoleHome
  } else {
    match plan {
      VisitorPlan => PublicTownHome
      PaidPlan => PersonalTownHome
      EnterprisePlan => EnterpriseTownHome
    }
  }
  {
    user_id: principal.user_id,
    display_name: principal.display_name,
    plan,
    roles,
    entitlements: account_entitlements_for(plan, roles),
    active_tenant_id: active_tenant.map(access => access.tenant_id),
    active_tenant_name: active_tenant.map(access => access.tenant_name),
    tenant_choices: principal.tenant_access.filter(access => access.active),
    home_surface,
    visitor: principal.personal_plan == VisitorPlan &&
    principal.tenant_access.all(access => !access.active),
  }
}
