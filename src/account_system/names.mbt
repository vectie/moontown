///|
pub fn account_plan_name(plan : AccountPlan) -> String {
  match plan {
    VisitorPlan => "visitor"
    PaidPlan => "paid"
    EnterprisePlan => "enterprise"
  }
}

///|
pub fn account_role_name(role : AccountRole) -> String {
  match role {
    AccountMember => "member"
    AccountEditor => "editor"
    AccountPublisher => "publisher"
    OrganizationAdmin => "organization-admin"
    PlatformAdmin => "platform-admin"
  }
}

///|
pub fn account_home_surface_name(surface : AccountHomeSurface) -> String {
  match surface {
    PublicTownHome => "public-town"
    PersonalTownHome => "personal-town"
    EnterpriseTownHome => "enterprise-town"
    AdminConsoleHome => "admin-console"
  }
}

///|
pub fn account_entitlement_name(entitlement : AccountEntitlement) -> String {
  match entitlement {
    ExplorePublicTown => "town.public.explore"
    DiscoverPublicServices => "town.public.discover"
    UsePersonalAgent => "agent.personal.use"
    ManagePersonalWorkspace => "workspace.personal.manage"
    UseMarketplaceActions => "marketplace.action.use"
    ManagePersonalBilling => "billing.personal.manage"
    UseTeamWorkspaces => "workspace.team.use"
    UseSharedAgents => "agent.shared.use"
    ViewMemberDirectory => "organization.members.view"
    ViewOrganizationUsage => "organization.usage.view"
    ViewComplianceControls => "organization.compliance.view"
    PublishTownContent => "town.content.publish"
    ManageOrganization => "organization.manage"
    ManageOrganizationMembers => "organization.members.manage"
    ManageOrganizationBilling => "organization.billing.manage"
    AccessAdminConsole => "platform.admin.access"
    ManagePlatformUsers => "platform.users.manage"
    ManagePlatformTenants => "platform.tenants.manage"
    ModerateTownContent => "platform.content.moderate"
    ViewPlatformAnalytics => "platform.analytics.view"
    ViewAuditLog => "platform.audit.view"
    ManageSystemHealth => "platform.health.manage"
  }
}
