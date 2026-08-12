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
  assert_eq(visitor.account_kind, VisitorAccount)
  assert_true(visitor.has_entitlement(ExplorePublicTown))
  assert_false(visitor.has_entitlement(UsePersonalAgent))
  let paid = account_context_for(test_principal(PaidPlan), None)
  assert_eq(paid.home_surface, PersonalTownHome)
  assert_eq(paid.account_kind, PaidUserAccount)
  assert_true(paid.has_entitlement(UsePersonalAgent))
  assert_false(paid.has_entitlement(UseTeamWorkspaces))
  let enterprise = account_context_for(
    test_principal(PaidPlan, tenant_access=[enterprise_access()]),
    Some("energy-labs"),
  )
  assert_eq(enterprise.home_surface, EnterpriseTownHome)
  assert_eq(enterprise.account_kind, EnterpriseAccount)
  assert_true(enterprise.has_entitlement(UseTeamWorkspaces))
  let admin = account_context_for(
    test_principal(PaidPlan, platform_roles=[PlatformAdmin]),
    None,
  )
  assert_eq(admin.home_surface, AdminConsoleHome)
  assert_eq(admin.account_kind, AdminAccount)
  assert_true(admin.has_entitlement(AccessAdminConsole))
}

///|
test "administrator authority never projects a visitor account flag" {
  let admin = account_context_for(
    test_principal(VisitorPlan, platform_roles=[PlatformAdmin]),
    None,
  )
  assert_eq(admin.account_kind, AdminAccount)
  assert_false(admin.visitor)
}

///|
test "v1 enterprise personal plans normalize to paid tenant-scoped accounts" {
  let legacy = {
    ..empty_account_state(),
    schema: "moontown.account-store.v1",
    principals: [
      test_principal(EnterprisePlan, tenant_access=[enterprise_access()]),
    ],
  }
  guard legacy.to_json() is Object(legacy_fields) else {
    fail("legacy account fixture must serialize as an object")
  }
  legacy_fields.remove("subscriptions")
  legacy_fields.remove("audit_events")
  let decoded : AccountState = @json.from_json(
    migrate_account_state_json(Json::object(legacy_fields)),
  ) catch {
    error => fail("legacy account state did not decode: \{error}")
  }
  let migrated = normalize_account_state(decoded)
  validate_account_state(migrated)
  assert_eq(migrated.principals[0].personal_plan, PaidPlan)
  assert_eq(
    account_context_for(migrated.principals[0], None).account_kind,
    PaidUserAccount,
  )
  assert_eq(
    account_context_for(migrated.principals[0], Some("energy-labs")).account_kind,
    EnterpriseAccount,
  )
}

