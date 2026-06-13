///|
test "app tool book contract exposes stable defaults" {
  assert_eq(template_root(), "assets/templates/books/app-tool-book")
  assert_eq(default_book_id(), "app-tool-data-watch-dashboard")
  assert_true(!default_book_id().contains("toolbook"))
  assert_true(default_purpose().contains("usable generated web tool"))
  assert_eq(generated_tool_path(), "book/site/generated/tool.html")
  assert_eq(
    generated_site_path(),
    @policy.default_generated_site_projection_path(),
  )
}

///|
test "app tool book catalog identity owns name tags and skills" {
  assert_eq(catalog_name("OPC Tool"), "MoonBook / App ToolBook / OPC Tool")
  let tags = catalog_tags()
  assert_true(!tags.contains("toolbook"))
  assert_true(tags.contains("generated-tool"))
  assert_true(tags.contains("web-tool-surface"))
  assert_true(tags.contains("template:app-tool-book"))
  let skills = catalog_skills()
  assert_true(skills.contains("tool-watch"))
  assert_true(skills.contains("tool-build"))
  assert_true(skills.contains("notification-digest"))
}

///|
test "app tool book config constructor composes catalog identity" {
  let config = config_with_catalog_identity(
    "app-tool-opc",
    "OPC Tool",
    "Watch OPC signals.",
    "/tmp/app-tool-opc",
    ["https://example.org/opc"],
    "opc-lab",
    31,
  )
  assert_eq(config.book_type, @policy.general_type())
  assert_true(!config.tags.contains("toolbook"))
  assert_true(config.tags.contains("template:app-tool-book"))
  assert_true(config.skills.contains("tool-watch"))
  assert_true(config.skills.contains("notification-digest"))
  assert_eq(config.watch.cadence_ticks, 31)
  assert_eq(config.civic.building_id, "opc-lab")
}

///|
test "app tool book required paths include generated tool and editable app" {
  let required = required_paths()
  assert_true(required.contains("tool-manifest.json"))
  assert_true(required.contains("app/index.html"))
  assert_true(required.contains(generated_tool_path()))
  assert_true(required.contains(generated_site_path()))
  for path in template_copy_paths() {
    assert_true(required.contains(path))
  }
  assert_true(!template_copy_paths().contains("book.json"))
  assert_true(template_copy_paths().contains("app/tool.js"))
}

///|
test "app tool book status readiness requires all gates" {
  let ready = status(
    "app-tool",
    "/tmp/app-tool",
    [],
    has_catalog_entry=true,
    has_standing_goal=true,
    standing_goal_enabled=true,
    has_tool_manifest=true,
  )
  assert_true(ready.ready)
  let missing_manifest = status(
    "app-tool",
    "/tmp/app-tool",
    [],
    has_catalog_entry=true,
    has_standing_goal=true,
    standing_goal_enabled=true,
    has_tool_manifest=false,
  )
  assert_false(missing_manifest.ready)
  let missing_path = status(
    "app-tool",
    "/tmp/app-tool",
    ["tool-manifest.json"],
    has_catalog_entry=true,
    has_standing_goal=true,
    standing_goal_enabled=true,
    has_tool_manifest=true,
  )
  assert_false(missing_path.ready)
}

///|
test "app tool book status markdown renders readiness and missing paths" {
  let view = status_markdown(
    status(
      "app-tool",
      "/tmp/app-tool",
      ["wiki/index.md", "app/index.html"],
      has_catalog_entry=true,
      has_standing_goal=true,
      standing_goal_enabled=false,
      has_tool_manifest=true,
    ),
  )
  assert_true(view.contains("# App ToolBook Status"))
  assert_true(view.contains("- Book: `app-tool`"))
  assert_true(view.contains("- Ready: `false`"))
  assert_true(view.contains("- Standing goal enabled: `false`"))
  assert_true(view.contains("- wiki/index.md"))
  assert_true(view.contains("- app/index.html"))
  let ready = status_markdown(
    status(
      "app-tool",
      "/tmp/app-tool",
      [],
      has_catalog_entry=true,
      has_standing_goal=true,
      standing_goal_enabled=true,
      has_tool_manifest=true,
    ),
  )
  assert_true(ready.contains("- none"))
}

