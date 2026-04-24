///|
pub struct Mayor {
  runtime : @moonclaw.EmbeddedMoonclawRuntime
} derive(Show, Eq)

///|
pub fn Mayor::new() -> Mayor {
  { runtime: @moonclaw.mayor_runtime() }
}

///|
pub fn Mayor::runtime(self : Mayor) -> @moonclaw.EmbeddedMoonclawRuntime {
  self.runtime
}

///|
pub struct MayorDispatchPacket {
  decision : @dispatch.RouteDecision
  output_contract : String
  rationale : String
} derive(Show, Eq)

///|
pub struct MayorGoalLane {
  entry : @moonbook.BookCatalogEntry
  objective : String
  rationale : String
} derive(Show, Eq)

///|
pub struct MayorGoalPlan {
  output_contract : String
  prompt : String
  parallelizable : Bool
  summary : String
  lanes : Array[MayorGoalLane]
} derive(Show, Eq)

///|
pub struct MayorSupervisionDirective {
  kind : String
  task_id : String
  execution_status : @core.TaskExecutionStatus
  detail : String
  next_retry_tick : Int?
} derive(Show, Eq)

///|
pub struct MayorSupervisionPacket {
  output_contract : String
  tick : Int
  summary : String
  directives : Array[MayorSupervisionDirective]
} derive(Show, Eq)

///|
pub fn Mayor::decide_dispatch(
  self : Mayor,
  state : @core.TownState,
  task : @core.TownTask,
) -> MayorDispatchPacket {
  let decision = @dispatch.route_task(state, @dispatch.RouteRequest::new(task~))
  let rationale = match decision {
    Assigned(plan) =>
      "mayor routed \{plan.task_id} to \{plan.worker_id} under \{plan.isolation.to_string()}"
    Escalated(reason) => "mayor escalated \{task.id}: \{reason}"
    Deferred(reason) => "mayor deferred \{task.id}: \{reason}"
  }
  {
    decision,
    output_contract: self.runtime.output_contract.unwrap_or(
      "mayor.dispatch.packet.v1",
    ),
    rationale,
  }
}

///|
pub fn Mayor::plan_goal(
  self : Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  goal : String,
  explicit_book_id? : String? = None,
) -> MayorGoalPlan {
  ignore(self)
  let prompt = mayor_goal_decomposition_prompt(catalog, goal, explicit_book_id~)
  match explicit_book_id {
    Some(book_id) =>
      match @moonbook.find_catalog_entry(catalog, book_id) {
        Some(entry) =>
          {
            output_contract: "mayor.goal.decomposition.v1",
            prompt,
            parallelizable: false,
            summary: "Mayor bound the goal to the explicit book \{entry.id}.",
            lanes: [goal_lane(entry, goal, entry.id)],
          }
        None =>
          {
            output_contract: "mayor.goal.decomposition.v1",
            prompt,
            parallelizable: false,
            summary: "Mayor could not find the explicit book \{book_id}.",
            lanes: [],
          }
      }
    None => {
      let topics = mayor_research_lane_topics(goal)
      if mayor_should_parallelize_goal(goal, topics) {
        let lanes = topics.map(fn(topic) {
          let entry = @moonbook.parallel_research_entry(topic)
          goal_lane(entry, goal, topic)
        })
        {
          output_contract: "mayor.goal.decomposition.v1",
          prompt,
          parallelizable: true,
          summary: "Mayor split the goal into \{lanes.length()} isolated research lanes because the request names multiple knowledge subjects.",
          lanes,
        }
      } else {
        let selected = select_default_entry(catalog, goal)
        match selected {
          Some(entry) =>
            {
              output_contract: "mayor.goal.decomposition.v1",
              prompt,
              parallelizable: false,
              summary: "Mayor kept the goal inside one book because the request reads as one domain lane.",
              lanes: [goal_lane(entry, goal, entry.id)],
            }
          None =>
            {
              output_contract: "mayor.goal.decomposition.v1",
              prompt,
              parallelizable: false,
              summary: "Mayor found no available book for the goal.",
              lanes: [],
            }
        }
      }
    }
  }
}

///|
fn mayor_research_lane_topics(goal : String) -> Array[String] {
  let notes = goal.to_lower()
  let topics : Array[String] = []
  for topic in ["moontown", "moonbook", "moonclaw", "finance", "coding"] {
    if notes.contains(topic) {
      topics.push(topic)
    }
  }
  topics
}

///|
fn mayor_should_parallelize_goal(goal : String, topics : Array[String]) -> Bool {
  let notes = goal.to_lower()
  let research_like = notes.contains("research") ||
    notes.contains("compare") ||
    notes.contains("survey") ||
    notes.contains("map")
  research_like && topics.length() > 1
}

