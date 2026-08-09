///|
priv enum AccountExperienceKind {
  VisitorExperience
  PaidExperience
  EnterpriseExperience
  AdminExperience
} derive(Debug, Eq)

///|
priv struct AccountExperience {
  contract_id : String
  user_id : String
  display_name : String
  plan : String
  roles : Array[String]
  entitlements : Array[String]
  active_tenant_id : String?
  active_tenant_name : String?
  tenant_choices : Array[AccountTenantChoice]
  home_surface : String
  visitor : Bool
} derive(Debug, Eq, FromJson)

///|
priv struct AccountTenantChoice {
  tenant_id : String
  tenant_name : String
  plan : String
  roles : Array[String]
} derive(Debug, Eq, FromJson)

///|
priv struct AccountNavItem {
  label : String
  href : String
  primary : Bool
} derive(Debug, Eq)

///|
priv enum AccountSurfaceRenderPlan {
  AccountTownProduct
  AccountOperationsProduct(OperationsContext)
  AccountOperationsDenied
}

///|
fn visitor_account_experience() -> AccountExperience {
  {
    contract_id: "moontown.account-context.v1",
    user_id: "visitor-fallback",
    display_name: "Visitor",
    plan: "visitor",
    roles: ["member"],
    entitlements: ["town.public.explore", "town.public.discover"],
    active_tenant_id: None,
    active_tenant_name: None,
    tenant_choices: [],
    home_surface: "public-town",
    visitor: true,
  }
}

///|
fn parse_bootstrap_account_experience() -> AccountExperience {
  let text = load_bootstrap_account_context_json()
  if text.is_empty() {
    return visitor_account_experience()
  }
  let parsed = @json.parse(text) catch {
    _ => return visitor_account_experience()
  }
  let account : AccountExperience = @json.from_json(parsed) catch {
    _ => return visitor_account_experience()
  }
  if account.contract_id != "moontown.account-context.v1" {
    visitor_account_experience()
  } else {
    account
  }
}

///|
fn AccountExperience::kind(self : AccountExperience) -> AccountExperienceKind {
  if self.roles.contains("platform-admin") ||
    self.home_surface == "admin-console" {
    AdminExperience
  } else {
    match self.plan {
      "paid" => PaidExperience
      "enterprise" => EnterpriseExperience
      _ => VisitorExperience
    }
  }
}

///|
fn account_experience_name(kind : AccountExperienceKind) -> String {
  match kind {
    VisitorExperience => "Visitor"
    PaidExperience => "Paid member"
    EnterpriseExperience => "Enterprise"
    AdminExperience => "Administrator"
  }
}

///|
fn account_experience_class(kind : AccountExperienceKind) -> String {
  match kind {
    VisitorExperience => "account-experience-visitor"
    PaidExperience => "account-experience-paid"
    EnterpriseExperience => "account-experience-enterprise"
    AdminExperience => "account-experience-admin"
  }
}

///|
fn account_navigation_items(
  kind : AccountExperienceKind,
) -> Array[AccountNavItem] {
  match kind {
    VisitorExperience =>
      [
        { label: "Explore town", href: "./index.html", primary: true },
        { label: "Policies", href: "./index.html?area=quests", primary: false },
        { label: "Talent", href: "./index.html?area=social", primary: false },
        { label: "Events", href: "./index.html?area=districts", primary: false },
        {
          label: "Join MoonTown",
          href: "./index.html?account=join",
          primary: true,
        },
      ]
    PaidExperience =>
      [
        { label: "My town", href: "./index.html", primary: true },
        { label: "My Agent", href: "./index.html?panel=agent", primary: false },
        { label: "Workspace", href: "./index.html?area=quests", primary: false },
        {
          label: "Marketplace",
          href: "./index.html?area=social",
          primary: false,
        },
        { label: "Billing", href: "./index.html?panel=billing", primary: false },
      ]
    EnterpriseExperience =>
      [
        { label: "Organization", href: "./index.html", primary: true },
        {
          label: "Team spaces",
          href: "./index.html?area=districts",
          primary: false,
        },
        {
          label: "Shared Agents",
          href: "./index.html?area=residents",
          primary: false,
        },
        { label: "Members", href: "./index.html?area=social", primary: false },
        { label: "Usage", href: "./index.html?panel=usage", primary: false },
        {
          label: "Compliance",
          href: "./index.html?panel=compliance",
          primary: false,
        },
      ]
    AdminExperience =>
      [
        { label: "Overview", href: "./operations.html", primary: true },
        {
          label: "Users",
          href: "./operations.html?admin=users",
          primary: false,
        },
        {
          label: "Organizations",
          href: "./operations.html?admin=tenants",
          primary: false,
        },
        {
          label: "Moderation",
          href: "./operations.html?admin=moderation",
          primary: false,
        },
        {
          label: "Analytics",
          href: "./operations.html?admin=analytics",
          primary: false,
        },
        {
          label: "Audit",
          href: "./operations.html?admin=audit",
          primary: false,
        },
        { label: "View town", href: "./index.html?view=town", primary: false },
      ]
  }
}

