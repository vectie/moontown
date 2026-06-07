///|
priv struct BookQualityStructuralAssessment {
  score : Int
  grade : String
  ready_without_semantic : Bool
}

///|
fn assess_structural_quality(
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
priv struct BookQualitySemanticAssessment {
  score : Int?
  grade : String
  status : String
  allows_ready : Bool
}

///|
fn semantic_quality_assessment(score : Int?) -> BookQualitySemanticAssessment {
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
fn semantic_quality_allows_ready(score : Int?) -> Bool {
  match score {
    Some(value) => value >= 80
    None => true
  }
}
