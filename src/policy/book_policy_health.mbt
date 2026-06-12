///|
pub struct PolicyHealth {
  structural_score : Int
  semantic_score : Int?
  missing_required_files : Array[String]
  execute_skill_count : Int
  tend_skill_count : Int
  ready : Bool
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn missing_required_files(
  policy : BookPolicy,
  present_required_files : Array[String],
) -> Array[String] {
  required_file_specs(policy).filter_map(file => {
    if file.required && !present_required_files.contains(file.path) {
      Some(file.path)
    } else {
      None
    }
  })
}

///|
fn semantic_score_ready(policy : BookPolicy, semantic_score : Int?) -> Bool {
  if !review_required(policy) {
    return true
  }
  match semantic_score {
    Some(score) => clamp_score(score) >= semantic_threshold(policy)
    None => true
  }
}

///|
fn policy_health_status(
  missing : Array[String],
  structural_ready : Bool,
  semantic_ready : Bool,
  execute_count : Int,
  tend_count : Int,
) -> String {
  if execute_count == 0 {
    "missing-execute-lane"
  } else if tend_count == 0 {
    "missing-tend-lane"
  } else if !missing.is_empty() {
    "missing-required-files"
  } else if !structural_ready {
    "below-structural-threshold"
  } else if !semantic_ready {
    "below-semantic-threshold"
  } else {
    "ready"
  }
}

///|
pub fn evaluate_health(
  policy : BookPolicy,
  structural_score : Int,
  semantic_score : Int?,
  present_required_files : Array[String],
) -> PolicyHealth {
  let structural_score = clamp_score(structural_score)
  let missing = missing_required_files(policy, present_required_files)
  let execute_count = execute_skills(policy).length()
  let tend_count = tend_skills(policy).length()
  let structural_ready = structural_score >= structural_threshold(policy)
  let semantic_ready = semantic_score_ready(policy, semantic_score)
  let ready = missing.is_empty() &&
    execute_count > 0 &&
    tend_count > 0 &&
    structural_ready &&
    semantic_ready
  {
    structural_score,
    semantic_score,
    missing_required_files: missing,
    execute_skill_count: execute_count,
    tend_skill_count: tend_count,
    ready,
    status: policy_health_status(
      missing, structural_ready, semantic_ready, execute_count, tend_count,
    ),
  }
}
