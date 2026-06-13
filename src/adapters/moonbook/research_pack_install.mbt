///|
async fn ensure_moontown_research_pack(
  root : String,
  entry : BookCatalogEntry,
) -> Unit {
  guard catalog_entry_is_research(entry) else { return }
  write_workspace_text(
    @research_policy.workspace_artifact_path(
      root,
      @research_policy.web_first_research_skill_path(),
    ),
    web_first_research_skill_text(entry),
  )
  write_workspace_text(
    @research_policy.workspace_artifact_path(
      root,
      @research_policy.wiki_ingest_skill_path(),
    ),
    research_wiki_ingest_skill_text(entry),
  )
  write_workspace_text(
    @research_policy.workspace_artifact_path(
      root,
      @research_policy.source_diarize_skill_path(),
    ),
    research_source_diarize_skill_text(entry),
  )
  write_workspace_text(
    @research_policy.workspace_artifact_path(
      root,
      @research_policy.evidence_synthesis_skill_path(),
    ),
    research_evidence_synthesis_skill_text(entry),
  )
  write_workspace_text(
    @research_policy.workspace_artifact_path(
      root,
      @research_policy.research_report_skill_path(),
    ),
    research_report_skill_text(entry),
  )
  write_workspace_text(
    @research_policy.workspace_artifact_path(
      root,
      @research_policy.repo_source_materialize_skill_path(),
    ),
    repo_source_materialize_skill_text(entry),
  )
  write_workspace_text(
    @research_policy.workspace_artifact_path(
      root,
      @research_policy.research_request_context_page(),
    ),
    research_request_text(entry),
  )
  write_workspace_text(
    @research_policy.workspace_artifact_path(
      root,
      @research_policy.source_hints_context_page(),
    ),
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
