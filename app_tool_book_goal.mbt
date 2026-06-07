///|
fn app_tool_book_standing_goal(
  book_id : String,
  title : String,
  purpose : String,
  websites : Array[String],
  civic_building_id : String,
  cadence_ticks : Int,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id=app_tool_book_goal_id(book_id),
    title="Watch and build tool for \{title}",
    prompt=app_tool_book_goal_prompt(
      title, purpose, websites, civic_building_id,
    ),
    target_book_id=Some(book_id),
    cadence_ticks~,
    next_due_tick=0,
    source_policy="web-first",
    quality_threshold=92,
  )
}

///|
fn upsert_app_tool_book_standing_goal(
  goals : Array[@core.StandingGoal],
  goal : @core.StandingGoal,
) -> Array[@core.StandingGoal] {
  standing_goal_registry_upsert(goals, goal)
}

///|
fn app_tool_book_goal_in(
  goals : Array[@core.StandingGoal],
  goal_id : String,
) -> Bool {
  standing_goal_registry_contains(goals, goal_id)
}

///|
fn app_tool_book_goal_enabled_in(
  goals : Array[@core.StandingGoal],
  goal_id : String,
) -> Bool {
  standing_goal_registry_enabled(goals, goal_id)
}

///|
fn app_tool_book_goal_id(book_id : String) -> String {
  "watch-\{book_id}-tool"
}

///|
fn app_tool_book_goal_prompt(
  title : String,
  purpose : String,
  websites : Array[String],
  civic_building_id : String,
) -> String {
  [
    "Maintain the App ToolBook `\{title}` for civic building `\{civic_building_id}`.",
    "",
    "Purpose: \{purpose}",
    "",
    "Use web-first source discovery for the configured websites:",
    if websites.is_empty() {
      "- no websites configured yet; inspect the book config and request Moondesk/operator configuration before inventing sources"
    } else {
      websites.map(fn(site) { "- \{site}" }).join("\n")
    },
    "",
    "Required loop:",
    "- check watched data/sources",
    "- update `raw/data/latest.json` only with accepted data",
    "- update `wiki/reports/latest-analysis.md` with evidence-backed analysis",
    "- update or repair the runnable tool under `app/` and `book/site/generated/tool.html` when the analysis benefits from interaction",
    "- update `tool-manifest.json` with route/build/review status",
    "- return a strict standing watch marker with `book_changed`, source counts, accepted fact counts, and tool build status",
    "",
    "Do not treat operational logs, retries, or generated wrapper files as domain evidence.",
  ].join("\n")
}
