///|
fn research_evidence_synthesis_skill_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  [
    research_evidence_synthesis_frontmatter(),
    research_evidence_synthesis_intro(),
    research_evidence_synthesis_temperament_section(),
    research_evidence_synthesis_reference_section(display),
    research_evidence_synthesis_protocol_section(display),
    research_evidence_matrix_schema_section(display),
    research_evidence_wiki_materialization_section(topic),
    research_evidence_example_source_page_section(display),
    research_evidence_failure_discipline_section(),
  ].join("\n")
}

///|
fn research_evidence_synthesis_frontmatter() -> String {
  [
    "---", "name: research-evidence-synthesis", "description: Apply a transparent evidence-synthesis workflow: question, search, screen, extract, triangulate, synthesize, and report gaps.",
    "---",
  ].join("\n")
}

///|
fn research_evidence_synthesis_intro() -> String {
  [
    "", "# Research Evidence Synthesis", "", "Use this skill when a research lane needs real knowledge work instead of a scaffold or candidate inventory.",
  ].join("\n")
}

///|
fn research_evidence_synthesis_temperament_section() -> String {
  [
    "", "## Research Temperament", "", "The goal is not to dump facts. The goal is to build understanding.",
    "", "- Imagination: propose plausible mechanisms and futures, then test them against evidence.",
    "- Curiosity: look for surprises, absences, contradictions, incentives, and second-order effects.",
    "- Judgement: decide what matters enough to become durable knowledge and what should be rejected or deferred.",
    "- Taste: make the synthesis useful to a human decision-maker, not just correct in isolation.",
  ].join("\n")
}

///|
fn research_evidence_synthesis_reference_section(display : String) -> String {
  [
    "",
    "## Reference-Aware Synthesis",
    "",
    "When a reference report is supplied, use it as a benchmark for research craft:",
    "",
    "- match its seriousness, section depth, table/diagram expectations, and approximate length class when the evidence supports that depth",
    "- preserve its language choice when the user has not asked otherwise",
    "- use its route taxonomy, comparison axes, and visual structure as candidate hypotheses only when the current topic calls for those comparisons",
    "- use optional `raw/bootstrap/REFERENCE_SOURCE_HINTS.md` only as a list of sources or searches to screen, not as evidence",
    "- do not copy its claims, source choices, or conclusions unless current screened evidence for \{display} independently supports them",
    "- if evidence is thinner than the reference, explain the gap and write the strongest honest version rather than padding with generic prose",
    "",
    "When no reference report is supplied, use the skill's own depth standard:",
    "",
    "- for complex external, comparative, route-map, or technology research, target a \{@research_policy.deep_dossier_word_target()} dossier when the screened source base has enough evidence",
    "- \{@research_policy.min_included_sources()} included inspected sources is the minimum for a cautious dossier; \{@research_policy.preferred_included_sources()} or more included sources is the preferred source base for a reference-grade report",
    "- build length from explanation depth: mechanisms, route tradeoffs, adoption constraints, evidence reliability, scenarios, second-order implications, and what would change the thesis",
    "- do not pad with repeated definitions, unverified background, or generic process notes",
    "- if the source base is too thin, say exactly which missing source classes block full depth",
  ].join("\n")
}

///|
fn research_evidence_synthesis_protocol_section(display : String) -> String {
  [
    "",
    "## Protocol",
    "",
    "1. Question: define the research question for \{display}, the subquestions, and what counts as in scope.",
    "2. Search: record every query attempted and why it was chosen.",
    "3. Screen: include or exclude sources using authority, relevance, recency, and source risk.",
    "4. Extract: convert source observations into claim rows before writing prose.",
    "5. Triangulate: compare multiple independent web sources, and compare with local repository evidence only when local evidence is explicitly relevant.",
    "6. Synthesize: combine claims into a short argument about what \{display} is, how it works, and why it matters.",
    "7. Position: use the marketing skill to convert supported claims into `\{@research_policy.marketing_brief_path()}` without inventing unsupported product claims.",
    "8. Gap map: list missing evidence, contradictions, and next searches.",
  ].join("\n")
}

///|
fn research_evidence_matrix_schema_section(display : String) -> String {
  [
    "",
    "## Evidence Matrix Schema",
    "",
    "Write `\{@research_policy.evidence_matrix_path()}` with this table:",
    "",
    "```md",
    "| Claim ID | Claim | Source IDs | Evidence detail | Confidence | Gap or contradiction |",
    "| --- | --- | --- | --- | --- | --- |",
    "| C1 | \{display} claim stated as a falsifiable sentence. | W1, L1 | What each source actually shows. | medium | What still needs verification. |",
    "```",
  ].join("\n")
}

///|
fn research_evidence_wiki_materialization_section(topic : String) -> String {
  [
    "",
    "## Wiki Materialization Rules",
    "",
    "- A source page such as `\{@research_policy.topic_source_page(topic)}` must identify source IDs, source type, inspected content, extracted claims, and risk.",
    "- An entity page such as `\{@research_policy.topic_entity_page(topic)}` must describe the concrete project, actor, institution, domain model, or market participant that the evidence actually supports.",
    "- A concept page such as `\{@research_policy.topic_concept_page(topic)}` must explain one architecture, workflow, business, legal, or market concept grounded in claims.",
    "- A synthesis page such as `\{@research_policy.topic_synthesis_page(topic)}` must connect claims across sources and name unresolved gaps.",
    "- `\{@research_policy.marketing_brief_path()}` must translate the evidence into product and seller perspective: buyer, pain, promise, strengths, proof, objections, and next action.",
    "- Every durable page must include provenance. Use claim IDs and source IDs from the evidence matrix.",
  ].join("\n")
}

///|
fn research_evidence_example_source_page_section(display : String) -> String {
  [
    "",
    "## Example Source Page",
    "",
    "```md",
    "# \{display} Web and Local Evidence",
    "",
    "- Source type: verified source digest",
    "- Topic: \{display}",
    "- Source IDs: W1, W2, optional L1 only when local evidence is relevant",
    "",
    "## Screened Sources",
    "",
    "- W1: fetched reputable web source. Included because it directly describes \{display}.",
    "- L1: optional local file path inspected only when source hints or screened evidence make it relevant.",
    "",
    "## Extracted Claims",
    "",
    "- C1: \{display} has a specific verified property. Sources: W1, W2. Confidence: medium.",
    "",
    "## Risks",
    "",
    "- Missing current evidence, blocked sources, jurisdiction limits, or single-source claims.",
    "```",
  ].join("\n")
}

///|
fn research_evidence_failure_discipline_section() -> String {
  [
    "", "## Failure Discipline", "", "If the research cannot reach verified coverage, make that explicit. Create provisional pages only when they are labeled provisional and explain the exact missing source or tool.",
  ].join("\n")
}
