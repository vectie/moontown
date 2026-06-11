///|
pub fn workspace_index_text(
  entry : @moonbook.BookCatalogEntry,
  service : CivicServiceDefinition,
) -> String {
  [
    "# \{service.title}",
    "",
    "This workspace supports the Wenyu Valley `\{service.title}` civic module. The building itself is the protocol place; this MoonBook is only the `\{service.persistence_mode}` durable support surface for a `\{service.module_mode}` building.",
    "",
    "## Ownership",
    "",
    "- Moontown owns routing, daemon supervision, UI projection, and cross-module resource policy.",
    "- MoonBook owns only the accepted records, schemas, review queues, memory, and generated projections that the building protocol sends here.",
    "- MoonClaw owns bounded execution through the service skill pack `\{service.skill_pack}`.",
    "",
    "## Service",
    "",
    "- Book: `\{entry.id}`",
    "- Kind: `\{service.service_kind}`",
    "- Module mode: `\{service.module_mode}`",
    "- Persistence mode: `\{service.persistence_mode}`",
    "- MoonBook role: `\{service.book_role}`",
    "- Skill mode: `\{service.skill_mode}`",
    "- Output contract: `\{service.output_contract}`",
    "",
    "## Start Here",
    "",
    "- `raw/bootstrap/CIVIC_SERVICE_CONTRACT.md`",
    "- `raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md`",
    "- `\{service.skill_path}`",
    "- `book/moonbook-ui-state.json`",
  ].join("\n")
}

///|
pub fn service_contract_text(
  entry : @moonbook.BookCatalogEntry,
  service : CivicServiceDefinition,
  objective : String,
) -> String {
  [
    "# \{service.title} Civic Service Contract",
    "",
    "## Objective",
    "",
    objective,
    "",
    "## Book",
    "",
    "- Book id: `\{entry.id}`",
    "- Module id: `\{service.id}`",
    "- Service kind: `\{service.service_kind}`",
    "- Module mode: `\{service.module_mode}`",
    "- Persistence mode: `\{service.persistence_mode}`",
    "- MoonBook role: `\{service.book_role}`",
    "- Skill mode: `\{service.skill_mode}`",
    "- Output contract: `\{service.output_contract}`",
    "- Skill pack: `\{service.skill_path}`",
    "- Building protocol: `raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md`",
    "",
    "## Purpose",
    "",
    service.purpose,
    "",
    "## Workflow Hints",
    "",
    markdown_bullets(service.workflow),
    "",
    "## Agent Work",
    "",
    markdown_bullets(service.agent_work),
    "",
    "## Place / Exchange Work",
    "",
    markdown_bullets(service.place_work),
    "",
    "## Required Schemas",
    "",
    markdown_bullets(service.schema_pages),
    "",
    "## Durable Wiki Pages",
    "",
    markdown_bullets(service.wiki_pages),
    "",
    "## Review Queues",
    "",
    markdown_bullets(service.review_queues),
    "",
    "## Acceptance",
    "",
    markdown_bullets(service.acceptance),
    "",
    "## Safety Boundary",
    "",
    "- External publication, applications, bookings, redemptions, robot actions, and sensitive personal data changes require review.",
    "- If evidence is thin, write the blocker and next source class instead of inventing confidence.",
    "- Operational records must not inflate domain evidence counts.",
    "- Do not turn this module into generic research unless its skill mode explicitly requires source research.",
    "- Do not treat this support MoonBook as the civic place itself. The civic place is the building protocol and its runtime ledgers; this workspace persists only accepted or reviewable outputs.",
  ].join("\n")
}

