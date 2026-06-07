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
async fn write_planbook_backlog_stop_policy(workspace_root : String) -> Unit {
  write_text_file(
    planbook_backlog_stop_policy_path(workspace_root),
    planbook_backlog_stop_policy_markdown(),
  )
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