///|
pub struct MayorKeeperPacket {
  handoff : @moonclaw.EmbeddedRuntimeHandoff
  packet : @moonclaw.ExternalProposalPacket
  packet_path : String
  rationale : String
} derive(Show, Eq)

///|
pub struct MayorPatrolPacket {
  output_contract : String
  report : @health.HealthReport
  actions : Array[@scheduler.SchedulerAction]
  tick : @scheduler.SchedulerTick
  recovery : Array[@health.RecoveryAction]
} derive(Show, Eq)

///|
pub fn Mayor::patrol(
  self : Mayor,
  state : @core.TownState,
) -> MayorPatrolPacket {
  ignore(self)
  let report = @health.inspect_town(state)
  let recovery = @health.recovery_actions(report)
  let actions = @scheduler.plan_tick(state, report)
  let tick = @scheduler.next_tick(1, actions)
  { output_contract: "mayor.patrol.packet.v1", report, actions, tick, recovery }
}

///|
pub fn Mayor::supervise(
  self : Mayor,
  state : @core.TownState,
  tick : Int,
) -> MayorSupervisionPacket {
  ignore(self)
  let directives : Array[MayorSupervisionDirective] = []
  for execution in state.executions {
    match supervision_directive_for(state, execution, tick) {
      Some(directive) => directives.push(directive)
      None => ()
    }
  }
  {
    output_contract: "mayor.supervision.packet.v1",
    tick,
    summary: if directives.is_empty() {
      "Mayor found no stale or retry-ready executions."
    } else {
      "Mayor produced \{directives.length()} supervision directives."
    },
    directives,
  }
}

///|
pub fn Mayor::handoff_to_keeper(
  self : Mayor,
  book : @core.BookRef,
  objective : String,
  scope_summary : String,
  constraints? : Array[String] = [],
) -> @moonclaw.EmbeddedRuntimeHandoff {
  ignore(self)
  @moonclaw.mayor_to_keeper_handoff(
    book.id,
    objective,
    scope_summary,
    constraints~,
  )
}

///|
pub async fn Mayor::prepare_keeper_packet(
  self : Mayor,
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  packet_dir? : String = @moonclaw.default_packet_directory(),
) -> MayorKeeperPacket {
  let bundle = @moonbook.hydrate_worker_context(entry, task)
  let packet_id = compact_keeper_packet_id(entry.id, task.id)
  let profile = moonclaw_profile_for_task(task)
  let packet = @moonclaw.proposal_packet_from_bundle(
    bundle,
    task.title,
    "Mayor issued a keeper packet for \{entry.name}.",
    profile,
    packet_id=Some(packet_id),
    notes=["produced by mayor runtime", "book task kind=\{task.kind}"],
    tags=[entry.id, task.kind, "keeper"],
  )
  {
    handoff: self.handoff_to_keeper(
      entry.to_book_ref(),
      task.title,
      bundle.memory_summary,
      constraints=["follow packet-first handoff", "keep book memory isolated"],
    ),
    packet,
    packet_path: @moonclaw.packet_file_path(packet_dir, packet.packet_id),
    rationale: "Mayor prepared keeper packet \{packet.packet_id} for \{entry.id} / \{task.id}.",
  }
}

///|
pub fn keeper_runtime(
  book : @core.BookRef,
) -> @moonclaw.EmbeddedMoonclawRuntime {
  @moonclaw.keeper_runtime(book)
}

///|
fn compact_keeper_packet_id(book_id : String, task_id : String) -> String {
  let hash = task_id.hash().to_string().trim(chars="-").to_string()
  let prefix = compact_id_segment(book_id, 24)
  let body = compact_id_segment(task_id, 40)
  "keeper-\{prefix}-\{body}-\{hash}"
}

///|
fn compact_id_segment(text : String, limit : Int) -> String {
  let builder = StringBuilder::new()
  let mut emitted = 0
  let mut last_dash = false
  for char in text.to_lower() {
    if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
      if emitted >= limit {
        break
      }
      builder.write_char(char)
      emitted += 1
      last_dash = false
    } else if !last_dash && emitted > 0 {
      if emitted >= limit {
        break
      }
      builder.write_char('-')
      emitted += 1
      last_dash = true
    }
  }
  let slug = builder.to_string().trim(chars="-").to_string()
  if slug.is_blank() {
    "task"
  } else {
    slug
  }
}

