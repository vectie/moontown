///|
pub struct Mayor {
  runtime : @moonclaw.EmbeddedMoonclawRuntime
} derive(Eq)

///|
pub impl Show for Mayor with fn output(self : Mayor, logger : &Logger) -> Unit {
  logger.write_string(
    "Mayor(runtime=\{self.runtime.runtime_id}, role=\{self.runtime.role_id})",
  )
}

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
} derive(Eq)

///|
pub impl Show for MayorDispatchPacket with fn output(
  self : MayorDispatchPacket,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "MayorDispatchPacket(output_contract=\{self.output_contract}, rationale=\{self.rationale})",
  )
}

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