///|
test "persisted account state rejects duplicate session identities" {
  let principal = test_principal(PaidPlan)
  let registered = account_register_session(
    empty_account_state(),
    principal,
    "session-a",
    "opaque-token-a",
    expires_at_ms=1000UL,
  )
  let invalid = {
    ..registered,
    sessions: [registered.sessions[0], registered.sessions[0]],
  }
  try validate_account_state(invalid) catch {
    error => assert_true("\{error}".contains("duplicate sessions"))
  } noraise {
    _ => fail("duplicate persisted sessions must be rejected")
  }
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
async test "application tenant switching persists both account surfaces" {
  let path = "/tmp/moontown-account-application-switch-test.json"
  @fs.remove(path) catch {
    _ => ()
  }
  let application = account_application(
    path,
    test_principal(PaidPlan, tenant_access=[enterprise_access()]),
    "bootstrap:user-a",
    "opaque-token-a",
  )
  let personal = application.switch_tenant("opaque-token-a", None, now_ms=100UL)
  assert_eq(personal.account_kind, PaidUserAccount)
  let enterprise = application.switch_tenant(
    "opaque-token-a",
    Some("energy-labs"),
    now_ms=101UL,
  )
  assert_eq(enterprise.account_kind, EnterpriseAccount)
  assert_eq(enterprise.active_tenant_id, Some("energy-labs"))
  @fs.remove(path) catch {
    _ => ()
  }
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

///|
test "expired and revoked sessions are pruned without deleting principals" {
  let principal = test_principal(PaidPlan)
  let registered = account_register_session(
    empty_account_state(),
    principal,
    "session-a",
    "opaque-token-a",
    expires_at_ms=1000UL,
  )
  let revoked = account_revoke_session(
    registered,
    "opaque-token-a",
    now_ms=100UL,
  )
  let pruned = account_prune_sessions(revoked, now_ms=101UL)
  assert_eq(pruned.sessions.length(), 0)
  assert_eq(pruned.principals.length(), 1)
}

///|
async test "paid lifecycle persists billing and logout revokes access" {
  let path = "/tmp/moontown-account-paid-lifecycle-test.json"
  @fs.remove(path) catch {
    _ => ()
  }
  let application = account_application(
    path,
    test_principal(PaidPlan, platform_roles=[PlatformAdmin]),
    "bootstrap:user-a",
    "administrator-token-a",
  )
  let visitor = application.create_visitor_session(
    "visitor-opaque-token-a",
    "visitor-paid-test",
    now_ms=100UL,
  )
  assert_eq(visitor.context.account_kind, VisitorAccount)
  let paid = application.set_paid_subscription(
    visitor.opaque_token,
    true,
    now_ms=101UL,
  )
  assert_eq(paid.account_kind, PaidUserAccount)
  assert_true(
    application
    .billing_snapshot(visitor.opaque_token, now_ms=102UL)
    .stringify()
    .contains("\"status\":\"active\""),
  )
  let cancelled = application.set_paid_subscription(
    visitor.opaque_token,
    false,
    now_ms=103UL,
  )
  assert_eq(cancelled.account_kind, VisitorAccount)
  assert_true(
    application
    .billing_snapshot(visitor.opaque_token, now_ms=104UL)
    .stringify()
    .contains("\"status\":\"cancelled\""),
  )
  application.logout(visitor.opaque_token, now_ms=105UL)
  assert_true(application.resolve(visitor.opaque_token, now_ms=106UL) is None)
  @fs.remove(path) catch {
    _ => ()
  }
}

///|
async test "administrator provisions accounts and enterprise members durably" {
  let path = "/tmp/moontown-account-management-test.json"
  @fs.remove(path) catch {
    _ => ()
  }
  let administrator = test_principal(
    PaidPlan,
    platform_roles=[AccountMember, PlatformAdmin],
    tenant_access=[enterprise_access(roles=[AccountMember, OrganizationAdmin])],
  )
  let application = account_application(
    path, administrator, "bootstrap:user-a", "administrator-token-a",
  )
  let created = application.admin_create_account(
    "administrator-token-a",
    "managed-user",
    "Managed User",
    "paid-user",
    "",
    "",
    "session-managed-user",
    "managed-user-token-a",
    now_ms=200UL,
  )
  assert_eq(created.context.account_kind, PaidUserAccount)
  let created_visitor = application.admin_create_account(
    "administrator-token-a",
    "managed-visitor",
    "Managed Visitor",
    "visitor",
    "",
    "",
    "session-managed-visitor",
    "managed-visitor-token",
    now_ms=201UL,
  )
  assert_eq(created_visitor.context.account_kind, VisitorAccount)
  let created_admin = application.admin_create_account(
    "administrator-token-a",
    "managed-admin",
    "Managed Admin",
    "admin",
    "",
    "",
    "session-managed-admin",
    "managed-admin-token-a",
    now_ms=202UL,
  )
  assert_eq(created_admin.context.account_kind, AdminAccount)
  let enterprise = application.enterprise_upsert_member(
    "administrator-token-a",
    "managed-user",
    "Managed User",
    false,
    "session-managed-enterprise",
    "managed-enterprise-token",
    now_ms=203UL,
  )
  assert_eq(enterprise.context.account_kind, EnterpriseAccount)
  assert_true(
    application
    .enterprise_snapshot("administrator-token-a", now_ms=204UL)
    .stringify()
    .contains("managed-user"),
  )
  assert_true(
    application
    .admin_snapshot("administrator-token-a", now_ms=204UL)
    .stringify()
    .contains("account.created"),
  )
  let removed = application.enterprise_remove_member(
    "administrator-token-a",
    "managed-user",
    now_ms=205UL,
  )
  assert_true(removed.stringify().contains("\"account_kind\":\"paid-user\""))
  let deactivated = application.admin_set_account_active(
    "administrator-token-a",
    "managed-user",
    false,
    now_ms=206UL,
  )
  assert_true(deactivated.stringify().contains("\"active\":false"))
  assert_true(application.resolve(created.opaque_token, now_ms=207UL) is None)
  let reactivated = application.admin_set_account_active(
    "administrator-token-a",
    "managed-user",
    true,
    now_ms=208UL,
  )
  assert_true(reactivated.stringify().contains("\"active\":true"))
  @fs.remove(path) catch {
    _ => ()
  }
}

///|
async test "administrator-created enterprise owner can manage members" {
  let path = "/tmp/moontown-account-enterprise-owner-test.json"
  @fs.remove(path) catch {
    _ => ()
  }
  let application = account_application(
    path,
    test_principal(PaidPlan, platform_roles=[AccountMember, PlatformAdmin]),
    "bootstrap:user-a",
    "administrator-token-a",
  )
  let owner = application.admin_create_account(
    "administrator-token-a",
    "enterprise-owner",
    "Enterprise Owner",
    "enterprise",
    "acme",
    "Acme",
    "session-enterprise-owner",
    "enterprise-owner-token",
    now_ms=250UL,
  )
  assert_eq(owner.context.account_kind, EnterpriseAccount)
  assert_true(owner.context.has_entitlement(ManageOrganizationMembers))
  let invited = application.enterprise_upsert_member(
    owner.opaque_token,
    "enterprise-member",
    "Enterprise Member",
    true,
    "session-enterprise-member",
    "enterprise-member-token",
    now_ms=251UL,
  )
  assert_eq(invited.context.account_kind, EnterpriseAccount)
  assert_true(invited.context.has_entitlement(ManageOrganizationMembers))
  assert_true(
    application
    .enterprise_snapshot(owner.opaque_token, now_ms=252UL)
    .stringify()
    .contains("enterprise-member"),
  )
  @fs.remove(path) catch {
    _ => ()
  }
}

///|
async test "bootstrap logout remains revoked across reloads" {
  let path = "/tmp/moontown-account-bootstrap-logout-test.json"
  @fs.remove(path) catch {
    _ => ()
  }
  let application = account_application(
    path,
    test_principal(PaidPlan, platform_roles=[PlatformAdmin]),
    "bootstrap:user-a",
    "administrator-token-a",
  )
  assert_true(
    application.resolve("administrator-token-a", now_ms=300UL) is Some(_),
  )
  application.logout("administrator-token-a", now_ms=301UL)
  assert_true(
    application.resolve("administrator-token-a", now_ms=302UL) is None,
  )
  assert_true(
    application.resolve("administrator-token-a", now_ms=303UL) is None,
  )
  @fs.remove(path) catch {
    _ => ()
  }
}
