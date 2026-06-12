///|
fn research_local_inspection_step(external_domain : Bool) -> String {
  if external_domain {
    let repository_boundary = "Do not infer a local repository from the topic name."
    let local_file_gate = "Inspect local files only when `SOURCE_HINTS.md` lists explicit paths or fetched sources prove local implementation material is relevant."
    research_numbered_step(7, [repository_boundary, local_file_gate])
  } else {
    "7. Only after web discovery, inspect high-signal local files for corroboration and implementation detail."
  }
}

///|
fn research_local_sources_step() -> String {
  "8. Write `\{research_local_sources_path()}` with exact paths, symbols or sections inspected, and evidence bullets."
}

///|
fn research_synthesis_brief_step() -> String {
  "9. Write `\{research_synthesis_brief_path()}` that separates findings, contradictions, gaps, and next research."
}

///|
fn research_deep_report_step() -> String {
  research_numbered_step(10, [
    "Write `\{research_deep_report_path()}` using `skills/research-report/SKILL.md`.",
    "Prefer a \{research_policy_deep_dossier_word_target()} deep dossier for complex external/technology-route research with enough screened sources.",
    "If a reference report exists, also match its reader-facing ambition and approximate length class without copying unsupported claims.",
  ])
}

///|
fn research_marketing_brief_step() -> String {
  "11. Write `\{research_marketing_brief_path()}` using `skills/wiki-marketing/SKILL.md`: buyer pain, promise, differentiation, proof, objections, and next action."
}

///|
fn research_materialization_handoff_step() -> String {
  let moonbook_handoff = "If running inside MoonBook, materialize durable wiki pages."
  let moonclaw_handoff = "If running inside a direct MoonClaw worker, stop at wiki-ready raw artifacts and clearly mark whether MoonBook has enough evidence to materialize pages."
  research_numbered_step(12, [moonbook_handoff, moonclaw_handoff])
}
