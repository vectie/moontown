///|
priv enum AccountExperienceKind {
  VisitorExperience
  MemberExperience
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
fn account_has_entitlements(
  account : AccountExperience,
  required : Array[String],
) -> Bool {
  required.all(entitlement => account.entitlements.contains(entitlement))
}

///|
/// Reject contradictory wire projections before they can select privileged
/// navigation or management surfaces.
fn account_experience_valid(account : AccountExperience) -> Bool {
  if account.user_id.trim().is_empty() ||
    account.display_name.trim().is_empty() ||
    !account_has_entitlements(account, [
      "town.public.explore", "town.public.discover",
    ]) {
    return false
  }
  let tenant_pair_valid = match
    (account.active_tenant_id, account.active_tenant_name) {
    (None, None) => true
    (Some(tenant_id), Some(tenant_name)) =>
      !tenant_id.trim().is_empty() &&
      !tenant_name.trim().is_empty() &&
      account.tenant_choices.any(choice => {
        choice.tenant_id == tenant_id &&
        choice.tenant_name == tenant_name &&
        choice.plan == "enterprise"
      })
    _ => false
  }
  if !tenant_pair_valid {
    return false
  }
  match account.account_kind {
    "member" =>
      account.plan == "visitor" &&
      !account.visitor &&
      account.home_surface == "public-town" &&
      account.active_tenant_id is None &&
      account.roles == ["member"] &&
      account.entitlements ==
      ["town.public.explore", "town.public.discover", "compute.own.view"]
    "visitor" =>
      account.plan == "visitor" &&
      account.home_surface == "public-town" &&
      account.visitor &&
      account.active_tenant_id is None
    "paid-user" =>
      account.plan == "paid" &&
      account.home_surface == "personal-town" &&
      !account.visitor &&
      account.active_tenant_id is None &&
      account_has_entitlements(account, [
        "agent.personal.use", "workspace.personal.manage", "marketplace.action.use",
        "billing.personal.manage",
      ])
    "enterprise" =>
      account.plan == "enterprise" &&
      account.home_surface == "enterprise-town" &&
      !account.visitor &&
      account.active_tenant_id is Some(_) &&
      account_has_entitlements(account, [
        "workspace.team.use", "agent.shared.use", "organization.members.view",
      ])
    "admin" =>
      account.roles.contains("platform-admin") &&
      account.home_surface == "admin-console" &&
      !account.visitor &&
      account_has_entitlements(account, [
        "platform.admin.access", "platform.users.manage", "platform.health.manage",
      ])
    _ => false
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
  if account.contract_id != "moontown.account-context.v1" ||
    !account_experience_valid(account) {
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
      "member" => MemberExperience
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
    MemberExperience => "member"
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
    VisitorExperience => "游客"
    MemberExperience => "统一账户"
    PaidExperience => "个人"
    EnterpriseExperience => "团队"
    AdminExperience => "管理员"
  }
}

///|
fn account_experience_class(kind : AccountExperienceKind) -> String {
  match kind {
    VisitorExperience => "account-experience-visitor"
    MemberExperience => "account-experience-member"
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
    MemberExperience =>
      [
        { label: "小镇", href: "./index.html", primary: true, },
        {
          label: "我的算力",
          href: "./index.html?layer=compute",
          primary: false,
        },
      ]
    VisitorExperience =>
      [
        { label: "Explore town", href: "./index.html", primary: true, },
        {
          label: "Policies",
          href: "./index.html?layer=indoor&building=policy-hall",
          primary: false,
        },
        { label: "Talent", href: "./index.html?area=social", primary: false, },
        {
          label: "Districts",
          href: "./index.html?area=districts",
          primary: false,
        },
        {
          label: "Join MoonTown",
          href: "./index.html?panel=join",
          primary: true,
        },
      ]
    PaidExperience =>
      [
        { label: "My town", href: "./index.html", primary: true, },
        { label: "My Agent", href: "./index.html?panel=agent", primary: false, },
        {
          label: "Workspace",
          href: "./index.html?area=quests",
          primary: false,
        },
        {
          label: "Marketplace",
          href: "./index.html?area=social",
          primary: false,
        },
        {
          label: "Billing",
          href: "./index.html?panel=billing",
          primary: false,
        },
      ]
    EnterpriseExperience =>
      [
        { label: "Organization", href: "./index.html", primary: true, },
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
        {
          label: "Members",
          href: "./index.html?panel=members",
          primary: false,
        },
        { label: "Usage", href: "./index.html?panel=usage", primary: false, },
        {
          label: "Compliance",
          href: "./index.html?panel=compliance",
          primary: false,
        },
      ]
    AdminExperience =>
      [
        { label: "Overview", href: "./operations.html", primary: true, },
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
        { label: "View town", href: "./index.html?view=town", primary: false, },
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
fn account_primary_navigation_items(
  kind : AccountExperienceKind,
) -> Array[AccountNavItem] {
  let town = if kind == AdminExperience {
    "./index.html?view=town"
  } else {
    "./index.html"
  }
  let separator = if town.contains("?") { "&" } else { "?" }
  [
    { label: "小镇", href: town, primary: true, },
    {
      label: "工作",
      href: town + separator + "request=watch",
      primary: false,
    },
    {
      label: "成果",
      href: town + separator + "request=outcomes",
      primary: false,
    },
    {
      label: "算力",
      href: town + separator + "layer=compute",
      primary: false,
    },
  ]
}

///|
fn account_navigation_icon(label : String) -> String {
  match label {
    "工作" => "work"
    "成果" => "book"
    "算力" => "server"
    _ => "building"
  }
}

///|
fn account_secondary_label(label : String) -> String {
  match label {
    "Policies" => "政策"
    "Talent" => "人才 · 示例"
    "Districts" | "Team spaces" => "街区"
    "Join MoonTown" => "本地账户兼容"
    "Workspace" => "任务空间"
    "Marketplace" => "发现"
    "Billing" => "方案与用量"
    "Shared Agents" => "团队 Agent"
    "Members" => "成员"
    "Usage" => "用量"
    "Compliance" => "访问记录"
    "Overview" => "管理概览"
    "Users" => "用户"
    "Organizations" => "组织"
    "Analytics" => "平台统计"
    "Settings" => "设置"
    "Audit" => "审计"
    _ => label
  }
}

///|
fn account_secondary_navigation_items(
  kind : AccountExperienceKind,
) -> Array[AccountNavItem] {
  account_navigation_items(kind).filter(item => {
    // These old links select no user surface; their current destinations are
    // the work panel and resident directory instead.
    item.label != "My Agent" &&
    item.label != "My town" &&
    item.label != "Organization" &&
    item.label != "Explore town" &&
    item.label != "小镇" &&
    item.label != "我的算力" &&
    item.label != "View town"
  })
}

///|
fn account_primary_item_active(
  label : String,
  kind : AccountExperienceKind,
) -> Bool {
  if current_town_surface_route() is OperationsConsole ||
    !current_browser_query_param("panel").is_empty() ||
    (kind == AdminExperience && current_browser_query_param("view") != "town") {
    return false
  }
  if current_browser_query_param("layer") == "compute" {
    return label == "算力"
  }
  let request = current_browser_query_param("request")
  match label {
    "成果" => request == "outcomes"
    "工作" => !request.is_empty() && request != "outcomes"
    "算力" => current_browser_query_param("layer") == "compute"
    _ => request.is_empty() && current_browser_query_param("layer") != "compute"
  }
}

///|
fn render_account_navigation(
  account : AccountExperience,
  dispatch? : Dispatch[Msg],
) -> @rabbita.Html {
  let kind = account.kind()
  let admin_surface = current_browser_query_param("admin")
  let tenant_label = account.active_tenant_name.unwrap_or_else(() => {
    match kind {
      PaidExperience => "个人工作区"
      AdminExperience => "平台管理"
      _ => "公共小镇"
    }
  })
  @html.nav(
    class="account-global-nav " + account_experience_class(kind),
    attrs=@html.Attrs::build().aria_label("Account navigation"),
    [
      div(class="account-global-identity", [
        span(class="account-global-brand", "MoonTown"),
        span(class="account-global-tenant", tenant_label),
      ]),
      div(
        class="account-global-links",
        [
          ..account_primary_navigation_items(kind).map(item => {
            let highlighted = account_primary_item_active(item.label, kind)
            let class_ = if highlighted {
              "account-global-link is-primary"
            } else {
              "account-global-link"
            }
            let attrs = @html.Attrs::build().aria_current(
              if highlighted {
                "page"
              } else {
                "false"
              },
            )
            let label = town_ui_label(
              account_navigation_icon(item.label),
              item.label,
            )
            match (dispatch, current_town_surface_route()) {
              (Some(emit), CanonicalEnergyValley) if current_browser_query_param(
                  "panel",
                ).is_empty() =>
                button(
                  class=class_,
                  attrs~,
                  on_click=emit(
                    match item.label {
                      "工作" => OpenWorkWorkspace(StandingWatchComposer)
                      "成果" => OpenWorkWorkspace(ResultsComposer)
                      "算力" => OpenSecretComputeRoom
                      _ => OpenTownWorkspace
                    },
                  ),
                  label,
                )
              _ =>
                a(
                  class=class_,
                  href=account_navigation_href(item.href, kind),
                  attrs~,
                  label,
                )
            }
          }),
          a(
            class="account-global-link",
            href=shared_account_portal_url(current_browser_origin()),
            target=Blank,
            rel="noopener noreferrer",
            attrs=@html.Attrs::build().aria_label(
              "统一账户（新标签页）",
            ),
            title=if account.visitor {
              "登录统一账户"
            } else {
              "打开账户中心"
            },
            town_ui_label(
              "people",
              if account.visitor {
                "登录"
              } else {
                "账户"
              },
            ),
          ),
        ],
      ),
      div(class="account-global-user", [
        if account_secondary_navigation_items(kind).is_empty() &&
          public_platform_enabled() {
          @html.nothing
        } else {
          @html.details(class="account-navigation-more", [
            @html.summary(
              class="account-global-link",
              town_ui_label(
                "sliders",
                if kind == AdminExperience {
                  "管理"
                } else {
                  "高级"
                },
              ),
            ),
            div(
              class="account-navigation-menu",
              [
                button(
                  id="account-pack-tools-open",
                  class="account-global-link",
                  attrs=@html.Attrs::build().aria_label("领域资料"),
                  on_click=@cmd.custom_cmd(_ => open_advanced_pack_tools()),
                  town_ui_label("book", "领域资料"),
                ),
                ..account_secondary_navigation_items(kind).map(item => {
                  a(
                    class=if kind == AdminExperience &&
                      admin_navigation_item_active(item.label, admin_surface) {
                      "account-global-link is-primary"
                    } else {
                      "account-global-link"
                    },
                    href=account_navigation_href(item.href, kind),
                    attrs=@html.Attrs::build().aria_label(
                      account_secondary_label(item.label),
                    ),
                    account_secondary_label(item.label),
                  )
                }),
              ],
            ),
          ])
        },
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
  let (title, _) = account_management_heading(surface)
  @html.main_(class="account-management", [
    section(class="account-management-shell", [
      header(class="account-management-header", [h1(title)]),
      div(id="account-management-root", class="account-management-workspace", [
        p(
          id="account-management-status",
          class="account-management-status",
          attrs=@html.Attrs::build().role("status").aria_live("polite"),
          "Loading…",
        ),
      ]),
    ]),
  ])
}

///|
fn render_account_operations_denied() -> @rabbita.Html {
  @html.main_(class="account-access-denied", [
    div(class="account-access-denied-panel", [
      h1("Operations access is restricted"),
      p("Platform administrator access required."),
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
  // The shared platform already has one compact identity/compute entry in the
  // town HUD. Do not expose legacy Join/billing navigation as a second account.
  if public_platform_enabled() {
    return match route {
      CanonicalEnergyValley => render_energy_valley_page(dispatch, model)
      OperationsConsole => render_account_operations_denied()
    }
  }
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
    render_account_navigation(account, dispatch~),
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
