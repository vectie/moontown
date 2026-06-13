///|
pub fn review_result_dir_for_snapshot(snapshot_path : String) -> String {
  "\{@storage.snapshot_base_dir(snapshot_path)}/book-quality/ai-review-results"
}

///|
pub async fn score_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let kind = score_book_type(entry)
  match kind {
    type_ if type_ == @policy.research_type() =>
      score_research_book(entry, review_result_dir)
    type_ if type_ == @policy.course_type() =>
      score_course_book(entry, review_result_dir)
    type_ if type_ == @policy.planbook_type() =>
      score_planbook(entry, review_result_dir)
    type_ if type_ == @policy.cookbook_type() =>
      score_cookbook(entry, review_result_dir)
    type_ if type_ == @policy.civic_type() =>
      score_civic_book(entry, review_result_dir)
    type_ if type_ == @policy.operational_type() =>
      score_operational_book(entry, review_result_dir)
    _ => score_general_book(entry, review_result_dir)
  }
}

///|
fn score_book_type(entry : @moonbook.BookCatalogEntry) -> String {
  @policy.catalog_entry_type(entry.id, entry.name, entry.tags)
}

///|
priv struct ScoreDraft {
  root : String
  strengths : Array[String]
  gaps : Array[String]
  base_score : Int
}

///|
async fn new_score_draft(entry : @moonbook.BookCatalogEntry) -> ScoreDraft {
  let root = @moonbook.workspace_root(entry)
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  {
    root,
    strengths,
    gaps,
    base_score: base_workspace_score(root, strengths, gaps),
  }
}

///|
async fn score_research_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let draft = new_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    research_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  let words = @support.count_english_word_tokens(
    @support.read_text_or_empty(
      workspace_path(draft.root, "raw/bootstrap/deep-report.md"),
    ),
  )
  score += apply_score_signal(
    research_deep_report_word_assessment(words),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    @policy.research_type(),
    draft,
    score,
    review_result_dir,
  )
}

///|
async fn score_course_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let draft = new_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    course_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  let index = @support.read_text_or_empty(
    workspace_path(draft.root, wiki_index_path()),
  )
  score += apply_score_signal(
    course_identity_assessment(entry.id, index),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    @policy.course_type(),
    draft,
    score,
    review_result_dir,
  )
}

///|
async fn score_planbook(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let draft = new_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    planbook_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    @policy.planbook_type(),
    draft,
    score,
    review_result_dir,
  )
}

///|
async fn score_cookbook(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let draft = new_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    cookbook_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  score += apply_score_signal(
    cookbook_audit_link_assessment(
      @fs.exists(".moontown/book-quality/audit.json"),
    ),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    @policy.cookbook_type(),
    draft,
    score,
    review_result_dir,
  )
}

///|
async fn score_operational_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let draft = new_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    operational_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    @policy.operational_type(),
    draft,
    score,
    review_result_dir,
  )
}

///|
async fn score_civic_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let draft = new_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    civic_base_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) =>
      score += score_civic_service_definition(
        draft.root,
        service,
        draft.strengths,
        draft.gaps,
      )
    None => draft.gaps.push("no civic service definition matched this book")
  }
  finalize_score_draft(
    entry,
    @policy.civic_type(),
    draft,
    score,
    review_result_dir,
  )
}

///|
async fn score_general_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let draft = new_score_draft(entry)
  let score = draft.base_score +
    path_score(draft.root, wiki_index_path(), 20, draft.strengths, draft.gaps) +
    path_score(
      draft.root,
      projection_state_path(),
      15,
      draft.strengths,
      draft.gaps,
    )
  finalize_score_draft(
    entry,
    @policy.general_type(),
    draft,
    score,
    review_result_dir,
  )
}

///|
async fn finalize_score_draft(
  entry : @moonbook.BookCatalogEntry,
  book_type : String,
  draft : ScoreDraft,
  raw_score : Int,
  review_result_dir : String,
) -> BookQualityScore {
  finalize_score(
    entry,
    book_type,
    draft.root,
    raw_score,
    draft.strengths,
    draft.gaps,
    review_result_dir,
  )
}

///|
async fn finalize_score(
  entry : @moonbook.BookCatalogEntry,
  book_type : String,
  root : String,
  raw_score : Int,
  strengths : Array[String],
  gaps : Array[String],
  review_result_dir : String,
) -> BookQualityScore {
  let policy = @policy.policy_for_type(book_type)
  let present_required_files = policy_present_required_files(
    root, policy, strengths, gaps,
  )
  let structural = assess_structural_quality(raw_score, gaps)
  let semantic_result_text = read_review_result_text(
    review_result_dir,
    entry.id,
  )
  let semantic_score = parse_ai_quality_score(semantic_result_text)
  let semantic = semantic_quality_assessment(semantic_score)
  let policy_health = @policy.evaluate_health(
    policy,
    structural.score,
    semantic.score,
    present_required_files,
  )
  {
    book_id: entry.id,
    title: entry.name,
    book_type,
    workspace_root: root,
    structural_score: structural.score,
    structural_grade: structural.grade,
    semantic_score: semantic.score,
    semantic_grade: semantic.grade,
    quality_status: semantic.status,
    score: structural.score,
    grade: structural.grade,
    ready: structural.ready_without_semantic &&
    policy_health.ready &&
    semantic.allows_ready,
    strengths,
    gaps,
    next_action: next_action(
      book_type,
      gaps,
      structural.score,
      semantic.score,
      semantic_repair_task=semantic_repair_task_from_review_text(
        semantic_result_text,
      ),
    ),
  }
}

///|
async fn policy_present_required_files(
  root : String,
  policy : @policy.BookPolicy,
  strengths : Array[String],
  gaps : Array[String],
) -> Array[String] {
  let present : Array[String] = []
  for file in @policy.required_file_specs(policy) {
    if !file.required {
      continue
    }
    if @fs.exists(workspace_path(root, file.path)) {
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
async fn base_workspace_score(
  root : String,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  let assessment = base_workspace_assessment(
    @fs.exists(root),
    @fs.exists(workspace_path(root, wiki_index_path())),
    @fs.exists(workspace_path(root, projection_state_path())),
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
async fn path_score(
  root : String,
  relative : String,
  points : Int,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  let assessment = path_presence_assessment(
    relative,
    points,
    @fs.exists(workspace_path(root, relative)),
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
async fn required_paths_score(
  root : String,
  paths : Array[BookQualityRequiredPath],
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  let mut score = 0
  for path in paths {
    score += path_score(root, path.relative, path.points, strengths, gaps)
  }
  score
}

///|
async fn paths_score(
  root : String,
  relatives : Array[String],
  points : Int,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  if relatives.is_empty() {
    return path_set_assessment(relatives, [], points).score
  }
  let missing = @support.workspace_missing_relative_paths(root, relatives)
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
