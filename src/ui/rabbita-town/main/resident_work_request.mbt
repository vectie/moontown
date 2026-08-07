///|
fn resident_request_book_id(
  model : Model,
  agent : EnergyValleyRuntimeAgent,
  task : EnergyValleyRuntimeWorkItem?,
) -> String {
  match task {
    Some(work) =>
      match golden_valley_optional_nonempty(work.bookId) {
        Some(book_id) => return book_id
        None => ()
      }
    None => ()
  }
  match golden_valley_optional_nonempty(agent.bookId) {
    Some(book_id) => book_id
    None => model.request_book_id
  }
}

///|
fn resident_request_freshness_label(phase : EnergyValleyRuntimePhase) -> String {
  match phase {
    Live => "当前实时运行时投影"
    Stale =>
      "最近运行时快照（已过期，不代表当前仍在执行）"
    Loading => "正在连接运行时；身份上下文尚未完成刷新"
    Unavailable => "运行时不可用；身份上下文无法复核"
    Error => "运行时投影读取失败；身份上下文无法复核"
  }
}

///|
fn resident_request_task_context(task : EnergyValleyRuntimeWorkItem?) -> String {
  match task {
    None => "Work item: 当前投影没有关联工作项"
    Some(work) => {
      let safe_title = resident_safe_task_summary(work.title)
      let run_id = work.runId.unwrap_or("未记录")
      let book_id = work.bookId.unwrap_or("未记录")
      let building_id = resident_task_runtime_building_identity(work)
      let safe_activity = match work.activityLabel {
        Some(label) if !label.trim().is_empty() =>
          resident_safe_task_summary(label)
        _ => "未记录"
      }
      "Work item: \{work.id}\n任务: \{safe_title}\n任务状态: \{work.status}\nRun ID: \{run_id}\nBook: \{book_id}\n建筑: \{building_id}\n活动: \{safe_activity}"
    }
  }
}

///|
fn resident_request_title(agent : EnergyValleyRuntimeAgent) -> String {
  "基于 \{agent.name} 的上下文创建真实工作"
}

///|
fn resident_request_prompt(
  model : Model,
  agent : EnergyValleyRuntimeAgent,
  task : EnergyValleyRuntimeWorkItem?,
) -> String {
  "运行时上下文（\{resident_request_freshness_label(model.energy_valley_runtime.phase)}）：\nAgent: \{agent.name}（\{agent.id}）\n角色: \{agent.role}\nAgent 状态: \{agent.status}\n\{resident_request_task_context(task)}\n\n请基于以上上下文建立一项可审阅、可追踪结果页的真实工作。此表单保存的是持续观察请求；MoonTown 调度策略会选择最终执行 Agent，所选居民只是上下文来源，不代表定向派单。只有运行时 Work item、Run ID 与结果链接可以作为完成证据。"
}
