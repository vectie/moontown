///|
pub fn standing_watch_task_kind() -> String {
  @standing_watch_contracts.standing_watch_task_kind()
}

///|
pub fn standing_watch_task_kind_matches(kind : String) -> Bool {
  @standing_watch_contracts.standing_watch_task_kind_matches(kind)
}

///|
pub fn standing_watch_target_pages() -> Array[String] {
  [
    "wiki/history/journey.md", "wiki/sources/", "wiki/synthesis/overview.md", "raw/bootstrap/",
  ]
}

///|
pub fn standing_watch_prompt(
  goal : @core.StandingGoal,
  target_book_id : String,
  tick : Int,
  no_change_streak : Int,
) -> String {
  let prompt =
    $|This is a MoonBook-owned 24/7 standing-watch cycle.
    $|
    $|Standing goal:
    $|- id: \{goal.id}
    $|- title: \{goal.title}
    $|- target_book_id: \{target_book_id}
    $|- source_policy: \{goal.source_policy}
    $|- quality_threshold: \{goal.quality_threshold}
    $|- daemon_tick: \{tick}
    $|- consecutive_no_change_before_this_check: \{no_change_streak}
    $|
    $|User intent:
    $|\{goal.prompt}
    $|
    $|Keeper responsibility:
    $|- MoonBook owns the baseline, source fingerprints, wiki memory, update threshold, digest history, and generated projection.
    $|- MoonClaw only performs bounded search/fetch/read/summarize work and returns candidate evidence.
    $|- Moontown only scheduled this check and will consume your final decision marker.
    $|
    $|Research temperament:
    $|- Use imagination to form better hypotheses and search angles, not to invent facts.
    $|- Use curiosity to ask what would surprise the current book, why this topic matters now, and which weak signals deserve a future pass.
    $|- Use judgement to reject noise, mirrors, stale material, inaccessible pages, and operational churn.
    $|- A truthful no-change digest is better than a fake update.
    $|
    $|Required workflow:
    $|1. Load the current book baseline before searching: wiki/sources, wiki/entities, wiki/concepts, wiki/synthesis, wiki/history, raw/bootstrap, and any latest digest.
    $|2. Search/fetch web sources first when the source policy is web-first. If web search is unavailable, record the tool blocker and use approved local/source hints only as fallback.
    $|3. Compare candidates against the existing baseline. Do not rewrite the wiki just because the standing goal is due.
    $|4. If the new evidence is meaningfully useful, add or revise durable MoonBook artifacts: source cards, claim/evidence notes, timeline/journey note, synthesis/digest, and generated-site projection inputs.
    $|5. If there is no meaningful new evidence, contradiction, advantage, risk, or synthesis value for this topic, write only a compact no-change observation in the book journey/review surface and do not inflate the wiki.
    $|6. If evidence is ambiguous or risky, queue review instead of silently accepting it.
    $|
    $|Required final marker in the result summary:
    $|standing_goal_decision: update | no_change | needs_review | failed
    $|delta_score: 0-100
    $|new_source_count: <integer>
    $|next_check_hint: normal | slower | faster | review
    $|checked_sources_count: <integer>
    $|new_sources_found: <integer>
    $|accepted_facts_count: <integer>
    $|rejected_facts_count: <integer>
    $|wiki_pages_changed_count: <integer>
    $|book_changed: yes | no
    $|
    $|Decision meaning:
    $|- update: useful new evidence was persisted or queued for durable memory.
    $|- no_change: checked sources did not beat the current baseline.
    $|- needs_review: likely useful, but requires keeper/human review.
    $|- failed: the check could not complete honestly.
    $|
    $|Strict accounting:
    $|- new_source_count counts newly useful accepted sources, not search results.
    $|- checked_sources_count counts sources actually opened/fetched/read enough to judge.
    $|- accepted_facts_count and wiki_pages_changed_count must be 0 for failed and ordinary no_change cycles.
    $|- book_changed is yes only when durable book knowledge changed or review was queued.
    $|- Generated site rebuilds, retries, history entries, and operational logs do not count as research progress.
  if @book_quality.is_repair_goal_id(goal.id) {
    "\{prompt}\n\{@book_quality.repair_goal_standing_watch_appendix()}"
  } else {
    prompt
  }
}
