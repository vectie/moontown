///|
pub(all) struct BookQualityStructuralAssessment {
  score : Int
  grade : String
  ready_without_semantic : Bool
} derive(Eq, ToJson, FromJson)

///|
pub fn assess_structural_quality(
  raw_score : Int,
  gaps : Array[String],
) -> BookQualityStructuralAssessment {
  let score = if gaps.is_empty() {
    clamp_score(raw_score)
  } else {
    clamp_score(raw_score).min(89)
  }
  {
    score,
    grade: quality_grade(score),
    ready_without_semantic: score >= 80 && gaps.is_empty(),
  }
}

///|
pub(all) struct BookQualitySemanticAssessment {
  score : Int?
  grade : String
  status : String
  allows_ready : Bool
} derive(Eq, ToJson, FromJson)

///|
pub fn semantic_quality_assessment(
  score : Int?,
) -> BookQualitySemanticAssessment {
  {
    score,
    grade: match score {
      Some(value) => quality_grade(value)
      None => "pending-ai-review"
    },
    status: match score {
      Some(_) => "ai-reviewed"
      None => "pending-ai-review"
    },
    allows_ready: semantic_quality_allows_ready(score),
  }
}

///|
pub fn semantic_quality_allows_ready(score : Int?) -> Bool {
  match score {
    Some(value) => value >= semantic_ready_threshold()
    None => true
  }
}
