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
    required_path("wiki/ledgers/service-ledger.md", 5),
    required_path("wiki/ledgers/exchange-ledger.md", 5),
    required_path("wiki/history/service-history.md", 5),
    required_path(service.skill_path, 10),
  ]
}

///|
async fn civic_service_latest_result_score(
  root : String,
  service : @civic.CivicServiceDefinition,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  let result_path = @civic.civic_service_result_path(service, root~)
  apply_score_signal(
    civic_latest_result_assessment(@fs.exists(result_path)),
    strengths,
    gaps,
  )
}