///|
test "app tool book bootstrap and install summaries are package-owned" {
  let summary = bootstrap_summary(
    "app-tool-opc",
    "/tmp/app-tool-opc",
    "/tmp/catalog.json",
    "watch-app-tool-opc-tool",
    "/tmp/standing-goals.json",
    "opc-lab",
    2,
    status(
      "app-tool-opc",
      "/tmp/app-tool-opc",
      [],
      has_catalog_entry=true,
      has_standing_goal=true,
      standing_goal_enabled=true,
      has_tool_manifest=true,
    ),
  )
  assert_true(summary.contains("Bootstrapped App ToolBook `app-tool-opc`"))
  assert_true(summary.contains("- Standing goal: `watch-app-tool-opc-tool`"))
  assert_true(summary.contains("- Websites: `2`"))
  assert_true(summary.contains("- Ready: `true`"))
  let installed = install_config_summary("/tmp/app-tool.json", summary)
  assert_true(
    installed.contains("Installed App ToolBook config `/tmp/app-tool.json`"),
  )
  assert_true(installed.contains("Bootstrapped App ToolBook `app-tool-opc`"))
}

///|
test "app tool book generated html keeps tool and report affordances" {
  let index = site_index_html(
    "app-tool-html", "HTML ToolBook", "Expose a generated app.", "html-lab",
  )
  assert_true(index.contains("href=\"tool.html\""))
  assert_true(index.contains("href=\"../../wiki/reports/latest-analysis.md\""))
  assert_true(index.contains("civic building html-lab"))
  let app = app_html(
    "app-tool-html", "HTML ToolBook", "Expose a generated app.", "html-lab",
  )
  assert_true(app.contains("<script src=\"tool.js\"></script>"))
  assert_true(app.contains("id=\"refresh-tool\""))
  assert_true(app.contains("Building: html-lab"))
}

///|
test "app tool book history renderer records book and generation time" {
  let text = history_markdown("app-tool-history", "History ToolBook", 1234)
  assert_true(text.contains("- book: `app-tool-history`"))
  assert_true(text.contains("- title: History ToolBook"))
  assert_true(text.contains("- generated_at_ms: `1234`"))
}

///|
test "app tool book standing watch prompt owns tool loop language" {
  assert_eq(standing_goal_id("opc-dashboard"), "watch-opc-dashboard-tool")
  let prompt = standing_goal_prompt(
    "OPC Dashboard",
    "Watch OPC signals.",
    ["https://example.org/opc"],
    "opc-lab",
  )
  assert_true(prompt.contains("Maintain the App ToolBook `OPC Dashboard`"))
  assert_true(prompt.contains("https://example.org/opc"))
  assert_true(prompt.contains("raw/data/latest.json"))
  assert_true(prompt.contains("book_changed"))
}

///|
test "app tool book owns standing goal construction and list policy" {
  let goal = standing_goal(
    "opc-dashboard",
    "OPC Dashboard",
    "Watch OPC signals.",
    ["https://example.org/opc"],
    "opc-lab",
    31,
  )
  assert_eq(goal.id, "watch-opc-dashboard-tool")
  assert_true(goal.target_book_id == Some("opc-dashboard"))
  assert_eq(goal.cadence_ticks, 31)
  assert_eq(goal.quality_threshold, 92)
  assert_eq(goal.source_policy, @policy.web_first_policy())
  assert_true(goal.prompt.contains("opc-lab"))
  let disabled = @core.StandingGoal::new(
    id=goal.id,
    title=goal.title,
    prompt=goal.prompt,
    target_book_id=goal.target_book_id,
    cadence_ticks=goal.cadence_ticks,
    next_due_tick=goal.next_due_tick,
    last_run_tick=goal.last_run_tick,
    enabled=false,
    source_policy=goal.source_policy,
    quality_threshold=goal.quality_threshold,
  )
  let other = @core.StandingGoal::new(
    id="watch-other-tool",
    title="Other",
    prompt="Other",
  )
  let inserted = upsert_standing_goal([other], goal)
  assert_true(standing_goal_in(inserted, goal.id))
  assert_true(standing_goal_enabled_in(inserted, goal.id))
  let replaced = upsert_standing_goal(inserted, disabled)
  assert_true(standing_goal_in(replaced, goal.id))
  assert_false(standing_goal_enabled_in(replaced, goal.id))
  assert_true(standing_goal_in(replaced, other.id))
}
