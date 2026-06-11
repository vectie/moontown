///|
fn live_autonomy_priority_section() -> String {
  [
    "", "## Priority", "", "Top priority.", "The town already has daemon, watchers, MoonBook workspaces, MoonClaw execution, civic protocols, and UI projection.",
    "The missing work is the connective spine that makes those components behave as one live autonomous town.",
  ].join("\n")
}

///|
fn live_autonomy_problem_section() -> String {
  [
    "", "## Problem", "", "Runtime state is spread across daemon files, watcher ledgers, MoonBook outputs, civic protocol ledgers, and visual projections.",
    "The UI can show pieces, but there is no single accepted lifecycle artifact.",
    "That artifact must say what is working, what changed, what is only no-change activity, what needs review, and what the Mayor should do next.",
  ].join("\n")
}

///|
fn live_autonomy_goal_section() -> String {
  [
    "", "## Goal", "", "- Maintain `.moontown/live-autonomy.json` as the current town spine.",
    "- Append `.moontown/town-journal.jsonl` on each daemon tick or manual refresh.",
    "- Refresh `visual-projection.json` from real task/worker/protocol state during daemon ticks.",
    "- Classify town activity into working, watching, or needs-recovery; keep review queues visible without letting routine review block the watch loop.",
    "- Separate accepted updates, no-change cycles, failed cycles, and review-gated outputs.",
    "- Make cookbook treat the live spine and journal as stable runtime artifacts.",
  ].join("\n")
}

///|
fn live_autonomy_ownership_section() -> String {
  [
    "", "## Ownership", "", "- Moontown Mayor owns the spine, scheduling, retry, projection, and journal.",
    "- MoonBook owns accepted durable records and support workspaces.", "- MoonClaw owns worker execution and structured result packets.",
    "- Moondesk later owns human browsing/editing of the cookbook and workspace files.",
  ].join("\n")
}

///|
fn live_autonomy_acceptance_section() -> String {
  [
    "", "## Acceptance Criteria", "", "- [x] `moon run cmd/main -- live refresh` writes `.moontown/live-autonomy.json`.",
    "- [x] `moon run cmd/main -- live status` renders the current spine.", "- [x] Daemon tick refreshes `visual-projection.json` and live autonomy state.",
    "- [x] The spine records active workers, reviews, blocked work, accepted updates, no-change cycles, due goals, and next actions.",
    "- [x] Cookbook tracks the live spine and journal as runtime-state artifacts.",
    "- [ ] UI consumes the live spine directly for the operator message panel.",
    "- [ ] Every MoonClaw result writes a strict accepted/no-change/review/blocked contract before projection.",
  ].join("\n")
}

///|
fn live_autonomy_validation_section() -> String {
  [
    "", "## Validation", "", "- `moon run cmd/main -- live refresh`", "- `moon run cmd/main -- live status`",
    "- `moon run cmd/main -- daemon run --once`", "- `moon check --no-render`", "- `moon test`",
  ].join("\n")
}
