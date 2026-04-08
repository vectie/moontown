///|
pub struct SchedulerTick {
  sequence : Int
  summary : String
} derive(Show, Eq)

///|
pub struct ScheduledJob {
  id : String
  kind : String
  interval_seconds : Int
} derive(Show, Eq)

///|
pub struct SchedulerAction {
  kind : String
  detail : String
} derive(Show, Eq)

///|
pub fn collect_due_tasks(town : @core.TownState) -> Array[@core.TownTask] {
  let tasks : Array[@core.TownTask] = []
  for task in town.tasks {
    if task.status == @core.TownTaskStatus::Pending ||
      task.status == @core.TownTaskStatus::Planned {
      tasks.push(task)
    }
  }
  tasks
}

///|
pub fn plan_tick(
  town : @core.TownState,
  report : @health.HealthReport,
) -> Array[SchedulerAction] {
  let actions : Array[SchedulerAction] = []
  for task in collect_due_tasks(town) {
    actions.push({ kind: "dispatch", detail: "\{task.id} for \{task.book_id}" })
  }
  for recovery in @health.recovery_actions(report) {
    actions.push({ kind: recovery.kind, detail: recovery.detail })
  }
  actions
}

///|
pub fn next_tick(
  sequence : Int,
  actions : Array[SchedulerAction],
) -> SchedulerTick {
  { sequence, summary: "\{actions.length()} town actions planned" }
}
