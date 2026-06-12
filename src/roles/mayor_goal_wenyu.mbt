///|
fn wenyu_valley_goal_lanes(goal : String) -> Array[MayorGoalLane] {
  @civic.wenyu_civic_services().map(fn(service) {
    let entry = @civic.wenyu_civic_book_entry(service)
    {
      entry,
      objective: wenyu_valley_lane_objective_for_service(goal, service),
      rationale: wenyu_valley_lane_rationale(service),
    }
  })
}

///|
fn wenyu_valley_lane_objective_for_service(
  goal : String,
  service : @civic.CivicServiceDefinition,
) -> String {
  [
    wenyu_valley_lane_ownership_clause(service),
    wenyu_valley_lane_source_clause(),
    wenyu_valley_lane_deliverables_clause(),
    wenyu_valley_lane_contract_clause(service),
    wenyu_valley_lane_boundary_clause(),
    "Global town goal: \{goal}",
  ].join(" ")
}

///|
fn wenyu_valley_lane_rationale(
  service : @civic.CivicServiceDefinition,
) -> String {
  [
    "Wenyu Valley civic service lane for \{service.title};",
    "isolated MoonBook owns this module's schemas, wiki pages, review queues, service projections, and role-specific MoonClaw skill contracts.",
  ].join(" ")
}

///|
fn wenyu_valley_lane_ownership_clause(
  service : @civic.CivicServiceDefinition,
) -> String {
  "Own only the Wenyu Valley `\{service.title}` civic service lane."
}

///|
fn wenyu_valley_lane_source_clause() -> String {
  "Use `../../../docs/WENYU_VALLEY_PRD.md` as the primary product contract from this book workspace, then gather supporting evidence before service planning."
}

///|
fn wenyu_valley_lane_deliverables_clause() -> String {
  "Produce durable wiki/source/entity/concept/synthesis coverage, module schemas, review queues, a generated projection, and MoonClaw-ready service skill/output contracts."
}

///|
fn wenyu_valley_lane_contract_clause(
  service : @civic.CivicServiceDefinition,
) -> String {
  "Service kind: `\{service.service_kind}`. Output contract: `\{service.output_contract}`."
}

///|
fn wenyu_valley_lane_boundary_clause() -> String {
  "Do not solve other Wenyu modules except by referencing their durable outputs."
}
