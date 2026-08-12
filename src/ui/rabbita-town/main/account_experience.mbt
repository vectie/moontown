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
  account_kind : String
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
    account_kind: "visitor",
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
  if self.account_kind == "admin" ||
    self.roles.contains("platform-admin") ||
    self.home_surface == "admin-console" {
    AdminExperience
  } else {
    match self.account_kind {
      "paid-user" => PaidExperience
      "enterprise" => EnterpriseExperience
      _ =>
        match self.plan {
          "paid" => PaidExperience
          "enterprise" => EnterpriseExperience
          _ => VisitorExperience
        }
    }
  }
}

///|
fn account_experience_query_name(kind : AccountExperienceKind) -> String {
  match kind {
    VisitorExperience => "visitor"
    PaidExperience => "paid"
    EnterpriseExperience => "enterprise"
    AdminExperience => "admin"
  }
}

///| Preserve an explicitly requested local preview while normal sessions remain

///|
/// entirely token-derived.
fn account_navigation_href(
  href : String,
  kind : AccountExperienceKind,
) -> String {
  if current_browser_query_param("demo") != "1" {
    return href
  }
  let separator = if href.contains("?") { "&" } else { "?" }
  href + separator + "demo=1&account=" + account_experience_query_name(kind)
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
          href: "./index.html?panel=join",
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
        { label: "Members", href: "./index.html?panel=members", primary: false },
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
          label: "Analytics",
          href: "./operations.html?admin=analytics",
          primary: false,
        },
        {
          label: "Settings",
          href: "./operations.html?admin=settings",
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
fn admin_navigation_item_active(label : String, surface : String) -> Bool {
  match surface {
    "users" => label == "Users"
    "tenants" => label == "Organizations"
    "analytics" => label == "Analytics"
    "settings" => label == "Settings"
    "audit" => label == "Audit"
    _ => label == "Overview"
  }
}

///|
fn render_account_navigation(account : AccountExperience) -> @rabbita.Html {
  let kind = account.kind()
  let admin_surface = current_browser_query_param("admin")
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
          let highlighted = if kind == AdminExperience {
            admin_navigation_item_active(item.label, admin_surface)
          } else {
            item.primary
          }
          a(
            class=if highlighted {
              "account-global-link is-primary"
            } else {
              "account-global-link"
            },
            href=account_navigation_href(item.href, kind),
            item.label,
          )
        }),
      ),
      div(class="account-global-user", [
        div(id="account-tenant-switcher", class="account-tenant-switcher", ""),
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
fn requested_account_management_surface(
  route : TownSurfaceRoute,
  kind : AccountExperienceKind,
) -> String? {
  let panel = current_browser_query_param("panel")
  match kind {
    VisitorExperience if panel == "join" => Some("join")
    PaidExperience if panel == "billing" => Some("billing")
    EnterpriseExperience if panel == "members" => Some("members")
    EnterpriseExperience if panel == "usage" => Some("usage")
    EnterpriseExperience if panel == "compliance" => Some("compliance")
    AdminExperience =>
      match route {
        OperationsConsole => {
          let section = current_browser_query_param("admin")
          Some(if section.is_empty() { "overview" } else { section })
        }
        CanonicalEnergyValley => None
      }
    _ => None
  }
}

///|
fn account_management_heading(surface : String) -> (String, String) {
  match surface {
    "join" =>
      (
        "Join MoonTown", "Activate a paid personal workspace and keep this account session.",
      )
    "billing" =>
      (
        "Personal billing", "Review the persisted subscription state or change the personal plan.",
      )
    "members" =>
      (
        "Organization members", "Invite members, assign organization administration, or remove access.",
      )
    "usage" =>
      (
        "Organization usage", "Review active membership and session usage for the selected tenant.",
      )
    "compliance" =>
      (
        "Compliance controls", "Inspect session, audit, and impersonation controls reported by the server.",
      )
    "users" =>
      (
        "Platform users", "Provision one of the four account kinds and control account activation.",
      )
    "tenants" =>
      (
        "Organizations", "Review tenants derived from durable enterprise membership records.",
      )
    "analytics" =>
      (
        "Platform analytics", "Review authoritative user, tenant, and active-session counts.",
      )
    "settings" =>
      (
        "System settings", "Manage grouped operational policy, capacity, retention, freshness, and service limits.",
      )
    "audit" =>
      ("Audit log", "Review bounded account lifecycle and membership events.")
    _ =>
      (
        "Account operations", "Review the authoritative platform account state without impersonation.",
      )
  }
}

///|
fn render_account_management_surface(surface : String) -> @rabbita.Html {
  let (title, description) = account_management_heading(surface)
  @html.main_(class="account-management", [
    section(class="account-management-shell", [
      header(class="account-management-header", [
        span(class="account-access-kicker", "MoonTown account system"),
        h1(title),
        p(description),
      ]),
      div(id="account-management-root", class="account-management-workspace", [
        p(
          id="account-management-status",
          class="account-management-status",
          attrs=@html.Attrs::build().role("status").aria_live("polite"),
          "Loading authoritative account data…",
        ),
      ]),
    ]),
  ])
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
  let management_surface = requested_account_management_surface(
    route,
    account.kind(),
  )
  div(class="account-experience " + account_experience_class(account.kind()), [
    render_account_navigation(account),
    div(class="account-product-surface", [
      match management_surface {
        Some(surface) => render_account_management_surface(surface)
        None =>
          match plan {
            AccountTownProduct => render_energy_valley_page(dispatch, model)
            AccountOperationsProduct(context) =>
              render_dashboard_page(dispatch, model, context)
            AccountOperationsDenied => render_account_operations_denied()
          }
      },
    ]),
  ])
}
