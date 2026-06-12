///|
fn standing_watch_worker_context_bundle(
  bundle : WorkerContextBundle,
) -> WorkerContextBundle {
  let skill_paths = unique_paths(
    [
      ..bundle.skill_paths,
      "skills/standing-watch/SKILL.md",
      "skills/web-first-research/SKILL.md",
      "skills/source-diarize/SKILL.md",
      "skills/research-evidence-synthesis/SKILL.md",
    ],
  )
  let context_pages = unique_paths(
    [
      ..bundle.context_pages,
      "wiki/history/standing-watch.md",
      "wiki/history/journey.md",
      "wiki/sources/",
      "wiki/synthesis/overview.md",
      "wiki/synthesis/claims.md",
    ],
  )
  let output_contract = unique_paths(
    [
      ..bundle.output_contract,
      "standing_goal_decision: update | no_change | needs_review | failed",
      "delta_score: 0-100",
      "new_source_count: <integer>",
      "next_check_hint: normal | slower | faster | review",
      "checked_sources_count: <integer>",
      "new_sources_found: <integer>",
      "accepted_facts_count: <integer>",
      "rejected_facts_count: <integer>",
      "wiki_pages_changed_count: <integer>",
      "book_changed: yes | no",
    ],
  )
  {
    book_id: bundle.book_id,
    workspace_root: bundle.workspace_root,
    task_id: bundle.task_id,
    prompt: bundle.prompt,
    policy: bundle.policy,
    routines: bundle.routines,
    skill_paths,
    context_pages,
    active_memory: bundle.active_memory,
    user_memory: bundle.user_memory,
    working_memory: bundle.working_memory,
    memory_summary: bundle.memory_summary,
    output_contract,
  }
}
