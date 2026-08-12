///|
fn account_experience_test_value(
  plan : String,
  roles? : Array[String] = ["member"],
  active_tenant_name? : String,
  home_surface? : String = "personal-town",
) -> AccountExperience {
  {
    contract_id: "moontown.account-context.v1",
    user_id: "test-user",
    display_name: "Test User",
    account_kind: if roles.contains("platform-admin") {
      "admin"
    } else if plan == "enterprise" {
      "enterprise"
    } else if plan == "paid" {
      "paid-user"
    } else {
      "visitor"
    },
    plan,
    roles,
    entitlements: [],
    active_tenant_id: active_tenant_name.map(_ => "test-tenant"),
    active_tenant_name,
    tenant_choices: [],
    home_surface,
    visitor: plan == "visitor",
  }
}

///|
test "bootstrap projection accepts server tenant choices" {
  let parsed : AccountExperience = @json.from_json(
    @json.parse(
      (
        #|{"contract_id":"moontown.account-context.v1","user_id":"enterprise-user","display_name":"Enterprise User","account_kind":"enterprise","plan":"enterprise","roles":["organization-admin"],"entitlements":["organization.manage"],"active_tenant_id":"energy-labs","active_tenant_name":"Energy Labs","tenant_choices":[{"tenant_id":"energy-labs","tenant_name":"Energy Labs","plan":"enterprise","roles":["organization-admin"]}],"home_surface":"enterprise-town","visitor":false}
      ),
    ),
  )
  assert_eq(parsed.kind(), EnterpriseExperience)
  assert_eq(parsed.tenant_choices.length(), 1)
}

///|
test "bootstrap projection accepts normalized paid tenant" {
  let text =
    #|{"contract_id":"moontown.account-context.v1","user_id":"paid-preview","display_name":"MoonTown Member","account_kind":"paid-user","plan":"paid","roles":["member"],"entitlements":["town.public.explore","agent.personal.use"],"tenant_choices":[],"home_surface":"personal-town","visitor":false}
  let parsed : AccountExperience = @json.from_json(@json.parse(text))
  assert_eq(parsed.kind(), PaidExperience)
}

///|
test "contradictory privileged account projections are invalid" {
  let text =
    #|{"contract_id":"moontown.account-context.v1","user_id":"impossible-admin","display_name":"Impossible Admin","account_kind":"admin","plan":"enterprise","roles":["platform-admin"],"entitlements":["town.public.explore","town.public.discover","platform.admin.access","platform.users.manage","platform.health.manage"],"active_tenant_id":"missing-tenant","active_tenant_name":"Missing Tenant","tenant_choices":[],"home_surface":"admin-console","visitor":true}
  let parsed : AccountExperience = @json.from_json(@json.parse(text))
  assert_false(account_experience_valid(parsed))
}

///|
test "four account experiences keep distinct navigation" {
  let visitor = account_experience_test_value(
    "visitor",
    home_surface="public-town",
  )
  let paid = account_experience_test_value("paid")
  let enterprise = account_experience_test_value(
    "enterprise",
    active_tenant_name="Energy Labs",
    home_surface="enterprise-town",
  )
  let admin = account_experience_test_value(
    "enterprise",
    roles=["platform-admin"],
    home_surface="admin-console",
  )
  assert_eq(visitor.kind(), VisitorExperience)
  assert_eq(paid.kind(), PaidExperience)
  assert_eq(enterprise.kind(), EnterpriseExperience)
  assert_eq(admin.kind(), AdminExperience)
  assert_true(
    account_navigation_items(VisitorExperience).any(item => {
      item.label == "Join MoonTown"
    }),
  )
  assert_true(
    account_navigation_items(PaidExperience).any(item => {
      item.label == "My Agent"
    }),
  )
  assert_true(
    account_navigation_items(EnterpriseExperience).any(item => {
      item.label == "Members"
    }),
  )
  assert_true(
    account_navigation_items(AdminExperience).any(item => item.label == "Users"),
  )
  assert_false(
    account_navigation_items(AdminExperience).any(item => {
      item.label == "Moderation"
    }),
  )
}

///|
test "account navigation exposes plan tenant and accessible label" {
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_account_navigation(
        account_experience_test_value(
          "enterprise",
          active_tenant_name="Energy Labs",
          home_surface="enterprise-town",
        ),
      ),
    ),
  )
  assert_true(html.contains("aria-label=\"Account navigation\""))
  assert_true(html.contains("Enterprise"))
  assert_true(html.contains("Energy Labs"))
  assert_true(html.contains("Shared Agents"))
  assert_true(html.contains("account-global-avatar"))
}

///|
test "non-admin operations denial provides a recovery action" {
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_account_operations_denied()),
  )
  assert_true(html.contains("Operations access is restricted"))
  assert_true(html.contains("Return to the town"))
  assert_true(html.contains("href=\"./index.html\""))
}

///|
test "management surfaces render a live status region" {
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_account_management_surface("billing")),
  )
  assert_true(html.contains("Personal billing"))
  assert_true(html.contains("id=\"account-management-root\""))
  assert_true(html.contains("aria-live=\"polite\""))
}

///|
test "administrator navigation and heading expose system settings" {
  let navigation = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_account_navigation(
        account_experience_test_value(
          "admin",
          roles=["platform-admin"],
          home_surface="admin-console",
        ),
      ),
    ),
  )
  assert_true(navigation.contains("admin=settings"))
  let surface = @rabbita.render_to_string(
    @rabbita.static_cell(render_account_management_surface("settings")),
  )
  assert_true(surface.contains("System settings"))
}

///|
test "administrator navigation highlights the selected management surface" {
  assert_true(admin_navigation_item_active("Settings", "settings"))
  assert_false(admin_navigation_item_active("Overview", "settings"))
  assert_true(admin_navigation_item_active("Overview", ""))
}
