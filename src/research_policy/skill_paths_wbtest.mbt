///|
test "research policy owns research skill path contracts" {
  assert_eq(
    web_first_research_skill_path(),
    "skills/web-first-research/SKILL.md",
  )
  assert_eq(wiki_ingest_skill_path(), "skills/wiki-ingest/SKILL.md")
  assert_eq(research_report_skill_path(), "skills/research-report/SKILL.md")
  assert_true(
    bootstrap_worker_skill_paths().contains(research_report_skill_path()),
  )
  assert_true(
    enrichment_skill_paths().contains(repo_source_materialize_skill_path()),
  )
  assert_true(
    standing_watch_research_skill_paths().contains(
      evidence_synthesis_skill_path(),
    ),
  )
}
