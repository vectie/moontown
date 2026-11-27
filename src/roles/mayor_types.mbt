///|
#derive(Eq)
pub struct MayorGoalLane {
  entry : @moonbook.BookCatalogEntry
  objective : String
  rationale : String
}

///|
pub fn MayorGoalLane::new(
  entry~ : @moonbook.BookCatalogEntry,
  objective~ : String,
  rationale~ : String,
) -> MayorGoalLane {
  { entry, objective, rationale, }
}

///|
pub impl Show for MayorGoalLane with fn output(
  self : MayorGoalLane,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "MayorGoalLane(book=\{self.entry.id}, objective=\{self.objective}, rationale=\{self.rationale})",
  )
}

///|
#derive(Eq)
pub struct MayorGoalPlan {
  output_contract : String
  prompt : String
  parallelizable : Bool
  summary : String
  lanes : Array[MayorGoalLane]
}

///|
pub fn MayorGoalPlan::new(
  output_contract~ : String,
  prompt~ : String,
  parallelizable~ : Bool,
  summary~ : String,
  lanes~ : Array[MayorGoalLane],
) -> MayorGoalPlan {
  { output_contract, prompt, parallelizable, summary, lanes, }
}

///|
pub impl Show for MayorGoalPlan with fn output(
  self : MayorGoalPlan,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "MayorGoalPlan(output_contract=\{self.output_contract}, parallelizable=\{self.parallelizable}, summary=\{self.summary}, lanes=\{self.lanes.length()})",
  )
}

///|
#derive(Eq)
pub struct MayorSupervisionDirective {
  kind : String
  task_id : String
  execution_status : @core.TaskExecutionStatus
  detail : String
  next_retry_tick : Int32?
}

///|
pub impl Show for MayorSupervisionDirective with fn output(
  self : MayorSupervisionDirective,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "MayorSupervisionDirective(kind=\{self.kind}, task_id=\{self.task_id}, status=\{self.execution_status}, detail=\{self.detail})",
  )
}

///|
#derive(Eq)
pub struct MayorSupervisionPacket {
  output_contract : String
  tick : Int32
  summary : String
  directives : Array[MayorSupervisionDirective]
}

///|
pub impl Show for MayorSupervisionPacket with fn output(
  self : MayorSupervisionPacket,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "MayorSupervisionPacket(output_contract=\{self.output_contract}, tick=\{self.tick}, summary=\{self.summary}, directives=\{self.directives.length()})",
  )
}

///|
#derive(Eq)
pub struct MayorKeeperPacket {
  handoff : @moonclaw.EmbeddedRuntimeHandoff
  packet : @moonclaw.ExternalProposalPacket
  packet_path : String
  rationale : String
}

///|
pub impl Show for MayorKeeperPacket with fn output(
  self : MayorKeeperPacket,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "MayorKeeperPacket(packet_path=\{self.packet_path}, rationale=\{self.rationale})",
  )
}

///|
#derive(Eq)
pub struct MayorPatrolPacket {
  output_contract : String
  report : @health.HealthReport
  actions : Array[@scheduler.SchedulerAction]
  tick : @scheduler.SchedulerTick
  recovery : Array[@health.RecoveryAction]
}

///|
pub impl Show for MayorPatrolPacket with fn output(
  self : MayorPatrolPacket,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "MayorPatrolPacket(output_contract=\{self.output_contract}, actions=\{self.actions.length()}, recovery=\{self.recovery.length()})",
  )
}
