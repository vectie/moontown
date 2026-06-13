///|
pub fn operational_index(
  book_id : String,
  workspace_root : String,
  title : String,
  summary : String,
  focus : Array[String],
) -> String {
  [
    "# \{title}",
    "",
    summary,
    "",
    "## Book",
    "",
    "- Book id: `\{book_id}`",
    "- Workspace: `\{workspace_root}`",
    "- Type: `\{@policy.operational_type()}`",
    "",
    "## Focus",
    "",
    operational_markdown_bullets(focus),
    "",
    "## Start Here",
    "",
    "- `raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md`",
    "- `wiki/operations/review-policy.md`",
    "- `wiki/history/journey.md`",
    "- `skills/operational-keeper/SKILL.md`",
  ].join("\n")
}

///|
pub fn operational_contract(title : String) -> String {
  [
    "# \{title} Contract",
    "",
    "This operational book preserves workspace memory, review rules, and safe execution boundaries.",
    "",
    "## Rules",
    "",
    "- Do not invent external facts.",
    "- Do not store sensitive user data unless explicitly provided and scoped.",
    "- Keep operational records separate from domain evidence.",
    "- Prefer small reviewed changes and durable journey notes.",
  ].join("\n")
}

///|
pub fn operational_review_policy(title : String) -> String {
  [
    "# \{title} Review Policy",
    "",
    "- Queue review when a change affects external systems, private data, money, or repo quality gates.",
    "- Record validation evidence before marking a task complete.",
    "- Preserve a short journey note for material decisions.",
  ].join("\n")
}

///|
pub fn operational_journey(title : String) -> String {
  [
    "# \{title} Journey",
    "",
    "| Date | Event | Evidence |",
    "| --- | --- | --- |",
    "| bootstrap | Created operational MoonBook workspace | `raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md` |",
  ].join("\n")
}

///|
pub fn operational_skill(
  title : String,
  quality_contract_section : String,
) -> String {
  [
    "---",
    "name: operational-keeper",
    "description: Maintain an operational MoonBook workspace with review policy, journey notes, and safe execution boundaries.",
    "---",
    "",
    "# Operational Keeper Skill",
    "",
    "Operate `\{title}` as durable workspace memory.",
    "",
    "## Rules",
    "",
    "- Read the book contract before updating memory.",
    "- Separate operational records from domain facts.",
    "- Write concise journey notes for material decisions.",
    "- Queue review for sensitive, financial, external, or code-quality-impacting changes.",
    "",
    quality_contract_section,
    "",
    "## Concrete Example",
    "",
    "```md",
    "operational_decision: update",
    "book_changed: yes",
    "review_required: no",
    "summary: Added a validated review policy note and linked the validation evidence.",
    "```",
  ].join("\n")
}

///|
pub fn operational_ui_state(
  book_id : String,
  title : String,
  summary : String,
) -> String {
  [
    "{",
    "  \"book_id\": \{operational_json_string(book_id)},",
    "  \"title\": \{operational_json_string(title)},",
    "  \"summary\": \{operational_json_string(summary)},",
    operational_ui_status_chips(),
    operational_ui_metrics(),
    operational_ui_readiness(),
    "  \"review_queue\": [],",
    operational_ui_page_families(),
    operational_ui_journey(),
    "}",
  ].join("\n")
}

///|
pub fn operational_site(
  workspace_root : String,
  title : String,
  summary : String,
) -> String {
  [
    operational_site_head(title),
    operational_site_body_open(),
    operational_site_hero(workspace_root, title, summary),
    operational_site_body_close(),
  ].join("\n")
}

///|
fn operational_markdown_bullets(values : Array[String]) -> String {
  let builder = StringBuilder::new()
  for value in values {
    builder.write_string("- ")
    builder.write_string(value)
    builder.write_char('\n')
  }
  builder.to_string().trim().to_owned()
}

///|
fn operational_json_string(text : String) -> String {
  text.to_json().stringify()
}

///|
fn operational_html_escape(text : String) -> String {
  text
  .replace(old="&", new="&amp;")
  .replace(old="<", new="&lt;")
  .replace(old=">", new="&gt;")
  .replace(old="\"", new="&quot;")
  .to_string()
}

///|
fn operational_ui_status_chips() -> String {
  [
    "  \"status_chips\": [",
    "    {\"label\":\{operational_json_string(@policy.operational_type())},\"tone\":\"healthy\"},",
    "    {\"label\":\"review-gated\",\"tone\":\"review\"}",
    "  ],",
  ].join("\n")
}

///|
fn operational_ui_metrics() -> String {
  [
    "  \"metrics\": [", "    {\"label\":\"Contracts\",\"value\":\"1\",\"note\":\"operational contract\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Skills\",\"value\":\"1\",\"note\":\"operational keeper\",\"tone\":\"healthy\"}",
    "  ],",
  ].join("\n")
}

///|
fn operational_ui_readiness() -> String {
  [
    "  \"readiness\": [", "    {\"title\":\"Operational contract\",\"detail\":\"raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md\",\"meta\":\"Ready\"}",
    "  ],",
  ].join("\n")
}

///|
fn operational_ui_page_families() -> String {
  [
    "  \"page_families\": [", "    {\"title\":\"Review policy\",\"detail\":\"wiki/operations/review-policy.md\",\"meta\":\"Operations\"}",
    "  ],",
  ].join("\n")
}

///|
fn operational_ui_journey() -> String {
  [
    "  \"journey\": [", "    {\"title\":\"Operational bootstrap\",\"stage\":\"generated\",\"status\":\"ready\",\"summary\":\"MoonBook workspace created for registered operational book.\",\"highlights\":[]}",
    "  ]",
  ].join("\n")
}

///|
fn operational_site_head(title : String) -> String {
  [
    "<!doctype html><html><head><meta charset=\"utf-8\">",
    "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">",
    "<title>\{operational_html_escape(title)}</title>",
    operational_site_style(),
  ].join("")
}

///|
fn operational_site_style() -> String {
  [
    "<style>", "body{margin:0;background:#f3efe3;color:#1f2e2a;font-family:Georgia,serif}",
    "main{max-width:900px;margin:auto;padding:48px 24px}", ".hero{padding:30px;border-radius:24px;background:#fffaf0;border:1px solid #c8b98d}",
    "code{background:#e8dec3;padding:2px 6px;border-radius:6px}", "</style>",
  ].join("")
}

///|
fn operational_site_body_open() -> String {
  "</head><body><main>"
}

///|
fn operational_site_body_close() -> String {
  "</main></body></html>"
}

///|
fn operational_site_hero(
  workspace_root : String,
  title : String,
  summary : String,
) -> String {
  [
    "<section class=\"hero\">",
    "<p>MoonBook operational workspace</p>",
    "<h1>\{operational_html_escape(title)}</h1>",
    "<p>\{operational_html_escape(summary)}</p>",
    "<p><code>\{operational_html_escape(workspace_root)}</code></p>",
    "</section>",
  ].join("")
}
