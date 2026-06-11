///|
pub fn role_model_markdown() -> String {
  planbook_markdown_page(
    [
      "# Mayor, Bookkeeper, And Worker Role Model", "", "This page prevents future implementation plans from confusing durable memory ownership with temporary execution.",
      "",
    ],
    [
      planbook_mayor_role_section(),
      planbook_bookkeeper_role_section(),
      planbook_worker_role_section(),
      planbook_role_model_rule_section(),
    ],
  )
}

///|
fn planbook_mayor_role_section() -> Array[String] {
  [
    "## Mayor", "", "- Scope: town-wide.", "- Runtime: logically long-lived through the daemon and live autonomy spine.",
    "- Owns: standing goals, routing, scheduling, escalation, recovery, cross-book priority, and civic/building protocol dispatch.",
    "- Does not own: domain truth, book wiki contents, or low-level tool execution.",
    "",
  ]
}

///|
fn planbook_bookkeeper_role_section() -> Array[String] {
  [
    "## MoonBook Bookkeeper", "", "- Scope: one MoonBook workspace.", "- Runtime: resident role, logically live through scheduled/event-driven keeper ticks; it does not need to burn a hot process continuously.",
    "- Wakes on: new worker result, standing-watch update, review queue change, stale projection interval, explicit operator/book request, or memory-health check.",
    "- Owns: working memory, durable wiki promotion, source/evidence ledgers, review policy, generated site/projection quality, next questions, and book health.",
    "- Does not own: town-global routing or arbitrary tool-heavy execution.", "",
  ]
}

///|
fn planbook_worker_role_section() -> Array[String] {
  [
    "## MoonClaw Worker", "", "- Scope: one bounded task.", "- Runtime: freelance executor. Spawn when needed, execute the packet, emit structured result/evidence/artifacts, then exit.",
    "- Owns: tool use, observations, synthesis, coding, review, image generation, result packaging, and memory candidates.",
    "- Does not own: durable memory, wiki promotion, standing-goal cadence, or cross-book policy.",
    "",
  ]
}

///|
fn planbook_role_model_rule_section() -> Array[String] {
  [
    "## Rule", "", "A future plan should specify whether it needs Mayor supervision, Bookkeeper memory work, or freelance Worker execution. If the answer is unclear, update this PlanBook before coding.",
  ]
}