///|
pub fn building_protocol_contract_text(
  service : CivicServiceDefinition,
) -> String {
  let protocol = wenyu_building_protocol_for_service(service)
  [
    "# \{service.title} Building Protocol Contract",
    "",
    "This building is a protocol place, not just a MoonBook and not just a static UI card.",
    "",
    "## Social Responsibility",
    "",
    protocol.social_responsibility,
    "",
    "## Protocol Mode",
    "",
    "- Building id: `\{protocol.building_id}`",
    "- Protocol mode: `\{protocol.protocol_mode}`",
    "- Persistence mode: `\{protocol.persistence_mode}`",
    "- Privacy scope: `\{protocol.privacy_scope}`",
    "- Projection contract: `\{protocol.projection_contract}`",
    "",
    "## Participants",
    "",
    markdown_bullets(protocol.participant_roles),
    "",
    "## Input Channels",
    "",
    markdown_bullets(protocol.input_channels),
    "",
    "## Output Channels",
    "",
    markdown_bullets(protocol.output_channels),
    "",
    "## Policies",
    "",
    "- Aggregation: \{protocol.aggregation_policy}",
    "- Exchange: \{protocol.exchange_policy}",
    "- Reduction: \{protocol.reduction_policy}",
    "- Distribution: \{protocol.distribution_policy}",
    "",
    "## Review Gates",
    "",
    markdown_bullets(protocol.review_gates),
    "",
    "## Runtime Ledgers",
    "",
    "- `.moontown/civic/protocols/\{protocol.building_id}/inbox.jsonl`",
    "- `.moontown/civic/protocols/\{protocol.building_id}/contributions.jsonl`",
    "- `.moontown/civic/protocols/\{protocol.building_id}/reductions.jsonl`",
    "- `.moontown/civic/protocols/\{protocol.building_id}/outbox.jsonl`",
    "- `.moontown/civic/protocols/\{protocol.building_id}/reviews.jsonl`",
    "",
    "## AI Reducer Boundary",
    "",
    "- Moontown hardcodes the envelope, routing, ledgers, idempotency, allowed channels, and review gates.",
    "- MoonClaw uses the skill pack to choose the building-native aggregation and reduction strategy.",
    "- MoonBook persists accepted civic records and review queues.",
    "- A module may be ledger-backed, projection-backed, handoff-ledger-backed, mixed-memory-backed, or workspace-backed; do not assume it is a research book.",
  ].join("\n")
}

///|
pub fn schema_page_text(
  service : CivicServiceDefinition,
  path : String,
) -> String {
  [
    "# \{schema_title(path)}",
    "",
    "Schema for `\{service.title}` (`\{service.service_kind}`).",
    "",
    "Module mode: `\{service.module_mode}`. Persistence mode: `\{service.persistence_mode}`. MoonBook role: `\{service.book_role}`. Skill mode: `\{service.skill_mode}`.",
    "",
    "## Required Fields",
    "",
    "- `id`: stable record id",
    "- `source`: evidence, operator input, resident input, or runtime event",
    "- `summary`: one-sentence service meaning",
    "- `confidence`: high, medium, low, or blocked",
    "- `review_state`: none, pending, approved, rejected",
    "- `projection_scope`: private, book-only, town-safe, public-ready",
    "",
    "## Evidence Rules",
    "",
    "- Knowledge claims need source IDs or clear operator input.",
    "- Operational retries are not domain evidence.",
    "- External-impact actions require review before completion.",
  ].join("\n")
}

///|
pub fn wiki_page_text(
  service : CivicServiceDefinition,
  path : String,
) -> String {
  [
    "# \{schema_title(path)}",
    "",
    "Durable MoonBook page for Wenyu Valley `\{service.title}`.",
    "",
    "## Current Service Thesis",
    "",
    service.projection_summary,
    "",
    "## Working Memory",
    "",
    "- The service should choose useful next actions from book evidence, resident/operator intent, and review gates.",
    "- The action should match module mode `\{service.module_mode}` and skill mode `\{service.skill_mode}`.",
    "- New claims must be grounded in sources or explicit operator input.",
    "- Projection state must remain safe for town UI.",
    "",
    "## Next Useful Questions",
    "",
    "- What changed since the last check?",
    "- Does the change create a resident-facing opportunity?",
    "- Does it require review before being shown, sent, booked, redeemed, or published?",
  ].join("\n")
}

