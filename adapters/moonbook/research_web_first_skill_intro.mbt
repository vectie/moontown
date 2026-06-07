///|
fn web_first_header_section() -> Array[String] {
  [
    "---",
    "name: web-first-research",
    web_first_header_description(),
    "---",
    "",
    "# Web-First Research",
    "",
    web_first_skill_scope_sentence(),
    "",
  ]
}

///|
fn web_first_header_description() -> String {
  web_first_text([
    "description: Discover authoritative web sources before local repository", "search, then convert them into durable bootstrap notes and wiki-ready",
    "claims.",
  ])
}

///|
fn web_first_skill_scope_sentence() -> String {
  web_first_text([
    "Use this skill for research-lane ingest and follow-up work.", "The output must look like a researcher worked through a transparent",
    "protocol, not like a product blurb.",
  ])
}

///|
fn web_first_temperament_section() -> Array[String] {
  [
    "## Research Temperament",
    "",
    "Good research needs more than correctness.",
    "",
    web_first_imagination_rule(),
    web_first_curiosity_rule(),
    web_first_judgement_rule(),
    web_first_point_of_view_rule(),
    "",
  ]
}

///|
fn web_first_imagination_rule() -> String {
  web_first_text([
    "- Use imagination to form hypotheses, adjacent-domain search angles,", "and second-order implications. Do not invent facts.",
  ])
}

///|
fn web_first_curiosity_rule() -> String {
  web_first_text([
    "- Use curiosity to ask why the topic matters now, what would surprise", "the current book, who benefits, who is harmed, and what evidence would",
    "change the synthesis.",
  ])
}

///|
fn web_first_judgement_rule() -> String {
  web_first_text([
    "- Use judgement to prefer high-signal sources and reject noise,", "stale mirrors, shallow commentary, and operational busywork.",
  ])
}

///|
fn web_first_point_of_view_rule() -> String {
  web_first_text([
    "- End with a point of view: what changed, what did not change,", "why it matters, and what should be watched next.",
  ])
}

///|
fn web_first_reference_style_section(display : String) -> Array[String] {
  [
    "## Reference Style Discipline",
    "",
    web_first_reference_file_rule(),
    web_first_reference_craft_rule(),
    web_first_reference_route_rule(),
    "- Never use reference-file claims as evidence for \{display} unless independent screened sources support them.",
    "",
  ]
}

///|
fn web_first_reference_file_rule() -> String {
  web_first_text([
    "- If `raw/bootstrap/REFERENCE_STYLE.md` or", "`raw/bootstrap/REFERENCE_OUTPUT.md` exists, read it before synthesis",
    "and use it to match the expected quality bar.",
  ])
}

///|
fn web_first_reference_craft_rule() -> String {
  web_first_text([
    "- Treat reference files as craft guidance only: length class, language,", "section architecture, table density, visualization type, and level of",
    "analytical courage.",
  ])
}

///|
fn web_first_reference_route_rule() -> String {
  web_first_text([
    "- Treat reference route names, comparison axes, and diagram dimensions", "as hypotheses/search leads when they fit the user's objective; verify",
    "them with current screened sources before including them.",
  ])
}

///|
fn web_first_method_section() -> Array[String] {
  [
    "## Research Method",
    "",
    "Follow this sequence:",
    "",
    web_first_question_scope_step(),
    web_first_web_before_local_step(),
    "3. Fetch and inspect selected sources before writing claims.",
    "4. Screen sources for authority, relevance, recency, and risk.",
    "5. Extract evidence into a claim matrix before synthesis.",
    "6. Compare web evidence with local repository evidence.",
    "7. Synthesize what is supported, what conflicts, and what remains unknown.",
    "8. Materialize verified wiki pages with source IDs and claim IDs.",
    "",
  ]
}

///|
fn web_first_question_scope_step() -> String {
  web_first_text([
    "1. Formulate the research question, scope, keywords, inclusion criteria,", "and exclusion criteria.",
  ])
}

///|
fn web_first_web_before_local_step() -> String {
  web_first_text([
    "2. Search the web before local files. Use multiple query phrasings,", "not just the project name.",
  ])
}
