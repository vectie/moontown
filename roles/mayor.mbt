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
pub fn Mayor::prepare_keeper_packet(
  self : Mayor,
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  packet_dir? : String = @moonclaw.default_packet_directory(),
) -> MayorKeeperPacket {
  let bundle = @moonbook.hydrate_worker_context(entry, task)
  let packet_id = "keeper-\{entry.id}-\{task.id}"
  let packet = @moonclaw.proposal_packet_from_bundle(
    bundle,
    task.title,
    "Mayor issued a keeper packet for \{entry.name}.",
    "wiki_ingest_controller",
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
