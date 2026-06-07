///|
fn default_operational_index(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  summary : String,
  focus : Array[String],
) -> String {
  [
    "# \{title}",
    "",
    summary,
    "",
    "## Book",
    "",
    "- Book id: `\{entry.id}`",
    "- Workspace: `\{entry.workspace_root}`",
    "- Type: `operational-book`",
    "",
    "## Focus",
    "",
    markdown_bullets(focus),
    "",
    "## Start Here",
    "",
    "- `raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md`",
    "- `wiki/operations/review-policy.md`",
    "- `wiki/history/journey.md`",
    "- `skills/operational-keeper/SKILL.md`",
  ].join("\n")
}

///|
fn default_operational_contract(title : String) -> String {
  [
    "# \{title} Contract",
    "",
    "This operational book preserves workspace memory, review rules, and safe execution boundaries.",
    "",
    "## Rules",
    "",
    "- Do not invent external facts.",
    "- Do not store sensitive user data unless explicitly provided and scoped.",
    "- Keep operational records separate from domain evidence.",
    "- Prefer small reviewed changes and durable journey notes.",
  ].join("\n")
}

///|
fn default_operational_review_policy(title : String) -> String {
  [
    "# \{title} Review Policy",
    "",
    "- Queue review when a change affects external systems, private data, money, or repo quality gates.",
    "- Record validation evidence before marking a task complete.",
    "- Preserve a short journey note for material decisions.",
  ].join("\n")
}

///|
fn default_operational_journey(title : String) -> String {
  [
    "# \{title} Journey",
    "",
    "| Date | Event | Evidence |",
    "| --- | --- | --- |",
    "| bootstrap | Created operational MoonBook workspace | `raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md` |",
  ].join("\n")
}

///|
fn default_operational_skill(title : String) -> String {
  [
    "---",
    "name: operational-keeper",
    "description: Maintain an operational MoonBook workspace with review policy, journey notes, and safe execution boundaries.",
    "---",
    "",
    "# Operational Keeper Skill",
    "",
    "Operate `\{title}` as durable workspace memory.",
    "",
    "## Rules",
    "",
    "- Read the book contract before updating memory.",
    "- Separate operational records from domain facts.",
    "- Write concise journey notes for material decisions.",
    "- Queue review for sensitive, financial, external, or code-quality-impacting changes.",
    "",
    moonbook_skill_quality_contract_section(),
    "",
    "## Concrete Example",
    "",
    "```md",
    "operational_decision: update",
    "book_changed: yes",
    "review_required: no",
    "summary: Added a validated review policy note and linked the validation evidence.",
    "```",
  ].join("\n")
}
