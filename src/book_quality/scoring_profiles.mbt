///|
pub fn required_path(
  relative : String,
  points : Int,
) -> BookQualityRequiredPath {
  { relative, points }
}

///|
priv struct BookQualityRequiredPathProfile {
  book_type : String
  paths : Array[BookQualityRequiredPath]
}

///|
fn required_path_profile(
  book_type : String,
  paths : Array[BookQualityRequiredPath],
) -> BookQualityRequiredPathProfile {
  { book_type, paths }
}

///|
fn required_path_profiles() -> Array[BookQualityRequiredPathProfile] {
  [
    required_path_profile(@policy.research_type(), research_required_paths()),
    required_path_profile(@policy.course_type(), course_required_paths()),
    required_path_profile(@policy.planbook_type(), planbook_required_paths()),
    required_path_profile(@policy.cookbook_type(), cookbook_required_paths()),
    required_path_profile(@policy.civic_type(), civic_base_required_paths()),
    required_path_profile(
      @policy.operational_type(),
      operational_required_paths(),
    ),
  ]
}

///|
pub fn required_paths_for_book_type(
  book_type : String,
) -> Array[BookQualityRequiredPath] {
  for profile in required_path_profiles() {
    if profile.book_type == book_type {
      return profile.paths
    }
  }
  [
    required_path(wiki_index_path(), 20),
    required_path(projection_state_path(), 15),
  ]
}

///|
fn required_path_present(
  paths : Array[BookQualityRequiredPath],
  relative : String,
) -> Bool {
  paths.any(path => path.relative == relative)
}

///|
fn include_policy_required_paths(
  book_type : String,
  paths : Array[BookQualityRequiredPath],
  points : Int,
) -> Array[BookQualityRequiredPath] {
  let result : Array[BookQualityRequiredPath] = []
  for path in paths {
    result.push(path)
  }
  for file in @policy.required_file_specs(@policy.policy_for_type(book_type)) {
    if file.required && !required_path_present(result, file.path) {
      result.push(required_path(file.path, points))
    }
  }
  result
}

///|
pub fn path_set_assessment(
  relatives : Array[String],
  missing : Array[String],
  points : Int,
) -> BookQualityPathSetAssessment {
  if relatives.is_empty() {
    return { score: points, strength: None, gap: None }
  }
  if missing.is_empty() {
    {
      score: points,
      strength: Some("all \{relatives.length()} expected typed pages exist"),
      gap: None,
    }
  } else {
    {
      score: points *
      (relatives.length() - missing.length()) /
      relatives.length(),
      strength: None,
      gap: Some("missing typed pages: \{missing.join(", ")}"),
    }
  }
}

///|
pub fn path_presence_assessment(
  relative : String,
  points : Int,
  exists : Bool,
) -> BookQualityPathAssessment {
  if exists {
    { score: points, strength: Some("has `\{relative}`"), gap: None }
  } else {
    { score: 0, strength: None, gap: Some("missing `\{relative}`") }
  }
}

///|
pub fn base_workspace_assessment(
  workspace_exists : Bool,
  wiki_index_exists : Bool,
  projection_state_exists : Bool,
) -> BookQualityWorkspaceAssessment {
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  let mut score = 0
  if workspace_exists {
    score += 12
    strengths.push("workspace exists")
  } else {
    gaps.push("workspace directory is missing")
  }
  if wiki_index_exists {
    score += 8
    strengths.push("wiki index exists")
  } else {
    gaps.push("missing \{wiki_index_path()}")
  }
  if projection_state_exists {
    score += 8
    strengths.push("MoonBook projection state exists")
  } else {
    gaps.push("missing \{projection_state_path()}")
  }
  { score, strengths, gaps }
}

///|
pub fn research_deep_report_word_assessment(
  words : Int,
) -> BookQualitySignalAssessment {
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  let mut score = 0
  if words >= 12000 {
    score += 18
    strengths.push("deep report reaches 12k+ words")
  } else if words >= 8000 {
    score += 12
    gaps.push("deep report below world-class 12k word target")
  } else if words >= 2000 {
    score += 6
    gaps.push("deep report is useful but too short for deep research")
  } else {
    gaps.push("deep report is missing or shallow")
  }
  { score, strengths, gaps }
}

///|
pub fn course_identity_assessment(
  book_id : String,
  index_text : String,
) -> BookQualitySignalAssessment {
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  let mut score = 0
  let index = index_text.to_lower()
  if index.contains("## research report") ||
    @policy.catalog_entry_runs_research_evidence(book_id, "", []) {
    gaps.push("course still looks research-shaped in id or index")
  } else if index.contains("course book") ||
    index.contains(@policy.book_type_marker(@policy.course_type())) {
    score += 8
    strengths.push("course identity is explicit")
  }
  { score, strengths, gaps }
}