///|
fn account_surface_render_plan(
  route : TownSurfaceRoute,
  model : Model,
  account : AccountExperience,
  admin_town_preview : Bool,
) -> AccountSurfaceRenderPlan {
  match account.kind() {
    AdminExperience =>
      match route {
        OperationsConsole =>
          AccountOperationsProduct(build_operations_context(model))
        CanonicalEnergyValley if admin_town_preview => AccountTownProduct
        CanonicalEnergyValley =>
          AccountOperationsProduct(build_operations_context(model))
      }
    _ =>
      match route {
        OperationsConsole => AccountOperationsDenied
        CanonicalEnergyValley => AccountTownProduct
      }
  }
}

///|
fn account_avatar_label(display_name : String) -> String {
  display_name.get_char(0).map(char => char.to_string()).unwrap_or("M")
}

///|
fn render_account_navigation(account : AccountExperience) -> @rabbita.Html {
  let kind = account.kind()
  let tenant_label = account.active_tenant_name.unwrap_or_else(() => {
    if kind == PaidExperience {
      "Personal workspace"
    } else {
      "Public town"
    }
  })
  @html.nav(
    class="account-global-nav " + account_experience_class(kind),
    attrs=@html.Attrs::build().aria_label("Account navigation"),
    [
      div(class="account-global-identity", [
        span(class="account-global-brand", "MoonTown"),
        span(class="account-global-plan", account_experience_name(kind)),
        span(class="account-global-tenant", tenant_label),
      ]),
      div(
        class="account-global-links",
        account_navigation_items(kind).map(item => {
          a(
            class=if item.primary {
              "account-global-link is-primary"
            } else {
              "account-global-link"
            },
            href=item.href,
            item.label,
          )
        }),
      ),
      div(class="account-global-user", [
        span(
          class="account-global-avatar",
          account_avatar_label(account.display_name),
        ),
        span(class="account-global-user-name", account.display_name),
      ]),
    ],
  )
}

///|
fn render_account_operations_denied() -> @rabbita.Html {
  @html.main_(class="account-access-denied", [
    div(class="account-access-denied-panel", [
      span(class="account-access-kicker", "MoonTown account boundary"),
      h1("Operations access is restricted"),
      p(
        "This console is available only to explicitly authorized platform administrators.",
      ),
      a(
        class="account-access-return",
        href="./index.html",
        "Return to the town",
      ),
    ]),
  ])
}

///|
fn render_account_surface_for_route(
  route : TownSurfaceRoute,
  dispatch : Dispatch[Msg],
  model : Model,
  account : AccountExperience,
) -> @rabbita.Html {
  let plan = account_surface_render_plan(
    route,
    model,
    account,
    current_browser_query_param("view") == "town",
  )
  div(class="account-experience " + account_experience_class(account.kind()), [
    render_account_navigation(account),
    div(class="account-product-surface", [
      match plan {
        AccountTownProduct => render_energy_valley_page(dispatch, model)
        AccountOperationsProduct(context) =>
          render_dashboard_page(dispatch, model, context)
        AccountOperationsDenied => render_account_operations_denied()
      },
    ]),
  ])
}
