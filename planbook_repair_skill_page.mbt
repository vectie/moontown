///|
fn planbook_repair_skill_markdown() -> String {
  [
    planbook_repair_skill_frontmatter(),
    planbook_repair_skill_intro(),
    planbook_repair_skill_required_decision_section(),
    planbook_repair_skill_rules_section(),
    moonbook_skill_quality_contract_section(),
    planbook_repair_skill_example_section(),
  ].join("\n")
}

///|
fn planbook_repair_skill_frontmatter() -> String {
  [
    "---", "name: planbook-repair", "description: Repair one bounded PlanBook self-build gap while preserving Moontown/MoonBook/MoonClaw ownership boundaries.",
    "---",
  ].join("\n")
}

///|
fn planbook_repair_skill_intro() -> String {
  [
    "# PlanBook Repair Skill", "", "You repair exactly one self-build criterion. Prefer small source patches, direct validation, and explicit blockers over broad rewrites.",
  ].join("\n")
}

///|
fn planbook_repair_skill_required_decision_section() -> String {
  [
    "## Required Decision",
    "",
    "- `repair_decision`: accepted | needs_external_owner | blocked | no_change",
    "- `criterion_id`: the criterion being repaired",
    "- `files_changed`: exact files changed, or `none`",
    "- `validation`: commands run and results",
    "- `diff_summary`: git status/diff hygiene and important changed hunks",
    "- `plan_update_status`: unchanged | updated | stale_blocked",
    "- `commit_status`: committed | ready_to_commit | skipped_no_change | blocked",
    "- `commit_message`: proposed or actual local commit message",
    "- `push_status`: not_pushed_by_policy | pushed | blocked",
    "- `remaining_blockers`: unresolved gaps",
    "- `cookbook_impact`: none | update_needed | updated",
    "- `patch_receipt`: required for `repair_decision: accepted`; contract `\{planbook_repair_patch_receipt_contract()}` with source-root ACP, validation, diff, commit, and push-policy fields",
  ].join("\n")
}

///|
fn planbook_repair_skill_rules_section() -> String {
  ["## Rules", "", planbook_repair_skill_rules().join("\n")].join("\n")
}

///|
fn planbook_repair_skill_rules() -> Array[String] {
  [
    "- Fix Moontown-owned routing/live-spine/UI/docs issues inside Moontown.",
    "- For `editor-selected-feature-implementation`, read `raw/editor-pipeline/next-feature.json` and implement the selected feature; do not choose a different feature in code.",
    "- For selected editor features, write `raw/editor-pipeline/selected-feature-implementation.md` with `contract: \{editor_selected_feature_implementation_contract()}`, `selected_feature: <id>`, and `implementation_status: accepted` only after validation.",
    "- For `backlog-*` criteria, write `raw/backlog/completed/<backlog-id>.md` only after validation and include the backlog id in `\{planbook_repair_result_relative_path()}`.",
    "- If the backlog item is already done, update progress/backlog evidence and return `repair_decision: no_change` or `accepted` with no source patch; do not invent code churn.",
    "- If the plan is stale, update the PlanBook plan/backlog documents first and record `plan_update_status`.",
    "- Preserve the operating architecture: durable truth in MoonBook documents/ledgers, active behavior as protocols, buildings as protocol places, Mayor for routing/cadence, Bookkeepers for memory, Workers for bounded execution.",
    "- For civic work, prove information exchange with inbox/contribution/reduction/outbox/review/return-home records instead of only adding UI labels.",
    "- For live autonomy work, prove growth with changed books, protocol ledgers, PlanBook evidence, code/tests, UI projections, or explicit no-change decisions.",
    "- For MoonBook-native provider/profile work, produce a MoonBook patch plan or patch only when executing inside MoonBook.",
    "- For MoonClaw runtime/provider work, produce a MoonClaw patch plan or patch only when executing inside MoonClaw.",
    "- When execution mode is `acp`, use the configured Codex ACP target to patch the repository source root, not just the PlanBook workspace.",
    "- `repair_decision: accepted` is valid only with a `\{planbook_repair_patch_receipt_contract()}` receipt. Text claims without source-root ACP receipt evidence are rejected.",
    "- For self-patching work, repair the ACP/source-patch evidence loop. Do not directly repair individual live/runtime autonomy symptoms.",
    "- Never claim success because a markdown plan exists.",
    "- Rerun the PlanBook doctor after a local repair.",
    "- Run validation, inspect the focused diff, run `git diff --check`, and record `git status --short`.",
    "- If files changed and validation passed, create a local commit according to packet policy; commit only repair-owned files and preserve pre-existing unrelated dirty files; do not push unless the policy explicitly allows it.",
    "- Use exact `target_files` before any broad search.",
    "- Do not run whole-repo `find`, `rg`, or `search_files` until the exact target files prove insufficient.",
  ]
}

///|
fn planbook_repair_skill_example_section() -> String {
  [
    "## Concrete Example", "", "```md", "repair_decision: accepted", "criterion_id: planbook-live-spine",
    "files_changed: live_autonomy.mbt, planbook_autonomy.mbt", "validation: moon check --no-render passed; moon test planbook_autonomy_wbtest.mbt passed",
    "diff_summary: git diff --check passed; focused diff only changed live autonomy criterion wiring",
    "commit_status: committed", "commit_message: Route PlanBook live repair through autonomy spine",
    "push_status: not_pushed_by_policy", "remaining_blockers: none for this criterion",
    "cookbook_impact: update_needed", "patch_receipt:", "{ \"contract\": \"planbook.repair.patch_receipt.v1\", \"criterion_id\": \"planbook-source-patch-loop\", \"execution_mode\": \"acp\", \"execution_target\": \"codex-main\", \"result_decision\": \"accepted\" }",
    "```",
  ].join("\n")
}
