///|
fn repo_source_materialize_skill_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  let pages = @research_policy.topic_wiki_page_examples(topic)
  let source_page = pages[0]
  let entity_page = pages[1]
  let concept_page = pages[2]
  let synthesis_page = pages[3]
  [
    "---",
    "name: repo-source-materialize",
    "description: Turn gathered web and local evidence into durable source, entity, concept, and synthesis pages instead of generic completion text.",
    "---",
    "",
    "# Repo Source Materialize",
    "",
    "Use this skill after source discovery for \{display}.",
    "",
    "## Rules",
    "",
    "- Convert evidence into durable markdown pages, not chat-style summaries.",
    "- Preserve provenance from both web and local sources.",
    "- Use the evidence matrix as the only source of claims. If a claim is not in `\{@research_policy.evidence_matrix_path()}`, extract it there first.",
    "- Mark source pages as `Source type: verified source digest` only when fetched or inspected content exists.",
    "- Candidate inventories and provisional blockers belong in `raw/bootstrap/` or clearly labeled provisional pages, not as the final source coverage.",
    "- Update `wiki/index.md` and `wiki/log.md` whenever new substantive pages are created or revised.",
    "- If evidence is still weak, create an explicit blocker note that states what is missing.",
    "",
    "## Minimum Acceptable Materialization",
    "",
    "- one verified source page, for example `\{source_page}`",
    "- one entity page, for example `\{entity_page}`",
    "- one concept page, for example `\{concept_page}`",
    "- one synthesis page, for example `\{synthesis_page}`",
    "- index and log updates that reference those pages",
    "",
    "## Example",
    "",
    "Good result:",
    "",
    "```md",
    "# \{display} Architecture",
    "",
    "## What It Is",
    "- precise description grounded in fetched docs and local repo evidence, with claim IDs",
    "",
    "## Evidence",
    "- C1: web source W1 shows the public/project-facing claim.",
    "- C2: local source L1 shows how the claim is implemented.",
    "",
    "## Synthesis",
    "- explain how the evidence fits together and where it is still weak",
    "",
    "## Open Questions",
    "- unresolved boundary or missing capability",
    "```",
    "",
    "Bad result:",
    "- `Completed provider task.`",
    "- generic workspace boilerplate with zero topic-specific claims",
    "- a `wiki/sources/` page that only lists candidate URLs without inspected evidence",
  ].join("\n")
}
