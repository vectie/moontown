///|
priv struct StandingGoalSummary {
  enabled_count : Int32
  disabled_count : Int32
  active_goal : StandingGoalSnapshot?
}

///|
fn standing_goal_summary(model : Model) -> StandingGoalSummary {
  let mut enabled_count = 0
  let mut disabled_count = 0
  let mut active_goal : StandingGoalSnapshot? = None
  for goal in model.standing_goals {
    if goal.enabled {
      enabled_count += 1
      match active_goal {
        None => active_goal = Some(goal)
        Some(_) => ()
      }
    } else {
      disabled_count += 1
    }
  }
  { enabled_count, disabled_count, active_goal, }
}

///|
priv struct StandingGoalNextCheckView {
  idle_detail : String
}

///|
fn standing_goal_next_check_view(model : Model) -> StandingGoalNextCheckView {
  let active_goal = standing_goal_summary(model).active_goal
  match active_goal {
    Some(goal) => {
      let remaining = ticks_until_next_goal_check(model, goal)
      { idle_detail: standing_goal_idle_wait_detail(goal, remaining), }
    }
    None =>
      {
        idle_detail: "Waiting for a configured standing watch. Save a watch to activate this worker.",
      }
  }
}

///|
fn standing_goal_idle_wait_detail(
  _goal : StandingGoalSnapshot,
  remaining_ticks : Int32,
) -> String {
  let wait = if remaining_ticks > 0 {
    "\{remaining_ticks} town checks"
  } else {
    "the next town check"
  }
  "Waiting until \{wait}. The next due check will move a watcher into an active run."
}

///|
fn ticks_until_next_goal_check(
  model : Model,
  goal : StandingGoalSnapshot,
) -> Int32 {
  let remaining = goal.next_due_tick - daemon_tick_count(model)
  if remaining < 0 {
    0
  } else {
    remaining
  }
}

///|
/// Enabled is configuration, not evidence of an active worker or a successful run.
fn standing_goal_work_status(
  goal : StandingGoalSnapshot,
  current_tick : Int32?,
) -> String {
  if !goal.enabled {
    "已暂停"
  } else {
    match current_tick {
      Some(tick) if goal.next_due_tick <= tick => "待检查"
      Some(_) => "已启用"
      None => "待同步"
    }
  }
}

///|
fn standing_goal_work_source(model : Model) -> String {
  match runtime_availability(model) {
    DemoRuntime => "演示配置"
    ConnectingRuntime => "连接中 · 尚未确认最新状态"
    OfflineRuntime => "离线 · 尚未确认最新状态"
    LiveRuntime => "已保存的任务"
  }
}

///|
fn render_standing_goal_work_panel(model : Model) -> @rabbita.Html {
  let summary = standing_goal_summary(model)
  let current_tick = model.daemon_snapshot.map(snapshot => {
    snapshot.tick_sequence
  })
  let rows = model.standing_goals.map(goal => {
    article(class="editor-pipeline-stage handoff-artifact-card", [
      div(class="handoff-artifact-heading", [
        h3(goal.title),
        span(
          class="handoff-status",
          standing_goal_work_status(goal, current_tick),
        ),
      ]),
      p(compact_single_line(goal.prompt, limit=180)),
      render_advanced_details("调度参数", [
        render_module_detail("任务", goal.id),
        render_module_detail(
          "频率",
          "每 \{goal.cadence_ticks} 个调度 tick",
        ),
        render_module_detail("下次检查", "tick \{goal.next_due_tick}"),
        p("调度 tick 不是日期；配置启用不代表任务已运行。"),
      ]),
    ])
  })
  section(class="editor-pipeline-panel viewport-editor-boundary", [
    div(class="viewport-panel-heading", [
      h2("自动任务"),
      p(standing_goal_work_source(model)),
    ]),
    if model.standing_goals.is_empty() {
      p("尚无任务记录。可从任务入口配置长期关注。")
    } else {
      div([
        p(
          "\{summary.enabled_count} 已启用 · \{summary.disabled_count} 已暂停",
        ),
        render_advanced_details(
          "自动任务列表",
          rows,
          compact_label="查看任务",
        ),
      ])
    },
  ])
}
