///|
fn score_civic_service_definition(
  structural : BookQualityStructuralObservation,
  service : @civic.CivicServiceDefinition,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  let mut score = 0
  score += paths_score(structural, service.schema_pages, 10, strengths, gaps)
  score += paths_score(structural, service.wiki_pages, 10, strengths, gaps)
  score += paths_score(structural, service.review_queues, 8, strengths, gaps)
  score += required_paths_score(
    structural,
    civic_service_workspace_required_paths(service),
    strengths,
    gaps,
  )
  score += civic_service_latest_result_score(structural, strengths, gaps)
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
fn civic_service_latest_result_score(
  structural : BookQualityStructuralObservation,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  apply_score_signal(
    civic_latest_result_assessment(structural.civic_latest_result_exists),
    strengths,
    gaps,
  )
}
