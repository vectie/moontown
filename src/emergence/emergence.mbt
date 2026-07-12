///|
pub(all) struct CivicContribution {
  contribution_id : String
  participant_id : String
  source_book_id : String
  origin : String
  summary : String
  evidence_refs : Array[String]
  alternatives : Array[String]
  blockers : Array[String]
  implementation_criteria : Array[String]
  claim_ceiling : String
  supports : Array[String]
  proposal : Json
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CivicCritique {
  critique_id : String
  participant_id : String
  target_contribution_id : String
  concern : String
  evidence_refs : Array[String]
  severity : String
  resolved : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CivicRanking {
  voter_id : String
  ordered_contribution_ids : Array[String]
  rationale : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CivicReview {
  reviewer_id : String
  decision : String
  evidence_refs : Array[String]
  note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CivicDeliveryReceipt {
  participant_id : String
  received : Bool
  returned_home : Bool
  receipt_ref : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CivicComparisonCriterion {
  criterion_id : String
  name : String
  definition : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AutonomousCivicRound {
  contract_id : String
  round_id : String
  commission_id : String
  question : String
  commissioned_agenda_ids : Array[String]
  comparison_criteria : Array[CivicComparisonCriterion]
  contributions : Array[CivicContribution]
  critiques : Array[CivicCritique]
  rankings : Array[CivicRanking]
  review : CivicReview
  deliveries : Array[CivicDeliveryReceipt]
  requested_authority : String
  recorded_at : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CoalitionEdge {
  from_id : String
  to_contribution_id : String
  relation : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ContributionEvaluation {
  contribution_id : String
  qualified : Bool
  ranking_score : Int
  reasons : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AutonomousCivicRoundResult {
  contract_id : String
  round_id : String
  commission_id : String
  accepted : Bool
  autonomous_round_qualified : Bool
  comparison_criteria : Array[CivicComparisonCriterion]
  winner_id : String
  unseeded_idea_ids : Array[String]
  dissent_ids : Array[String]
  minority_ids : Array[String]
  evaluations : Array[ContributionEvaluation]
  coalition_graph : Array[CoalitionEdge]
  stage_receipts : Array[String]
  review : CivicReview
  deliveries : Array[CivicDeliveryReceipt]
  requested_authority : String
  proposal : Json
  recorded_at : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn safe_claim_ceiling(value : String) -> Bool {
  ["observation", "research-evidence", "execution-result", "accepted-knowledge"].contains(
    value,
  )
}

///|
fn allowed_mayor_authority(value : String) -> Bool {
  ["observe", "cognitive-maintenance", "workspace-mutation"].contains(value)
}

///|
fn contribution_by_id(
  contributions : Array[CivicContribution],
  id : String,
) -> CivicContribution? {
  for contribution in contributions {
    if contribution.contribution_id == id {
      return Some(contribution)
    }
  }
  None
}

///|
fn ranking_score(round : AutonomousCivicRound, id : String) -> Int {
  let mut score = 0
  for ranking in round.rankings {
    let points = ranking.ordered_contribution_ids.length()
    for index in 0..<ranking.ordered_contribution_ids.length() {
      if ranking.ordered_contribution_ids[index] == id {
        score += points - index
      }
    }
  }
  score
}

///|
fn evaluate_contribution(
  round : AutonomousCivicRound,
  contribution : CivicContribution,
) -> ContributionEvaluation {
  let reasons : Array[String] = []
  if contribution.summary.trim().is_empty() {
    reasons.push("summary is required")
  }
  if contribution.source_book_id.trim().is_empty() {
    reasons.push("source MoonBook is required")
  }
  if !["commissioned", "emergent", "dissenting", "minority", "synthesized"].contains(
      contribution.origin,
    ) {
    reasons.push("unsupported contribution origin")
  }
  if contribution.evidence_refs.is_empty() {
    reasons.push("evidence is required")
  }
  if contribution.alternatives.is_empty() {
    reasons.push("alternatives are required")
  }
  if contribution.implementation_criteria.is_empty() {
    reasons.push("implementation criteria are required")
  }
  if !safe_claim_ceiling(contribution.claim_ceiling) {
    reasons.push("claim ceiling exceeds MoonTown knowledge authority")
  }
  for critique in round.critiques {
    if critique.target_contribution_id == contribution.contribution_id &&
      critique.severity == "blocking" &&
      !critique.resolved {
      reasons.push("unresolved blocking critique: \{critique.critique_id}")
    }
  }
  {
    contribution_id: contribution.contribution_id,
    qualified: reasons.is_empty(),
    ranking_score: ranking_score(round, contribution.contribution_id),
    reasons,
  }
}

///|
pub fn evaluate_autonomous_civic_round(
  round : AutonomousCivicRound,
) -> Result[AutonomousCivicRoundResult, String] {
  if round.contract_id != "moontown.autonomous-civic-round.v1" {
    return Err("unsupported autonomous civic round contract")
  }
  if round.round_id.trim().is_empty() ||
    round.commission_id.trim().is_empty() ||
    round.question.trim().is_empty() {
    return Err("round, commission, and question identities are required")
  }
  if !allowed_mayor_authority(round.requested_authority) {
    return Err("Mayor cannot schedule external or physical authority")
  }
  if round.contributions.length() < 2 ||
    round.critiques.is_empty() ||
    round.rankings.is_empty() {
    return Err("round requires contributions, critique, and ranking stages")
  }
  if round.comparison_criteria.is_empty() ||
    round.comparison_criteria.any(criterion => {
      criterion.criterion_id.trim().is_empty() ||
      criterion.name.trim().is_empty() ||
      criterion.definition.trim().is_empty()
    }) {
    return Err("round requires explicit comparison criteria")
  }
  if round.review.decision != "accepted" && round.review.decision != "rejected" {
    return Err("round review decision must be accepted or rejected")
  }
  if round.review.evidence_refs.is_empty() {
    return Err("round review requires evidence")
  }
  let contribution_ids = round.contributions.map(item => item.contribution_id)
  for ranking in round.rankings {
    if ranking.ordered_contribution_ids.is_empty() ||
      ranking.rationale.trim().is_empty() {
      return Err("rankings require candidates and rationale")
    }
    for id in ranking.ordered_contribution_ids {
      if !contribution_ids.contains(id) {
        return Err("ranking references unknown contribution: \{id}")
      }
    }
  }
  let participants = round.contributions.map(item => item.participant_id)
  for participant in participants {
    if !round.deliveries.any(receipt => {
        receipt.participant_id == participant &&
        receipt.received &&
        receipt.returned_home &&
        !receipt.receipt_ref.trim().is_empty()
      }) {
      return Err(
        "distribution and home return are incomplete for \{participant}",
      )
    }
  }
  let evaluations = round.contributions.map(contribution => {
    evaluate_contribution(round, contribution)
  })
  let unseeded = round.contributions.filter_map(contribution => {
    if contribution.origin == "emergent" &&
      !round.commissioned_agenda_ids.contains(contribution.contribution_id) &&
      !contribution.evidence_refs.is_empty() &&
      !contribution.implementation_criteria.is_empty() {
      Some(contribution.contribution_id)
    } else {
      None
    }
  })
  let dissent_ids = round.contributions.filter_map(contribution => {
    if contribution.origin == "dissenting" {
      Some(contribution.contribution_id)
    } else {
      None
    }
  })
  let minority_ids = round.contributions.filter_map(contribution => {
    if contribution.origin == "minority" {
      Some(contribution.contribution_id)
    } else {
      None
    }
  })
  let coalition : Array[CoalitionEdge] = []
  for contribution in round.contributions {
    for supported in contribution.supports {
      if contribution_ids.contains(supported) {
        coalition.push({
          from_id: contribution.contribution_id,
          to_contribution_id: supported,
          relation: "supports",
        })
      }
    }
  }
  for ranking in round.rankings {
    if !ranking.ordered_contribution_ids.is_empty() {
      coalition.push({
        from_id: ranking.voter_id,
        to_contribution_id: ranking.ordered_contribution_ids[0],
        relation: "ranked-first",
      })
    }
  }
  let mut winner_id = ""
  let mut winner_score = -1
  for evaluation in evaluations {
    if evaluation.qualified && evaluation.ranking_score > winner_score {
      winner_id = evaluation.contribution_id
      winner_score = evaluation.ranking_score
    }
  }
  let autonomous_qualified = !unseeded.is_empty() &&
    !dissent_ids.is_empty() &&
    round.review.decision == "accepted"
  let accepted = !winner_id.is_empty() && autonomous_qualified
  let proposal = if accepted {
    match contribution_by_id(round.contributions, winner_id) {
      Some(winner) => winner.proposal
      None => Json::null()
    }
  } else {
    Json::null()
  }
  Ok({
    contract_id: "moontown.autonomous-civic-round-result.v1",
    round_id: round.round_id,
    commission_id: round.commission_id,
    accepted,
    autonomous_round_qualified: autonomous_qualified,
    comparison_criteria: round.comparison_criteria,
    winner_id: if accepted {
      winner_id
    } else {
      ""
    },
    unseeded_idea_ids: unseeded,
    dissent_ids,
    minority_ids,
    evaluations,
    coalition_graph: coalition,
    stage_receipts: [
      "commission", "contribution", "critique", "synthesis", "dissent", "ranking",
      "review", "distribution", "home-return",
    ],
    review: round.review,
    deliveries: round.deliveries,
    requested_authority: round.requested_authority,
    proposal,
    recorded_at: round.recorded_at,
  })
}
