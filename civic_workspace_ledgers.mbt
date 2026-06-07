///|
fn civic_service_ledger_text(service : @civic.CivicServiceDefinition) -> String {
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
fn civic_exchange_ledger_text(
  service : @civic.CivicServiceDefinition,
) -> String {
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
fn civic_service_history_text(
  service : @civic.CivicServiceDefinition,
) -> String {
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
