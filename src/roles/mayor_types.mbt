///|
pub struct MayorGoalLane {
  entry : @moonbook.BookCatalogEntry
  objective : String
  rationale : String
} derive(Eq)

///|
pub fn MayorGoalLane::new(
  entry~ : @moonbook.BookCatalogEntry,
  objective~ : String,
  rationale~ : String,
) -> MayorGoalLane {
  { entry, objective, rationale }
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
pub struct MayorGoalPlan {
  output_contract : String
  prompt : String
  parallelizable : Bool
  summary : String
  lanes : Array[MayorGoalLane]
} derive(Eq)

///|
pub fn MayorGoalPlan::new(
  output_contract~ : String,
  prompt~ : String,
  parallelizable~ : Bool,
  summary~ : String,
  lanes~ : Array[MayorGoalLane],
) -> MayorGoalPlan {
  { output_contract, prompt, parallelizable, summary, lanes }
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
pub struct MayorSupervisionDirective {
  kind : String
  task_id : String
  execution_status : @core.TaskExecutionStatus
  detail : String
  next_retry_tick : Int?
} derive(Eq)

///|
pub impl Show for MayorSupervisionDirective with fn output(
  self : MayorSupervisionDirective,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "MayorSupervisionDirective(kind=\{self.kind}, task_id=\{self.task_id}, status=\{self.execution_status.to_string()}, detail=\{self.detail})",
  )
}

///|
pub struct MayorSupervisionPacket {
  output_contract : String
  tick : Int
  summary : String
  directives : Array[MayorSupervisionDirective]
} derive(Eq)

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
pub struct MayorKeeperPacket {
  handoff : @moonclaw.EmbeddedRuntimeHandoff
  packet : @moonclaw.ExternalProposalPacket
  packet_path : String
  rationale : String
} derive(Eq)

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
pub struct MayorPatrolPacket {
  output_contract : String
  report : @health.HealthReport
  actions : Array[@scheduler.SchedulerAction]
  tick : @scheduler.SchedulerTick
  recovery : Array[@health.RecoveryAction]
} derive(Eq)

///|
pub impl Show for MayorPatrolPacket with fn output(
  self : MayorPatrolPacket,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "MayorPatrolPacket(output_contract=\{self.output_contract}, actions=\{self.actions.length()}, recovery=\{self.recovery.length()})",
  )
}
