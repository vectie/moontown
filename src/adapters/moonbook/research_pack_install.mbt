///|
async fn ensure_moontown_research_pack(
  root : String,
  entry : BookCatalogEntry,
) -> Unit {
  guard catalog_entry_is_research(entry) else { return }
  write_workspace_text(
    "\{root}/skills/web-first-research/SKILL.md",
    web_first_research_skill_text(entry),
  )
  write_workspace_text(
    "\{root}/skills/wiki-ingest/SKILL.md",
    research_wiki_ingest_skill_text(entry),
  )
  write_workspace_text(
    "\{root}/skills/source-diarize/SKILL.md",
    research_source_diarize_skill_text(entry),
  )
  write_workspace_text(
    "\{root}/skills/research-evidence-synthesis/SKILL.md",
    research_evidence_synthesis_skill_text(entry),
  )
  write_workspace_text(
    "\{root}/skills/research-report/SKILL.md",
    research_report_skill_text(entry),
  )
  write_workspace_text(
    "\{root}/skills/repo-source-materialize/SKILL.md",
    repo_source_materialize_skill_text(entry),
  )
  write_workspace_text(
    "\{root}/raw/bootstrap/RESEARCH_REQUEST.md",
    research_request_text(entry),
  )
  write_workspace_text(
    "\{root}/raw/bootstrap/SOURCE_HINTS.md",
    research_source_hints_text(entry),
  )
  write_workspace_text_if_missing(
    research_workspace_artifact_path(root, research_question_path()),
    research_question_seed_text(entry),
  )
  write_workspace_text_if_missing(
    research_workspace_artifact_path(root, research_search_log_path()),
    research_search_log_seed_text(entry),
  )
  ensure_moontown_research_moonclaw_profile(root)
}
