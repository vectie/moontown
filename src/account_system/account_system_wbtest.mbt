///|
fn test_principal(
  personal_plan : AccountPlan,
  platform_roles? : Array[AccountRole] = [],
  tenant_access? : Array[AccountTenantAccess] = [],
) -> AccountPrincipal {
  {
    user_id: "user-a",
    display_name: "Ada",
    personal_plan,
    platform_roles,
    tenant_access,
    active: true,
    version: 1,
  }
}

///|
fn enterprise_access(
  roles? : Array[AccountRole] = [AccountMember],
) -> AccountTenantAccess {
  {
    tenant_id: "energy-labs",
    tenant_name: "Energy Labs",
    plan: EnterprisePlan,
    roles,
    active: true,
    version: 1,
  }
}

///|
test "plans and roles produce four distinct account experiences" {
  let visitor = account_context_for(test_principal(VisitorPlan), None)
  assert_eq(visitor.home_surface, PublicTownHome)
  assert_true(visitor.has_entitlement(ExplorePublicTown))
  assert_false(visitor.has_entitlement(UsePersonalAgent))
  let paid = account_context_for(test_principal(PaidPlan), None)
  assert_eq(paid.home_surface, PersonalTownHome)
  assert_true(paid.has_entitlement(UsePersonalAgent))
  assert_false(paid.has_entitlement(UseTeamWorkspaces))
  let enterprise = account_context_for(
    test_principal(PaidPlan, tenant_access=[enterprise_access()]),
    Some("energy-labs"),
  )
  assert_eq(enterprise.home_surface, EnterpriseTownHome)
  assert_true(enterprise.has_entitlement(UseTeamWorkspaces))
  let admin = account_context_for(
    test_principal(PaidPlan, platform_roles=[PlatformAdmin]),
    None,
  )
  assert_eq(admin.home_surface, AdminConsoleHome)
  assert_true(admin.has_entitlement(AccessAdminConsole))
}

///|
test "enterprise payment never grants organization administration" {
  let enterprise_member = account_context_for(
    test_principal(PaidPlan, tenant_access=[enterprise_access()]),
    Some("energy-labs"),
  )
  assert_false(enterprise_member.has_entitlement(ManageOrganizationMembers))
  let admin = account_context_for(
    test_principal(PaidPlan, tenant_access=[
      enterprise_access(roles=[OrganizationAdmin]),
    ]),
    Some("energy-labs"),
  )
  assert_true(admin.has_entitlement(ManageOrganizationMembers))
  assert_false(admin.has_entitlement(ManagePlatformUsers))
}

///|
test "opaque sessions resolve identity and tenant switches are scoped" {
  let principal = test_principal(PaidPlan, tenant_access=[enterprise_access()])
  let state = account_register_session(
    empty_account_state(),
    principal,
    "session-a",
    "opaque-token-a",
    expires_at_ms=1000UL,
  )
  let paid = account_context_for_session(state, "opaque-token-a", now_ms=100UL).unwrap()
  assert_eq(paid.plan, PaidPlan)
  let switched = account_switch_session_tenant(
    state,
    "opaque-token-a",
    Some("energy-labs"),
    now_ms=100UL,
  )
  let enterprise = account_context_for_session(
    switched,
    "opaque-token-a",
    now_ms=100UL,
  ).unwrap()
  assert_eq(enterprise.plan, EnterprisePlan)
  assert_true(
    account_context_for_session(state, "wrong-token-value", now_ms=100UL)
    is None,
  )
}

///|
test "tenant switch rejects caller-selected foreign tenant" {
  let state = account_register_session(
    empty_account_state(),
    test_principal(PaidPlan, tenant_access=[enterprise_access()]),
    "session-a",
    "opaque-token-a",
    expires_at_ms=1000UL,
  )
  try
    account_switch_session_tenant(
      state,
      "opaque-token-a",
      Some("foreign-tenant"),
      now_ms=100UL,
    )
  catch {
    error => assert_true("\{error}".contains("not available"))
  } noraise {
    _ => fail("foreign tenant must be rejected")
  }
}

///|
test "bootstrap reload preserves a persisted personal tenant selection" {
  let principal = test_principal(PaidPlan, tenant_access=[enterprise_access()])
  let application = account_application(
    "/tmp/moontown-account-bootstrap-preservation.json", principal, "bootstrap:user-a",
    "opaque-token-a",
  )
  let enterprise = account_register_session(
    empty_account_state(),
    principal,
    "bootstrap:user-a",
    "opaque-token-a",
    active_tenant_id="energy-labs",
    expires_at_ms=1000UL,
  )
  let personal = account_switch_session_tenant(
    enterprise,
    "opaque-token-a",
    None,
    now_ms=100UL,
  )
  let reloaded = application.ensure_bootstrap(personal)
  let context = account_context_for_session(
    reloaded,
    "opaque-token-a",
    now_ms=100UL,
  ).unwrap()
  assert_eq(context.plan, PaidPlan)
  assert_eq(context.active_tenant_id, None)
  assert_false(context.has_entitlement(UseTeamWorkspaces))
}

///|
test "account projection emits tenant optionals as string or null" {
  let enterprise = account_context_for(
    test_principal(PaidPlan, tenant_access=[enterprise_access()]),
    Some("energy-labs"),
  )
  guard account_context_projection(enterprise)
    is {
      "active_tenant_id": String(tenant_id),
      "active_tenant_name": String(tenant_name),
      ..
    } else {
    fail("active enterprise tenant must use the string wire shape")
  }
  assert_eq(tenant_id, "energy-labs")
  assert_eq(tenant_name, "Energy Labs")
  guard account_context_projection(
      account_context_for(test_principal(PaidPlan), None),
    )
    is { "active_tenant_id": Null, "active_tenant_name": Null, .. } else {
    fail("missing active tenant must use the null wire shape")
  }
}
