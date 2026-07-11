///|
pub(all) struct CommissionCriterion {
  criterion_id : String
  weight : Double
  minimum_score : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CommissionRating {
  criterion_id : String
  score : Double
  evidence_refs : Array[String]
  rationale : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CommissionCandidate {
  candidate_id : String
  summary : String
  source_book_ids : Array[String]
  artifact_refs : Array[String]
  ratings : Array[CommissionRating]
  proposal : Json
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TownCommission {
  contract_id : String
  commission_id : String
  question : String
  criteria : Array[CommissionCriterion]
  candidates : Array[CommissionCandidate]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CandidateEvaluation {
  candidate_id : String
  qualified : Bool
  weighted_score : Double
  evidence_count : Int
  reasons : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TownPromotion {
  contract_id : String
  commission_id : String
  accepted : Bool
  winner_id : String
  winning_score : Double
  evaluations : Array[CandidateEvaluation]
  source_book_ids : Array[String]
  artifact_refs : Array[String]
  proposal : Json
} derive(Debug, Eq, ToJson, FromJson)

///|
fn rating_for(
  candidate : CommissionCandidate,
  criterion_id : String,
) -> CommissionRating? {
  for rating in candidate.ratings {
    if rating.criterion_id == criterion_id {
      return Some(rating)
    }
  }
  None
}

///|
fn duplicate_id(ids : Array[String]) -> String? {
  for index in 0..<ids.length() {
    for other in (index + 1)..<ids.length() {
      if ids[index] == ids[other] {
        return Some(ids[index])
      }
    }
  }
  None
}

///|
fn evaluate_candidate(
  candidate : CommissionCandidate,
  criteria : Array[CommissionCriterion],
) -> CandidateEvaluation {
  let reasons : Array[String] = []
  let mut weighted_total = 0.0
  let mut weight_total = 0.0
  let mut evidence_count = candidate.artifact_refs.length()
  if candidate.summary.trim().is_empty() {
    reasons.push("candidate summary is empty")
  }
  if candidate.source_book_ids.is_empty() {
    reasons.push("candidate has no source MoonBook")
  }
  if candidate.artifact_refs.is_empty() {
    reasons.push("candidate has no proposal artifact")
  }
  match duplicate_id(candidate.ratings.map(rating => rating.criterion_id)) {
    Some(id) => reasons.push("duplicate rating for criterion " + id)
    None => ()
  }
  for criterion in criteria {
    match rating_for(candidate, criterion.criterion_id) {
      None =>
        reasons.push("missing rating for criterion " + criterion.criterion_id)
      Some(rating) => {
        evidence_count += rating.evidence_refs.length()
        if rating.score < 0.0 || rating.score > 10.0 {
          reasons.push(
            "criterion " + criterion.criterion_id + " score is outside 0..10",
          )
        }
        if rating.score < criterion.minimum_score {
          reasons.push(
            "criterion " + criterion.criterion_id + " is below its minimum",
          )
        }
        if rating.evidence_refs.is_empty() {
          reasons.push(
            "criterion " + criterion.criterion_id + " has no evidence",
          )
        }
        weighted_total += rating.score * criterion.weight
        weight_total += criterion.weight
      }
    }
  }
  {
    candidate_id: candidate.candidate_id,
    qualified: reasons.is_empty(),
    weighted_score: if weight_total == 0.0 {
      0.0
    } else {
      weighted_total / weight_total
    },
    evidence_count,
    reasons,
  }
}

///|
pub fn evaluate_commission(
  commission : TownCommission,
) -> Result[TownPromotion, String] {
  if commission.contract_id != "moonsuite.town-commission.v1" {
    return Err("unsupported Town commission contract")
  }
  if commission.commission_id.trim().is_empty() ||
    commission.question.trim().is_empty() {
    return Err("commission identity and question are required")
  }
  if commission.criteria.is_empty() {
    return Err("commission requires explicit criteria")
  }
  if commission.candidates.length() < 2 {
    return Err(
      "commission requires at least two independently proposed candidates",
    )
  }
  match
    duplicate_id(commission.criteria.map(criterion => criterion.criterion_id)) {
    Some(id) => return Err("duplicate commission criterion: " + id)
    None => ()
  }
  match
    duplicate_id(commission.candidates.map(candidate => candidate.candidate_id)) {
    Some(id) => return Err("duplicate commission candidate: " + id)
    None => ()
  }
  for criterion in commission.criteria {
    if criterion.criterion_id.trim().is_empty() || criterion.weight <= 0.0 {
      return Err("commission criteria require ids and positive weights")
    }
    if criterion.minimum_score < 0.0 || criterion.minimum_score > 10.0 {
      return Err("commission minimum scores must be within 0..10")
    }
  }
  let evaluations = commission.candidates.map(candidate => {
    evaluate_candidate(candidate, commission.criteria)
  })
  let mut winner_index = -1
  let mut winner_score = -1.0
  for index in 0..<evaluations.length() {
    let evaluation = evaluations[index]
    if evaluation.qualified && evaluation.weighted_score > winner_score {
      winner_index = index
      winner_score = evaluation.weighted_score
    }
  }
  if winner_index < 0 {
    return Ok({
      contract_id: "moonsuite.town-promotion.v1",
      commission_id: commission.commission_id,
      accepted: false,
      winner_id: "",
      winning_score: 0.0,
      evaluations,
      source_book_ids: [],
      artifact_refs: [],
      proposal: Json::null(),
    })
  }
  let winner = commission.candidates[winner_index]
  Ok({
    contract_id: "moonsuite.town-promotion.v1",
    commission_id: commission.commission_id,
    accepted: true,
    winner_id: winner.candidate_id,
    winning_score: winner_score,
    evaluations,
    source_book_ids: winner.source_book_ids,
    artifact_refs: winner.artifact_refs,
    proposal: winner.proposal,
  })
}
