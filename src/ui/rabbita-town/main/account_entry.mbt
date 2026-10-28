///|
/// Keep the verified public port for local previews. A hosted town stays on
/// its own approved origin: moving from 8443 to 443 is a deployment migration,
/// not a browser redirect. Opening this page does not bind a local session.
fn shared_account_portal_url(origin : String) -> String {
  match origin {
    "https://suanli.kechuangfuwu.com"
    | "https://suanli.kechuangfuwu.com:8443" => origin + "/user/"
    _ => "https://suanli.kechuangfuwu.com:8443/user/"
  }
}

///|
fn render_shared_account_entry(state : String) -> @rabbita.Html {
  let label = match state {
    "sign-in-required" | "public-demo" => "登录"
    "not-configured" => "在线账户"
    _ => "账户中心"
  }
  a(
    class="building-interior-exit",
    href=shared_account_portal_url(current_browser_origin()),
    target=Blank,
    rel="noopener noreferrer",
    attrs=@html.Attrs::build().aria_label(label + "（新标签页）"),
    label,
  )
}

///|
extern "js" fn public_platform_enabled() -> Bool =
  #|() => globalThis.__MOONTOWN_PUBLIC_PLATFORM === true

///|
fn render_public_platform_account() -> @rabbita.Html {
  if !public_platform_enabled() {
    return @html.nothing
  }
  let account = parse_bootstrap_account_experience()
  let signed_in = !account.visitor
  div(class="town-platform-account", [
    a(
      class="town-topbar-chip",
      href="./index.html?layer=compute",
      title=if signed_in {
        "查看账户可见的算力"
      } else {
        "查看 Trial 展示算力"
      },
      town_ui_label("server", "算力"),
    ),
    a(
      class="town-topbar-chip",
      href=shared_account_portal_url(current_browser_origin()),
      target=Blank,
      rel="noopener noreferrer",
      attrs=@html.Attrs::build().aria_label(
        if signed_in {
          "账户中心（新标签页）"
        } else {
          "登录（新标签页）"
        },
      ),
      if signed_in {
        "账户"
      } else {
        "登录"
      },
    ),
  ])
}
