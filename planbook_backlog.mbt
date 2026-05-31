///|
struct PlanbookImplementationBacklogItem {
  id : String
  title : String
  owner : String
  priority : Int
  status : String
  source_plan : String
  rationale : String
  target_files : Array[String]
  acceptance : Array[String]
  validation : Array[String]
  created_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
fn default_planbook_backlog_path(
  workspace_root? : String = default_planbook_workspace_root(),
) -> String {
  "\{workspace_root}/raw/backlog/implementation-backlog.json"
}

///|
fn planbook_backlog_markdown_path(workspace_root : String) -> String {
  "\{workspace_root}/wiki/planning/implementation-backlog.md"
}

///|
fn planbook_change_log_path(workspace_root : String) -> String {
  "\{workspace_root}/wiki/history/change-log.md"
}

///|
fn planbook_backlog_progress_path(workspace_root : String) -> String {
  "\{workspace_root}/wiki/planning/backlog-progress.md"
}

///|
fn planbook_backlog_stop_policy_path(workspace_root : String) -> String {
  "\{workspace_root}/wiki/planning/stop-policy.md"
}

///|
async fn ensure_planbook_backlog(
  workspace_root : String,
) -> Array[PlanbookImplementationBacklogItem] {
  let path = default_planbook_backlog_path(workspace_root~)
  let items = if @fs.exists(path) {
    load_planbook_backlog_items(workspace_root)
  } else {
    default_planbook_backlog_items()
  }
  if !@fs.exists(path) {
    write_text_file(path, items.to_json().stringify(indent=2))
  }
  write_planbook_backlog_projection(workspace_root, items)
  write_planbook_backlog_progress(workspace_root, items)
  write_planbook_backlog_stop_policy(workspace_root)
  items
}

///|
async fn load_planbook_backlog_items(
  workspace_root : String,
) -> Array[PlanbookImplementationBacklogItem] {
  let path = default_planbook_backlog_path(workspace_root~)
  let text = read_text_or_empty(path)
  if text.trim().is_empty() {
    return default_planbook_backlog_items()
  }
  let parsed = @json.parse(text) catch {
    _ => return default_planbook_backlog_items()
  }
  @json.from_json(parsed) catch {
    _ => default_planbook_backlog_items()
  }
}

///|
fn planbook_backlog_target_files_for_criterion(
  criterion_id : String,
  source_root : String,
) -> Array[String] {
  if !criterion_id.contains("backlog-") {
    return []
  }
  [
    "\{source_root}/planbook_backlog.mbt",
    "\{source_root}/planbook_autonomy.mbt",
    "\{source_root}/planbook_repair.mbt",
    "\{source_root}/planbook.mbt",
    "\{source_root}/runtime_status.mbt",
    "\{source_root}/docs/PLANBOOK.md",
    "\{source_root}/docs/USAGE.md",
    "\{source_root}/.moontown/books/plan-moontown-quality/raw/backlog/implementation-backlog.json",
  ]
}

///|
fn planbook_backlog_criterion_for_item(
  item : PlanbookImplementationBacklogItem,
  workspace_root : String,
) -> PlanbookCriterionStatus {
  ignore(workspace_root)
  planbook_criterion(
    "backlog-\{item.id}",
    item.source_plan,
    "Backlog: \{item.title}",
    item.owner,
    false,
    "\{item.rationale} Priority: \{item.priority}. Target files: \{item.target_files.join(", ")}",
    "implement backlog item `\{item.id}` using its acceptance criteria: \{item.acceptance.join("; ")}. Validate with: \{item.validation.join("; ")}. Write completion evidence to `raw/backlog/completed/\{item.id}.md` after validation.",
  )
}

///|
async fn first_open_planbook_backlog_item(
  workspace_root : String,
) -> PlanbookImplementationBacklogItem? {
  let items = ensure_planbook_backlog(workspace_root)
  let mut best : PlanbookImplementationBacklogItem? = None
  for item in items {
    if item.status == "open" &&
      !@fs.exists(planbook_backlog_completion_path(workspace_root, item.id)) {
      match best {
        None => best = Some(item)
        Some(current) =>
          if item.priority < current.priority {
            best = Some(item)
          }
      }
    }
  }
  best
}

///|
fn planbook_backlog_completion_path(
  workspace_root : String,
  item_id : String,
) -> String {
  "\{workspace_root}/raw/backlog/completed/\{item_id}.md"
}

///|
async fn write_planbook_backlog_projection(
  workspace_root : String,
  items : Array[PlanbookImplementationBacklogItem],
) -> Unit {
  write_text_file(
    "\{workspace_root}/raw/backlog/README.md",
    planbook_backlog_readme_markdown(),
  )
  write_text_file(
    planbook_backlog_markdown_path(workspace_root),
    render_planbook_backlog_markdown(workspace_root, items),
  )
}

///|
async fn write_planbook_backlog_progress(
  workspace_root : String,
  items : Array[PlanbookImplementationBacklogItem],
) -> Unit {
  let total = items.length()
  let mut open = 0
  let mut completed = 0
  let mut blocked = 0
  for item in items {
    if @fs.exists(planbook_backlog_completion_path(workspace_root, item.id)) ||
      item.status == "done" {
      completed += 1
    } else if item.status == "blocked" || item.status == "paused" {
      blocked += 1
    } else if item.status == "open" {
      open += 1
    }
  }
  let interval_ms = planbook_backlog_next_check_interval_ms(
    open, completed, total,
  )
  write_text_file(
    "\{workspace_root}/raw/backlog/progress.json",
    "{\n  \"generated_at_ms\": \{@env.now()},\n  \"total\": \{total},\n  \"open\": \{open},\n  \"completed\": \{completed},\n  \"blocked_or_paused\": \{blocked},\n  \"next_check_interval_ms\": \{interval_ms},\n  \"policy\": \"immediate while open, 30 minutes when clear\"\n}\n",
  )
  write_text_file(
    planbook_backlog_progress_path(workspace_root),
    render_planbook_backlog_progress_markdown(
      total, open, completed, blocked, interval_ms,
    ),
  )
}

///|
fn planbook_backlog_next_check_interval_ms(
  open : Int,
  completed : Int,
  total : Int,
) -> Int {
  if open > 0 {
    0
  } else if total == 0 || completed >= total {
    1800000
  } else {
    300000
  }
}

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
async fn write_planbook_backlog_stop_policy(workspace_root : String) -> Unit {
  write_text_file(
    planbook_backlog_stop_policy_path(workspace_root),
    planbook_backlog_stop_policy_markdown(),
  )
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

///|
fn default_planbook_backlog_items() -> Array[PlanbookImplementationBacklogItem] {
  [
    {
      id: "live-change-log-projection",
      title: "Project live change history into PlanBook and operator UI state",
      owner: "moontown+planbook",
      priority: 10,
      status: "open",
      source_plan: "docs/PLANBOOK.md",
      rationale: "The town must explain what changed over time, not only what is true now.",
      target_files: [
        "planbook_autonomy.mbt", "planbook.mbt", "live_autonomy.mbt", "ui/rabbita-town/main/main.mbt",
        "docs/PLANBOOK.md",
      ],
      acceptance: [
        "PlanBook workspace has a durable change log", "Generated MoonBook UI state links to recent change history",
        "Operator can inspect what changed without reading raw daemon logs",
      ],
      validation: [
        "moon check --no-render", "moon test planbook_autonomy_wbtest.mbt live_autonomy_wbtest.mbt --no-render",
        "git diff --check",
      ],
      created_at_ms: @env.now(),
    },
    {
      id: "validated-auto-commit-policy",
      title: "Promote validated self-repairs into local commits with auditable policy",
      owner: "moontown+planbook+moonclaw",
      priority: 20,
      status: "open",
      source_plan: "docs/PLANBOOK.md",
      rationale: "A live software town needs source-control discipline, not only file patches.",
      target_files: [
        "planbook_repair.mbt", "planbook_autonomy.mbt", "docs/PLANBOOK.md",
      ],
      acceptance: [
        "Repair packets carry explicit commit and push policy", "Accepted repair result records commit status and message",
        "Push remains disabled unless policy is changed in JSON or docs",
      ],
      validation: [
        "moon check --no-render", "moon test planbook_autonomy_wbtest.mbt --no-render",
        "git diff --check",
      ],
      created_at_ms: @env.now(),
    },
    {
      id: "daily-engineering-digest",
      title: "Generate a daily engineering digest from PlanBook repair and daemon history",
      owner: "moontown+planbook",
      priority: 30,
      status: "open",
      source_plan: "docs/USAGE.md",
      rationale: "The operator should see overnight progress, blockers, and commits without tailing logs.",
      target_files: [
        "planbook_autonomy.mbt", "runtime_status.mbt", "docs/USAGE.md",
      ],
      acceptance: [
        "Daily digest summarizes attempts, accepted repairs, blockers, validations, and commits",
        "Digest is written to the PlanBook workspace", "Live status points to the latest digest",
      ],
      validation: [
        "moon check --no-render", "moon test planbook_autonomy_wbtest.mbt live_autonomy_wbtest.mbt --no-render",
        "git diff --check",
      ],
      created_at_ms: @env.now(),
    },
  ]
}

///|
async fn append_planbook_change_log(
  workspace_root : String,
  event : String,
  detail : String,
) -> Unit {
  let path = planbook_change_log_path(workspace_root)
  let previous = read_text_or_empty(path)
  let header = if previous.trim().is_empty() {
    "# PlanBook Change Log\n\nThis log records live changes in the PlanBook-managed self-build system.\n\n"
  } else {
    previous.trim_end().to_owned() + "\n\n"
  }
  let entry = ["## \{@env.now()} - \{event}", "", detail].join("\n")
  write_text_file(path, header + entry + "\n")
}
