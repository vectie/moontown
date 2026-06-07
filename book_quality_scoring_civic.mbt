///|
async fn score_civic_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let draft = new_book_quality_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    civic_book_base_required_paths(),
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
    book_quality_civic_type(),
    draft,
    score,
    review_result_dir,
  )
}

///|
fn civic_book_base_required_paths() -> Array[BookQualityRequiredPath] {
  [
    book_quality_required_path("raw/bootstrap/CIVIC_SERVICE_CONTRACT.md", 12),
    book_quality_required_path(
      "raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md", 12,
    ),
    book_quality_required_path("skills/wenyu-civic-service/SKILL.md", 10),
    book_quality_required_path("moonclaw.jobs.json", 10),
    book_quality_required_path(book_quality_generated_site_path(), 6),
  ]
}

///|
async fn score_civic_service_definition(
  root : String,
  service : @civic.CivicServiceDefinition,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  let mut score = 0
  score += paths_score(root, service.schema_pages, 10, strengths, gaps)
  score += paths_score(root, service.wiki_pages, 10, strengths, gaps)
  score += paths_score(root, service.review_queues, 8, strengths, gaps)
  score += required_paths_score(
    root,
    civic_service_workspace_required_paths(service),
    strengths,
    gaps,
  )
  score += civic_service_latest_result_score(root, service, strengths, gaps)
  score
}

///|
fn civic_service_workspace_required_paths(
  service : @civic.CivicServiceDefinition,
) -> Array[BookQualityRequiredPath] {
  [
    book_quality_required_path("wiki/ledgers/service-ledger.md", 5),
    book_quality_required_path("wiki/ledgers/exchange-ledger.md", 5),
    book_quality_required_path("wiki/history/service-history.md", 5),
    book_quality_required_path(service.skill_path, 10),
  ]
}

///|
async fn civic_service_latest_result_score(
  root : String,
  service : @civic.CivicServiceDefinition,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  let result_path = civic_service_result_path(service, root~)
  if @fs.exists(result_path) {
    strengths.push("latest civic service result exists")
    10
  } else {
    gaps.push(
      "no latest civic service result; workspace is still mostly scaffold",
    )
    0
  }
}
