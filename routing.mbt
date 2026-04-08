///|
pub fn role_label(role : WorkerRole) -> String {
  match role {
    Harness => "harness"
    Planner => "planner"
    Specialist => "specialist"
    Reviewer => "reviewer"
    MemoryKeeper => "memory"
    Watcher => "watcher"
  }
}

///|
pub fn domain_label(domain : WorkDomain) -> String {
  match domain {
    Coding => "coding"
    Finance => "finance"
    Research => "research"
    Operations => "operations"
    Custom(name) => name
  }
}

///|
pub fn isolation_label(mode : IsolationMode) -> String {
  match mode {
    SharedWorkspace => "shared-workspace"
    BookWorkspace => "book-workspace"
    Worktree => "worktree"
  }
}

///|
fn worker_is_available(worker : Worker) -> Bool {
  match worker.status {
    Idle => true
    _ => false
  }
}

///|
fn role_matches(worker : Worker, task : Task) -> Bool {
  match task.required_role {
    Some(role) => worker.role == role
    None => true
  }
}

///|
fn array_contains(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}

///|
fn skill_overlap(worker : Worker, task : Task) -> Int {
  let mut score = 0
  for skill in task.required_skills {
    if array_contains(worker.skills, skill) {
      score += 1
    }
  }
  score
}

///|
pub fn worker_score(worker : Worker, task : Task) -> Int {
  if !worker_is_available(worker) {
    return -1
  }
  if !role_matches(worker, task) {
    return -1
  }
  let mut score = 0
  if worker.book_id == task.book_id {
    score += 50
  }
  score += skill_overlap(worker, task) * 10
  match task.required_role {
    Some(role) if role == worker.role => score += 20
    _ => ()
  }
  match worker.role {
    Harness if task.required_role == None => score += 5
    Specialist if task.required_role == None => score += 3
    _ => ()
  }
  score
}

///|
pub fn preferred_isolation(task : Task, worker : Worker) -> IsolationMode {
  if task.book_id != worker.book_id {
    return Worktree
  }
  match task.domain {
    Coding =>
      match worker.preferred_isolation {
        SharedWorkspace => BookWorkspace
        other => other
      }
    Finance => Worktree
    Research => worker.preferred_isolation
    Operations => worker.preferred_isolation
    Custom(_) => worker.preferred_isolation
  }
}

///|
fn assignment_rationale(
  task : Task,
  worker : Worker,
  isolation : IsolationMode,
) -> String {
  let skill_count = skill_overlap(worker, task)
  if worker.book_id == task.book_id {
    "same-book route for \{domain_label(task.domain)} with \{skill_count} matching skills using \{isolation_label(isolation)}"
  } else {
    "cross-book escalation from \{task.book_id} to \{worker.book_id} via \{role_label(worker.role)} using \{isolation_label(isolation)}"
  }
}

///|
pub fn Town::plan_assignment(self : Town, task : Task) -> Assignment? {
  let mut best_score = -1
  let mut best_worker : Worker? = None
  for worker in self.workers {
    let score = worker_score(worker, task)
    if score > best_score {
      best_score = score
      best_worker = Some(worker)
    }
  }
  match best_worker {
    Some(worker) if best_score >= 0 => {
      let isolation = preferred_isolation(task, worker)
      Some(
        Assignment::new(
          task_id=task.id,
          worker_id=worker.id,
          book_id=task.book_id,
          isolation~,
          rationale=assignment_rationale(task, worker, isolation),
        ),
      )
    }
    _ => None
  }
}

///|
fn reserve_worker(
  workers : Array[Worker],
  worker_id : String,
  task_id : String,
) -> Unit {
  for i in 0..<workers.length() {
    let worker = workers[i]
    if worker.id == worker_id {
      workers[i] = { ..worker, status: Running, active_task_id: Some(task_id) }
      break
    }
  }
}

///|
fn mark_task_assigned(
  tasks : Array[Task],
  task_id : String,
  worker_id : String,
) -> Unit {
  for i in 0..<tasks.length() {
    let task = tasks[i]
    if task.id == task_id {
      tasks[i] = {
        ..task,
        status: Assigned,
        assigned_worker_id: Some(worker_id),
      }
      break
    }
  }
}

///|
fn task_summary_line(task : Task, assignment : Assignment) -> String {
  "\{task.title} -> \{assignment.worker_id} (\{assignment.rationale})"
}

///|
pub fn Town::assign_backlog(self : Town) -> Array[Assignment] {
  let planned : Array[Assignment] = []
  for task in self.tasks {
    if task.status != Backlog {
      continue
    }
    match self.plan_assignment(task) {
      Some(assignment) => {
        reserve_worker(self.workers, assignment.worker_id, assignment.task_id)
        mark_task_assigned(self.tasks, assignment.task_id, assignment.worker_id)
        self.assignments.push(assignment)
        self.events.push(
          TownEvent::new(
            title="assignment",
            detail=task_summary_line(task, assignment),
          ),
        )
        planned.push(assignment)
      }
      None =>
        self.events.push(
          TownEvent::new(
            title="unassigned",
            detail="\{task.id} stayed in backlog because no worker matched \{task.title}",
          ),
        )
    }
  }
  planned
}
