///|
pub fn ui_state_json(entry : @moonbook.BookCatalogEntry) -> String {
  [
    "{",
    "  \"book_id\": \{json_string(entry.id)},",
    "  \"title\": \"Moontown Quality Planbook\",",
    "  \"summary\": \"Implementation plans, acceptance gates, execution evidence, and review notes for Moontown quality work.\",",
    "  \"status_chips\": [",
    "    {\"label\":\"planbook\",\"tone\":\"healthy\"},",
    "    {\"label\":\"acceptance-gated\",\"tone\":\"review\"},",
    "    {\"label\":\"cookbook handoff\",\"tone\":\"info\"}",
    "  ],",
    "  \"metrics\": [",
    "    {\"label\":\"Seed plans\",\"value\":\"3\",\"note\":\"quality governance, live autonomy spine, and editor pipeline\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Skills\",\"value\":\"3\",\"note\":\"plan, review, doc sync\",\"tone\":\"healthy\"}",
    "  ],",
    "  \"readiness\": [",
    "    {\"title\":\"Planbook contract\",\"detail\":\"raw/bootstrap/PLANBOOK_CONTRACT.md\",\"meta\":\"Ready\"},",
    "    {\"title\":\"Top priority live spine\",\"detail\":\"plans/2026-05-29-live-autonomy-spine/plan.md\",\"meta\":\"Top Priority\"},",
    "    {\"title\":\"Editor pipeline self-build test\",\"detail\":\"plans/2026-05-31-editor-mode-real-pipeline/plan.md\",\"meta\":\"Self Build\"},",
    "    {\"title\":\"Quality plan\",\"detail\":\"plans/2026-05-29-book-quality-upgrade/plan.md\",\"meta\":\"Ready\"}",
    "  ],",
    "  \"review_queue\": [",
    "    {\"title\":\"Book quality audit\",\"detail\":\"Run `books doctor` and fix the lowest score first.\",\"meta\":\"Open\"}",
    "  ],",
    "  \"page_families\": [",
    "    {\"title\":\"Quality Gates\",\"detail\":\"wiki/planning/quality-gates.md\",\"meta\":\"Planning\"}",
    "  ],",
    "  \"journey\": [",
    "    {\"title\":\"Planbook bootstrap\",\"stage\":\"generated\",\"status\":\"review\",\"summary\":\"Moontown registered a first-class planbook workspace for world-class book quality governance.\",\"highlights\":[]}",
    "  ]",
    "}",
  ].join("\n")
}

///|
pub fn generated_site_html(entry : @moonbook.BookCatalogEntry) -> String {
  [
    planbook_generated_site_head(),
    planbook_generated_site_body_open(),
    planbook_generated_site_hero(entry),
    planbook_generated_site_cards(),
    planbook_generated_site_body_close(),
  ].join("\n")
}

///|
fn planbook_generated_site_head() -> String {
  [
    "<!doctype html><html lang=\"en\"><head>",
    "<meta charset=\"utf-8\">",
    "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">",
    "<title>Moontown Quality Planbook</title>",
    "<style>\{planbook_generated_site_css()}</style>",
    "</head>",
  ].join("")
}

///|
fn planbook_generated_site_css() -> String {
  [
    planbook_page_css(),
    planbook_hero_css(),
    planbook_card_grid_css(),
    planbook_code_css(),
  ].join("")
}

///|
fn planbook_page_css() -> String {
  "body{margin:0;background:#101820;color:#f7f3e8;font-family:Georgia,serif}main{max-width:980px;margin:auto;padding:56px 24px}"
}

///|
fn planbook_hero_css() -> String {
  ".hero{border:1px solid #d8c58a;border-radius:28px;padding:34px;background:linear-gradient(135deg,#172536,#263f4c)}"
}

///|
fn planbook_card_grid_css() -> String {
  ".grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:16px}.card{margin-top:18px;padding:18px;border:1px solid rgba(216,197,138,.35);border-radius:18px;background:rgba(255,255,255,.07)}"
}

///|
fn planbook_code_css() -> String {
  "code{color:#ffe08a}"
}

///|
fn planbook_generated_site_body_open() -> String {
  "<body><main>"
}

///|
fn planbook_generated_site_hero(entry : @moonbook.BookCatalogEntry) -> String {
  [
    "<section class=\"hero\">",
    "<p>MoonBook managed / Mayor routed / MoonClaw executed</p>",
    "<h1>Moontown Quality Planbook</h1>",
    "<p>Workspace <code>\{html_escape(entry.workspace_root)}</code>. Plans are the durable checkpoint before implementation and cookbook promotion.</p>",
    "</section>",
  ].join("")
}

///|
fn planbook_generated_site_cards() -> String {
  [
    "<section class=\"grid\">",
    planbook_generated_site_card(
      "Plan", "Problem, current state, decision, steps, and acceptance criteria.",
    ),
    planbook_generated_site_card(
      "Execute", "MoonClaw works against the plan and records evidence.",
    ),
    planbook_generated_site_card(
      "Review", "Quality gates decide whether the result becomes stable state.",
    ),
    "</section>",
  ].join("")
}

///|
fn planbook_generated_site_card(title : String, body : String) -> String {
  "<article class=\"card\"><h2>\{title}</h2><p>\{body}</p></article>"
}

///|
fn planbook_generated_site_body_close() -> String {
  "</main></body></html>"
}
