///|
/// Stable, domain-neutral contract for one baseline/challenger capability
/// experiment. MoonTown recommends a decision; it never activates a version.
pub fn capability_experiment_contract_version() -> String {
  "moontown.capability_experiment.v1"
}

///|
pub(all) struct CapabilityExperimentRecordRef {
  record_id : String
  record_version : String
  record_digest : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CapabilityExperimentPlan {
  contract_version : String
  experiment_id : String
  scope_id : String
  baseline_capability : CapabilityExperimentRecordRef
  challenger_capability : CapabilityExperimentRecordRef
  baseline_participant_ids : Array[String]
  challenger_participant_ids : Array[String]
  minimum_observations_per_arm : Int
  minimum_accepted_rate_delta : Double
  maximum_challenger_rejection_rate : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CapabilityExperimentAssignment {
  contract_version : String
  experiment_id : String
  scope_id : String
  participant_id : String
  assignment : String
  capability : CapabilityExperimentRecordRef
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CapabilityExperimentObservation {
  observation_id : String
  experiment_id : String
  scope_id : String
  participant_id : String
  assignment : String
  capability : CapabilityExperimentRecordRef
  outcome : CapabilityExperimentRecordRef
  reward_evidence : CapabilityExperimentRecordRef
  accepted : Bool
  recorded_at : Int64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CapabilityExperimentOutcome {
  contract_version : String
  experiment_id : String
  scope_id : String
  baseline_observations : Int
  challenger_observations : Int
  baseline_accepted_rate : Double
  challenger_accepted_rate : Double
  accepted_rate_delta : Double
  recommendation : String
  evidence_complete : Bool
  evaluated_at : Int64
} derive(Debug, Eq, ToJson, FromJson)

///|
fn capability_experiment_ref_valid(
  reference : CapabilityExperimentRecordRef,
) -> Bool {
  !reference.record_id.is_blank() &&
  !reference.record_version.is_blank() &&
  !reference.record_digest.is_blank()
}

///|
fn capability_experiment_participants_valid(
  baseline : ArrayView[String],
  challenger : ArrayView[String],
) -> Bool {
  let seen : Array[String] = []
  for participant in baseline {
    if participant.is_blank() || seen.contains(participant) {
      return false
    }
    seen.push(participant)
  }
  for participant in challenger {
    if participant.is_blank() || seen.contains(participant) {
      return false
    }
    seen.push(participant)
  }
  true
}

///|
pub fn validate_capability_experiment_plan(
  plan : CapabilityExperimentPlan,
) -> Unit raise {
  guard plan.contract_version == capability_experiment_contract_version() else {
    fail("unsupported capability experiment contract")
  }
  guard !plan.experiment_id.is_blank() && !plan.scope_id.is_blank() else {
    fail("capability experiment identity is required")
  }
  guard capability_experiment_ref_valid(plan.baseline_capability) &&
    capability_experiment_ref_valid(plan.challenger_capability) &&
    plan.baseline_capability != plan.challenger_capability else {
    fail("capability experiment requires distinct versioned arms")
  }
  guard !plan.baseline_participant_ids.is_empty() &&
    !plan.challenger_participant_ids.is_empty() &&
    capability_experiment_participants_valid(
      plan.baseline_participant_ids,
      plan.challenger_participant_ids,
    ) else {
    fail("capability experiment participants must be non-empty and disjoint")
  }
  guard plan.minimum_observations_per_arm > 0 &&
    plan.minimum_accepted_rate_delta >= -1.0 &&
    plan.minimum_accepted_rate_delta <= 1.0 &&
    plan.maximum_challenger_rejection_rate >= 0.0 &&
    plan.maximum_challenger_rejection_rate <= 1.0 else {
    fail("capability experiment thresholds are invalid")
  }
}

///|
pub fn assign_capability_experiment(
  plan : CapabilityExperimentPlan,
  participant_id : String,
) -> CapabilityExperimentAssignment raise {
  validate_capability_experiment_plan(plan)
  let challenger = plan.challenger_participant_ids.contains(participant_id)
  guard challenger || plan.baseline_participant_ids.contains(participant_id) else {
    fail("participant is not enrolled in the capability experiment")
  }
  {
    contract_version: capability_experiment_contract_version(),
    experiment_id: plan.experiment_id,
    scope_id: plan.scope_id,
    participant_id,
    assignment: if challenger {
      "challenger"
    } else {
      "baseline"
    },
    capability: if challenger {
      plan.challenger_capability
    } else {
      plan.baseline_capability
    },
  }
}

///|
pub fn evaluate_capability_experiment(
  plan : CapabilityExperimentPlan,
  observations : ArrayView[CapabilityExperimentObservation],
  evaluated_at~ : Int64,
) -> CapabilityExperimentOutcome raise {
  validate_capability_experiment_plan(plan)
  guard evaluated_at >= 0 else { fail("evaluated_at must be non-negative") }
  let seen : Array[String] = []
  let mut baseline_count = 0
  let mut baseline_accepted = 0
  let mut challenger_count = 0
  let mut challenger_accepted = 0
  for observation in observations {
    guard !observation.observation_id.is_blank() &&
      !seen.contains(observation.observation_id) &&
      observation.experiment_id == plan.experiment_id &&
      observation.scope_id == plan.scope_id &&
      observation.recorded_at <= evaluated_at &&
      capability_experiment_ref_valid(observation.outcome) &&
      capability_experiment_ref_valid(observation.reward_evidence) else {
      fail("capability experiment observation is invalid or conflicting")
    }
    seen.push(observation.observation_id)
    let assignment = assign_capability_experiment(
      plan,
      observation.participant_id,
    )
    guard assignment.assignment == observation.assignment &&
      assignment.capability == observation.capability else {
      fail("capability experiment observation does not match assignment")
    }
    if observation.assignment == "challenger" {
      challenger_count += 1
      if observation.accepted {
        challenger_accepted += 1
      }
    } else {
      baseline_count += 1
      if observation.accepted {
        baseline_accepted += 1
      }
    }
  }
  let baseline_rate = if baseline_count == 0 {
    0.0
  } else {
    baseline_accepted.to_double() / baseline_count.to_double()
  }
  let challenger_rate = if challenger_count == 0 {
    0.0
  } else {
    challenger_accepted.to_double() / challenger_count.to_double()
  }
  let evidence_complete = baseline_count >= plan.minimum_observations_per_arm &&
    challenger_count >= plan.minimum_observations_per_arm
  let rejection_rate = if challenger_count == 0 {
    0.0
  } else {
    1.0 - challenger_rate
  }
  let delta = challenger_rate - baseline_rate
  let recommendation = if evidence_complete &&
    rejection_rate > plan.maximum_challenger_rejection_rate {
    "rollback"
  } else if evidence_complete && delta >= plan.minimum_accepted_rate_delta {
    "promote"
  } else {
    "hold"
  }
  {
    contract_version: capability_experiment_contract_version(),
    experiment_id: plan.experiment_id,
    scope_id: plan.scope_id,
    baseline_observations: baseline_count,
    challenger_observations: challenger_count,
    baseline_accepted_rate: baseline_rate,
    challenger_accepted_rate: challenger_rate,
    accepted_rate_delta: delta,
    recommendation,
    evidence_complete,
    evaluated_at,
  }
}
