///|
fn standing_watch_task(
  goal : @core.StandingGoal,
  target_book_id : String,
  tick : Int,
  no_change_streak : Int,
) -> @moonbook.BookTask {
  @moonbook.BookTask::new(
    id=standing_watch_task_id(goal.id, tick),
    goal=Some(goal.prompt),
    title="Standing watch: \{goal.title}",
    kind="standing-watch",
    prompt=standing_watch_prompt(goal, target_book_id, tick, no_change_streak),
    priority=95,
    requires_review=false,
    target_pages=[
      "wiki/history/journey.md", "wiki/sources/", "wiki/synthesis/overview.md", "raw/bootstrap/",
    ],
    required_role=Some(@core.WorkerRole::Watcher),
  )
}

///|
fn standing_watch_prompt(
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
  if standing_goal_is_book_quality_repair(goal) {
    "\{prompt}\n\{standing_watch_book_quality_repair_appendix()}"
  } else {
    prompt
  }
}

///|
fn standing_goal_is_book_quality_repair(goal : @core.StandingGoal) -> Bool {
  goal.id.has_prefix("book-quality-repair-")
}

///|
fn standing_watch_book_quality_repair_appendix() -> String {
  let appendix =
    $|
    $|Book-quality repair mode:
    $|- This standing goal is not a passive latest-news watch. It exists because a semantic MoonBook quality review found a concrete gap.
    $|- Read `wiki/reviews/book-quality-repair.md` and execute the named repair task before deciding.
    $|- If the repair queue names missing artifacts, create or revise those artifacts using the book's own SKILL.md, contracts, local source hints, approved web/source tools, and current workspace state.
    $|- If web search/fetch is unavailable, record that blocker but still use approved local/source hints and existing book context to make bounded progress when possible.
    $|- Do not return ordinary `no_change` merely because no fresh source was found while the repair queue still names missing artifacts.
    $|- Return `no_change` only when the required artifacts already exist, the named gap is already satisfied, or the review queue is stale and no longer applies.
    $|- Return `needs_review` when source authority, policy, privacy, or evidence uncertainty prevents autonomous promotion after useful repair work.
    $|- Return `update` when durable book artifacts, accepted evidence, or review-gated repair artifacts were created or revised.
    $|- Keep the repair book-local. Do not create v1/v2/v3/v4 alternate books.
  appendix
}

///|
fn standing_watch_task_id(goal_id : String, tick : Int) -> String {
  "standing-\{compact_watch_segment(goal_id)}-tick-\{tick}"
}
