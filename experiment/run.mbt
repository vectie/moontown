///|
pub enum ExperimentPhase {
  Draft
  Running
  CoolingDown
  Complete
  Halted
} derive(Show, Eq)

///|
pub fn experiment_phases() -> Array[ExperimentPhase] {
  [Draft, Running, CoolingDown, Complete, Halted]
}

///|
pub struct Cohort {
  id : String
  name : String
  participants : Array[String]
} derive(Show, Eq)

///|
pub fn Cohort::new(
  id~ : String,
  name~ : String,
  participants? : Array[String] = [],
) -> Cohort {
  { id, name, participants }
}

///|
pub struct Intervention {
  id : String
  title : String
  detail : String
  target_book_ids : Array[String]
} derive(Show, Eq)

///|
pub fn Intervention::new(
  id~ : String,
  title~ : String,
  detail~ : String,
  target_book_ids? : Array[String] = [],
) -> Intervention {
  { id, title, detail, target_book_ids }
}

///|
pub struct Measurement {
  metric : String
  value : Double
  note : String
} derive(Show, Eq)

///|
pub fn Measurement::new(
  metric~ : String,
  value~ : Double,
  note? : String = "",
) -> Measurement {
  { metric, value, note }
}

///|
pub struct StopRule {
  metric : String
  threshold : Double
  direction : String
} derive(Show, Eq)

///|
pub fn StopRule::new(
  metric~ : String,
  threshold~ : Double,
  direction? : String = "gte",
) -> StopRule {
  { metric, threshold, direction }
}

///|
pub struct ExperimentDefinition {
  id : String
  title : String
  hypothesis : String
  target_book_ids : Array[String]
  interventions : Array[Intervention]
  stop_rules : Array[StopRule]
} derive(Show, Eq)

///|
pub fn ExperimentDefinition::new(
  id~ : String,
  title~ : String,
  hypothesis~ : String,
  target_book_ids? : Array[String] = [],
  interventions? : Array[Intervention] = [],
  stop_rules? : Array[StopRule] = [],
) -> ExperimentDefinition {
  { id, title, hypothesis, target_book_ids, interventions, stop_rules }
}

///|
pub struct ExperimentRun {
  id : String
  definition_id : String
  phase : ExperimentPhase
  cohorts : Array[Cohort]
  measurements : Array[Measurement]
  spawned_task_ids : Array[String]
} derive(Show, Eq)

///|
pub struct ExperimentOutcome {
  run_id : String
  summary : String
  should_stop : Bool
} derive(Show, Eq)

///|
pub fn start_experiment(
  definition : ExperimentDefinition,
  cohorts : Array[Cohort],
) -> ExperimentRun {
  {
    id: "\{definition.id}-run",
    definition_id: definition.id,
    phase: Running,
    cohorts,
    measurements: [],
    spawned_task_ids: [],
  }
}

///|
pub fn ExperimentRun::record_measurement(
  self : ExperimentRun,
  measurement : Measurement,
) -> ExperimentRun {
  let next = self.measurements.copy()
  next.push(measurement)
  { ..self, measurements: next }
}

///|
pub fn evaluate_run(
  run : ExperimentRun,
  definition : ExperimentDefinition,
) -> ExperimentOutcome {
  let should_stop = if definition.stop_rules.is_empty() {
    false
  } else {
    crossed_stop_rule(run.measurements, definition.stop_rules[0])
  }
  let summary = if should_stop {
    "stop requested for \{run.id}"
  } else {
    "run \{run.id} remains active"
  }
  { run_id: run.id, summary, should_stop }
}

///|
fn crossed_stop_rule(
  measurements : Array[Measurement],
  rule : StopRule,
) -> Bool {
  for measurement in measurements {
    if measurement.metric == rule.metric {
      if rule.direction == "gte" && measurement.value >= rule.threshold {
        return true
      }
      if rule.direction == "lte" && measurement.value <= rule.threshold {
        return true
      }
    }
  }
  false
}
