///|
fn render_planbook_backlog_progress_markdown(
  total : Int,
  open : Int,
  completed : Int,
  blocked : Int,
  interval_ms : Int,
) -> String {
  [
    "# Backlog Progress",
    "",
    "- total: `\{total}`",
    "- open: `\{open}`",
    "- completed: `\{completed}`",
    "- blocked_or_paused: `\{blocked}`",
    "- next_check_interval_ms: `\{interval_ms}`",
    "",
    "## Cadence",
    "",
    "- When backlog work is open, the town may take the next bounded task immediately, one at a time.",
    "- When the backlog is clear, the code-building visit decays to a 30-minute check interval.",
    "- If a worker reaches the building and discovers the work is already done, it should write completion evidence and update the backlog/plan instead of patching code.",
  ].join("\n")
}

///|
fn planbook_backlog_stop_policy_markdown() -> String {
  [
    "# Stop Policy", "", "The town should stop implementing when one of these conditions is true:",
    "", "- The selected backlog item has completion evidence under `raw/backlog/completed/<id>.md`.",
    "- The selected backlog item status is `done`, `blocked`, or `paused` in `raw/backlog/implementation-backlog.json`.",
    "- The repair result is `needs_external_owner`, `blocked`, or `no_change` and explains why code should not change.",
    "- Required validation fails; the worker must record the blocker rather than continuing to patch blindly.",
    "- The focused diff exceeds the target-file boundary or changes ownership between Moontown, MoonBook, MoonClaw, or Moondesk without an explicit plan update.",
    "", "If the worker discovers the feature is already complete, it should update the PlanBook progress/backlog documents and write completion evidence instead of generating unnecessary code.",
    "", "If the worker discovers the plan is stale, it should update the plan/backlog document with the new reality before attempting more code.",
  ].join("\n")
}

///|
fn render_planbook_backlog_markdown(
  workspace_root : String,
  items : Array[PlanbookImplementationBacklogItem],
) -> String {
  let rows : Array[String] = []
  for item in items {
    ignore(workspace_root)
    rows.push(
      "|\{item.id}|\{item.priority}|\{item.status}|\{item.owner}|\{item.title}|",
    )
  }
  [
    "# Implementation Backlog",
    "",
    "This backlog is the document-controlled source of future self-build work. Add, remove, reprioritize, or close work by editing `raw/backlog/implementation-backlog.json`; MoonBit code should not hardcode the future feature list.",
    "",
    "| ID | Priority | State | Owner | Title |",
    "| --- | --- | --- | --- | --- |",
    if rows.is_empty() {
      "| none | 0 | empty | none | none |"
    } else {
      rows.join("\n")
    },
  ].join("\n")
}

///|
fn planbook_backlog_readme_markdown() -> String {
  [
    "# PlanBook Backlog Contract", "", "The PlanBook backlog lets the live town continue improving itself without waiting for a hardcoded doctor criterion.",
    "", "Each item is still bounded:", "", "- `id`: stable identifier used as the repair criterion id",
    "- `title`: human-readable implementation goal", "- `owner`: repository or system owner boundary",
    "- `priority`: lower number means earlier selection", "- `status`: `open`, `blocked`, `paused`, or `done`",
    "- `source_plan`: durable plan or course source", "- `target_files`: first files the repair worker may inspect",
    "- `acceptance`: concrete criteria before the item can be completed", "- `validation`: commands or evidence required before acceptance",
    "", "Completion evidence belongs under `raw/backlog/completed/<id>.md` and should be produced by the repair worker after validation.",
    "", "Progress and cadence are projected to `wiki/planning/backlog-progress.md`. Stop rules are projected to `wiki/planning/stop-policy.md`.",
  ].join("\n")
}
