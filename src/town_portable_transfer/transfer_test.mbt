///|
test "public defaults exact identity and authoritative account actor" {
  let limits = @town_portable_transfer.default_limits()
  assert_eq(limits.max_package_bytes, 67108864)
  assert_eq(limits.chunk_bytes, 65536)
  assert_eq(limits.max_retained_bytes, 536870912)
  assert_eq(limits.lease_ms, 600000UL)
  let first = @town_portable_transfer.package_id("sha256:first")
  assert_eq(first.length(), 68)
  assert_true(first.has_prefix("pkg-"))
  assert_eq(first, @town_portable_transfer.package_id("sha256:first"))
  assert_true(first != @town_portable_transfer.package_id("sha256:second"))
  let principal : @account_system.AccountPrincipal = {
    user_id: "alice",
    display_name: "Alice",
    personal_plan: PaidPlan,
    platform_roles: [AccountPublisher],
    active: true,
    version: 1,
    tenant_access: [
      {
        tenant_id: "team",
        tenant_name: "Team",
        plan: EnterprisePlan,
        roles: [AccountMember],
        active: true,
        version: 1,
      },
    ],
  }
  let personal = @town_portable_transfer.actor_for_account(
    @account_system.account_context_for(principal, None),
  )
  assert_eq(personal.principal_id, "alice")
  assert_eq(personal.tenant_id, "personal:alice")
  assert_true(personal.publisher)
  let team = @town_portable_transfer.actor_for_account(
    @account_system.account_context_for(principal, Some("team")),
  )
  assert_eq(team.tenant_id, "team")
  assert_true(team != personal)
  let visitor = @account_system.account_context_for(
    { ..principal, personal_plan: VisitorPlan, platform_roles: [], },
    None,
  )
  try @town_portable_transfer.actor_for_account(visitor) catch {
    @town_portable_transfer.TransferError(code, reason) => {
      assert_eq(code, 403)
      assert_eq(reason, "marketplace_entitlement_required")
    }
    _ => fail("wrong error")
  } noraise {
    _ => fail("visitor must be denied")
  }
}
