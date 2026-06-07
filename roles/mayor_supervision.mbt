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
