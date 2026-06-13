///|
fn wenyu_course_ui_state_json(entry : @moonbook.BookCatalogEntry) -> String {
  [
    "{",
    "  \"book_id\": \{@support.json_string(entry.id)},",
    "  \"title\": \"Wenyu Valley Game Design Course\",",
    "  \"summary\": \"Beginner course for learning tile-map UI, modular building placement, agent movement, and editor/view/output modes.\",",
    "  \"status_chips\": [",
    "    {\"label\":\{@support.json_string(@policy.course_type())},\"tone\":\"healthy\"},",
    "    {\"label\":\"beginner-friendly\",\"tone\":\"info\"},",
    "    {\"label\":\"not research-shaped\",\"tone\":\"healthy\"}",
    "  ],",
    "  \"metrics\": [",
    "    {\"label\":\"Lessons\",\"value\":\"7\",\"note\":\"outline modules\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Exercises\",\"value\":\"4\",\"note\":\"artifact-producing exercises\",\"tone\":\"review\"}",
    "  ],",
    "  \"readiness\": [",
    "    {\"title\":\"Course contract\",\"detail\":\"raw/bootstrap/COURSE_CONTRACT.md\",\"meta\":\"Ready\"},",
    "    {\"title\":\"Beginner course\",\"detail\":\"wiki/course/beginner-course.md\",\"meta\":\"Ready\"}",
    "  ],",
    "  \"review_queue\": [",
    "    {\"title\":\"Beginner usability pass\",\"detail\":\"Check every lesson has an exercise and checkpoint.\",\"meta\":\"Pending\"}",
    "  ],",
    "  \"page_families\": [",
    "    {\"title\":\"Course\",\"detail\":\"wiki/course/beginner-course.md\",\"meta\":\"Lessons\"}",
    "  ],",
    "  \"journey\": [",
    "    {\"title\":\"Course bootstrap\",\"stage\":\"generated\",\"status\":\"review\",\"summary\":\"Moontown registered a first-class course book for Wenyu Valley game-design learning.\",\"highlights\":[]}",
    "  ]",
    "}",
  ].join("\n")
}

///|
fn wenyu_course_generated_site_html(
  entry : @moonbook.BookCatalogEntry,
) -> String {
  [
    wenyu_course_generated_site_head(),
    wenyu_course_generated_site_body_open(),
    wenyu_course_generated_site_hero(entry),
    wenyu_course_generated_site_cards(),
    wenyu_course_generated_site_body_close(),
  ].join("\n")
}

///|
fn wenyu_course_generated_site_head() -> String {
  [
    "<!doctype html><html lang=\"en\"><head>",
    "<meta charset=\"utf-8\">",
    "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">",
    "<title>Wenyu Valley Game Design Course</title>",
    "<style>\{wenyu_course_generated_site_css()}</style>",
    "</head>",
  ].join("")
}

///|
fn wenyu_course_generated_site_css() -> String {
  [
    wenyu_course_page_css(),
    wenyu_course_hero_css(),
    wenyu_course_card_grid_css(),
    wenyu_course_code_css(),
  ].join("")
}

///|
fn wenyu_course_page_css() -> String {
  "body{margin:0;background:#f5f1df;color:#26321f;font-family:Georgia,serif}main{max-width:1040px;margin:auto;padding:48px 24px}"
}

///|
fn wenyu_course_hero_css() -> String {
  ".hero{padding:34px;border-radius:30px;background:linear-gradient(135deg,#fff7da,#cfe4b0);box-shadow:0 24px 80px rgba(44,70,38,.16)}"
}

///|
fn wenyu_course_card_grid_css() -> String {
  ".grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:16px}.card{margin-top:18px;padding:18px;border:1px solid rgba(38,50,31,.18);border-radius:18px;background:rgba(255,255,255,.72)}"
}

///|
fn wenyu_course_code_css() -> String {
  "code{background:#e8dfba;padding:2px 6px;border-radius:6px}"
}

///|
fn wenyu_course_generated_site_body_open() -> String {
  "<body><main>"
}

///|
fn wenyu_course_generated_site_hero(
  entry : @moonbook.BookCatalogEntry,
) -> String {
  [
    "<section class=\"hero\">",
    "<p>MoonBook Course</p>",
    "<h1>Wenyu Valley Game Design Course</h1>",
    "<p>A beginner learning path for tile maps, terrain, buildings, roads, agents, and editor/view/output modes.</p>",
    "<p><code>\{@support.html_escape(entry.workspace_root)}</code></p>",
    "</section>",
  ].join("")
}

///|
fn wenyu_course_generated_site_cards() -> String {
  [
    "<section class=\"grid\">",
    wenyu_course_generated_site_card(
      "Learn", "Lessons explain each concept in plain language.",
    ),
    wenyu_course_generated_site_card(
      "Build", "Exercises produce real Wenyu artifacts.",
    ),
    wenyu_course_generated_site_card(
      "Review", "Checkpoints help the learner judge quality.",
    ),
    "</section>",
  ].join("")
}

///|
fn wenyu_course_generated_site_card(title : String, body : String) -> String {
  "<article class=\"card\"><h2>\{title}</h2><p>\{body}</p></article>"
}

///|
fn wenyu_course_generated_site_body_close() -> String {
  "</main></body></html>"
}
