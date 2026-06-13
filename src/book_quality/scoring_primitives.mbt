///|
priv struct ScoreDraft {
  root : String
  strengths : Array[String]
  gaps : Array[String]
  base_score : Int
}

///|
fn new_score_draft(
  entry : @moonbook.BookCatalogEntry,
  structural : BookQualityStructuralObservation,
) -> ScoreDraft {
  let root = @moonbook.workspace_root(entry)
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  {
    root,
    strengths,
    gaps,
    base_score: base_workspace_score(structural, strengths, gaps),
  }
}

///|
fn finalize_score_draft(
  entry : @moonbook.BookCatalogEntry,
  book_type : String,
  draft : ScoreDraft,
  structural : BookQualityStructuralObservation,
  raw_score : Int,
  semantic_review_text : String,
) -> BookQualityScore {
  finalize_score(
    entry,
    book_type,
    draft.root,
    structural,
    raw_score,
    draft.strengths,
    draft.gaps,
    semantic_review_text,
  )
}

///|
fn finalize_score(
  entry : @moonbook.BookCatalogEntry,
  book_type : String,
  root : String,
  structural : BookQualityStructuralObservation,
  raw_score : Int,
  strengths : Array[String],
  gaps : Array[String],
  semantic_review_text : String,
) -> BookQualityScore {
  let policy = @policy.policy_for_type(book_type)
  let present_required_files = policy_present_required_files(
    policy, structural, strengths, gaps,
  )
  let structural_assessment = assess_structural_quality(raw_score, gaps)
  let semantic_score = parse_ai_quality_score(semantic_review_text)
  let semantic = semantic_quality_assessment(semantic_score)
  let policy_health = @policy.evaluate_health(
    policy,
    structural_assessment.score,
    semantic.score,
    present_required_files,
  )
  {
    book_id: entry.id,
    title: entry.name,
    book_type,
    workspace_root: root,
    structural_score: structural_assessment.score,
    structural_grade: structural_assessment.grade,
    semantic_score: semantic.score,
    semantic_grade: semantic.grade,
    quality_status: semantic.status,
    score: structural_assessment.score,
    grade: structural_assessment.grade,
    ready: structural_assessment.ready_without_semantic &&
    policy_health.ready &&
    semantic.allows_ready,
    strengths,
    gaps,
    next_action: next_action(
      book_type,
      gaps,
      structural_assessment.score,
      semantic.score,
      semantic_repair_task=semantic_repair_task_from_review_text(
        semantic_review_text,
      ),
    ),
  }
}

///|
fn policy_present_required_files(
  policy : @policy.BookPolicy,
  structural : BookQualityStructuralObservation,
  strengths : Array[String],
  gaps : Array[String],
) -> Array[String] {
  let present : Array[String] = []
  for file in @policy.required_file_specs(policy) {
    if !file.required {
      continue
    }
    if structural_path_exists(structural, file.path) {
      present.push(file.path)
      push_unique_note(strengths, "policy required file exists `\{file.path}`")
    } else {
      push_unique_note(gaps, "policy missing required file `\{file.path}`")
    }
  }
  present
}

///|
fn apply_score_signal(
  assessment : BookQualitySignalAssessment,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  for strength in assessment.strengths {
    strengths.push(strength)
  }
  for gap in assessment.gaps {
    gaps.push(gap)
  }
  assessment.score
}

///|
fn base_workspace_score(
  structural : BookQualityStructuralObservation,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  let assessment = base_workspace_assessment(
    structural.workspace_exists,
    structural.wiki_index_exists,
    structural.projection_state_exists,
  )
  for strength in assessment.strengths {
    strengths.push(strength)
  }
  for gap in assessment.gaps {
    gaps.push(gap)
  }
  assessment.score
}

///|
fn path_score(
  structural : BookQualityStructuralObservation,
  relative : String,
  points : Int,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  let assessment = path_presence_assessment(
    relative,
    points,
    structural_path_exists(structural, relative),
  )
  match assessment.strength {
    Some(note) => strengths.push(note)
    None => ()
  }
  match assessment.gap {
    Some(note) => gaps.push(note)
    None => ()
  }
  assessment.score
}

///|
fn required_paths_score(
  structural : BookQualityStructuralObservation,
  paths : Array[BookQualityRequiredPath],
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  let mut score = 0
  for path in paths {
    score += path_score(structural, path.relative, path.points, strengths, gaps)
  }
  score
}

///|
fn paths_score(
  structural : BookQualityStructuralObservation,
  relatives : Array[String],
  points : Int,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  if relatives.is_empty() {
    return path_set_assessment(relatives, [], points).score
  }
  let missing = relatives.filter(fn(relative) {
    !structural_path_exists(structural, relative)
  })
  let assessment = path_set_assessment(relatives, missing, points)
  match assessment.strength {
    Some(note) => strengths.push(note)
    None => ()
  }
  match assessment.gap {
    Some(note) => gaps.push(note)
    None => ()
  }
  assessment.score
}

///|
fn structural_path_exists(
  structural : BookQualityStructuralObservation,
  relative : String,
) -> Bool {
  structural.existing_relative_paths.contains(relative)
}
