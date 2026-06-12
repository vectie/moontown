///|
pub struct SkillSpec {
  id : String
  lane : String
  cadence : String
  purpose : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct FileSpec {
  path : String
  required : Bool
  purpose : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct QualityCriteria {
  threshold : Int
  semantic_threshold : Int
  review_required : Bool
  description : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct OutputSpec {
  surface : String
  contract : String
  projection_path : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookPolicy {
  skills : Array[SkillSpec]
  required_files : Array[FileSpec]
  quality_criteria : QualityCriteria
  output : OutputSpec
} derive(Debug, Eq, ToJson, FromJson)

///|
fn clamp_score(score : Int) -> Int {
  if score < 0 {
    0
  } else if score > 100 {
    100
  } else {
    score
  }
}

///|
pub fn skill(
  id : String,
  lane : String,
  cadence : String,
  purpose : String,
) -> SkillSpec {
  { id, lane, cadence, purpose }
}

///|
pub fn file(path : String, required : Bool, purpose : String) -> FileSpec {
  { path, required, purpose }
}

///|
pub fn quality(
  threshold : Int,
  semantic_threshold : Int,
  review_required : Bool,
  description : String,
) -> QualityCriteria {
  {
    threshold: clamp_score(threshold),
    semantic_threshold: clamp_score(semantic_threshold),
    review_required,
    description,
  }
}

///|
pub fn output(
  surface : String,
  contract : String,
  projection_path : String,
) -> OutputSpec {
  { surface, contract, projection_path }
}

///|
pub fn new(
  skills : Array[SkillSpec],
  required_files : Array[FileSpec],
  quality_criteria : QualityCriteria,
  output : OutputSpec,
) -> BookPolicy {
  { skills, required_files, quality_criteria, output }
}

///|
fn upsert_skill(
  skills : Array[SkillSpec],
  next : SkillSpec,
) -> Array[SkillSpec] {
  let result : Array[SkillSpec] = []
  let mut inserted = false
  for existing in skills {
    if existing.id == next.id {
      if !inserted {
        result.push(next)
        inserted = true
      }
    } else {
      result.push(existing)
    }
  }
  if !inserted {
    result.push(next)
  }
  result
}

///|
fn upsert_file(files : Array[FileSpec], next : FileSpec) -> Array[FileSpec] {
  let result : Array[FileSpec] = []
  let mut inserted = false
  for existing in files {
    if existing.path == next.path {
      if !inserted {
        result.push(next)
        inserted = true
      }
    } else {
      result.push(existing)
    }
  }
  if !inserted {
    result.push(next)
  }
  result
}

///|
pub fn with_skill(policy : BookPolicy, next : SkillSpec) -> BookPolicy {
  { ..policy, skills: upsert_skill(policy.skills, next) }
}

///|
pub fn with_file(policy : BookPolicy, next : FileSpec) -> BookPolicy {
  { ..policy, required_files: upsert_file(policy.required_files, next) }
}

///|
pub fn with_quality(
  policy : BookPolicy,
  quality_criteria : QualityCriteria,
) -> BookPolicy {
  { ..policy, quality_criteria, }
}

///|
pub fn with_output(policy : BookPolicy, output : OutputSpec) -> BookPolicy {
  { ..policy, output, }
}

///|
fn lane_skills(policy : BookPolicy, lane : BookLane) -> Array[SkillSpec] {
  policy.skills.filter(skill => skill_in_lane(skill, lane))
}

///|
pub fn execute_skills(policy : BookPolicy) -> Array[SkillSpec] {
  lane_skills(policy, Execute)
}

///|
pub fn tend_skills(policy : BookPolicy) -> Array[SkillSpec] {
  lane_skills(policy, Tend)
}

///|
pub fn has_skill(policy : BookPolicy, id : String) -> Bool {
  policy.skills.any(skill => skill.id == id)
}

///|
pub fn required_file_paths(policy : BookPolicy) -> Array[String] {
  policy.required_files.filter_map(file => {
    if file.required {
      Some(file.path)
    } else {
      None
    }
  })
}

///|
pub fn required_file_specs(policy : BookPolicy) -> Array[FileSpec] {
  policy.required_files.copy()
}

///|
pub fn skill_specs(policy : BookPolicy) -> Array[SkillSpec] {
  policy.skills.copy()
}

///|
pub fn output_surface(policy : BookPolicy) -> String {
  policy.output.surface
}

///|
pub fn output_contract(policy : BookPolicy) -> String {
  policy.output.contract
}

///|
pub fn output_projection_path(policy : BookPolicy) -> String {
  policy.output.projection_path
}

///|
fn structural_threshold(policy : BookPolicy) -> Int {
  policy.quality_criteria.threshold
}

///|
fn semantic_threshold(policy : BookPolicy) -> Int {
  policy.quality_criteria.semantic_threshold
}

///|
fn review_required(policy : BookPolicy) -> Bool {
  policy.quality_criteria.review_required
}

///|
fn quality_description(policy : BookPolicy) -> String {
  policy.quality_criteria.description
}

///|
fn skill_rows(policy : BookPolicy) -> Array[String] {
  policy.skills.map(skill => {
    "- `\{skill.id}` lane=`\{skill.lane}` cadence=`\{skill.cadence}`: \{skill.purpose}"
  })
}

///|
fn file_rows(policy : BookPolicy) -> Array[String] {
  policy.required_files.map(file => {
    let required = if file.required { "required" } else { "optional" }
    "- `\{file.path}` (\{required}): \{file.purpose}"
  })
}

///|
pub fn markdown(policy : BookPolicy) -> String {
  [
    "BookPolicy:",
    "",
    "Skills:",
    skill_rows(policy).join("\n"),
    "",
    "Required files:",
    file_rows(policy).join("\n"),
    "",
    "Quality:",
    "- structural threshold: `\{structural_threshold(policy)}`",
    "- semantic threshold: `\{semantic_threshold(policy)}`",
    "- review required: `\{review_required(policy)}`",
    "- criteria: \{quality_description(policy)}",
    "",
    "Output:",
    "- surface: `\{output_surface(policy)}`",
    "- contract: `\{output_contract(policy)}`",
    "- projection path: `\{output_projection_path(policy)}`",
    "",
    loop_markdown(policy),
    "",
    internal_distance_markdown(policy),
  ].join("\n")
}