///|
pub fn review_queue_text(
  service : CivicServiceDefinition,
  path : String,
) -> String {
  [
    "# \{schema_title(path)}",
    "",
    "Review queue for Wenyu Valley `\{service.title}`.",
    "",
    "## Pending Review Items",
    "",
    "| ID | Trigger | Risk | Required Reviewer | Status |",
    "| --- | --- | --- | --- | --- |",
    "| seed-\{service.id}-1 | Initial service bootstrap | confirm schemas, projection, and skill boundaries | keeper/operator | pending |",
    "",
    "## Review Rules",
    "",
    markdown_bullets(service.acceptance),
  ].join("\n")
}

///|
pub fn service_ledger_text(service : CivicServiceDefinition) -> String {
  [
    "# Service Ledger",
    "",
    "Durable service ledger for Wenyu Valley `\{service.title}`.",
    "",
    "| ID | Kind | Decision | Accepted Facts | Review Items | Projection Delta | Status |",
    "| --- | --- | --- | ---: | ---: | --- | --- |",
    "| seed-\{service.id}-ledger | bootstrap | seeded | 0 | 1 | workspace initialized; no domain/service facts accepted yet | pending-review |",
    "",
    "## Ledger Rules",
    "",
    "- Accepted facts must be domain/service facts, not daemon retries or bootstrap activity.",
    "- Every public or external-impact action needs an explicit review state.",
    "- A no-change cycle should still record checked sources/inputs, but it must not inflate accepted facts.",
  ].join("\n")
}

///|
pub fn exchange_ledger_text(service : CivicServiceDefinition) -> String {
  [
    "# Exchange Ledger",
    "",
    "Place-level aggregation/exchange/reduction/distribution ledger for `\{service.title}`.",
    "",
    "| ID | Input | Aggregation | Reduction | Distribution | Review State |",
    "| --- | --- | --- | --- | --- | --- |",
    "| seed-\{service.id}-exchange | bootstrap contracts | group by module mode `\{service.module_mode}` | no service output yet | book-local projection only | pending |",
    "",
    "## Protocol Shape",
    "",
    "- Aggregate compatible inputs.",
    "- Exchange information only inside allowed privacy scope.",
    "- Reduce to the module-native output contract `\{service.output_contract}`.",
    "- Distribute only through allowed output channels and review gates.",
  ].join("\n")
}

///|
pub fn service_history_text(service : CivicServiceDefinition) -> String {
  [
    "# Service History",
    "",
    "Chronological history for `\{service.title}`.",
    "",
    "## Bootstrap",
    "",
    "- Workspace seeded with schemas, wiki pages, review queues, service skill pack, MoonClaw profile, and projection state.",
    "- No completed civic service result has been accepted yet unless `.moontown/book-results/goal-\{service.book_id}-civic-service.json` exists.",
    "- Next meaningful work should be module-native: `\{service.skill_mode}`.",
  ].join("\n")
}

///|
fn schema_title(path : String) -> String {
  label_from_slug(path_basename(path).replace(old=".md", new=""))
}

///|
fn path_basename(path : String) -> String {
  match path.split("/").last() {
    Some(name) => name.to_owned()
    None => path
  }
}

///|
fn label_from_slug(value : String) -> String {
  value
  .replace(old="-", new=" ")
  .replace(old="_", new=" ")
  .split(" ")
  .filter(fn(part) { !part.is_empty() })
  .map(fn(part) { capitalize_ascii_word(part.to_owned()) })
  .join(" ")
}

///|
fn capitalize_ascii_word(value : String) -> String {
  if value.is_empty() {
    value
  } else {
    value[:1].to_upper().to_owned() + value[1:].to_owned()
  }
}