///|
fn moonclaw_profile_for_task(task : @moonbook.BookTask) -> String {
  match task.kind {
    "ingest" | "ingest-followup" => "wiki_ingest_controller"
    "review" | "planning" => "wiki_lint_controller"
    "analysis" | "synthesis" => "wiki_query_controller"
    _ => "wiki_query_controller"
  }
}

///|
fn goal_lane(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
  topic : String,
) -> MayorGoalLane {
  let objective = if @moonbook.should_parallelize_goal(goal) {
    "Own only the \{topic} research lane. Build durable source, entity, concept, and synthesis coverage for this lane. Cross-reference other lanes only through durable outputs. Global town goal: \{goal}"
  } else {
    goal
  }
  {
    entry,
    objective,
    rationale: if objective == goal {
      "single-lane book objective"
    } else {
      "parallel research lane for \{topic}"
    },
  }
}

///|
fn select_default_entry(
  catalog : Array[@moonbook.BookCatalogEntry],
  goal : String,
) -> @moonbook.BookCatalogEntry? {
  let notes = goal.to_lower()
  let book_id = if notes.contains("finance") ||
    notes.contains("ledger") ||
    notes.contains("budget") ||
    notes.contains("daily") {
    "finance"
  } else {
    "coding"
  }
  match @moonbook.find_catalog_entry(catalog, book_id) {
    Some(entry) => Some(entry)
    None => if catalog.is_empty() { None } else { Some(catalog[0]) }
  }
}

///|
fn supervision_directive_for(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
  tick : Int,
) -> MayorSupervisionDirective? {
  ignore(state)
  let stale = if execution.status == @core.TaskExecutionStatus::Running ||
    execution.status == @core.TaskExecutionStatus::RunConfirmed {
    execution.stale_after_tick <= tick
  } else {
    false
  }
  if stale {
    return Some({
      kind: if execution.attempt < 3 {
        "mark-stale-retry"
      } else {
        "mark-stale-failed"
      },
      task_id: execution.task_id,
      execution_status: @core.TaskExecutionStatus::Stale,
      detail: "Execution \{execution.task_id} missed its heartbeat window and needs mayor recovery.",
      next_retry_tick: if execution.attempt < 3 {
        Some(tick + retry_backoff_ticks(execution.attempt))
      } else {
        None
      },
    })
  }
  match execution.status {
    @core.TaskExecutionStatus::AwaitingPersistence =>
      Some({
        kind: "persist-result",
        task_id: execution.task_id,
        execution_status: execution.status,
        detail: "Execution \{execution.task_id} should be persisted into MoonBook.",
        next_retry_tick: None,
      })
    @core.TaskExecutionStatus::ReviewQueued =>
      Some({
        kind: "review-sync",
        task_id: execution.task_id,
        execution_status: execution.status,
        detail: "Execution \{execution.task_id} is waiting for keeper review sync.",
        next_retry_tick: None,
      })
    @core.TaskExecutionStatus::Stale | @core.TaskExecutionStatus::Failed =>
      match execution.next_retry_tick {
        Some(next_tick) if execution.attempt < 3 && next_tick <= tick =>
          Some({
            kind: "retry-execution",
            task_id: execution.task_id,
            execution_status: execution.status,
            detail: "Execution \{execution.task_id} is eligible for a supervised retry.",
            next_retry_tick: Some(
              tick + retry_backoff_ticks(execution.attempt + 1),
            ),
          })
        _ => None
      }
    _ => None
  }
}

///|
fn retry_backoff_ticks(attempt : Int) -> Int {
  match attempt {
    0 | 1 => 1
    2 => 3
    _ => 6
  }
}

///|
fn mayor_goal_decomposition_prompt(
  catalog : Array[@moonbook.BookCatalogEntry],
  goal : String,
  explicit_book_id? : String? = None,
) -> String {
  let books = catalog.map(fn(entry) { entry.id }).join(", ")
  let explicit = explicit_book_id.unwrap_or("none")
  "You are the Mayor claw for Moontown.\nDecide whether the town goal should stay in one MoonBook or decompose into multiple isolated MoonBooks.\nAvailable books: \{books}\nExplicit book: \{explicit}\nGoal: \{goal}\nRules:\n- parallelize only when the goal names meaningfully distinct knowledge subjects or domains\n- each lane must own an isolated wiki/workspace\n- prefer one lane if shared context is essential and decomposition would create artificial fragmentation\n- if decomposing, emit one lane per durable knowledge subject\n- each lane objective must be self-contained and book-local\nRequired output contract: mayor.goal.decomposition.v1\nFields:\n- parallelizable: bool\n- summary: string\n- lanes: [{book_id, objective, rationale}]"
}
