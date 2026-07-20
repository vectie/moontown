///|
fn experiment_ref(
  id : String,
  version : String,
) -> CapabilityExperimentRecordRef {
  {
    record_id: id,
    record_version: version,
    record_digest: "sha256:\{id}:\{version}",
  }
}

///|
fn experiment_observation(
  id : String,
  participant_id : String,
  assignment : String,
  capability : CapabilityExperimentRecordRef,
  accepted : Bool,
) -> CapabilityExperimentObservation {
  {
    observation_id: id,
    experiment_id: "experiment-1",
    scope_id: "wiki-maintainer",
    participant_id,
    assignment,
    capability,
    outcome: experiment_ref("outcome-\{id}", "1"),
    reward_evidence: experiment_ref("reward-\{id}", "1"),
    accepted,
    recorded_at: 10L,
  }
}

///|
test "capability experiment recommends promotion only after both arms complete" {
  let baseline = experiment_ref("capability", "4")
  let challenger = experiment_ref("capability", "5")
  let plan : CapabilityExperimentPlan = {
    contract_version: capability_experiment_contract_version(),
    experiment_id: "experiment-1",
    scope_id: "wiki-maintainer",
    baseline_capability: baseline,
    challenger_capability: challenger,
    baseline_participant_ids: ["baseline-a", "baseline-b"],
    challenger_participant_ids: ["challenger-a", "challenger-b"],
    minimum_observations_per_arm: 2,
    minimum_accepted_rate_delta: 0.4,
    maximum_challenger_rejection_rate: 0.25,
  }
  let incomplete = evaluate_capability_experiment(
    plan,
    [
      experiment_observation(
        "1", "challenger-a", "challenger", challenger, true,
      ),
    ],
    evaluated_at=20L,
  )
  assert_eq(incomplete.recommendation, "hold")
  assert_false(incomplete.evidence_complete)
  let outcome = evaluate_capability_experiment(
    plan,
    [
      experiment_observation("1", "baseline-a", "baseline", baseline, false),
      experiment_observation("2", "baseline-b", "baseline", baseline, true),
      experiment_observation(
        "3", "challenger-a", "challenger", challenger, true,
      ),
      experiment_observation(
        "4", "challenger-b", "challenger", challenger, true,
      ),
    ],
    evaluated_at=20L,
  )
  assert_true(outcome.evidence_complete)
  assert_eq(outcome.baseline_accepted_rate, 0.5)
  assert_eq(outcome.challenger_accepted_rate, 1.0)
  assert_eq(outcome.recommendation, "promote")
}
