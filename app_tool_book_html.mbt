///|
fn app_tool_book_site_index_html(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  purpose : String,
  civic_building_id : String,
) -> String {
  [
    "<!doctype html>",
    "<html>",
    app_tool_book_html_head(title, app_tool_book_site_styles()),
    "<body>",
    "<main class=\"shell\">",
    "<section class=\"card\">",
    "<p class=\"meta\">App ToolBook / \{entry.id} / civic building \{civic_building_id}</p>",
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
fn app_tool_book_app_html(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  purpose : String,
  civic_building_id : String,
) -> String {
  [
    "<!doctype html>",
    "<html>",
    app_tool_book_html_head(
      "\{title} Tool",
      "<link rel=\"stylesheet\" href=\"styles.css\">",
    ),
    "<body>",
    "<main class=\"tool-shell\">",
    "<section class=\"hero\">",
    "<p>App ToolBook / \{entry.id}</p>",
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
fn app_tool_book_html_head(title : String, extra_head : String) -> String {
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
fn app_tool_book_site_styles() -> String {
  [
    "<style>", "body{font-family:ui-sans-serif,system-ui;margin:0;background:#f7faf8;color:#132018}",
    ".shell{max-width:1040px;margin:0 auto;padding:48px 24px}", ".card{background:white;border:1px solid #dbe8df;border-radius:24px;padding:28px;box-shadow:0 24px 80px rgba(20,50,30,.1)}",
    "a.button{display:inline-block;margin-top:18px;padding:12px 18px;border-radius:999px;background:#0f6b55;color:white;text-decoration:none;font-weight:700}",
    "a.button.secondary{margin-left:10px;background:#263f34}", ".meta{color:#5d7468}",
    "</style>",
  ].join("\n")
}