///|
pub fn civic_latest_result_assessment(
  exists : Bool,
) -> BookQualitySignalAssessment {
  if exists {
    { score: 10, strengths: ["latest civic service result exists"], gaps: [] }
  } else {
    {
      score: 0,
      strengths: [],
      gaps: [
        "no latest civic service result; workspace is still mostly scaffold",
      ],
    }
  }
}

///|
pub fn cookbook_audit_link_assessment(
  exists : Bool,
) -> BookQualitySignalAssessment {
  if exists {
    {
      score: 6,
      strengths: ["book quality audit is linked into stable-state governance"],
      gaps: [],
    }
  } else {
    {
      score: 0,
      strengths: [],
      gaps: ["book quality audit has not been written yet"],
    }
  }
}

///|
pub fn research_required_paths() -> Array[BookQualityRequiredPath] {
  include_policy_required_paths(
    @policy.research_type(),
    [
      required_path("raw/bootstrap/research-question.md", 6),
      required_path("raw/bootstrap/search-log.md", 8),
      required_path("raw/bootstrap/source-screen.md", 8),
      required_path("raw/bootstrap/evidence-matrix.md", 10),
      required_path("raw/bootstrap/deep-report.md", 12),
      required_path("raw/bootstrap/marketing-brief.md", 5),
      required_path(wiki_index_path(), 7),
      policy_type_output_required_path(@policy.research_type(), 6),
    ],
    5,
  )
}

///|
pub fn course_required_paths() -> Array[BookQualityRequiredPath] {
  include_policy_required_paths(
    @policy.course_type(),
    [
      required_path("raw/bootstrap/COURSE_CONTRACT.md", 12),
      required_path("raw/bootstrap/course-outline.md", 10),
      required_path("raw/bootstrap/source-material.md", 4),
      required_path("wiki/course/beginner-course.md", 16),
      required_path("wiki/course/exercises.md", 10),
      required_path("wiki/course/progress-rubric.md", 8),
      required_path("skills/course-builder/SKILL.md", 12),
      policy_type_output_required_path(@policy.course_type(), 6),
    ],
    5,
  )
}

///|
pub fn planbook_required_paths() -> Array[BookQualityRequiredPath] {
  include_policy_required_paths(
    @policy.planbook_type(),
    [
      required_path("raw/bootstrap/PLANBOOK_CONTRACT.md", 14),
      required_path("plans/2026-05-29-book-quality-upgrade/plan.md", 16),
      required_path("plans/index.md", 8),
      required_path("wiki/planning/quality-gates.md", 12),
      required_path("wiki/planning/execution-evidence.md", 10),
      required_path("wiki/reviews/active-plan-review.md", 10),
      required_path("wiki/history/decision-log.md", 8),
      required_path("schemas/plan-record.schema.md", 6),
      required_path("skills/code-plan/SKILL.md", 12),
      required_path("skills/code-review/SKILL.md", 10),
      required_path("skills/doc-sync/SKILL.md", 8),
      policy_type_output_required_path(@policy.planbook_type(), 6),
    ],
    5,
  )
}

///|
pub fn cookbook_required_paths() -> Array[BookQualityRequiredPath] {
  include_policy_required_paths(
    @policy.cookbook_type(),
    [
      required_path("raw/bootstrap/COOKBOOK_CONTRACT.md", 14),
      required_path("wiki/definitions/stable-state.md", 16),
      required_path("wiki/definitions/ownership.md", 12),
      required_path("wiki/definitions/book-types.md", 6),
      required_path("wiki/definitions/runtime-boundaries.md", 6),
      required_path("wiki/operating-procedures/doctor.md", 10),
      required_path("wiki/operating-procedures/book-governance.md", 6),
      required_path("wiki/history/stable-state-ledger.md", 6),
      required_path("schemas/stable-state-manifest.schema.md", 8),
      policy_type_output_required_path(@policy.cookbook_type(), 6),
    ],
    5,
  )
}

///|
pub fn operational_required_paths() -> Array[BookQualityRequiredPath] {
  include_policy_required_paths(
    @policy.operational_type(),
    [
      required_path("raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md", 18),
      required_path("wiki/operations/review-policy.md", 16),
      required_path("wiki/history/journey.md", 12),
      required_path("skills/operational-keeper/SKILL.md", 16),
      policy_type_output_required_path(@policy.operational_type(), 10),
    ],
    5,
  )
}

///|
pub fn civic_base_required_paths() -> Array[BookQualityRequiredPath] {
  include_policy_required_paths(
    @policy.civic_type(),
    [
      required_path("raw/bootstrap/CIVIC_SERVICE_CONTRACT.md", 12),
      required_path("raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md", 12),
      required_path("skills/wenyu-civic-service/SKILL.md", 10),
      required_path("moonclaw.jobs.json", 10),
      policy_type_output_required_path(@policy.civic_type(), 6),
    ],
    5,
  )
}
