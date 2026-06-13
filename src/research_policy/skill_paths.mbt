///|
pub fn web_first_research_skill_path() -> String {
  "skills/web-first-research/SKILL.md"
}

///|
pub fn wiki_ingest_skill_path() -> String {
  "skills/wiki-ingest/SKILL.md"
}

///|
pub fn source_diarize_skill_path() -> String {
  "skills/source-diarize/SKILL.md"
}

///|
pub fn evidence_synthesis_skill_path() -> String {
  "skills/research-evidence-synthesis/SKILL.md"
}

///|
pub fn research_report_skill_path() -> String {
  "skills/research-report/SKILL.md"
}

///|
pub fn repo_source_materialize_skill_path() -> String {
  "skills/repo-source-materialize/SKILL.md"
}

///|
pub fn wiki_marketing_skill_path() -> String {
  "skills/wiki-marketing/SKILL.md"
}

///|
pub fn bootstrap_worker_skill_paths() -> Array[String] {
  [
    web_first_research_skill_path(),
    source_diarize_skill_path(),
    evidence_synthesis_skill_path(),
    research_report_skill_path(),
    wiki_marketing_skill_path(),
  ]
}

///|
pub fn enrichment_skill_paths() -> Array[String] {
  [
    web_first_research_skill_path(),
    evidence_synthesis_skill_path(),
    repo_source_materialize_skill_path(),
    wiki_marketing_skill_path(),
  ]
}

///|
pub fn standing_watch_research_skill_paths() -> Array[String] {
  [
    web_first_research_skill_path(),
    source_diarize_skill_path(),
    evidence_synthesis_skill_path(),
  ]
}
