///|
pub fn history_markdown(
  book_id : String,
  title : String,
  generated_at_ms : UInt64,
) -> String {
  [
    "# App ToolBook Watch History",
    "",
    "- book: `\{book_id}`",
    "- title: \{title}",
    "- generated_at_ms: `\{generated_at_ms}`",
    "",
    "Standing watch cycles append source checks, analysis deltas, tool build results, and review decisions here.",
  ].join("\n")
}

///|
pub fn bootstrap_summary(
  book_id : String,
  workspace_root : String,
  book_catalog_path : String,
  standing_goal_id : String,
  standing_goal_path : String,
  civic_building_id : String,
  website_count : Int,
  status : AppToolBookStatus,
) -> String {
  [
    "Bootstrapped App ToolBook `\{book_id}`.",
    "- Workspace: `\{workspace_root}`",
    "- Catalog: `\{book_catalog_path}`",
    "- Standing goal: `\{standing_goal_id}` in `\{standing_goal_path}`",
    "- Civic building: `\{civic_building_id}`",
    "- Websites: `\{website_count}`",
    "- Ready: `\{status.ready}`",
    "- Missing required: `\{status.missing_count}`",
  ].join("\n")
}

///|
pub fn install_config_summary(
  config_path : String,
  bootstrap_summary : String,
) -> String {
  "Installed App ToolBook config `\{config_path}`.\n\{bootstrap_summary}"
}

///|
pub fn site_index_html(
  book_id : String,
  title : String,
  purpose : String,
  civic_building_id : String,
) -> String {
  [
    "<!doctype html>",
    "<html>",
    html_head(title, site_styles()),
    "<body>",
    "<main class=\"shell\">",
    "<section class=\"card\">",
    "<p class=\"meta\">App ToolBook / \{book_id} / civic building \{civic_building_id}</p>",
    "<h1>\{title}</h1>",
    "<p>\{purpose}</p>",
    "<a class=\"button\" href=\"tool.html\">Open generated tool</a>",
    "<a class=\"button secondary\" href=\"../../wiki/reports/latest-analysis.md\">Open latest report</a>",
    "</section>",
    "</main>",
    "</body>",
    "</html>",
  ].join("\n")
}

///|
pub fn app_html(
  book_id : String,
  title : String,
  purpose : String,
  civic_building_id : String,
) -> String {
  [
    "<!doctype html>",
    "<html>",
    html_head("\{title} Tool", "<link rel=\"stylesheet\" href=\"styles.css\">"),
    "<body>",
    "<main class=\"tool-shell\">",
    "<section class=\"hero\">",
    "<p>App ToolBook / \{book_id}</p>",
    "<h1>\{title}</h1>",
    "<span>Building: \{civic_building_id}</span>",
    "</section>",
    "<section class=\"tool-card\">",
    "<h2>Interactive tool placeholder</h2>",
    "<p>\{purpose}</p>",
    "<div id=\"tool-output\">Waiting for MoonClaw to populate accepted data and tool logic.</div>",
    "<button id=\"refresh-tool\">Inspect tool manifest</button>",
    "</section>",
    "</main>",
    "<script src=\"tool.js\"></script>",
    "</body>",
    "</html>",
  ].join("\n")
}

///|
fn html_head(title : String, extra_head : String) -> String {
  [
    "<head>",
    "<meta charset=\"utf-8\">",
    "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">",
    "<title>\{title}</title>",
    extra_head,
    "</head>",
  ].join("\n")
}

///|
fn site_styles() -> String {
  [
    "<style>", "body{font-family:ui-sans-serif,system-ui;margin:0;background:#f7faf8;color:#132018}",
    ".shell{max-width:1040px;margin:0 auto;padding:48px 24px}", ".card{background:white;border:1px solid #dbe8df;border-radius:24px;padding:28px;box-shadow:0 24px 80px rgba(20,50,30,.1)}",
    "a.button{display:inline-block;margin-top:18px;padding:12px 18px;border-radius:999px;background:#0f6b55;color:white;text-decoration:none;font-weight:700}",
    "a.button.secondary{margin-left:10px;background:#263f34}", ".meta{color:#5d7468}",
    "</style>",
  ].join("\n")
}
