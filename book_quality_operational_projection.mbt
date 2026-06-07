///|
fn default_operational_ui_state(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  summary : String,
) -> String {
  [
    "{",
    "  \"book_id\": \{json_string(entry.id)},",
    "  \"title\": \{json_string(title)},",
    "  \"summary\": \{json_string(summary)},",
    default_operational_ui_status_chips(),
    default_operational_ui_metrics(),
    default_operational_ui_readiness(),
    "  \"review_queue\": [],",
    default_operational_ui_page_families(),
    default_operational_ui_journey(),
    "}",
  ].join("\n")
}

///|
fn default_operational_ui_status_chips() -> String {
  [
    "  \"status_chips\": [", "    {\"label\":\"operational-book\",\"tone\":\"healthy\"},",
    "    {\"label\":\"review-gated\",\"tone\":\"review\"}", "  ],",
  ].join("\n")
}

///|
fn default_operational_ui_metrics() -> String {
  [
    "  \"metrics\": [", "    {\"label\":\"Contracts\",\"value\":\"1\",\"note\":\"operational contract\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Skills\",\"value\":\"1\",\"note\":\"operational keeper\",\"tone\":\"healthy\"}",
    "  ],",
  ].join("\n")
}

///|
fn default_operational_ui_readiness() -> String {
  [
    "  \"readiness\": [", "    {\"title\":\"Operational contract\",\"detail\":\"raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md\",\"meta\":\"Ready\"}",
    "  ],",
  ].join("\n")
}

///|
fn default_operational_ui_page_families() -> String {
  [
    "  \"page_families\": [", "    {\"title\":\"Review policy\",\"detail\":\"wiki/operations/review-policy.md\",\"meta\":\"Operations\"}",
    "  ],",
  ].join("\n")
}

///|
fn default_operational_ui_journey() -> String {
  [
    "  \"journey\": [", "    {\"title\":\"Operational bootstrap\",\"stage\":\"generated\",\"status\":\"ready\",\"summary\":\"MoonBook workspace created for registered operational book.\",\"highlights\":[]}",
    "  ]",
  ].join("\n")
}

///|
fn default_operational_site(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  summary : String,
) -> String {
  [
    default_operational_site_head(title),
    default_operational_site_body_open(),
    default_operational_site_hero(entry, title, summary),
    default_operational_site_body_close(),
  ].join("\n")
}

///|
fn default_operational_site_head(title : String) -> String {
  [
    "<!doctype html><html><head><meta charset=\"utf-8\">",
    "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">",
    "<title>\{html_escape(title)}</title>",
    default_operational_site_style(),
  ].join("")
}

///|
fn default_operational_site_style() -> String {
  [
    "<style>", "body{margin:0;background:#f3efe3;color:#1f2e2a;font-family:Georgia,serif}",
    "main{max-width:900px;margin:auto;padding:48px 24px}", ".hero{padding:30px;border-radius:24px;background:#fffaf0;border:1px solid #c8b98d}",
    "code{background:#e8dec3;padding:2px 6px;border-radius:6px}", "</style>",
  ].join("")
}

///|
fn default_operational_site_body_open() -> String {
  "</head><body><main>"
}

///|
fn default_operational_site_body_close() -> String {
  "</main></body></html>"
}

///|
fn default_operational_site_hero(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  summary : String,
) -> String {
  [
    "<section class=\"hero\">",
    "<p>MoonBook operational workspace</p>",
    "<h1>\{html_escape(title)}</h1>",
    "<p>\{html_escape(summary)}</p>",
    "<p><code>\{html_escape(entry.workspace_root)}</code></p>",
    "</section>",
  ].join("")
}
