///|
fn civic_schema_page_text(
  service : @civic.CivicServiceDefinition,
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
fn civic_wiki_page_text(
  service : @civic.CivicServiceDefinition,
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
fn civic_review_queue_text(
  service : @civic.CivicServiceDefinition,
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
