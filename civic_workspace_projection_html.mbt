///|
fn civic_generated_site_html(service : @civic.CivicServiceDefinition) -> String {
  [
    "<!doctype html>",
    "<html lang=\"en\">",
    "<head>",
    "  <meta charset=\"utf-8\">",
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
    "  <title>Wenyu Valley / \{service.title}</title>",
    civic_generated_site_styles(),
    "</head>",
    "<body>",
    "<main>",
    civic_generated_site_hero(service),
    civic_generated_site_work_sections(service),
    civic_generated_site_workspace_sections(service),
    "</main>",
    "</body>",
    "</html>",
  ].join("\n")
}

///|
fn civic_generated_site_styles() -> String {
  [
    "  <style>", "    body{margin:0;font-family:Georgia,'Times New Roman',serif;background:#f5f0df;color:#20321f;}",
    "    main{max-width:960px;margin:0 auto;padding:48px 24px 72px;}", "    .hero{border:1px solid rgba(32,50,31,.18);border-radius:28px;padding:36px;background:linear-gradient(135deg,#fff9df,#dceec8);box-shadow:0 22px 70px rgba(55,81,46,.16);}",
    "    .eyebrow{letter-spacing:.14em;text-transform:uppercase;font:700 12px system-ui,sans-serif;color:#60733a;}",
    "    h1{font-size:48px;line-height:1;margin:10px 0 16px;}", "    h2{margin-top:34px;}",
    "    li{margin:8px 0;}", "    .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px;margin-top:22px;}",
    "    .card{border:1px solid rgba(32,50,31,.14);border-radius:18px;padding:18px;background:rgba(255,255,255,.68);}",
    "    code{background:rgba(32,50,31,.08);padding:2px 6px;border-radius:6px;}",
    "  </style>",
  ].join("\n")
}

///|
fn civic_generated_site_hero(service : @civic.CivicServiceDefinition) -> String {
  [
    "  <section class=\"hero\">",
    "    <p class=\"eyebrow\">Wenyu Valley Civic MoonBook</p>",
    "    <h1>\{service.title}</h1>",
    "    <p>\{service.projection_summary}</p>",
    "    <p><code>\{service.module_mode}</code> <code>\{service.skill_mode}</code> <code>\{service.output_contract}</code></p>",
    "  </section>",
  ].join("\n")
}

///|
fn civic_generated_site_work_sections(
  service : @civic.CivicServiceDefinition,
) -> String {
  [
    "  <h2>Module Role</h2>",
    "  <p>MoonBook role: <code>\{service.book_role}</code>. This building should follow its dedicated skill and building protocol, not a generic research workflow.</p>",
    "  <div class=\"grid\">",
    "    <section class=\"card\"><h2>Agent Work</h2><ul>\{html_list_items(service.agent_work)}</ul></section>",
    "    <section class=\"card\"><h2>Place Work</h2><ul>\{html_list_items(service.place_work)}</ul></section>",
    "  </div>",
    "  <h2>Service Workflow</h2>",
    "  <ul>\{html_list_items(service.workflow)}</ul>",
  ].join("\n")
}

///|
fn civic_generated_site_workspace_sections(
  service : @civic.CivicServiceDefinition,
) -> String {
  [
    "  <div class=\"grid\">",
    "    <section class=\"card\"><h2>Schemas</h2><ul>\{html_list_items(service.schema_pages)}</ul></section>",
    "    <section class=\"card\"><h2>Wiki Pages</h2><ul>\{html_list_items(service.wiki_pages)}</ul></section>",
    "    <section class=\"card\"><h2>Review Queues</h2><ul>\{html_list_items(service.review_queues)}</ul></section>",
    "    <section class=\"card\"><h2>Skill Pack</h2><p><code>\{service.skill_path}</code></p></section>",
    "  </div>",
  ].join("\n")
}
