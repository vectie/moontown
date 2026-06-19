///|
pub enum EmbeddedPlanningLayer {
  Strategic
  Domain
  Execution
} derive(Debug, Eq)

///|
pub enum EmbeddedRuntimeMode {
  PlannerOnly
  Executor
} derive(Debug, Eq)

///|
pub enum EmbeddedToolAccess {
  Disabled
  Limited
  Full
} derive(Debug, Eq)

///|
pub enum EmbeddedMemoryScope {
  Step
  Workspace
  Domain
  Global
} derive(Debug, Eq)

///|
pub enum EmbeddedHandoffKind {
  StrategicToDomain
  DomainToExecution
  ExecutionToDomain
  DomainToStrategic
} derive(Debug, Eq)

///|
pub impl Show for EmbeddedPlanningLayer with fn output(self, logger) {
  match self {
    Strategic => logger.write_string("Strategic")
    Domain => logger.write_string("Domain")
    Execution => logger.write_string("Execution")
  }
}

///|
pub impl Show for EmbeddedRuntimeMode with fn output(self, logger) {
  match self {
    PlannerOnly => logger.write_string("PlannerOnly")
    Executor => logger.write_string("Executor")
  }
}

///|
pub impl Show for EmbeddedToolAccess with fn output(self, logger) {
  match self {
    Disabled => logger.write_string("Disabled")
    Limited => logger.write_string("Limited")
    Full => logger.write_string("Full")
  }
}

///|
pub impl Show for EmbeddedMemoryScope with fn output(self, logger) {
  match self {
    Step => logger.write_string("Step")
    Workspace => logger.write_string("Workspace")
    Domain => logger.write_string("Domain")
    Global => logger.write_string("Global")
  }
}

///|
pub impl Show for EmbeddedHandoffKind with fn output(self, logger) {
  match self {
    StrategicToDomain => logger.write_string("StrategicToDomain")
    DomainToExecution => logger.write_string("DomainToExecution")
    ExecutionToDomain => logger.write_string("ExecutionToDomain")
    DomainToStrategic => logger.write_string("DomainToStrategic")
  }
}

///|
pub struct EmbeddedMoonclawRuntime {
  runtime_id : String
  display_name : String
  role_id : String
  planning_layer : EmbeddedPlanningLayer
  runtime_mode : EmbeddedRuntimeMode
  tool_access : EmbeddedToolAccess
  memory_scope : EmbeddedMemoryScope
  allow_delegate : Bool
  allow_workspace_write : Bool
  allow_execution_tools : Bool
  visible_tools : Array[String]
  skills : Array[String]
  output_contract : String?
  authority_scope : String
} derive(Debug, Eq)

///|
pub fn EmbeddedMoonclawRuntime::new(
  runtime_id~ : String,
  display_name~ : String,
  role_id~ : String,
  planning_layer? : EmbeddedPlanningLayer = Execution,
  runtime_mode? : EmbeddedRuntimeMode = Executor,
  tool_access? : EmbeddedToolAccess = Full,
  memory_scope? : EmbeddedMemoryScope = Workspace,
  allow_delegate? : Bool = false,
  allow_workspace_write? : Bool = true,
  allow_execution_tools? : Bool = true,
  visible_tools? : Array[String] = [],
  skills? : Array[String] = [],
  output_contract? : String? = None,
  authority_scope~ : String,
) -> EmbeddedMoonclawRuntime {
  {
    runtime_id,
    display_name,
    role_id,
    planning_layer,
    runtime_mode,
    tool_access,
    memory_scope,
    allow_delegate,
    allow_workspace_write,
    allow_execution_tools,
    visible_tools,
    skills,
    output_contract,
    authority_scope,
  }
}

///|
pub struct EmbeddedRuntimeHandoff {
  kind : EmbeddedHandoffKind
  objective : String
  scope_summary : String
  constraints : Array[String]
  output_contract : String?
  target_role_id : String
} derive(Debug, Eq)

///|
pub fn EmbeddedRuntimeHandoff::new(
  kind~ : EmbeddedHandoffKind,
  objective~ : String,
  scope_summary~ : String,
  constraints? : Array[String] = [],
  output_contract? : String? = None,
  target_role_id~ : String,
) -> EmbeddedRuntimeHandoff {
  {
    kind,
    objective,
    scope_summary,
    constraints,
    output_contract,
    target_role_id,
  }
}
